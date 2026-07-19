#!/usr/bin/env bash
# ==============================================================================
# e14-s03-scrape-hook.sh — POST_SERVE_HOOK for e14-s03-live-prove.sh
# ==============================================================================
#
# Runs while the ephemeral Nix VM is STILL ALIVE (invoked by the live-prove
# script's POST_SERVE_HOOK, with VM_IP exported). Proves the second half of
# E14-S03: the GSK-standing Prometheus scrapes the Nix VM's :2019/metrics and
# registers up=1 for the caddy job — the same job="caddy" contract E13-S05
# proved for the Ubuntu/Packer target, now with the Nix image as the target.
#
# It:
#   1. Applies a prometheus-operator ScrapeConfig (label release=monitoring so the
#      GSK Prometheus scrapeConfigSelector picks it up) with a single static
#      target ${VM_IP}:2019, job="caddy-nix-e14".
#   2. Port-forwards to the Prometheus service and polls the query API until
#      up{job="caddy-nix-e14"} == 1 (a real scrape landed), or times out.
#   3. ALWAYS cleans up (trap): kill the port-forward + delete the ScrapeConfig.
#      The VM itself is torn down by the parent live-prove script's own trap.
#
# Requires: KUBECONFIG pointed at the GSK cluster; VM_IP exported by the parent.
# ------------------------------------------------------------------------------
set -euo pipefail

: "${VM_IP:?VM_IP must be exported by the parent live-prove script}"
: "${KUBECONFIG:?KUBECONFIG must point at the GSK cluster}"

# Defence-in-depth: VM_IP comes from the gridscale API (.ip.ip), not attacker
# input, but validate the IPv4 shape before interpolating it into the ScrapeConfig
# heredoc so a malformed value can never inject YAML/target syntax.
[[ "$VM_IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] || { echo "VM_IP '$VM_IP' is not a dotted-quad IPv4" >&2; exit 1; }

NS="${MONITORING_NS:-monitoring}"
JOB="caddy-nix-e14"
SC_NAME="e14-s03-nix-serve"
PROM_SVC="${PROM_SVC:-monitoring-kube-prometheus-prometheus}"
PROM_PORT="${PROM_PORT:-9090}"
LOCAL_PORT="${LOCAL_PORT:-19090}"
UP_TIMEOUT_SECS="${UP_TIMEOUT_SECS:-150}"   # a couple of 30s scrape cycles + slack

PF_PID=""
cleanup() {
  local rc=$?
  [[ -n "$PF_PID" ]] && kill "$PF_PID" >/dev/null 2>&1 || true
  kubectl delete scrapeconfig "$SC_NAME" -n "$NS" --ignore-not-found >/dev/null 2>&1 || true
  echo "   scrape-hook cleanup done (ScrapeConfig deleted, port-forward killed)"
  exit "$rc"
}
trap cleanup EXIT

echo "   applying ScrapeConfig ${SC_NAME} (target ${VM_IP}:2019, job=${JOB})"
kubectl apply -n "$NS" -f - >/dev/null <<YAML
apiVersion: monitoring.coreos.com/v1alpha1
kind: ScrapeConfig
metadata:
  name: ${SC_NAME}
  namespace: ${NS}
  labels:
    release: monitoring
spec:
  jobName: ${JOB}
  metricsPath: /metrics
  scrapeInterval: 15s
  staticConfigs:
    - targets:
        - ${VM_IP}:2019
      labels:
        job: ${JOB}
YAML

echo "   port-forwarding svc/${PROM_SVC} ${LOCAL_PORT}->${PROM_PORT}"
kubectl port-forward -n "$NS" "svc/${PROM_SVC}" "${LOCAL_PORT}:${PROM_PORT}" >/dev/null 2>&1 &
PF_PID=$!
sleep 4   # let the forward establish

echo "   polling up{job=\"${JOB}\"}==1 (up to ${UP_TIMEOUT_SECS}s)"
deadline=$(( $(date +%s) + UP_TIMEOUT_SECS ))
up_val=""
while :; do
  # Prometheus instant query; jq extracts the scalar sample value ("1"/"0").
  up_val="$(curl -s --max-time 5 \
    "http://127.0.0.1:${LOCAL_PORT}/api/v1/query?query=up%7Bjob%3D%22${JOB}%22%7D" 2>/dev/null \
    | jq -r '.data.result[0].value[1] // empty' 2>/dev/null || true)"
  if [[ "$up_val" == "1" ]]; then
    echo "   up{job=\"${JOB}\"} = 1  [PASS] — GSK Prometheus scraped the Nix VM"
    exit 0
  fi
  if [[ $(date +%s) -ge $deadline ]]; then
    echo "   up{job=\"${JOB}\"} never reached 1 within ${UP_TIMEOUT_SECS}s (last: '${up_val:-none}')  [FAIL]" >&2
    exit 1
  fi
  sleep 5
done

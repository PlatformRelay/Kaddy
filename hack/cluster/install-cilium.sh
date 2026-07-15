#!/usr/bin/env bash
# Install Cilium (CNI + Gateway API + LB-IPAM/L2 + kube-proxy replacement) and the
# LB pool / L2 policy, carved from the real kind bridge subnet (E1e S02).
set -euo pipefail

CLUSTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${CLUSTER_DIR}/common.sh"

require_tools
detect_provider
use_context

DEPLOY_DIR="${REPO_ROOT}/deploy/cluster-local"

# --- 1) Gateway API standard-channel CRDs BEFORE Cilium (REQ-E1e-S02-02) ---
log "applying Gateway API ${GATEWAY_API_VERSION} standard-channel CRDs"
GWAPI_BASE="https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/standard-install.yaml"
kubectl apply -f "${GWAPI_BASE}"
kubectl wait --for=condition=Established --timeout=60s \
  crd/gateways.gateway.networking.k8s.io \
  crd/httproutes.gateway.networking.k8s.io \
  crd/gatewayclasses.gateway.networking.k8s.io

# --- 2) Cilium via Helm (pinned) ---
CP_IP="$(control_plane_ip)"
[[ -n "${CP_IP}" ]] || fail "could not determine control-plane IP for k8sServiceHost"
log "installing Cilium ${CILIUM_VERSION} (k8sServiceHost=${CP_IP})"

helm repo add cilium https://helm.cilium.io >/dev/null 2>&1 || true
helm repo update cilium >/dev/null 2>&1 || true

# kubeProxyReplacement=true is the desired secure default. On rootless podman it
# can be finicky; k8sServiceHost/Port are set explicitly (per the S02 note) to
# help the agents reach the API server. If it still will not go Ready, the
# documented fallback is CILIUM_KUBE_PROXY_REPLACEMENT=false (kube-proxy kept) —
# see the deviation note in the spec/proposal.
KPR="${CILIUM_KUBE_PROXY_REPLACEMENT:-true}"

helm upgrade --install cilium cilium/cilium \
  --version "${CILIUM_VERSION}" \
  --namespace kube-system \
  --set kubeProxyReplacement="${KPR}" \
  --set k8sServiceHost="${CP_IP}" \
  --set k8sServicePort=6443 \
  --set ipam.mode=kubernetes \
  --set gatewayAPI.enabled=true \
  --set l2announcements.enabled=true \
  --set "l2announcements.leaseDuration=3s" \
  --set "l2announcements.leaseRenewDeadline=1s" \
  --set "l2announcements.leaseRetryPeriod=200ms" \
  --set externalIPs.enabled=true \
  --wait --timeout "${HELM_TIMEOUT}"

log "waiting for cilium DaemonSet"
kubectl -n kube-system rollout status ds/cilium --timeout=180s

# --- 3) LB-IPAM pool carved from the ACTUAL kind bridge subnet (REQ-E1e-S02-03) ---
CLI="$(runtime_cli)"
KIND_SUBNET="$("${CLI}" network inspect kind 2>/dev/null \
  | jq -r 'if type=="array" then .[0] else . end
           | (.subnets[0].subnet // .IPAM.Config[0].Subnet // empty)' 2>/dev/null || true)"
if [[ -z "${KIND_SUBNET}" ]]; then
  log "WARN: could not read kind subnet from runtime — falling back to 172.18.0.0/16 default"
  KIND_SUBNET="172.18.0.0/16"
fi
# Carve a high /24 slice .200-.250 so it can't collide with node IPs.
BASE="$(echo "${KIND_SUBNET}" | cut -d/ -f1 | awk -F. '{printf "%s.%s.%s", $1,$2,$3}')"
LB_START="${BASE}.200"
LB_STOP="${BASE}.250"
log "LB-IPAM pool from kind subnet ${KIND_SUBNET}: ${LB_START}-${LB_STOP}"

RENDERED="${STATE_DIR}/lb-ippool.yaml"
sed -e "s#__LB_START__#${LB_START}#" -e "s#__LB_STOP__#${LB_STOP}#" \
  "${DEPLOY_DIR}/lb-ippool.yaml.tmpl" > "${RENDERED}"
kubectl apply -f "${RENDERED}"
kubectl apply -f "${DEPLOY_DIR}/l2-announcement.yaml"

# --- 4) cilium GatewayClass Accepted ---
log "waiting for cilium GatewayClass Accepted"
for _ in $(seq 1 30); do
  if kubectl get gatewayclass cilium -o json 2>/dev/null \
      | jq -e '.status.conditions[]? | select(.type=="Accepted") | .status=="True"' >/dev/null; then
    break
  fi
  sleep 4
done

log "Cilium install complete"

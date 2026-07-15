#!/usr/bin/env bash
# REQ-E1-EXIT: epic exit gate — the full E1 smoke bundle from a green cluster.
# Runs S01 (handoff runbook), S02 (argocd-server Running), S03 (cluster baseline),
# then proves ArgoCD is reachable THROUGH its Gateway HTTPRoute via the kind
# loopback port-mapping (macOS-safe) — HTTPS on 127.0.0.1:30443, TLS terminated at
# the Cilium Gateway with the kaddy-local-ca cert, routed to argocd-server (--insecure).
#
# Why the loopback nodePort (not port-forward, not the LB IP): the cilium-gateway
# LoadBalancer service is selectorless (Envoy datapath, not pods) so port-forward
# cannot attach; the LB-IPAM address is not host-routable across the macOS VM
# boundary. We pin the gateway service nodePort to 30443 (kind maps it to
# 127.0.0.1:30443) and curl that — traffic still traverses the Gateway + HTTPRoute.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

# 1) Story smokes, in order (each self-contained; S02 (re)bootstraps ArgoCD).
for t in e1-s01-01.sh req-e1-s02-01-argocd-server-running.sh e1-s03-01.sh; do
  echo "=== ${t} ==="
  bash "${DIR}/${t}" || smoke_fail "story smoke ${t} failed"
done

# 2) Gateway reachability (the EXIT proof).
NS="argocd"
GW_SVC="cilium-gateway-argocd"
HOST_PORT="${KIND_HOST_HTTPS_PORT:-30443}"

echo "=== REQ-E1-EXIT: ArgoCD via Gateway HTTPRoute on https://127.0.0.1:${HOST_PORT} ==="

# Gateway must be Programmed and hold an LB-IPAM address (assignment only — never
# host-curled; the raw LB IP is not routable from macOS).
addr=""
for _ in $(seq 1 45); do
  addr="$(kubectl -n "${NS}" get gateway argocd -o json 2>/dev/null \
    | jq -r '.status.addresses[0].value // empty')"
  [[ -n "${addr}" ]] && break
  sleep 4
done
[[ -n "${addr}" ]] || smoke_fail "Gateway argocd received no address in status.addresses"
echo "Gateway argocd address: ${addr} (asserted assigned only — NOT host-curled)"

# HTTPRoute must resolve its backendRef. The upstream install creates the
# argocd-server Service after our overlay applies the route, so an early apply can
# leave a stale ResolvedRefs=False; nudge a reconcile and wait for it to resolve.
resolved=""
for _ in $(seq 1 30); do
  resolved="$(kubectl -n "${NS}" get httproute argocd-server -o json 2>/dev/null \
    | jq -r '[.status.parents[]?.conditions[]? | select(.type=="ResolvedRefs") | .status] | first // empty')"
  [[ "${resolved}" == "True" ]] && break
  kubectl -n "${NS}" annotate httproute argocd-server \
    "kaddy.local/reconcile=$(date +%s)" --overwrite >/dev/null 2>&1 || true
  sleep 4
done
[[ "${resolved}" == "True" ]] || smoke_fail "HTTPRoute argocd-server did not resolve backendRefs"
echo "HTTPRoute argocd-server ResolvedRefs=True"

# Pin the gateway service nodePort to the loopback-mapped host port (30443).
# Idempotent: only patch if not already pinned; guard against another service
# holding the port (stale gateway from a prior run).
for _ in $(seq 1 30); do
  kubectl -n "${NS}" get svc "${GW_SVC}" >/dev/null 2>&1 && break
  sleep 3
done
kubectl -n "${NS}" get svc "${GW_SVC}" >/dev/null 2>&1 || smoke_fail "gateway service ${GW_SVC} not found"

cur_np="$(kubectl -n "${NS}" get svc "${GW_SVC}" -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)"
if [[ "${cur_np}" != "${HOST_PORT}" ]]; then
  holder="$(kubectl get svc -A -o json 2>/dev/null \
    | jq -r --argjson p "${HOST_PORT}" \
        '.items[] | select(.spec.ports[]?.nodePort==$p) | "\(.metadata.namespace)/\(.metadata.name)"' \
    | grep -v "^${NS}/${GW_SVC}$" || true)"
  [[ -z "${holder}" ]] \
    || smoke_fail "nodePort ${HOST_PORT} already held by ${holder} (stale gateway? delete that ns and retry)"
  kubectl -n "${NS}" patch svc "${GW_SVC}" --type=json \
    -p="[{\"op\":\"replace\",\"path\":\"/spec/ports/0/nodePort\",\"value\":${HOST_PORT}}]" >/dev/null \
    || smoke_fail "failed to pin ${GW_SVC} nodePort to ${HOST_PORT}"
fi
sleep 5
np="$(kubectl -n "${NS}" get svc "${GW_SVC}" -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)"
[[ "${np}" == "${HOST_PORT}" ]] || smoke_fail "gateway nodePort did not pin to ${HOST_PORT} (got ${np})"

# Real HTTPS via the host loopback (NOT the LB IP), through the Gateway HTTPRoute.
# -k: the serving cert is signed by the local CA; we skip CA verification here
# (traffic still traverses the Gateway — the LB IP is never curled).
echo "curling https://127.0.0.1:${HOST_PORT}/ (loopback -> node NodePort -> Cilium Gateway -> HTTPRoute -> argocd-server)"
code="000"
for _ in $(seq 1 20); do
  code="$(curl -k -fsS -o /dev/null -m 5 -w '%{http_code}' "https://127.0.0.1:${HOST_PORT}/" 2>/dev/null || echo 000)"
  [[ "${code}" == "200" ]] && break
  sleep 3
done
[[ "${code}" == "200" ]] || smoke_fail "expected HTTP 200 via loopback https://127.0.0.1:${HOST_PORT}, got ${code}"
echo "HTTP 200 via https://127.0.0.1:${HOST_PORT} through the ArgoCD Gateway HTTPRoute"

smoke_ok "REQ-E1-EXIT"

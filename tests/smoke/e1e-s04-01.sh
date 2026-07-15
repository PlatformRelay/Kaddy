#!/usr/bin/env bash
# REQ-E1e-S04-01: Gateway HTTP reachable locally (macOS-safe).
# Applies the smoke Gateway + HTTPRoute + echo backend, asserts the Gateway
# receives an LB-IPAM address (assignment only — never host-curled), then
# exercises real HTTP through `kubectl port-forward` to 127.0.0.1 (the docker/
# podman bridge is not host-routable on macOS, per the spec note).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

DEPLOY_DIR="${SMOKE_ROOT}/deploy/cluster-local"
PF_PID=""
cleanup() {
  [[ -n "${PF_PID}" ]] && kill "${PF_PID}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

kubectl apply -f "${DEPLOY_DIR}/smoke-gateway.yaml"
kubectl -n e1e-smoke rollout status deploy/echo --timeout=120s

# 1) Gateway must be Programmed and receive an assigned address (assignment only).
echo "waiting for Gateway kaddy-smoke to be programmed + get an address"
for _ in $(seq 1 45); do
  addr="$(kubectl -n e1e-smoke get gateway kaddy-smoke -o json 2>/dev/null \
    | jq -r '.status.addresses[0].value // empty')"
  if [[ -n "${addr}" ]]; then
    echo "Gateway assigned address: ${addr} (asserted assigned only — NOT host-curled)"
    break
  fi
  sleep 4
done
[[ -n "${addr:-}" ]] || smoke_fail "Gateway kaddy-smoke received no address in status.addresses"

# 2) Real HTTP via port-forward to loopback (NOT the LB IP).
# Gateways surface as a LoadBalancer service named cilium-gateway-<name>.
GW_SVC="cilium-gateway-kaddy-smoke"
kubectl -n e1e-smoke get svc "${GW_SVC}" >/dev/null 2>&1 \
  || smoke_fail "gateway service ${GW_SVC} not found"

kubectl -n e1e-smoke port-forward "svc/${GW_SVC}" 30080:80 >/dev/null 2>&1 &
PF_PID=$!
# give port-forward a moment to bind
for _ in $(seq 1 20); do
  if curl -fsS -o /dev/null "http://127.0.0.1:30080/" 2>/dev/null; then break; fi
  sleep 1
done

body="$(curl -fsS "http://127.0.0.1:30080/" 2>/dev/null || true)"
code="$(curl -fsS -o /dev/null -w '%{http_code}' "http://127.0.0.1:30080/" 2>/dev/null || echo 000)"
[[ "${code}" == "200" ]] || smoke_fail "expected HTTP 200 via loopback, got ${code}"
echo "HTTP 200 via 127.0.0.1 port-forward (body: ${body})"
smoke_ok "REQ-E1e-S04-01 Gateway HTTP reachable via loopback (macOS-safe)"

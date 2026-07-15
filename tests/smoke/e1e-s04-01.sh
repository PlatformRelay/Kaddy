#!/usr/bin/env bash
# REQ-E1e-S04-01: Gateway HTTP reachable locally (macOS-safe).
# Applies the smoke Gateway + HTTPRoute + echo backend, asserts the Gateway
# receives an LB-IPAM address (assignment only — never host-curled), then
# exercises real HTTP THROUGH the Cilium Gateway via the loopback-bound kind
# extraPortMapping (host 127.0.0.1:30080 -> node NodePort 30080).
#
# Why not port-forward: the Cilium gateway LoadBalancer service is selectorless
# (Cilium's Envoy datapath, not a pod), so `kubectl port-forward svc/...` cannot
# attach. Instead we pin that service's NodePort to 30080 — the port the kind
# node exposes on the host loopback — and curl 127.0.0.1:30080. Traffic still
# traverses the Gateway + HTTPRoute (verified: the LB IP is NOT curled).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

DEPLOY_DIR="${SMOKE_ROOT}/deploy/cluster-local"
NS="e1e-smoke"
GW_SVC="cilium-gateway-kaddy-smoke"
HOST_PORT="${KIND_HOST_HTTP_PORT:-30080}"

kubectl apply -f "${DEPLOY_DIR}/smoke-gateway.yaml"
kubectl -n "${NS}" rollout status deploy/echo --timeout=120s

# 1) Gateway must be Programmed and receive an assigned LB address (assignment only).
echo "waiting for Gateway kaddy-smoke to be programmed + get an address"
addr=""
for _ in $(seq 1 45); do
  addr="$(kubectl -n "${NS}" get gateway kaddy-smoke -o json 2>/dev/null \
    | jq -r '.status.addresses[0].value // empty')"
  if [[ -n "${addr}" ]]; then
    echo "Gateway assigned address: ${addr} (asserted assigned only — NOT host-curled)"
    break
  fi
  sleep 4
done
[[ -n "${addr}" ]] || smoke_fail "Gateway kaddy-smoke received no address in status.addresses"

# 2) Pin the gateway service NodePort to the loopback-mapped host port (30080).
echo "waiting for gateway service ${GW_SVC}"
for _ in $(seq 1 30); do
  kubectl -n "${NS}" get svc "${GW_SVC}" >/dev/null 2>&1 && break
  sleep 3
done
kubectl -n "${NS}" get svc "${GW_SVC}" >/dev/null 2>&1 || smoke_fail "gateway service ${GW_SVC} not found"

kubectl -n "${NS}" patch svc "${GW_SVC}" --type=json \
  -p="[{\"op\":\"replace\",\"path\":\"/spec/ports/0/nodePort\",\"value\":${HOST_PORT}}]" >/dev/null \
  || smoke_fail "failed to pin ${GW_SVC} nodePort to ${HOST_PORT}"
# Confirm the pin stuck (Cilium reconciles the service).
sleep 5
np="$(kubectl -n "${NS}" get svc "${GW_SVC}" -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)"
[[ "${np}" == "${HOST_PORT}" ]] || smoke_fail "gateway nodePort did not pin to ${HOST_PORT} (got ${np})"

# 3) Real HTTP via the host loopback (NOT the LB IP), through the Gateway.
echo "curling http://127.0.0.1:${HOST_PORT}/ (loopback -> node NodePort -> Cilium Gateway)"
code="000"
for _ in $(seq 1 20); do
  code="$(curl -fsS -o /dev/null -m 5 -w '%{http_code}' "http://127.0.0.1:${HOST_PORT}/" 2>/dev/null || echo 000)"
  [[ "${code}" == "200" ]] && break
  sleep 3
done
[[ "${code}" == "200" ]] || smoke_fail "expected HTTP 200 via loopback 127.0.0.1:${HOST_PORT}, got ${code}"

body="$(curl -fsS -m 5 "http://127.0.0.1:${HOST_PORT}/" 2>/dev/null || true)"
echo "HTTP 200 via 127.0.0.1:${HOST_PORT} through the Cilium Gateway (body: ${body})"
smoke_ok "REQ-E1e-S04-01 Gateway HTTP reachable via loopback (macOS-safe)"

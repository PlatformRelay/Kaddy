#!/usr/bin/env bash
# REQ-E4-S03-03 (should/optional): HTTP -> HTTPS redirect.
# Asserts the clubhouse-redirect HTTPRoute is Accepted on the Gateway's http
# listener and that plain HTTP through the Gateway returns a 301/308 redirect to
# https. Curled in-cluster (macOS loopback maps only 30080/30443, both held —
# see hack/smoke/https-clubhouse.sh header).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

NS="gateway"
HOST="clubhouse.kaddy.local"
GW_SVC="cilium-gateway-clubhouse"

kubectl apply -f "${SMOKE_ROOT}/deploy/gateway/namespace.yaml" >/dev/null
kubectl apply -f "${SMOKE_ROOT}/deploy/gateway/gateway.yaml" >/dev/null
kubectl apply -f "${SMOKE_ROOT}/deploy/gateway/httproute-redirect.yaml" >/dev/null

kubectl -n "${NS}" wait --for=condition=Programmed gateway/clubhouse --timeout=120s \
  || smoke_fail "Gateway clubhouse not Programmed"

# Route must be Accepted by the parent Gateway.
acc="$(kubectl -n "${NS}" get httproute clubhouse-redirect \
  -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}' 2>/dev/null || true)"
[[ "${acc}" == "True" ]] || smoke_fail "clubhouse-redirect HTTPRoute not Accepted (got '${acc}')"

for _ in $(seq 1 20); do
  kubectl -n "${NS}" get svc "${GW_SVC}" >/dev/null 2>&1 && break; sleep 3
done
GW_IP="$(kubectl -n "${NS}" get svc "${GW_SVC}" -o jsonpath='{.spec.clusterIP}' 2>/dev/null || true)"
[[ -n "${GW_IP}" ]] || smoke_fail "gateway service ${GW_SVC} has no clusterIP"

POD="clubhouse-redir-$$"
code="$(kubectl -n "${NS}" run "${POD}" --rm -i --restart=Never \
  --image=curlimages/curl:8.11.0 --quiet \
  --overrides='{"spec":{"securityContext":{"runAsNonRoot":true,"runAsUser":100}}}' \
  -- sh -c "curl -s -o /dev/null -w '%{http_code}' -H 'Host: ${HOST}' http://${GW_IP}:80/" \
  2>/dev/null || true)"
echo "plain-HTTP status via Gateway: ${code}"
case "${code}" in
  301|302|307|308) smoke_ok "REQ-E4-S03-03 HTTP redirects to HTTPS (${code})" ;;
  *) smoke_fail "expected 3xx redirect from HTTP listener, got '${code}'" ;;
esac

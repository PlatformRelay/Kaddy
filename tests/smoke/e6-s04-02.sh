#!/usr/bin/env bash
# REQ-E6-S04-02 — the root path is STILL the clubhouse landing page (the new
# website route must not shadow /). Curled in-cluster from the gateway ns with
# the E4-established probe pod pattern (clubhouse-smoke-* is Kyverno-excluded
# and covered by allow-probe-egress-to-edge).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/smoke/lib.sh
source "${DIR}/lib.sh"
smoke_require_cluster

NS="gateway"
HOST="clubhouse.kaddy.local"
GW_SVC="cilium-gateway-clubhouse"

GW_IP="$(kubectl -n "${NS}" get svc "${GW_SVC}" -o jsonpath='{.spec.clusterIP}' 2>/dev/null || true)"
[[ -n "${GW_IP}" ]] || smoke_fail "gateway service ${GW_SVC} has no clusterIP"

POD="clubhouse-smoke-$$"
raw="$(kubectl -n "${NS}" run "${POD}" --rm -i --restart=Never \
  --image=curlimages/curl:8.11.0 --quiet \
  --overrides='{"spec":{"securityContext":{"runAsNonRoot":true,"runAsUser":100}}}' \
  -- sh -c "printf 'CODE:'; curl -sk -o /tmp/body -w '%{http_code}' --resolve ${HOST}:443:${GW_IP} https://${HOST}:443/; printf '\nBODY:'; grep -c 'clubhouse' /tmp/body; printf '\n'" \
  2>/dev/null || true)"
code="$(printf '%s' "${raw}" | grep -oE 'CODE:[0-9]{3}' | head -1 | grep -oE '[0-9]{3}')"
body="$(printf '%s' "${raw}" | grep -oE 'BODY:[0-9]+' | head -1 | grep -oE '[0-9]+')"

echo "edge status for /: ${code}, clubhouse marker hits: ${body:-0}"
[[ "${code}" == "200" ]] || smoke_fail "expected 200 at /, got '${code}'"
[[ "${body:-0}" -ge 1 ]] || smoke_fail "root body missing 'clubhouse' marker — did a website route shadow /?"

smoke_ok "REQ-E6-S04-02 root path still serves clubhouse"

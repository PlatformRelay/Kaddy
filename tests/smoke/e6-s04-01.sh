#!/usr/bin/env bash
# REQ-E6-S04-01 — the claimed site answers 200 through the Cilium TLS edge at
# its route path (https://clubhouse.kaddy.local/putting-green/ -> showcase body).
# Curled in-cluster from the websites namespace (macOS loopback maps only
# 30080/30443 — same constraint as the E4 smokes). The probe pod carries the
# mandatory ADR-0301 labels (websites ns is Kyverno-enforced, no exclusions)
# and its egress is admitted by the allow-probe-egress-to-edge CNP mirrored
# into deploy/policies/network/websites.yaml.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/smoke/lib.sh
source "${DIR}/lib.sh"
smoke_require_cluster

NS="websites"
HOST="clubhouse.kaddy.local"
SITE_PATH="/putting-green/"
GW_SVC="cilium-gateway-clubhouse"

GW_IP="$(kubectl -n gateway get svc "${GW_SVC}" -o jsonpath='{.spec.clusterIP}' 2>/dev/null || true)"
[[ -n "${GW_IP}" ]] || smoke_fail "gateway service ${GW_SVC} has no clusterIP"

POD="website-smoke-$$"
LABELS="owner=platform-team,service=website-smoke,part-of=kaddy,managed-by=smoke-test,data-classification=internal,business-criticality=business-operational,track=stable"
raw="$(kubectl -n "${NS}" run "${POD}" --rm -i --restart=Never \
  --image=curlimages/curl:8.11.0 --quiet \
  --labels="${LABELS}" \
  --overrides='{"spec":{"securityContext":{"runAsNonRoot":true,"runAsUser":100}}}' \
  -- sh -c "printf 'CODE:'; curl -sk -o /tmp/body -w '%{http_code}' --resolve ${HOST}:443:${GW_IP} https://${HOST}:443${SITE_PATH}; printf '\nBODY:'; grep -c 'kaddy showcase' /tmp/body; printf '\n'" \
  2>/dev/null || true)"
code="$(printf '%s' "${raw}" | grep -oE 'CODE:[0-9]{3}' | head -1 | grep -oE '[0-9]{3}')"
body="$(printf '%s' "${raw}" | grep -oE 'BODY:[0-9]+' | head -1 | grep -oE '[0-9]+')"

echo "edge status for ${SITE_PATH}: ${code}, marker hits: ${body:-0} (raw: ${raw//$'\n'/ })"
[[ "${code}" == "200" ]] || smoke_fail "expected 200 via TLS edge at ${SITE_PATH}, got '${code}'"
[[ "${body:-0}" -ge 1 ]] || smoke_fail "response body missing marker 'kaddy showcase'"

smoke_ok "REQ-E6-S04-01 claimed site serves 200 through the Cilium TLS edge at ${SITE_PATH}"

#!/usr/bin/env bash
# REQ-E4-S03-04: Production Let's Encrypt cert issued and trusted (no -k, default
# system trust store) -> `200 0`.
#
# DEFERRED / NOT ISSUABLE ON KIND — documented, honest SKIP.
#   Let's Encrypt requires a public inbound HTTP-01 (or DNS-01) challenge against
#   a publicly resolvable hostname. The local kind/podman substrate has no public
#   DNS and no inbound reachability, so an LE order can never validate here — the
#   Certificate would hang `pending` forever. We therefore do NOT claim a real LE
#   prod cert was issued on kind.
#
#   The honest kind-local demonstration of "verified HTTPS, no -k" is
#   hack/smoke/https-clubhouse.sh, which verifies the chain via --cacert against
#   the genuinely-trusted kaddy-local-ca (verify=0, HTTP 200).
#
#   The cloud path (LE staging -> prod on a real hostname) is captured as
#   documented, sync-skipped manifests in
#   deploy/cert-manager/clubhouse-certificate-letsencrypt.yaml.
#
# Set E4_LE_PROD_HOST=<public-host> on a real cloud edge to actually run the
# verify command below; otherwise this test SKIPs (exit 0) by design.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"

HOST="${E4_LE_PROD_HOST:-}"
if [[ -z "${HOST}" ]]; then
  echo "SKIP: REQ-E4-S03-04 Let's Encrypt prod is cloud-only (not issuable on kind)."
  echo "      Kind-local verified-HTTPS evidence: hack/smoke/https-clubhouse.sh (verify=0, no -k)."
  exit 0
fi

# Cloud path: default system trust store, no --cacert, no -k.
res="$(curl -sS -o /dev/null -w '%{http_code} %{ssl_verify_result}' "https://${HOST}/" || true)"
echo "curl https://${HOST}/ -> ${res}"
[[ "${res}" == "200 0" ]] || smoke_fail "expected '200 0' (publicly trusted, HTTP 200), got '${res}'"
smoke_ok "REQ-E4-S03-04 LE prod cert publicly trusted (200 0)"

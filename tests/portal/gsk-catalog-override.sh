#!/usr/bin/env bash
# REQ-E10-S05 / GSK lab — the live Backstage override must NOT empty the
# software catalog. Live-proven 2026-07-20: portal.lab loaded as guest but
# Create → Templates was empty and Register Existing timed out to GitHub
# because:
#   1. ConfigMap backstage-override set `catalog: { locations: [] }` (wipes
#      baked-in platform + example Template locations)
#   2. default-deny NetPol blocked egress :443 (register url + scaffolder PR)
#
# This gate asserts the GitOps override + NetPol shape offline. It does NOT
# run Backstage.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"

OVERRIDE="${ROOT}/deploy/portal/backstage/gsk/app-config-override.yaml"
NETPOL="${ROOT}/deploy/portal/backstage/rbac/networkpolicy.yaml"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

[[ -f "${OVERRIDE}" ]] || fail "missing ${OVERRIDE} (GSK lab Backstage ConfigMap)"
[[ -f "${NETPOL}" ]]   || fail "missing ${NETPOL}"

# --- 1) ConfigMap mounts as backstage-override (live Deployment volume) ------
grep -qE 'kind:[[:space:]]*ConfigMap' "${OVERRIDE}" \
  || fail "gsk override must be a ConfigMap"
grep -qE 'name:[[:space:]]*backstage-override' "${OVERRIDE}" \
  || fail "ConfigMap must be named backstage-override (live Deployment mounts it)"
grep -qE 'namespace:[[:space:]]*portal' "${OVERRIDE}" \
  || fail "ConfigMap must live in namespace portal"
grep -qE 'app-config\.override\.yaml' "${OVERRIDE}" \
  || fail "ConfigMap must carry app-config.override.yaml key"
ok "GSK override ConfigMap is backstage-override in portal"

# --- 2) public URL is portal.lab (not the temporary LB bootstrap host) -------
# Assert inside the mounted override payload only (comments may mention the
# historical bootstrap hostname).
payload="$(awk '
  /^[[:space:]]*app-config\.override\.yaml:[[:space:]]*\|/ {inpayload=1; next}
  inpayload && /^[^ ]/ {inpayload=0}
  inpayload {print}
' "${OVERRIDE}")"
[[ -n "${payload}" ]] || fail "could not extract app-config.override.yaml payload"
printf '%s\n' "${payload}" | grep -qF 'portal.lab.platformrelay.dev' \
  || fail "override must set app/backend baseUrl to portal.lab.platformrelay.dev"
! printf '%s\n' "${payload}" | grep -qE 'nip\.io' \
  || fail "override payload must not keep the nip.io bootstrap baseUrl (breaks cookies/CORS on portal.lab)"
ok "override baseUrl is portal.lab.platformrelay.dev"

# --- 3) catalog.locations must load platform + Template (cwd-relative) -------
# The live bug was an empty locations array wipe. Omitting catalog: is NOT
# enough on GSK: the image's ../../ paths resolve from cwd=/app to /catalog/...
# and miss the files. Override MUST pin ./catalog/... and ./examples/... .
payload_nocomment="$(printf '%s\n' "${payload}" | sed 's/#.*//')"
if printf '%s\n' "${payload_nocomment}" | grep -qiE 'locations:[[:space:]]*\[\]'; then
  fail "override must NOT set catalog.locations: [] (that empties Create → Templates)"
fi
printf '%s\n' "${payload_nocomment}" | grep -qE '^[[:space:]]*catalog:' \
  || fail "override must set catalog: with cwd-relative locations (image ../../ paths break on GSK)"
printf '%s\n' "${payload}" | grep -qE '\./catalog/kaddy-platform\.yaml' \
  || fail "override catalog.locations must include ./catalog/kaddy-platform.yaml"
printf '%s\n' "${payload}" | grep -qE '\./examples/template/template\.yaml' \
  || fail "override catalog.locations must include ./examples/template/template.yaml (Create → Templates)"
printf '%s\n' "${payload_nocomment}" | grep -qiE 'allow:.*Template|Template' \
  || fail "override must allow Template kind for the example scaffolder location"
ok "override pins cwd-relative platform + Template catalog locations"

# --- 4) lab guest is explicit (Dex OIDC still the production target) ---------
# GSK lab currently has no Dex client wired for portal.lab — guest is the
# intentional lab path (ADR-0107 still owns production). Documented in the
# ConfigMap header; assert guest is present so operators know the trade.
printf '%s\n' "${payload}" | grep -qiE 'guest:' \
  || fail "GSK lab override must enable guest (Dex not wired on portal.lab yet)"
ok "GSK lab override keeps guest auth (lab-only; production stays OIDC)"

# --- 5) NetPol allows HTTPS egress for register + scaffolder -----------------
# Register Existing Component only accepts type=url and fetches raw GitHub;
# scaffolder publishPhase talks to api.github.com. Port-scoped :443 (same
# pattern as allow-apiserver :6443) — not an unscoped 0.0.0.0/0.
grep -qE 'name:[[:space:]]*allow-https-egress' "${NETPOL}" \
  || fail "networkpolicy.yaml must define allow-https-egress (GitHub register/scaffold)"
# Ensure the policy selects backstage and allows TCP 443.
awk '
  /name:[[:space:]]*allow-https-egress/ {inpol=1}
  inpol && /kind:[[:space:]]*NetworkPolicy/ {next}
  inpol && /^---/ {inpol=0}
  inpol {print}
' "${NETPOL}" | grep -qE 'port:[[:space:]]*443' \
  || fail "allow-https-egress must allow TCP 443"
awk '
  /name:[[:space:]]*allow-https-egress/ {inpol=1}
  inpol && /^---/ {inpol=0}
  inpol {print}
' "${NETPOL}" | grep -qE 'app:[[:space:]]*backstage' \
  || fail "allow-https-egress must select app: backstage"
ok "NetPol allow-https-egress selects backstage and allows :443"

echo "PASS: gsk-catalog-override — locations preserved + portal.lab URL + HTTPS egress"

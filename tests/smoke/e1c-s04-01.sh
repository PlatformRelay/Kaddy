#!/usr/bin/env bash
# REQ-E1c-S04-01 (offline, phase-2 facing): External Secrets Operator pattern
# for gridscale provider creds — docs + sample manifests only. Does NOT
# install ESO or touch live identity KSOPS.
#
# Asserts:
#   1) runbook documents SecretStore/ClusterSecretStore + ExternalSecret
#      and that ESO complements (does not replace) SOPS/KSOPS for Dex
#   2) sample manifests under deploy/examples/external-secrets/ exist with
#      the key fields (target Secret openstack-creds in crossplane-system)
#   3) samples are not wired into app-of-apps
#   4) no GRIDSCALE_TOKEN / plaintext token: credential literals under deploy/
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

DOC="${ROOT}/docs/runbooks/external-secrets-gridscale.md"
EXAMPLES="${ROOT}/deploy/examples/external-secrets"

# --- 1) Runbook present with required pattern language -----------------------
[[ -f "${DOC}" ]] || fail "missing ${DOC}"
for needle in \
  "ClusterSecretStore" \
  "ExternalSecret" \
  "openstack-creds" \
  "crossplane-system" \
  "SOPS" \
  "KSOPS" \
  "complement" \
  "gridscale"
do
  grep -qi "${needle}" "${DOC}" || fail "runbook missing required term: ${needle}"
done
ok "runbook documents ESO pattern + SOPS/KSOPS complement"

# --- 2) Sample manifests with key fields ------------------------------------
[[ -d "${EXAMPLES}" ]] || fail "missing ${EXAMPLES}/"
[[ -f "${EXAMPLES}/README.md" ]] || fail "missing ${EXAMPLES}/README.md"
grep -qiE 'example|not synced|do not apply|phase.?2' "${EXAMPLES}/README.md" \
  || fail "examples README must state these are examples / not synced"

store="$(find "${EXAMPLES}" -type f \( -name '*.yaml' -o -name '*.yml' \) \
  | xargs grep -l 'kind:[[:space:]]*ClusterSecretStore' 2>/dev/null | head -1 || true)"
[[ -n "${store}" ]] || fail "no ClusterSecretStore sample under ${EXAMPLES}"

es="$(find "${EXAMPLES}" -type f \( -name '*.yaml' -o -name '*.yml' \) \
  | xargs grep -l 'kind:[[:space:]]*ExternalSecret' 2>/dev/null | head -1 || true)"
[[ -n "${es}" ]] || fail "no ExternalSecret sample under ${EXAMPLES}"

# Target Secret name + namespace required by REQ-E1c-S04-02.
grep -q 'name:[[:space:]]*openstack-creds' "${es}" \
  || fail "ExternalSecret sample must target secret name openstack-creds"
grep -q 'namespace:[[:space:]]*crossplane-system' "${es}" \
  || fail "ExternalSecret sample must be in namespace crossplane-system"
# remoteRef (or dataFrom) — no inline credential values.
grep -qE 'remoteRef:|dataFrom:' "${es}" \
  || fail "ExternalSecret sample must use remoteRef or dataFrom (no inline secrets)"
ok "sample ClusterSecretStore + ExternalSecret present with key fields"

# --- 3) Not wired into app-of-apps ------------------------------------------
if grep -RIn --include='*.yaml' --include='*.yml' \
    -E 'path:[[:space:]]*deploy/examples' "${ROOT}/deploy/apps" >/dev/null 2>&1; then
  fail "deploy/apps must not sync deploy/examples (ESO samples are offline-only)"
fi
ok "deploy/examples not referenced by app-of-apps"

# --- 4) No gridscale credential literals under deploy/ ----------------------
# Flag GRIDSCALE_TOKEN assignments / YAML values, and token: "<non-empty>" /
# token: '<non-empty>' string literals. Allow secretKey: token and remote keys.
if grep -RIn --include='*.yaml' --include='*.yml' --include='*.md' --include='*.sh' \
    -E 'GRIDSCALE_TOKEN[[:space:]]*[=:][[:space:]]*[^[:space:]#]+' \
    "${ROOT}/deploy" >/dev/null 2>&1; then
  fail "GRIDSCALE_TOKEN literal assignment found under deploy/"
fi
# Plaintext token: "..." / token: '...' (not secretKey: token).
if grep -RIn --include='*.yaml' --include='*.yml' \
    -E '^[[:space:]]*token:[[:space:]]*["'\''][^"'\'']+["'\'']' \
    "${ROOT}/deploy" >/dev/null 2>&1; then
  fail "plaintext token: \"…\" literal found under deploy/"
fi
ok "no GRIDSCALE_TOKEN / plaintext token: literals under deploy/"

ok "REQ-E1c-S04-01 External Secrets pattern (offline)"

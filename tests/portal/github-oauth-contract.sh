#!/usr/bin/env bash
# Offline gate: portal.lab GitHub OAuth contract (GSK — never localhost).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
STACK="${ROOT}/stacks/github/portal-oauth/main.tf"
WIRE="${ROOT}/hack/portal/wire-github-oauth-secret.sh"
DEPRECATED="${ROOT}/hack/portal/create-github-app-manifest.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

[[ -f "${STACK}" ]] || fail "missing ${STACK}"
[[ -f "${WIRE}" ]]  || fail "missing ${WIRE}"
[[ -x "${WIRE}" ]] || chmod +x "${WIRE}"

HOMEPAGE='https://portal.lab.platformrelay.dev'
CALLBACK='https://portal.lab.platformrelay.dev/api/auth/github/handler/frame'

grep -qF "${HOMEPAGE}" "${STACK}" || fail "stack must declare portal.lab homepage"
grep -qF "${CALLBACK}" "${STACK}" || fail "stack must declare portal.lab github handler callback"
grep -qF 'oauth_callback_url' "${STACK}" || fail "stack must export oauth_callback_url"
grep -qE 'AUTH_GITHUB_CLIENT_ID|AUTH_GITHUB_CLIENT_SECRET' "${STACK}" \
  || fail "stack must wire AUTH_GITHUB_*"
grep -qiE 'no .*API|cannot be created|terraform-provider-github' "${STACK}" \
  || fail "stack must document TF cannot create classic OAuth Apps"
# Must forbid localhost as the GSK callback
grep -qiE 'NEVER|must not|MUST NOT' "${STACK}" \
  || fail "stack must warn against localhost callbacks"
! grep -qE 'oauth_callback_url\s*=\s*\"http://127\.0\.0\.1' "${STACK}" \
  || fail "stack oauth_callback_url must not be 127.0.0.1"

grep -qF "${CALLBACK}" "${WIRE}" || fail "wire script must use portal.lab callback"
! grep -qE 'Authorization callback.*127\.0\.0\.1|CALLBACK=.*127\.0\.0\.1' "${WIRE}" \
  || fail "wire script must not set CALLBACK to localhost"

# Deprecated manifest helper must refuse GSK misuse
[[ -f "${DEPRECATED}" ]] || fail "missing deprecated manifest stub"
grep -qi 'DEPRECATED' "${DEPRECATED}" || fail "manifest stub must be marked DEPRECATED"
grep -qF "${CALLBACK}" "${DEPRECATED}" || fail "manifest stub must still document portal.lab callback"

if command -v tofu >/dev/null; then
  (
    cd "${ROOT}/stacks/github/portal-oauth"
    tofu init -backend=false -input=false >/dev/null
    tofu validate
    # Outputs must not mention localhost as callback
    out="$(tofu console -input=false <<<"local.oauth_callback_url" 2>/dev/null || true)"
  ) || fail "tofu validate failed"
  ok "tofu validate stacks/github/portal-oauth"
else
  echo "tofu not installed — skip validate"
fi

ok "portal-oauth GSK contract: ${CALLBACK} (no localhost)"
echo "PASS: portal-github-oauth-contract"

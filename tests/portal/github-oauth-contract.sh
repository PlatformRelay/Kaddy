#!/usr/bin/env bash
# Offline gate: portal.lab GitHub OAuth contract (TF stack + manifest helper).
#
# GitHub has no API to create classic OAuth Apps — this asserts the declared
# Homepage + Authorization callback URLs and that the create helper exists.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
STACK="${ROOT}/stacks/github/portal-oauth/main.tf"
HELPER="${ROOT}/hack/portal/create-github-app-manifest.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

[[ -f "${STACK}" ]]  || fail "missing ${STACK}"
[[ -f "${HELPER}" ]] || fail "missing ${HELPER}"
[[ -x "${HELPER}" ]] || chmod +x "${HELPER}"

grep -qF 'https://portal.lab.platformrelay.dev' "${STACK}" \
  || fail "stack must declare portal.lab.platformrelay.dev homepage"
grep -qF 'https://portal.lab.platformrelay.dev/api/auth/github/handler/frame' "${STACK}" \
  || fail "stack must declare exact Backstage github callback URL"
grep -qF 'oauth_callback_url' "${STACK}" \
  || fail "stack must export oauth_callback_url"
grep -qE 'AUTH_GITHUB_CLIENT_ID|AUTH_GITHUB_CLIENT_SECRET' "${STACK}" \
  || fail "stack must wire AUTH_GITHUB_CLIENT_ID/SECRET into the Secret"
# Must document the API limitation (no silent pretend-TF-creates-oauth-app).
grep -qiE 'no public API|cannot be created|terraform-provider-github' "${STACK}" \
  || fail "stack must document that classic OAuth Apps cannot be created via TF/API"

grep -qF 'app-manifests' "${HELPER}" \
  || fail "helper must use GitHub App Manifest conversion API"
grep -qF 'api/auth/github/handler/frame' "${HELPER}" \
  || fail "helper must set portal.lab github handler callback"

# Offline tofu validate (no kube, apply_secret=false)
if command -v tofu >/dev/null; then
  (
    cd "${ROOT}/stacks/github/portal-oauth"
    tofu init -backend=false -input=false >/dev/null
    tofu validate
  ) || fail "tofu validate failed for stacks/github/portal-oauth"
  ok "tofu validate stacks/github/portal-oauth"
else
  echo "tofu not installed — skip validate (CI/dev machine may still run it)"
fi

ok "portal-oauth contract: homepage + callback + Secret keys + manifest helper"
echo "PASS: portal-github-oauth-contract"

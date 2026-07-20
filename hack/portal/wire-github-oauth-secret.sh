#!/usr/bin/env bash
# Wire a GitHub OAuth App / GitHub App OAuth credentials for GSK portal.lab.
#
# GSK callback is ALWAYS:
#   https://portal.lab.platformrelay.dev/api/auth/github/handler/frame
# NEVER http://127.0.0.1 or kind-local URLs.
#
# WHY NOT terraform-provider-github?
#   Classic OAuth Apps have NO create API (integrations/terraform-provider-github#786).
#   Create the app in the GitHub UI (or a GitHub App with the same callback), then
#   pass client_id/secret here to update Secret portal/backstage-github + SOPS.
#
# Usage (from repo root):
#   export KUBECONFIG=.state/gsk/kubeconfig
#   bash hack/portal/wire-github-oauth-secret.sh
#   # prompts for client id + secret, or pass via env:
#   AUTH_GITHUB_CLIENT_ID=… AUTH_GITHUB_CLIENT_SECRET=… bash hack/portal/wire-github-oauth-secret.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOMEPAGE="https://portal.lab.platformrelay.dev"
CALLBACK="https://portal.lab.platformrelay.dev/api/auth/github/handler/frame"
CREATE_URL="https://github.com/organizations/PlatformRelay/settings/applications/new"
# GitHub Apps (if you used App Manifest earlier) — edit Callback URL here:
APPS_URL="https://github.com/organizations/PlatformRelay/settings/apps"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

echo
echo "=== GSK portal.lab GitHub OAuth (NOT kind / NOT localhost) ==="
echo "  Homepage URL:              ${HOMEPAGE}"
echo "  Authorization callback URL: ${CALLBACK}"
echo
echo "Create or fix the app:"
echo "  Classic OAuth App:  ${CREATE_URL}"
echo "  Or existing GitHub App settings: ${APPS_URL}"
echo "    → set User authorization callback URL to EXACTLY the callback above"
echo "    → do NOT use http://127.0.0.1:8765/callback (that was only a one-shot"
echo "      create-helper redirect; it is NOT the Backstage login callback)"
echo

CLIENT_ID="${AUTH_GITHUB_CLIENT_ID:-}"
CLIENT_SECRET="${AUTH_GITHUB_CLIENT_SECRET:-}"

if [[ -z "${CLIENT_ID}" || -z "${CLIENT_SECRET}" ]]; then
  if [[ ! -t 0 ]]; then
    fail "set AUTH_GITHUB_CLIENT_ID and AUTH_GITHUB_CLIENT_SECRET (non-interactive)"
  fi
  read -r -p "Client ID: " CLIENT_ID
  read -r -s -p "Client secret: " CLIENT_SECRET
  echo
fi

[[ -n "${CLIENT_ID}" && -n "${CLIENT_SECRET}" ]] || fail "empty client id/secret"
[[ "${CLIENT_ID}" != *127.0.0.1* ]] || fail "client id looks wrong"
[[ "${CALLBACK}" != *127.0.0.1* && "${CALLBACK}" != *localhost* ]] || fail "callback must not be localhost"

export KUBECONFIG="${KUBECONFIG:-${ROOT}/.state/gsk/kubeconfig}"
[[ -f "${KUBECONFIG}" ]] || fail "KUBECONFIG missing: ${KUBECONFIG}"

kubectl --request-timeout=30s -n portal create secret generic backstage-github \
  --from-literal=AUTH_GITHUB_CLIENT_ID="${CLIENT_ID}" \
  --from-literal=AUTH_GITHUB_CLIENT_SECRET="${CLIENT_SECRET}" \
  --dry-run=client -o yaml | kubectl --request-timeout=30s apply -f -
ok "Secret portal/backstage-github updated (AUTH_GITHUB_*)"

# Ensure Deployment env refs exist — require BOTH id AND secret so a
# half-wired Deployment (e.g. only CLIENT_ID present) gets repaired.
env_names="$(kubectl --request-timeout=15s -n portal get deploy backstage \
  -o jsonpath='{.spec.template.spec.containers[0].env[*].name}')"
if ! grep -q 'AUTH_GITHUB_CLIENT_ID' <<<"${env_names}" \
  || ! grep -q 'AUTH_GITHUB_CLIENT_SECRET' <<<"${env_names}"; then
  kubectl --request-timeout=30s -n portal set env deployment/backstage \
    --from=secret/backstage-github
  ok "wired AUTH_GITHUB_* env from secret onto Deployment"
fi

kubectl --request-timeout=30s -n portal set env deployment/backstage NODE_ENV=production
kubectl --request-timeout=30s -n portal rollout restart deployment/backstage
kubectl --request-timeout=180s -n portal rollout status deployment/backstage --timeout=180s
ok "Backstage restarted"

# SOPS (optional)
if [[ "${SKIP_SOPS:-0}" != "1" ]] && command -v sops >/dev/null; then
  export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-${HOME}/.config/sops/age/keys.txt}"
  mkdir -p "${ROOT}/deploy/secrets/portal"
  OUT="${ROOT}/deploy/secrets/portal/backstage-github.enc.yaml"
  umask 077
  TMP="$(mktemp)"
  cat > "${TMP}" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: backstage-github
  namespace: portal
  labels:
    owner: platform-team
    service: portal
    part-of: kaddy
    managed-by: argocd
    app.kubernetes.io/name: backstage-github
    app.kubernetes.io/part-of: kaddy
type: Opaque
stringData:
  AUTH_GITHUB_CLIENT_ID: "${CLIENT_ID}"
  AUTH_GITHUB_CLIENT_SECRET: "${CLIENT_SECRET}"
EOF
  sops --encrypt --input-type yaml --output-type yaml "${TMP}" > "${OUT}"
  rm -f "${TMP}"
  ok "wrote encrypted ${OUT}"
fi

echo
echo "=== prove authorize redirect (must be portal.lab, not 127.0.0.1) ==="
LOC="$(curl -sS -D- -o /dev/null --connect-timeout 15 \
  "https://portal.lab.platformrelay.dev/api/auth/github/start?env=production" \
  | awk 'tolower($1)=="location:"{print $2}' | tr -d '\r')"
echo "Location: ${LOC}"
echo "${LOC}" | grep -q 'redirect_uri=https%3A%2F%2Fportal.lab.platformrelay.dev%2Fapi%2Fauth%2Fgithub%2Fhandler%2Fframe' \
  || echo "${LOC}" | grep -q 'portal.lab.platformrelay.dev/api/auth/github/handler/frame' \
  || fail "authorize Location missing portal.lab github handler callback"
echo "${LOC}" | grep -Eiq '127\.0\.0\.1|localhost' && fail "authorize Location still mentions localhost" || true
ok "redirect_uri is portal.lab …/api/auth/github/handler/frame (no localhost)"

echo
echo "Next: open ${HOMEPAGE}/login and complete GitHub consent."
echo "If GitHub still says redirect_uri mismatch, edit the App/OAuth App and set"
echo "  Authorization callback URL = ${CALLBACK}"

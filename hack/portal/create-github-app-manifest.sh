#!/usr/bin/env bash
# Create a GitHub App via the App Manifest flow and wire portal.lab Backstage
# AUTH_GITHUB_* (Secret portal/backstage-github + optional SOPS file).
#
# WHY NOT terraform-provider-github?
#   Classic OAuth Apps have NO create API — the TF provider cannot create them
#   (integrations/terraform-provider-github#786). The App Manifest flow is the
#   supported one-click create that returns client_id + client_secret usable by
#   Backstage's github auth provider (same /login/oauth/authorize dance).
#
# Usage (from repo root, operator browser already logged into GitHub):
#   bash hack/portal/create-github-app-manifest.sh
#
# Env:
#   PORTAL_OAUTH_ORG=PlatformRelay   (org that owns the App)
#   PORTAL_OAUTH_LISTEN=8765         (local redirect capture port)
#   KUBECONFIG=.state/gsk/kubeconfig (optional live apply)
#   SKIP_KUBECTL=1                   (SOPS only)
#   SKIP_SOPS=1                      (kubectl only)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ORG="${PORTAL_OAUTH_ORG:-PlatformRelay}"
LISTEN_PORT="${PORTAL_OAUTH_LISTEN:-8765}"
HOMEPAGE="https://portal.lab.platformrelay.dev"
CALLBACK="https://portal.lab.platformrelay.dev/api/auth/github/handler/frame"
REDIRECT="http://127.0.0.1:${LISTEN_PORT}/callback"
APP_NAME="kaddy-portal-lab"
STATE="kaddy-portal-$(date +%s)"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

command -v python3 >/dev/null || fail "python3 required"
command -v curl >/dev/null || fail "curl required"

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/kaddy-oauth-XXXXXX")"
trap 'rm -rf "${WORKDIR}"' EXIT
CODE_FILE="${WORKDIR}/code"
MANIFEST_HTML="${WORKDIR}/manifest.html"

# Manifest per https://docs.github.com/en/apps/sharing-github-apps/registering-a-github-app-from-a-manifest
MANIFEST_JSON="$(python3 - <<PY
import json
print(json.dumps({
  "name": "${APP_NAME}",
  "url": "${HOMEPAGE}",
  "hook_attributes": {"url": "${HOMEPAGE}/github/hook"},
  "redirect_url": "${REDIRECT}",
  "callback_urls": ["${CALLBACK}"],
  "setup_url": "${HOMEPAGE}",
  "description": "kaddy Backstage portal.lab (GSK) — GitHub sign-in only",
  "public": False,
  "default_events": [],
  "default_permissions": {},
  "request_oauth_on_install": True,
}))
PY
)"

python3 - <<PY > "${MANIFEST_HTML}"
import html, json, pathlib
manifest = '''${MANIFEST_JSON}'''
action = f"https://github.com/organizations/${ORG}/settings/apps/new?state=${STATE}"
pathlib.Path("${MANIFEST_HTML}").write_text(f"""<!DOCTYPE html>
<html><head><meta charset=utf-8><title>Create {html.escape("${APP_NAME}")}</title></head>
<body style="font-family:system-ui;max-width:40rem;margin:2rem auto">
  <h1>Create GitHub App for kaddy portal</h1>
  <p>This submits an <strong>App Manifest</strong> to <code>{html.escape("${ORG}")}</code>.
     After GitHub creates the App it redirects to localhost so this script can
     capture <code>client_id</code> / <code>client_secret</code>.</p>
  <p>Callback wired into the App: <code>{html.escape("${CALLBACK}")}</code></p>
  <form action="{html.escape(action)}" method="post">
    <input type="hidden" name="manifest" value="{html.escape(manifest)}">
    <button type="submit" style="font-size:1.1rem;padding:.6rem 1.2rem">Create GitHub App on {html.escape("${ORG}")}</button>
  </form>
</body></html>
""")
PY

# Local one-shot HTTP server to capture ?code=
export CODE_FILE LISTEN_PORT
CODE_FILE="${CODE_FILE}" PORTAL_OAUTH_LISTEN="${LISTEN_PORT}" python3 - <<'PY' &
import http.server, urllib.parse, pathlib, os, threading, time
port=int(os.environ["PORTAL_OAUTH_LISTEN"])
code_file=pathlib.Path(os.environ["CODE_FILE"])
class H(http.server.BaseHTTPRequestHandler):
  def log_message(self,*a): pass
  def do_GET(self):
    q=urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
    if self.path.startswith("/callback") and "code" in q:
      code_file.write_text(q["code"][0])
      body=b"<h1>OK — return to the terminal.</h1><p>You can close this tab.</p>"
      self.send_response(200); self.send_header("Content-Type","text/html"); self.end_headers(); self.wfile.write(body)
      threading.Thread(target=lambda: (time.sleep(0.3), self.server.shutdown()), daemon=True).start()
    else:
      self.send_response(404); self.end_headers()
http.server.HTTPServer(("127.0.0.1",port),H).serve_forever()
PY
SERVER_PID=$!
trap 'kill ${SERVER_PID} 2>/dev/null || true; rm -rf "${WORKDIR}"' EXIT

echo
echo "Opening App Manifest form in your browser…"
echo "  Homepage:  ${HOMEPAGE}"
echo "  Callback:  ${CALLBACK}"
echo "  Org:       ${ORG}"
echo
if command -v open >/dev/null; then
  open "${MANIFEST_HTML}"
elif command -v xdg-open >/dev/null; then
  xdg-open "${MANIFEST_HTML}"
else
  echo "Open this file in a browser: ${MANIFEST_HTML}"
fi

echo "Waiting for GitHub redirect to ${REDIRECT} …"
for _ in $(seq 1 180); do
  if [[ -s "${CODE_FILE}" ]]; then
    break
  fi
  sleep 1
done
[[ -s "${CODE_FILE}" ]] || fail "timed out waiting for GitHub redirect (did you complete the Create flow?)"

CODE="$(cat "${CODE_FILE}")"
ok "captured manifest code"

# Exchange code → App credentials (includes oauth client_id + client_secret)
CONV="$(curl -sS -X POST \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app-manifests/${CODE}/conversions")"

CLIENT_ID="$(python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("client_id") or "")' <<<"${CONV}")"
CLIENT_SECRET="$(python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("client_secret") or "")' <<<"${CONV}")"
APP_ID="$(python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("id") or "")' <<<"${CONV}")"
HTML_URL="$(python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("html_url") or "")' <<<"${CONV}")"

[[ -n "${CLIENT_ID}" && -n "${CLIENT_SECRET}" ]] \
  || fail "manifest conversion missing client_id/secret: $(python3 -c 'import json,sys; print(json.load(sys.stdin).get("message","?"))' <<<"${CONV}")"

ok "GitHub App created id=${APP_ID} client_id=${CLIENT_ID:0:8}… settings=${HTML_URL}"
echo
echo "IMPORTANT: confirm the App's Callback URL is exactly:"
echo "  ${CALLBACK}"
echo "(User authorization → Callback URL in ${HTML_URL})"
echo

# Live Secret
if [[ "${SKIP_KUBECTL:-0}" != "1" ]]; then
  export KUBECONFIG="${KUBECONFIG:-${ROOT}/.state/gsk/kubeconfig}"
  [[ -f "${KUBECONFIG}" ]] || fail "KUBECONFIG not found at ${KUBECONFIG}"
  kubectl --request-timeout=30s -n portal create secret generic backstage-github \
    --from-literal=AUTH_GITHUB_CLIENT_ID="${CLIENT_ID}" \
    --from-literal=AUTH_GITHUB_CLIENT_SECRET="${CLIENT_SECRET}" \
    --dry-run=client -o yaml | kubectl --request-timeout=30s apply -f -
  ok "Secret portal/backstage-github applied"
  kubectl --request-timeout=30s -n portal rollout restart deployment/backstage
  kubectl --request-timeout=180s -n portal rollout status deployment/backstage --timeout=180s
  ok "Backstage restarted"
fi

# SOPS-encrypted GitOps copy (no plaintext)
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

# Prove redirect_uri is what we expect (login still needs operator consent in browser)
if curl -sS -D- -o /dev/null --connect-timeout 10 \
  "https://portal.lab.platformrelay.dev/api/auth/github/start?env=production" 2>/dev/null \
  | grep -qi "redirect_uri=.*portal.lab.platformrelay.dev"; then
  ok "live /api/auth/github/start redirects with portal.lab callback"
fi

echo
echo "Done. Complete GitHub login at:"
echo "  https://portal.lab.platformrelay.dev/login"
echo "App settings: ${HTML_URL}"

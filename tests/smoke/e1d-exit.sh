#!/usr/bin/env bash
# REQ-E1d-EXIT — E1d live exit bundle:
#   the KSOPS chain renders SOPS-encrypted git into live Secrets, Dex serves
#   OIDC through the Gateway, Argo CD offers OIDC login and its redirect
#   chain reaches GitHub's authorize endpoint with the right client_id, the
#   API stays closed unauthenticated, and the identity netpol baseline holds.
# Secret VALUES are never printed — comparisons happen in-shell, output is
# redacted.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

ARGOCD="https://127.0.0.1:30443"
ISSUER="https://dex.kaddy.local:30443"
RESOLVE=(--resolve "dex.kaddy.local:30443:127.0.0.1")

# 1) identity Application Synced/Healthy with content (no longer a placeholder).
sync="$(kubectl -n argocd get application identity -o jsonpath='{.status.sync.status}')"
health="$(kubectl -n argocd get application identity -o jsonpath='{.status.health.status}')"
[[ "${sync}/${health}" == "Synced/Healthy" ]] \
  || smoke_fail "identity app is ${sync}/${health}"
n="$(kubectl -n argocd get application identity -o json | jq '.status.resources | length')"
[[ "${n}" -ge 7 ]] || smoke_fail "identity app tracks only ${n} resources (placeholder?)"
smoke_ok "identity Application Synced/Healthy with ${n} tracked resources"

# 2) Dex Deployment Ready (REQ-E1d-S01-01).
kubectl -n identity rollout status deploy/dex --timeout=180s >/dev/null \
  || smoke_fail "dex Deployment not Ready"
smoke_ok "dex Deployment Ready in identity ns"

# 3) Story-level smokes.
bash "${DIR}/e1d-s01-02.sh"
bash "${DIR}/e1d-s01-04.sh"
bash "${DIR}/e1d-s01-05.sh"
bash "${DIR}/e1d-s01-06.sh"
bash "${DIR}/e1d-s02-03.sh"

# 4) REQ-E1d-S01-03: live connector matches the golden fixture.
live_conn="$(kubectl -n identity get cm dex -o jsonpath='{.data.config\.yaml}' \
  | yq e '{"connectors": .connectors}' -)"
golden_conn="$(yq e '{"connectors": .connectors}' "${ROOT}/tests/fixtures/dex-github-connector-golden.yaml")"
diff <(echo "${live_conn}") <(echo "${golden_conn}") >/dev/null \
  || smoke_fail "live dex connector drifts from tests/fixtures/dex-github-connector-golden.yaml"
smoke_ok "dex GitHub connector matches golden (org PlatformRelay)"

# 5) REQ-E1d-S02-01a: Argo CD advertises OIDC login (settings endpoint feeds
#    the login page button).
oidc_name="$(curl -fsk "${ARGOCD}/api/v1/settings" | jq -r '.oidcConfig.name // empty')"
[[ "${oidc_name}" == "GitHub (Dex)" ]] \
  || smoke_fail "argocd settings advertise no OIDC config (got '${oidc_name}')"
smoke_ok "argocd login offers OIDC provider '${oidc_name}'"

# 6) REQ-E1d-S02-01b: the login redirect chain
#    argocd /auth/login -> dex /auth -> dex /auth/github -> github.com/login/oauth/authorize
#    is followed WITHOUT completing the OAuth dance (interactive operator step).
loc1="$(curl -sk -o /dev/null -w '%{redirect_url}' "${ARGOCD}/auth/login")"
[[ "${loc1}" == "${ISSUER}/auth?"* ]] \
  || smoke_fail "argocd /auth/login did not redirect to the dex issuer (got '${loc1%%\?*}...')"
grep -q "client_id=argocd" <<<"${loc1}" || smoke_fail "dex redirect lacks client_id=argocd"
smoke_ok "argocd /auth/login redirects to dex authorize endpoint (client_id=argocd)"

loc2="$(curl -sk -o /dev/null -w '%{redirect_url}' "${RESOLVE[@]}" "${loc1}")"
if [[ "${loc2}" == /auth/github* ]]; then loc2="${ISSUER}${loc2}"; fi
[[ "${loc2}" == "${ISSUER}/auth/github?"* ]] \
  || smoke_fail "dex /auth did not hand off to the github connector (got '${loc2%%\?*}')"

loc3="$(curl -sk -o /dev/null -w '%{redirect_url}' "${RESOLVE[@]}" "${loc2}")"
[[ "${loc3}" == "https://github.com/login/oauth/authorize?"* ]] \
  || smoke_fail "dex github connector did not redirect to github.com/login/oauth/authorize (got '${loc3%%\?*}')"
gh_client_id="$(sed -n 's/.*[?&]client_id=\([^&]*\).*/\1/p' <<<"${loc3}")"
[[ -n "${gh_client_id}" ]] || smoke_fail "github authorize redirect lacks client_id"

# Compare against the SOPS-encrypted source of truth — in-shell only, never
# printed (requires the operator age key; otherwise presence-only assert).
export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-${HOME}/.config/sops/age/keys.txt}"
if [[ -f "${SOPS_AGE_KEY_FILE}" ]]; then
  want_id="$(sops --decrypt "${ROOT}/deploy/secrets/identity/dex-github.enc.yaml" \
    | yq e '.stringData."client-id"' -)"
  [[ "${gh_client_id}" == "${want_id}" ]] \
    || smoke_fail "github authorize client_id does not match the SOPS-encrypted client-id"
  unset want_id
  smoke_ok "redirect chain reaches github.com/login/oauth/authorize with the RIGHT client_id (value redacted)"
else
  smoke_ok "redirect chain reaches github.com/login/oauth/authorize with a client_id (no age key on host — value unverified)"
fi
unset gh_client_id
echo "     note: completing the GitHub consent is the documented interactive operator step"

# 7) REQ-E1d-S02-02: unauthenticated API access denied.
code="$(curl -sk -o /dev/null -w '%{http_code}' "${ARGOCD}/api/v1/applications")"
[[ "${code}" == "401" || "${code}" == "403" ]] \
  || smoke_fail "unauthenticated /api/v1/applications returned ${code} (want 401/403)"
smoke_ok "unauthenticated argocd API denied (${code})"

# 8) REQ-E1d-S04-01/-02: identity netpol baseline present + deny is real.
kubectl -n identity get networkpolicy default-deny-all >/dev/null \
  || smoke_fail "identity default-deny-all missing"
kubectl -n identity get cnp allow-gateway-to-dex >/dev/null \
  || smoke_fail "identity CNP allow-gateway-to-dex missing"
smoke_ok "identity default-deny + gateway CNP present"

# Deny branch: a pod in an unrelated namespace cannot reach dex :5556.
# (default ns; labeled so Kyverno admits it — netpol, not admission, must block.)
dex_ip="$(kubectl -n identity get svc dex -o jsonpath='{.spec.clusterIP}')"
kubectl -n default delete pod e1d-deny-probe --ignore-not-found --now >/dev/null 2>&1
# --overrides: the probe must itself pass the Enforce admission set
# (nonroot, no-privesc) — netpol, not admission, is what must block it.
kubectl -n default run e1d-deny-probe --restart=Never --image=curlimages/curl:8.11.0 \
  --labels="owner=platform-team,service=identity,part-of=kaddy,managed-by=argocd,data-classification=internal,business-criticality=business-operational,track=stable,app.kubernetes.io/name=e1d-deny-probe" \
  --overrides='{"spec":{"securityContext":{"runAsNonRoot":true,"runAsUser":100,"seccompProfile":{"type":"RuntimeDefault"}},"containers":[{"name":"e1d-deny-probe","image":"curlimages/curl:8.11.0","command":["curl","-sf","-m","5","http://'"${dex_ip}"':5556/healthz"],"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}}]}}' \
  >/dev/null \
  || smoke_fail "deny-probe pod was not admitted (drifted from the Kyverno Enforce set?)"
phase=""
for _ in $(seq 1 30); do
  phase="$(kubectl -n default get pod e1d-deny-probe -o jsonpath='{.status.phase}' 2>/dev/null || true)"
  [[ "${phase}" == "Succeeded" || "${phase}" == "Failed" ]] && break
  sleep 2
done
kubectl -n default delete pod e1d-deny-probe --ignore-not-found --now >/dev/null 2>&1 || true
[[ "${phase}" == "Failed" ]] \
  || smoke_fail "probe from default ns REACHED dex :5556 (phase=${phase}; default-deny not enforcing)"
smoke_ok "cross-namespace probe to dex :5556 denied (default-deny enforcing)"

echo
echo "E1d exit bundle green — KSOPS chain, Dex issuer, ArgoCD OIDC redirect, RBAC, netpol."

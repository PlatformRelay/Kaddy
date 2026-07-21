#!/usr/bin/env bash
# E1g-S05 follow-up (operator directive: "everything on gridscale, GitOps-managed")
# — OFFLINE gate for the GSK cloud-edge Argo CD Applications in deploy/apps-cloud/.
#
# The imperative hack/gsk/edge-up.sh manifest applies (deploy/gateway/cloud-only/
# + the DNS-01 issuers) are codified as Applications so Argo OWNS the edge on GSK.
# No cluster, no API. Asserts:
#   1. Both cloud-edge Apps exist, parse, and are kind: Application.
#   2. Both are scoped to the closed-list gsk-cloud-edge AppProject.
#   3. The Traefik App pins an exact numeric chart version (no floating tag).
#   4. gateway App syncs deploy/gateway/cloud-only with retry (Traefik-readiness
#      ordering) and automated prune:true / selfHeal:false.
#   5. cert-manager App syncs ONLY the DNS-01 ClusterIssuers (directory.include)
#      — the ExternalSecret stays out-of-band, the deferred E4 clubhouse certs
#      stay unapplied (exactly what edge-up.sh applied imperatively).
#   6. KIND-SAFETY (behavioural): the kind root app-of-apps recurses ONLY
#      deploy/apps, and NO Application under deploy/apps/ (which root would
#      auto-apply on kind) is scoped to gsk-cloud-edge — copying the cloud-edge
#      Apps into root's path MUST fail this gate.
#   7. The gsk-cloud-edge AppProject allowlists every namespace the cloud-only
#      manifests actually use, plus the cluster-scoped ClusterIssuer.
#   8. edge-up.sh hands ownership to Argo (applies deploy/apps-cloud/), keeping
#      the raw manifests as documented break-glass only.
#   9. kubeconform schema-validates the App manifests (if installed).
#  10. The gsk-cloud-edge AppProject spec.description FOLDS to <=255 chars —
#      Argo's API server rejects longer ones (seen live: the apply failed and
#      the cluster kept the OLD project, blocking both cloud-edge Apps).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"

APPS_CLOUD="${ROOT}/deploy/apps-cloud"
GW_APP="${APPS_CLOUD}/gateway-cloud-edge.yaml"
CM_APP="${APPS_CLOUD}/cert-manager-cloud-edge.yaml"
TRAEFIK_APP="${ROOT}/deploy/gateway-controller/traefik/application.yaml"
ROOT_APP="${ROOT}/deploy/apps/root.yaml"
PROJECT="${ROOT}/deploy/apps/projects/gsk-cloud-edge.yaml"
EDGE_UP="${ROOT}/hack/gsk/edge-up.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }
need_file() { [[ -f "$1" ]] || fail "missing $1"; }

command -v yq >/dev/null 2>&1 || fail "yq required for this gate"

need_file "${GW_APP}"
need_file "${CM_APP}"
need_file "${TRAEFIK_APP}"
need_file "${ROOT_APP}"
need_file "${PROJECT}"
need_file "${EDGE_UP}"

# --- 1+2) Apps parse, are Applications, and are project-scoped ---------------
for app in "${GW_APP}" "${CM_APP}"; do
  kind="$(yq -r '.kind' "${app}")" || fail "unparseable YAML: ${app}"
  [[ "${kind}" == "Application" ]] || fail "$(basename "${app}") must be an Argo CD Application (got kind: ${kind})"
  proj="$(yq -r '.spec.project' "${app}")"
  [[ "${proj}" == "gsk-cloud-edge" ]] \
    || fail "$(basename "${app}") must use the closed-list gsk-cloud-edge AppProject (got: ${proj})"
done
ok "cloud-edge Apps parse and are scoped to gsk-cloud-edge"

# --- 3) Traefik chart version pinned (no floating tag) -----------------------
traefik_rev="$(yq -r '.spec.source.targetRevision' "${TRAEFIK_APP}")"
[[ "${traefik_rev}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
  || fail "Traefik App must pin an exact chart version (got: ${traefik_rev})"
ok "Traefik chart version pinned (${traefik_rev})"

# --- 4) gateway App: path, retry ordering, sync policy -----------------------
gw_path="$(yq -r '.spec.source.path' "${GW_APP}")"
[[ "${gw_path}" == "deploy/gateway/cloud-only" ]] \
  || fail "gateway-cloud-edge must sync deploy/gateway/cloud-only (got: ${gw_path})"
retry_limit="$(yq -r '.spec.syncPolicy.retry.limit // "missing"' "${GW_APP}")"
[[ "${retry_limit}" =~ ^[0-9]+$ && "${retry_limit}" -ge 1 ]] \
  || fail "gateway-cloud-edge needs syncPolicy.retry (Traefik/CRD readiness ordering)"
for app in "${GW_APP}" "${CM_APP}"; do
  [[ "$(yq -r '.spec.syncPolicy.automated.prune' "${app}")" == "true" ]] \
    || fail "$(basename "${app}") must set automated.prune: true (repo convention)"
  [[ "$(yq -r '.spec.syncPolicy.automated.selfHeal' "${app}")" == "false" ]] \
    || fail "$(basename "${app}") must set automated.selfHeal: false (live edge — human in the loop)"
done
ok "gateway App syncs cloud-only with retry; sync policy matches conventions"

# --- 5) cert-manager App: issuers only (matches the imperative apply) --------
cm_path="$(yq -r '.spec.source.path' "${CM_APP}")"
[[ "${cm_path}" == "deploy/cert-manager/cloud-only" ]] \
  || fail "cert-manager-cloud-edge must sync deploy/cert-manager/cloud-only (got: ${cm_path})"
cm_include="$(yq -r '.spec.source.directory.include // "missing"' "${CM_APP}")"
# Exact match, not substring: widening the include (e.g. '*.yaml' or a brace
# pattern that still contains the dns01 stem) must FAIL this gate.
[[ "${cm_include}" == "cluster-issuer-dns01-*.yaml" ]] \
  || fail "cert-manager-cloud-edge must directory.include EXACTLY 'cluster-issuer-dns01-*.yaml' (ExternalSecret + deferred E4 certs stay out of sync); got: ${cm_include}"
ok "cert-manager App syncs only the DNS-01 ClusterIssuers"

# --- 6) KIND-SAFETY: root never picks up the cloud-edge Apps -----------------
root_path="$(yq -r '.spec.source.path' "${ROOT_APP}")"
[[ "${root_path}" == "deploy/apps" ]] \
  || fail "kind root app-of-apps must sync exactly deploy/apps (got: ${root_path})"
case "${APPS_CLOUD}" in
  "${ROOT}/deploy/apps/"*) fail "deploy/apps-cloud must NOT live under root's deploy/apps path" ;;
esac
while IFS= read -r -d '' f; do
  while IFS=$'\t' read -r k p; do
    [[ "${k}" == "Application" ]] || continue
    [[ "${p}" != "gsk-cloud-edge" ]] \
      || fail "KIND-SAFETY VIOLATION: ${f#"${ROOT}"/} is a gsk-cloud-edge Application inside root's deploy/apps path — the kind cluster would apply the GSK cloud edge"
  done < <(yq -r 'select(.kind != null) | [.kind, .spec.project // "none"] | @tsv' "${f}" 2>/dev/null || true)
done < <(find "${ROOT}/deploy/apps" -name '*.yaml' -print0)
ok "kind-safety: root recurses only deploy/apps and holds no gsk-cloud-edge Apps"

# --- 7) AppProject allowlists cover what the Apps deploy ---------------------
# Every namespaced resource in deploy/gateway/cloud-only must land in a project
# destination namespace (closed list — extend the project when adding a route ns).
proj_ns="$(yq -r '.spec.destinations[].namespace' "${PROJECT}")"
while IFS= read -r ns; do
  [[ -z "${ns}" || "${ns}" == "null" || "${ns}" == "---" ]] && continue
  grep -qxF -- "${ns}" <<<"${proj_ns}" \
    || fail "namespace '${ns}' (deploy/gateway/cloud-only) missing from gsk-cloud-edge project destinations"
done < <(yq -r 'select(.metadata.namespace != null) | .metadata.namespace' "${ROOT}"/deploy/gateway/cloud-only/*.yaml | sort -u)
# The issuers App destination namespace must be permitted too.
cm_ns="$(yq -r '.spec.destination.namespace' "${CM_APP}")"
grep -qxF -- "${cm_ns}" <<<"${proj_ns}" \
  || fail "cert-manager App destination ns '${cm_ns}' missing from gsk-cloud-edge project destinations"
# ClusterIssuer is cluster-scoped — must be on the closed clusterResourceWhitelist.
yq -e '.spec.clusterResourceWhitelist[] | select(.group == "cert-manager.io" and .kind == "ClusterIssuer")' \
  "${PROJECT}" >/dev/null 2>&1 \
  || fail "gsk-cloud-edge project must whitelist cert-manager.io/ClusterIssuer (cluster-scoped)"
ok "gsk-cloud-edge project allowlists cover the cloud-edge Apps (closed list)"

# --- 8) edge-up.sh hands the edge to Argo ------------------------------------
grep -q 'deploy/apps-cloud' "${EDGE_UP}" \
  || fail "edge-up.sh must apply deploy/apps-cloud/ (Argo owns the edge after bootstrap)"
if grep -qE '^[^#]*kubectl apply -f "\$\{REPO_ROOT\}/deploy/gateway/cloud-only/?"' "${EDGE_UP}"; then
  fail "edge-up.sh still applies deploy/gateway/cloud-only imperatively — Argo must own it (raw apply is break-glass, documented not scripted)"
fi
if grep -qE '^[^#]*kubectl apply -f "\$\{REPO_ROOT\}/deploy/cert-manager/cloud-only/cluster-issuer' "${EDGE_UP}"; then
  fail "edge-up.sh still applies the DNS-01 issuers imperatively — Argo must own them"
fi
ok "edge-up.sh bootstraps the Apps once; Argo owns the edge"

# --- 9) kubeconform schema validation ----------------------------------------
if command -v kubeconform >/dev/null 2>&1; then
  kubeconform -strict -ignore-missing-schemas -summary \
    "${GW_APP}" "${CM_APP}" >/dev/null \
    || fail "kubeconform rejected a cloud-edge App manifest"
  ok "kubeconform: cloud-edge App manifests schema-valid"
else
  echo "kubeconform not installed — skip schema validation (CI installs it)"
fi

# --- 10) AppProject description within Argo's 255-char server-side limit -----
# Argo CD rejects AppProjects whose spec.description exceeds 255 characters
# ("spec.description: Too long"). Measure the FOLDED scalar — exactly the
# string the API server validates — in bytes (strictest; description must stay
# ASCII so bytes == chars). yq emits the parsed (post-folding) value plus ONE
# trailing newline of its own; strip exactly that one — NOT every newline:
# multi-paragraph folded scalars (blank lines under >-) keep real \n characters
# that the server counts too.
folded_desc_len() {
  local n
  n="$(yq -r '.spec.description // ""' "$1" | wc -c | tr -d ' ')"
  echo "$(( n - 1 ))"
}
# Self-check the folding emulation against a known multi-paragraph fixture:
# >- folds the single line break to a space but KEEPS the blank-line paragraph
# break as \n, so 'a / b / <blank> / c' folds to 'a b\nc' = 5 bytes.
fixture="$(mktemp)"
trap 'rm -f "${fixture}"' EXIT
printf 'spec:\n  description: >-\n    a\n    b\n\n    c\n' > "${fixture}"
[[ "$(folded_desc_len "${fixture}")" == "5" ]] \
  || fail "folded-length self-check broken: '>-' multi-paragraph fixture must measure 5 bytes ('a b\\nc'), got $(folded_desc_len "${fixture}") — paragraph newlines count toward Argo's 255 limit"
desc_len="$(folded_desc_len "${PROJECT}")"
[[ "${desc_len}" -le 255 ]] \
  || fail "gsk-cloud-edge AppProject spec.description folds to ${desc_len} chars — Argo rejects >255 (apply fails, cluster keeps the OLD project); move rationale into YAML comments above the field"
ok "AppProject description within Argo's 255-char limit (${desc_len} chars folded)"

echo "PASS: gsk cloud-edge GitOps offline gate green"

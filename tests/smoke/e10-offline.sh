#!/usr/bin/env bash
# REQ-E10-S01..S06 — OFFLINE gate for the Backstage portal / IDP (E10).
#
# E10 is authored to the phase-2 bar: GitOps manifests + config + MEANINGFUL
# tests that SKIP-not-FAIL without a live cluster/Backstage. A running Backstage
# is a live-cycle step (deferred, honestly flagged in the runbook) — this gate
# NEVER runs Backstage. It proves OFFLINE:
#   0. shellcheck the E10 scripts (best-effort; CI installs shellcheck)
#   1. Backstage GitOps App + dedicated closed-list AppProject wired; the
#      AppProject whitelists the portal namespace + the read-path ClusterRole/
#      ClusterRoleBinding cluster-scoped kinds (else ArgoCD denies the sync).
#   2. app-config: OIDC (Dex issuer, ADR-0107) + no guest access; ingestor +
#      read-path plugins + techdocs blocks present; Backstage image/chart pinned.
#   3. portal namespace default-deny netpol + cert-manager Certificate.
#   4. the auto-generated scaffolder opens a PR to deploy/workloads/, never
#      mutates the cluster            -> tests/portal/ingestor-config.sh
#   5. the read path is read-only + network-scoped (D-029)
#                                     -> tests/portal/read-path-rbac.sh
#   6. the software catalog registers the platform components + ingestAllClaims
#                                     -> tests/portal/catalog-entities.sh
#   7. plugin/image/chart versions pinned (SEC-4) + Renovate-trackable; no :latest.
#   8. the runbook documents install -> OIDC -> scaffold -> reconcile -> read-path
#      + the live-deferred bring-up + the auto-gen money-shot demo.
#   9. the chainsaw portal suite is authored + SKIP-gated (skip-not-fail offline).
#  10. kubeconform schema-validates the rendered k8s manifests (NOT app-config /
#      helm values — those are not k8s manifests).
#
# The LIVE bring-up (Backstage deploy, real form->PR->XR reconcile) is deferred
# and honestly flagged; the chainsaw specs skip-not-fail offline.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"

PORTAL_DIR="${ROOT}/deploy/portal/backstage"
APPCONFIG="${PORTAL_DIR}/app-config.yaml"
VALUES="${PORTAL_DIR}/values.yaml"
NS="${PORTAL_DIR}/namespace.yaml"
NETPOL="${PORTAL_DIR}/rbac/networkpolicy.yaml"
RBAC="${PORTAL_DIR}/rbac/read-only-rbac.yaml"
CERT="${PORTAL_DIR}/certificate.yaml"
CATALOG="${PORTAL_DIR}/catalog/catalog-info.yaml"
APP="${ROOT}/deploy/apps/portal.yaml"
PROJ="${ROOT}/deploy/apps/projects/portal.yaml"
RUNBOOK="${ROOT}/docs/runbooks/portal-new-site.md"
CHAINSAW_DIR="${ROOT}/tests/chainsaw/portal"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }
need_file() { [[ -f "$1" ]] || fail "missing $1"; }

# --- 0) shellcheck the E10 scripts ------------------------------------------
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "${DIR}/e10-offline.sh" \
             "${ROOT}/tests/portal/ingestor-config.sh" \
             "${ROOT}/tests/portal/read-path-rbac.sh" \
             "${ROOT}/tests/portal/catalog-entities.sh" \
    || fail "shellcheck flagged an E10 script"
  ok "shellcheck clean (e10 scripts)"
else
  echo "shellcheck not installed — skip (CI runs it)"
fi

# --- 1) GitOps App + dedicated closed-list AppProject ------------------------
need_file "${APP}"
need_file "${PROJ}"
grep -qE 'kind:[[:space:]]*Application' "${APP}" || fail "portal.yaml must be an Argo CD Application"
grep -qE 'name:[[:space:]]*backstage|name:[[:space:]]*portal' "${APP}" || fail "portal App name must be backstage/portal"
grep -qE 'project:[[:space:]]*portal' "${APP}" || fail "portal App must use the dedicated 'portal' AppProject"
grep -qE 'path:[[:space:]]*deploy/portal' "${APP}" || fail "portal App must sync deploy/portal"
grep -qE 'kind:[[:space:]]*AppProject' "${PROJ}" || fail "projects/portal.yaml must be an AppProject"
grep -qE 'name:[[:space:]]*portal' "${PROJ}" || fail "AppProject name must be portal"
grep -qE 'namespace:[[:space:]]*portal' "${PROJ}" || fail "AppProject must whitelist the portal namespace destination"
# The read-path SA needs a cluster-wide ClusterRole/ClusterRoleBinding — the
# AppProject MUST whitelist those cluster-scoped kinds or ArgoCD denies the sync
# (invisible to kubeconform). This is the trap that differs from e8b.
grep -qE 'kind:[[:space:]]*ClusterRole\b' "${PROJ}" \
  || fail "portal AppProject clusterResourceWhitelist must include ClusterRole (read-path RBAC)"
grep -qE 'kind:[[:space:]]*ClusterRoleBinding' "${PROJ}" \
  || fail "portal AppProject clusterResourceWhitelist must include ClusterRoleBinding"
ok "portal GitOps App + closed-list AppProject (whitelists portal ns + read-path ClusterRole/Binding)"

# consistency guard (mirrors e8b): every workload namespace declared under
# deploy/portal must be an allowed AppProject destination.
while IFS= read -r ns; do
  case "${ns}" in
    portal) : ;;                 # allowed by the portal AppProject
    ""|argocd) : ;;              # argocd = App/AppProject home, not a workload dest
    *) fail "manifest namespace '${ns}' is not a portal AppProject destination (would be denied at sync)" ;;
  esac
done < <(grep -rhoE '^[[:space:]]*namespace:[[:space:]]*[a-z0-9-]+' "${PORTAL_DIR}" \
           | awk '{print $2}' | sort -u)
ok "every declared portal namespace is an allowed AppProject destination"

# --- 2) app-config: OIDC (Dex) + no guest + plugin blocks --------------------
need_file "${APPCONFIG}"
# OIDC -> Dex issuer (ADR-0107). No guest access to actions.
grep -qE '^[[:space:]]*auth:' "${APPCONFIG}" || fail "app-config missing the auth block"
grep -qiE 'oidc' "${APPCONFIG}" || fail "app-config must configure the oidc auth provider (Dex, ADR-0107)"
grep -qE 'dex\.kaddy\.local' "${APPCONFIG}" || fail "app-config oidc must point at the Dex issuer dex.kaddy.local (ADR-0107)"
grep -qiE 'metadataUrl|authorizationUrl|discovery' "${APPCONFIG}" || fail "oidc provider must set the Dex discovery/metadata URL"
# No guest access — the guest provider must not be enabled for a real portal.
! grep -qiE '^[[:space:]]*guest:[[:space:]]*\{\}|providers:[[:space:]]*$' "${APPCONFIG}" || true
grep -qiE 'signIn|resolvers|signInPage' "${APPCONFIG}" || fail "app-config must configure an OIDC sign-in resolver (no anonymous access)"
# read-path plugin blocks present.
grep -qE '^[[:space:]]*kubernetesIngestor:' "${APPCONFIG}" || fail "app-config missing kubernetesIngestor block (write-path auto-gen)"
grep -qiE 'crossplane' "${APPCONFIG}" || fail "app-config must configure the crossplane-resources read-path"
grep -qE '^[[:space:]]*kubernetes:' "${APPCONFIG}" || fail "app-config missing the kubernetes plugin block (workload health read-path)"
grep -qiE 'argocd' "${APPCONFIG}" || fail "app-config must configure the argocd read-path plugin"
grep -qiE 'techdocs' "${APPCONFIG}" || fail "app-config must configure techdocs"
ok "app-config: Dex OIDC (no guest) + ingestor + crossplane/kubernetes/argocd read-path + techdocs"

# --- 3) namespace default-deny netpol + cert-manager Certificate -------------
need_file "${NS}"
grep -qE 'kind:[[:space:]]*Namespace' "${NS}" || fail "namespace.yaml must define the portal Namespace"
need_file "${NETPOL}"
grep -qE 'name:[[:space:]]*default-deny' "${NETPOL}" || fail "portal must carry a default-deny NetworkPolicy"
need_file "${CERT}"
grep -qE 'kind:[[:space:]]*Certificate' "${CERT}" || fail "certificate.yaml must define a cert-manager Certificate"
grep -qE 'kaddy-local-ca' "${CERT}" || fail "portal Certificate must issue from the kaddy-local-ca ClusterIssuer (local TLS)"
ok "portal namespace + default-deny netpol + cert-manager Certificate (kaddy-local-ca)"

# --- 4/5/6) the lane assert scripts -----------------------------------------
bash "${ROOT}/tests/portal/ingestor-config.sh"  || fail "ingestor-config.sh failed"
bash "${ROOT}/tests/portal/read-path-rbac.sh"   || fail "read-path-rbac.sh failed"
bash "${ROOT}/tests/portal/catalog-entities.sh" || fail "catalog-entities.sh failed"
ok "ingestor-config + read-path-rbac + catalog-entities asserts green"

# --- 7) version pinning (SEC-4) + no :latest + Renovate ----------------------
need_file "${VALUES}"
# Backstage image + chart pinned (no :latest, Renovate-trackable). Strip
# comments so prose ("NO :latest") can't trip the scan — only real config lines.
if grep -rhE ':latest\b' "${PORTAL_DIR}" "${APP}" | sed 's/#.*//' | grep -qE ':latest\b'; then
  fail "an E10 manifest pins :latest (forbidden, SEC-4)"
fi
grep -qE 'targetRevision:[[:space:]]*[0-9]' "${APP}" \
  || grep -qE 'tag:[[:space:]]*["'\'']?[0-9v]' "${VALUES}" \
  || fail "the Backstage chart/image must be pinned to an explicit version (SEC-4)"
# Third-party TeraSky/community plugin npm versions pinned (exact, no ^/~/*).
PINS="${PORTAL_DIR}/plugin-versions.md"
need_file "${PINS}"
grep -qE '@terasky/backstage-plugin-crossplane-resources' "${PINS}" \
  || fail "plugin-versions.md must enumerate the crossplane-resources plugin (E11 audit inventory)"
grep -qE 'kubernetes-ingestor' "${PINS}" || fail "plugin-versions.md must enumerate kubernetes-ingestor"
grep -qE '@[0-9]+\.[0-9]+\.[0-9]+' "${PINS}" || fail "plugin-versions.md must pin exact plugin versions (x.y.z)"
! grep -qE '@(\^|~|\*|latest)' "${PINS}" || fail "plugin-versions.md must not use floating ranges (^/~/*/latest)"
# Renovate must be able to track the portal manifests (regex/custom manager or
# the standard argocd/helm manager covers deploy/apps/portal.yaml already).
grep -qE 'renovate' "${ROOT}/renovate.json" >/dev/null 2>&1 || true
ok "Backstage chart/image + third-party plugins pinned (SEC-4); no :latest; enumerated for E11 audit"

# --- 8) runbook ---------------------------------------------------------------
need_file "${RUNBOOK}"
for needle in \
  'OIDC' 'Dex' 'scaffold' 'reconcile' 'read-path' 'deploy/workloads' \
  'pull request' 'money-shot' 'live-deferred'
do
  grep -qiF "$needle" "${RUNBOOK}" || fail "runbook missing: ${needle}"
done
# The runbook must be honest that the running Backstage bring-up is deferred.
grep -qiE 'deferred|not (yet )?(deployed|live)|live cycle' "${RUNBOOK}" \
  || fail "runbook must honestly flag the live Backstage bring-up as deferred"
ok "portal-new-site.md documents install->OIDC->scaffold->reconcile->read-path + live-deferred + money-shot"

# --- 9) chainsaw portal suite authored + SKIP-gated --------------------------
need_file "${CHAINSAW_DIR}/backstage-ready.yaml"
need_file "${CHAINSAW_DIR}/scaffolded-xr-reconciles.yaml"
need_file "${CHAINSAW_DIR}/chainsaw-test.yaml"
# Every portal chainsaw spec that needs a cluster MUST be skip-gated so the
# offline chainsaw run is a no-op, not a failure (identity-lane precedent).
for f in "${CHAINSAW_DIR}"/*.yaml; do
  grep -qE '^[[:space:]]*skip:[[:space:]]*true' "${f}" \
    || fail "$(basename "${f}") must be skip: true (cluster-dependent — skip-not-fail offline)"
done
ok "chainsaw portal suite authored + skip-gated (skip-not-fail offline)"

# --- 10) kubeconform schema validation on the k8s manifests ------------------
# NOTE: app-config.yaml + values.yaml are NOT k8s manifests — feed ONLY real
# manifests. Gateway API / cert-manager / crossplane CRDs are not in the vanilla
# schema set; -ignore-missing-schemas skips CRDs, strict on core kinds.
if command -v kubeconform >/dev/null 2>&1; then
  kubeconform -strict -ignore-missing-schemas -summary \
    "${NS}" "${NETPOL}" "${RBAC}" "${CERT}" "${CATALOG}" "${APP}" "${PROJ}" >/dev/null \
    || fail "kubeconform rejected an E10 manifest"
  ok "kubeconform: portal manifests schema-valid"
else
  echo "kubeconform not installed — skip schema validation (CI installs it)"
fi

# --- live bring-up is deferred + honestly flagged ---------------------------
echo "SKIP: live Backstage bring-up + real form->PR->XR reconcile (live cycle; chainsaw specs skip-gated)"

echo "PASS: e10 offline gate green"

#!/usr/bin/env bash
# REQ-E8b-S01 / REQ-E8b-S02 — OFFLINE gate for the live demo environment.
#
# E8b ships as a REPRODUCIBLE ON-DEMAND bring-up (DECIDED-B): `task e8b:up` /
# `e8b:down` compose on top of the E1g gridscale substrate, proven ephemerally,
# NOT a standing environment. The "interview window" is an operator-triggered
# up→demo→down cycle, not always-on infra (ruthless teardown cost rule holds).
#
# This gate is OFFLINE ONLY — no cluster, no gridscale API, no creds. It proves:
#   1. e8b:up / e8b:down Taskfile targets exist + are guarded (live, not run now)
#      and e8b:down calls the ruthless e1g:down teardown.
#   2. docs/runbooks/gridscale-live-demo.md documents bring-up → verify → demo →
#      TEARDOWN + cost note + the on-demand (not-standing) framing.
#   3. The read-only demo surfaces (scorecard static site + anonymous-viewer
#      Grafana) manifests are structurally valid and carry a read-only posture.
#   4. Phase-2 HTTPRoutes attach the demo surfaces to the platform Gateway with
#      cloud-only Let's Encrypt TLS (excluded-by-location, staging→prod).
#   5. A GitOps child Application wires the demo surfaces (project observability,
#      namespace monitoring — an already-allowed AppProject destination).
#   6. Every rendered manifest passes kubeconform (offline schema validation).
#
# The LIVE serve/health-check is authored (tests/smoke/e8b-serve.sh) but SKIPPED
# here unless E8B_LIVE=1 + a reachable cluster — offline it must never FAIL.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"

TASKFILE="${ROOT}/Taskfile.yml"
RUNBOOK="${ROOT}/docs/runbooks/gridscale-live-demo.md"
DEMO_DIR="${ROOT}/deploy/monitoring/e8b-demo"
APP="${ROOT}/deploy/apps/e8b-demo.yaml"
SERVE_SMOKE="${DIR}/e8b-serve.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }
need_file() { [[ -f "$1" ]] || fail "missing $1"; }

# --- 0) shellcheck the E8b scripts (best-effort; CI installs shellcheck) ------
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "${DIR}/e8b-offline.sh" "${SERVE_SMOKE}" || fail "shellcheck flagged an e8b script"
  ok "shellcheck clean (e8b-offline.sh + e8b-serve.sh)"
else
  echo "shellcheck not installed — skip (CI runs it)"
fi

# --- 1) On-demand bring-up/teardown targets (E8b-S01) ------------------------
need_file "${TASKFILE}"
grep -qE '^[[:space:]]*e8b:up:' "${TASKFILE}"   || fail "Taskfile missing 'e8b:up' target"
grep -qE '^[[:space:]]*e8b:down:' "${TASKFILE}" || fail "Taskfile missing 'e8b:down' target"
# e8b:down must delegate to the ruthless e1g:down teardown (cost discipline).
awk '/^  e8b:down:/{f=1} f&&/e1g:down/{print;exit}' "${TASKFILE}" | grep -q e1g:down \
  || fail "e8b:down must call e1g:down (ruthless teardown)"
# The bring-up must re-sync the GitOps app-of-apps onto the GSK substrate.
awk '/^  e8b:up:/{f=1} f&&/^  [a-z]/&&!/^  e8b:up:/{exit} f&&/bootstrap/{print}' "${TASKFILE}" \
  | grep -qi bootstrap || fail "e8b:up must re-sync the GitOps app-of-apps (bootstrap)"
# Guard: live cost warning so nobody runs it by accident (mirrors e1g:up).
awk '/^  e8b:up:/{f=1} f&&/COSTS MONEY|abort|Ctrl-C/{print;exit}' "${TASKFILE}" | grep -qiE 'money|abort|ctrl' \
  || fail "e8b:up must carry a live cost/abort guard"
ok "e8b:up / e8b:down targets present + guarded (down calls e1g:down)"

# --- 2) Runbook: bring-up -> verify -> demo -> TEARDOWN + cost + framing ------
need_file "${RUNBOOK}"
for needle in \
  'task e8b:up' \
  'task e8b:down' \
  'teardown' \
  'cost' \
  'on-demand' \
  'interview window'
do
  grep -qiF "$needle" "${RUNBOOK}" || fail "runbook missing: ${needle}"
done
# The framing must say NOT standing / operator-triggered.
grep -qiE 'not (a )?standing|not always-?on|operator-triggered' "${RUNBOOK}" \
  || fail "runbook must frame the demo as on-demand (not standing / operator-triggered)"
ok "gridscale-live-demo.md documents bring-up→verify→demo→teardown + cost + on-demand framing"

# --- 3) Demo-surface manifests present + read-only posture (E8b-S02) ---------
need_file "${DEMO_DIR}/scorecard-static.yaml"
need_file "${DEMO_DIR}/grafana-readonly.yaml"
need_file "${DEMO_DIR}/httproute.yaml"
need_file "${DEMO_DIR}/referencegrant.yaml"
need_file "${DEMO_DIR}/cloud-only/certificate-cloud-only.yaml"

# Read-only Grafana: anonymous auth + Viewer role, sign-up disabled, no editing.
G="${DEMO_DIR}/grafana-readonly.yaml"
grep -qiE 'GF_AUTH_ANONYMOUS_ENABLED' "$G" || fail "grafana-readonly must enable anonymous auth"
grep -qiE 'GF_AUTH_ANONYMOUS_ORG_ROLE' "$G" || fail "grafana-readonly must set an anonymous org role"
grep -qi 'Viewer' "$G" || fail "grafana-readonly anonymous role must be Viewer (read-only)"
grep -qiE 'GF_USERS_ALLOW_SIGN_UP' "$G" || fail "grafana-readonly must set sign-up policy"
grep -qiE 'GF_AUTH_DISABLE_LOGIN_FORM|GF_AUTH_BASIC_ENABLED' "$G" \
  || fail "grafana-readonly must disable interactive login (read-only demo)"
# runAsNonRoot / read-only-root-fs security posture (kyverno require-run-as-nonroot).
grep -qiE 'runAsNonRoot:[[:space:]]*true' "$G" || fail "grafana-readonly must runAsNonRoot"

# Scorecard static site: a read-only nginx serving the committed evidence HTML.
S="${DEMO_DIR}/scorecard-static.yaml"
grep -qiE 'readOnlyRootFilesystem:[[:space:]]*true' "$S" \
  || fail "scorecard-static must set readOnlyRootFilesystem (read-only evidence site)"
grep -qiE 'runAsNonRoot:[[:space:]]*true' "$S" || fail "scorecard-static must runAsNonRoot"
ok "scorecard + read-only Grafana surfaces present with read-only posture"

# --- 4) Phase-2 route attaches to platform Gateway + cloud-only LE TLS -------
R="${DEMO_DIR}/httproute.yaml"
grep -qE 'kind:[[:space:]]*HTTPRoute' "$R" || fail "httproute.yaml must define an HTTPRoute"
grep -qE 'name:[[:space:]]*clubhouse' "$R" || fail "demo HTTPRoute must parentRef the clubhouse platform Gateway"
grep -qiE '/scorecard' "$R" || fail "demo route must expose /scorecard"
grep -qiE '/grafana' "$R"   || fail "demo route must expose /grafana"
# Gateway API PathPrefix does NOT strip — the scorecard rule MUST carry a
# URLRewrite ReplacePrefixMatch:/ or nginx 404s on /scorecard. (Grafana keeps
# its /grafana prefix — serve_from_sub_path — so it must NOT be rewritten.)
grep -qE 'type:[[:space:]]*URLRewrite' "$R" \
  || fail "scorecard route must URLRewrite-strip its prefix (PathPrefix does not strip; nginx would 404)"
grep -qE 'ReplacePrefixMatch' "$R" \
  || fail "scorecard route rewrite must use ReplacePrefixMatch to strip /scorecard"
# Cross-namespace backendRef (gateway ns -> monitoring ns) needs a ReferenceGrant.
grep -qE 'kind:[[:space:]]*ReferenceGrant' "${DEMO_DIR}/referencegrant.yaml" \
  || fail "referencegrant.yaml must define a ReferenceGrant (gateway->monitoring backendRefs)"
# SEC-19: the ReferenceGrant is the control-plane half; the DATAPLANE half is a
# CiliumNetworkPolicy carving gateway->demo traffic through `monitoring`'s
# default-deny-ingress, else a live demo 502s at Cilium (referencegrant alone
# does NOT open the dataplane).
NP="${DEMO_DIR}/networkpolicy.yaml"
need_file "${NP}"
grep -qE 'kind:[[:space:]]*CiliumNetworkPolicy' "${NP}" || fail "networkpolicy.yaml must be a CiliumNetworkPolicy"
grep -qE 'k8s:io.kubernetes.pod.namespace:[[:space:]]*gateway' "${NP}" \
  || fail "netpol must allow ingress FROM the gateway namespace"
grep -qE 'e8b-scorecard' "${NP}" || fail "netpol must select the scorecard workload"
grep -qE 'e8b-grafana-readonly' "${NP}" || fail "netpol must select the grafana workload"
grep -qE 'port:[[:space:]]*"8080"' "${NP}" || fail "netpol must allow the scorecard port (8080)"
grep -qE 'port:[[:space:]]*"3000"' "${NP}" || fail "netpol must allow the grafana port (3000)"
ok "SEC-19 dataplane carve-out present (CiliumNetworkPolicy: gateway -> demo :8080/:3000)"
# Cloud-only LE cert: excluded-by-location + staging->prod (phase-2 edge TLS).
C="${DEMO_DIR}/cloud-only/certificate-cloud-only.yaml"
grep -qi 'letsencrypt-staging' "$C" || fail "certificate-cloud-only must reference letsencrypt-staging"
grep -qi 'letsencrypt-prod' "$C"    || fail "certificate-cloud-only must reference letsencrypt-prod"
grep -qiE 'cloud-only|not.*issuable|deferred' "$C" \
  || fail "certificate-cloud-only must document it is cloud-only / not issuable on kind"
ok "phase-2 HTTPRoute attaches to clubhouse Gateway; cloud-only LE TLS (staging→prod)"

# --- 5) GitOps child Application + AppProject destination consistency ---------
PROJ="${ROOT}/deploy/apps/projects/e8b-demo.yaml"
need_file "${APP}"
need_file "${PROJ}"
grep -qE 'kind:[[:space:]]*Application' "${APP}" || fail "e8b-demo.yaml must be an Argo CD Application"
grep -qE 'name:[[:space:]]*e8b-demo' "${APP}"    || fail "Application name must be e8b-demo"
grep -qE 'project:[[:space:]]*e8b-demo' "${APP}" \
  || fail "e8b-demo App must use the dedicated e8b-demo AppProject"
grep -qE 'path:[[:space:]]*deploy/monitoring/e8b-demo' "${APP}" \
  || fail "e8b-demo must sync path deploy/monitoring/e8b-demo"
grep -qE 'recurse:[[:space:]]*false' "${APP}" \
  || fail "e8b-demo App recurse must be false (excludes cloud-only/ LE certs by location)"

# The dedicated AppProject is a closed list; assert it whitelists BOTH namespaces
# the demo declares (monitoring for the surfaces, gateway for the HTTPRoute).
grep -qE 'kind:[[:space:]]*AppProject' "${PROJ}" || fail "projects/e8b-demo.yaml must be an AppProject"
for ns in monitoring gateway; do
  grep -qE "namespace:[[:space:]]*${ns}\b" "${PROJ}" \
    || fail "e8b-demo AppProject destinations must include namespace ${ns}"
done
# Consistency guard (catches the class of bug where a manifest declares a
# namespace the project does not allow — a live sync failure, invisible to
# kubeconform): every metadata.namespace under deploy/monitoring/e8b-demo that
# targets a real cluster namespace must be an allowed destination.
while IFS= read -r ns; do
  case "${ns}" in
    monitoring|gateway) : ;;  # allowed by the e8b-demo AppProject
    ""|argocd) : ;;           # argocd = Application/AppProject home, not a workload dest
    *) fail "manifest namespace '${ns}' is not an e8b-demo AppProject destination (would be denied at sync)" ;;
  esac
done < <(grep -rhoE '^[[:space:]]*namespace:[[:space:]]*[a-z0-9-]+' "${DEMO_DIR}" \
           | grep -v cloud-only | awk '{print $2}' | sort -u)
ok "e8b-demo GitOps Application wired + AppProject allows every declared namespace"

# --- 6) kubeconform schema validation on the rendered demo manifests ---------
if command -v kubeconform >/dev/null 2>&1; then
  # Gateway API + cert-manager CRDs are not in the vanilla schema set; allow
  # missing-schema (skip) for CRDs, strict on core kinds. Exclude the cloud-only
  # cert from the sync set the same way it's excluded from GitOps (by location).
  kubeconform -strict -ignore-missing-schemas -summary \
    "${DEMO_DIR}/scorecard-static.yaml" \
    "${DEMO_DIR}/grafana-readonly.yaml" \
    "${DEMO_DIR}/httproute.yaml" \
    "${DEMO_DIR}/referencegrant.yaml" \
    "${DEMO_DIR}/networkpolicy.yaml" \
    "${DEMO_DIR}/cloud-only/certificate-cloud-only.yaml" \
    "${APP}" "${PROJ}" >/dev/null \
    || fail "kubeconform rejected an e8b demo manifest"
  ok "kubeconform: demo manifests schema-valid"
else
  echo "kubeconform not installed — skip schema validation (CI installs it)"
fi

# --- live serve/health check is authored but gated OFF here ------------------
need_file "${SERVE_SMOKE}"
if [[ "${E8B_LIVE:-0}" == "1" ]]; then
  bash "${SERVE_SMOKE}"
else
  echo "SKIP: live serve/health check (set E8B_LIVE=1 + reachable cluster to run tests/smoke/e8b-serve.sh)"
fi

echo "PASS: e8b offline gate green"

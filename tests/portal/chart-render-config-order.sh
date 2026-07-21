#!/usr/bin/env bash
# R4-1 / REQ-E10-S01-01 + REQ-E10-S05-03 — chart-cutover render gate.
#
# The live GSK Deployment/backstage is out-of-band (hand-applied). The cutover
# to GitOps is deploy/apps-cloud/backstage-workload.yaml (pinned
# backstage.github.io chart + $values ref to deploy/portal/backstage/values.yaml,
# MANUAL sync). This gate proves — OFFLINE, no cluster — that the RENDERED chart
# honors the canonical live env contract
# (deploy/portal/backstage/gsk/deployment-env.yaml):
#   1. The cutover App parses: project portal, pinned chart version, $values
#      ref, destination portal, NO automated sync (human-in-the-loop adoption).
#   2. helm template with the repo values renders a Deployment whose --config
#      chain is EXACTLY app-config.yaml then /cfg/app-config.override.yaml,
#      override LAST (security-load-bearing: Backstage replaces ARRAYS with the
#      later file's value — only an override loaded last keeps the
#      catalog-restricted resolver + sign-in-page:app: false authoritative).
#   3. NODE_ENV=production is set (guest backend module unload) and the env
#      Secrets backstage-github + backstage-backend-auth are wired via envFrom.
#   4. dangerouslyAllowSignInWithoutUserInCatalog appears NOWHERE in the render.
#   5. replicas=1, memory request/limit present, pod label app=backstage kept,
#      Deployment NAME is exactly `backstage` (Argo must ADOPT the live object,
#      not create a sibling), override ConfigMap backstage-override mounted at
#      /cfg.
#   6. image is ghcr.io/platformrelay/kaddy-portal with a pinned non-latest tag.
#
# NETWORK: the chart tarball is fetched ONCE into the gitignored .cache/charts/
# (helm pull --repo). Tool-absence and network-absence SKIP-not-fail with a
# clear message — the same posture as kubeconform/shellcheck-absent gates
# ("CI runs it"); the STATIC App-manifest asserts above always run.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"

APP="${ROOT}/deploy/apps-cloud/backstage-workload.yaml"
VALUES="${ROOT}/deploy/portal/backstage/values.yaml"
ENV_CONTRACT="${ROOT}/deploy/portal/backstage/gsk/deployment-env.yaml"
CHART_REPO="https://backstage.github.io/charts"
CACHE_DIR="${ROOT}/.cache/charts"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }
skip() { echo "SKIP: $*"; }

command -v yq >/dev/null 2>&1 || fail "yq required for this gate"

[[ -f "${APP}" ]]    || fail "missing ${APP} (chart cutover Application)"
[[ -f "${VALUES}" ]] || fail "missing ${VALUES}"
[[ -f "${ENV_CONTRACT}" ]] || fail "missing ${ENV_CONTRACT}"

# --- 1) cutover App manifest (static, always runs) ---------------------------
[[ "$(yq -r '.kind' "${APP}")" == "Application" ]] \
  || fail "backstage-workload.yaml must be an Argo CD Application"
[[ "$(yq -r '.spec.project' "${APP}")" == "portal" ]] \
  || fail "cutover App must use the closed-list portal AppProject"
chart_src_repo="$(yq -r '.spec.sources[] | select(.chart == "backstage") | .repoURL' "${APP}")"
[[ "${chart_src_repo}" == "${CHART_REPO}" ]] \
  || fail "cutover App must source chart 'backstage' from ${CHART_REPO} (got: ${chart_src_repo:-none})"
CHART_VERSION="$(yq -r '.spec.sources[] | select(.chart == "backstage") | .targetRevision' "${APP}")"
[[ "${CHART_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
  || fail "cutover App must pin an exact numeric chart version (got: ${CHART_VERSION})"
yq -r '.spec.sources[] | select(.chart == "backstage") | .helm.valueFiles[]' "${APP}" \
  | grep -qx -- "[\$]values/deploy/portal/backstage/values.yaml" \
  || fail "cutover App must render \$values/deploy/portal/backstage/values.yaml"
# ADOPTION NAMING (static — the render below cannot prove this on its own:
# helm template is invoked with the release name read HERE, so only the App
# manifest pin is load-bearing): releaseName must be `backstage` or Argo
# derives the release from the App name (backstage-workload) and renders a
# sibling next to the live objects.
release_name="$(yq -r '.spec.sources[] | select(.chart == "backstage") | .helm.releaseName // "absent"' "${APP}")"
[[ "${release_name}" == "backstage" ]] \
  || fail "cutover App must pin helm.releaseName: backstage (got: ${release_name}) — adoption naming must not depend on the Argo App name"
ref_repo="$(yq -r '.spec.sources[] | select(.ref == "values") | .repoURL' "${APP}")"
[[ "${ref_repo}" == "https://github.com/PlatformRelay/Kaddy.git" ]] \
  || fail "cutover App \$values ref must point at this repo (got: ${ref_repo:-none})"
[[ "$(yq -r '.spec.destination.namespace' "${APP}")" == "portal" ]] \
  || fail "cutover App destination namespace must be portal"
# MANUAL sync only: adopting a live out-of-band Deployment must be observed by
# a human (first sync may need Replace on the immutable selector).
[[ "$(yq -r '.spec.syncPolicy.automated // "absent"' "${APP}")" == "absent" ]] \
  || fail "cutover App must NOT set syncPolicy.automated (manual, human-in-the-loop adoption)"
ok "cutover App: portal project, chart ${CHART_VERSION} pinned, \$values ref, manual sync"

# --- 2) helm render (SKIP-not-fail on missing helm / network) ----------------
if ! command -v helm >/dev/null 2>&1; then
  skip "helm not installed — skip chart render asserts (CI runs it)"
  echo "PASS: chart-render-config-order (static asserts only)"
  exit 0
fi

TGZ="${CACHE_DIR}/backstage-${CHART_VERSION}.tgz"
if [[ ! -f "${TGZ}" ]]; then
  mkdir -p "${CACHE_DIR}"
  if ! helm pull backstage --repo "${CHART_REPO}" --version "${CHART_VERSION}" \
       -d "${CACHE_DIR}" >/dev/null 2>&1; then
    # In CI a fetch failure is a FAILURE: a network flake must not silently
    # downgrade this gate to static-only there. Locally (offline dev) it SKIPs.
    [[ -z "${CI:-}" ]] \
      || fail "cannot fetch backstage chart ${CHART_VERSION} in CI — the render asserts must run there (network flake: rerun)"
    skip "cannot fetch backstage chart ${CHART_VERSION} (offline?) — skip render asserts (CI runs it)"
    echo "PASS: chart-render-config-order (static asserts only)"
    exit 0
  fi
fi

# Render under the App-pinned release name (asserted == backstage above) —
# exactly the name Argo will use.
rendered="$(helm template "${release_name}" "${TGZ}" -n portal -f "${VALUES}")" \
  || fail "helm template failed for chart ${CHART_VERSION} with ${VALUES}"

deployment="$(printf '%s\n' "${rendered}" | yq 'select(.kind == "Deployment")')"
[[ -n "${deployment}" ]] || fail "chart render produced no Deployment"

# --- 2a) Deployment NAME must be backstage (adopt, not sibling) --------------
dep_name="$(printf '%s\n' "${deployment}" | yq -r '.metadata.name')"
[[ "${dep_name}" == "backstage" ]] \
  || fail "rendered Deployment must be named 'backstage' to adopt the live object (got: ${dep_name}) — set fullnameOverride"

# --- 2b) --config chain: override LAST, exactly the live contract ------------
mapfile -t args < <(printf '%s\n' "${deployment}" \
  | yq -r '.spec.template.spec.containers[0].args[]')
[[ "${#args[@]}" -gt 0 ]] || fail "rendered Deployment has no container args (--config chain missing)"
configs=()
for i in "${!args[@]}"; do
  if [[ "${args[$i]}" == "--config" ]]; then
    configs+=("${args[$((i + 1))]:-MISSING}")
  fi
done
[[ "${#configs[@]}" -eq 2 ]] \
  || fail "rendered args must load EXACTLY two --config files (got ${#configs[@]}: ${configs[*]:-none}) — the override must be self-sufficient (no production.yaml, no third config)"
[[ "${configs[0]}" == "app-config.yaml" ]] \
  || fail "first --config must be the baked app-config.yaml (got: ${configs[0]})"
[[ "${configs[1]}" == "/cfg/app-config.override.yaml" ]] \
  || fail "LAST --config must be /cfg/app-config.override.yaml (got: ${configs[1]}) — else the baked dangerous resolver array wins"
ok "rendered --config chain matches the live contract (override LAST)"

# --- 2c) NODE_ENV=production + env Secrets -----------------------------------
printf '%s\n' "${deployment}" \
  | yq -e '.spec.template.spec.containers[0].env[] | select(.name == "NODE_ENV" and .value == "production")' >/dev/null 2>&1 \
  || fail "rendered Deployment must set NODE_ENV=production (guest module unload)"
for secret in backstage-github backstage-backend-auth; do
  printf '%s\n' "${deployment}" \
    | yq -e ".spec.template.spec.containers[0].envFrom[] | select(.secretRef.name == \"${secret}\")" >/dev/null 2>&1 \
    || fail "rendered Deployment must envFrom Secret ${secret}"
done
ok "NODE_ENV=production + envFrom backstage-github/backstage-backend-auth"

# --- 2d) dangerous sign-in flag NOWHERE in the render ------------------------
if printf '%s\n' "${rendered}" | grep -qi 'dangerouslyAllowSignInWithoutUserInCatalog'; then
  fail "rendered output must NOT contain dangerouslyAllowSignInWithoutUserInCatalog (ANY GitHub account could sign in)"
fi
ok "no dangerouslyAllowSignInWithoutUserInCatalog anywhere in the render"

# --- 2e) replicas + memory resources -----------------------------------------
[[ "$(printf '%s\n' "${deployment}" | yq -r '.spec.replicas')" == "1" ]] \
  || fail "rendered Deployment must pin replicas: 1 (in-memory sqlite — no HA)"
mem_req="$(printf '%s\n' "${deployment}" | yq -r '.spec.template.spec.containers[0].resources.requests.memory // "missing"')"
mem_lim="$(printf '%s\n' "${deployment}" | yq -r '.spec.template.spec.containers[0].resources.limits.memory // "missing"')"
[[ "${mem_req}" != "missing" && "${mem_lim}" != "missing" ]] \
  || fail "rendered Deployment must carry memory requests+limits (got req=${mem_req} lim=${mem_lim})"
ok "replicas=1; memory req=${mem_req} lim=${mem_lim}"

# --- 2f) pod label + override ConfigMap mount --------------------------------
[[ "$(printf '%s\n' "${deployment}" | yq -r '.spec.template.metadata.labels.app // "missing"')" == "backstage" ]] \
  || fail "rendered pod template must keep label app: backstage (NetPols/CNPs select it)"
printf '%s\n' "${deployment}" \
  | yq -e '.spec.template.spec.volumes[] | select(.configMap.name == "backstage-override")' >/dev/null 2>&1 \
  || fail "rendered Deployment must mount a volume from ConfigMap backstage-override (the Argo-synced override — do not duplicate config)"
printf '%s\n' "${deployment}" \
  | yq -e '.spec.template.spec.containers[0].volumeMounts[] | select(.mountPath == "/cfg")' >/dev/null 2>&1 \
  || fail "override volume must be mounted at /cfg (the --config path)"
ok "pod label app=backstage kept; backstage-override ConfigMap mounted at /cfg"

# --- 2g) image pinned, non-latest --------------------------------------------
image="$(printf '%s\n' "${deployment}" | yq -r '.spec.template.spec.containers[0].image')"
[[ "${image}" == ghcr.io/platformrelay/kaddy-portal:* ]] \
  || fail "rendered image must be ghcr.io/platformrelay/kaddy-portal (got: ${image})"
tag="${image##*:}"
[[ -n "${tag}" && "${tag}" != "latest" && "${tag}" =~ ^[0-9] ]] \
  || fail "rendered image tag must be a pinned numeric version, never latest (got: ${tag})"
ok "image pinned: ${image}"

echo "PASS: chart-render-config-order — rendered chart honors the live GSK env contract"

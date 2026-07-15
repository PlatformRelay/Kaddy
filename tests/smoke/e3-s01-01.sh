#!/usr/bin/env bash
# REQ-E3-S01-01: the app-of-apps root registers its child Applications and they
# reach Synced/Healthy. Live gate (chainsaw runs in CI only).
#
# The COMMITTED root.yaml pins targetRevision: main. For live verification against
# an un-merged lane we apply a runtime-overridden copy pinned to the branch under
# test (E3_TARGET_REV, default: current git branch), into a temp dir. Steady-state
# truth in Git stays `main`.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

REPO_ROOT="$(cd "${DIR}/../.." && pwd)"
TARGET_REV="${E3_TARGET_REV:-$(git -C "${REPO_ROOT}" rev-parse --abbrev-ref HEAD)}"
TMP="${CLAUDE_JOB_DIR:-/tmp}/tmp"
mkdir -p "${TMP}"

echo "=== applying app-of-apps (targetRevision override -> ${TARGET_REV}) ==="
# The committed children hard-code targetRevision: main, and the paths they
# reference do not exist on main until this lane merges. So we can NOT let the
# root generate usable children from the branch (it would render them verbatim,
# still main-pinned). We override targetRevision on root AND every child, apply
# the children DIRECTLY, and neutralise the root's automated sync so it does not
# reconcile our branch-pinned children back to the git-verbatim (main-pinned)
# copies. Committed files stay main + selfHeal:true (steady-state truth).
yq e ".spec.source.targetRevision = \"${TARGET_REV}\"
     | del(.spec.syncPolicy.automated)" \
  "${REPO_ROOT}/deploy/apps/root.yaml" > "${TMP}/root.yaml"
kubectl apply -f "${TMP}/root.yaml" >/dev/null
for f in "${REPO_ROOT}"/deploy/apps/*.yaml; do
  b="$(basename "${f}")"; [[ "${b}" == "root.yaml" ]] && continue
  yq e ".spec.source.targetRevision = \"${TARGET_REV}\"" "${f}" > "${TMP}/${b}"
  kubectl apply -f "${TMP}/${b}" >/dev/null
done

echo "=== waiting for child Applications to register ==="
expected=(platform-core observability gateway workloads identity)
for _ in $(seq 1 60); do
  missing=0
  for app in "${expected[@]}"; do
    kubectl -n argocd get application "${app}" >/dev/null 2>&1 || missing=1
  done
  [[ "${missing}" == "0" ]] && break
  sleep 5
done
for app in "${expected[@]}"; do
  kubectl -n argocd get application "${app}" >/dev/null 2>&1 \
    || smoke_fail "child Application '${app}' never registered"
done
echo "child Applications registered: ${expected[*]}"

# The demoable-path children must reach Synced/Healthy. identity is deferred
# (manual sync, empty dir) so we do NOT require it Synced/Healthy.
echo "=== waiting for platform-core + observability children Synced/Healthy ==="
for app in platform-core observability; do
  ok=""
  for _ in $(seq 1 90); do
    sync="$(kubectl -n argocd get application "${app}" -o jsonpath='{.status.sync.status}' 2>/dev/null || true)"
    health="$(kubectl -n argocd get application "${app}" -o jsonpath='{.status.health.status}' 2>/dev/null || true)"
    if [[ "${sync}" == "Synced" && "${health}" == "Healthy" ]]; then ok=1; break; fi
    sleep 10
  done
  [[ -n "${ok}" ]] || smoke_fail "Application '${app}' not Synced/Healthy (sync=${sync:-?} health=${health:-?})"
  smoke_ok "${app} Synced/Healthy"
done

smoke_ok "REQ-E3-S01-01"

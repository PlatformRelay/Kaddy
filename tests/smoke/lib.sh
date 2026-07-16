#!/usr/bin/env bash
# Shared helpers for E1e live smoke tests. Source this file.
set -euo pipefail

# shellcheck disable=SC2034  # consumed by sourcing smoke tests (e.g. e1e-s04-01.sh)
SMOKE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# SAFETY: target ONLY the isolated kind kubeconfig, never the shared ~/.kube/config
# (which carries real GKE prod contexts on this workstation).
export KUBECONFIG="${KUBECONFIG:-${SMOKE_ROOT}/.state/kubeconfig}"

smoke_fail() { echo "FAIL: $*" >&2; exit 1; }
smoke_ok()   { echo "OK: $*"; }

# A live cluster is required for every smoke test. If the kaddy-dev context is
# not reachable, fail loudly (the live gate must not silently pass) UNLESS
# E1E_SMOKE_ALLOW_SKIP=1 (used by the design-phase gate on hosts with no runtime).
smoke_require_cluster() {
  # kind's exposed API port can change when the podman/docker node container
  # restarts, leaving a stale port in .state/kubeconfig. If the first probe
  # fails but the cluster still exists, re-export the kubeconfig once and retry.
  if ! _smoke_cluster_reachable; then
    if command -v kind >/dev/null 2>&1 \
        && kind get clusters 2>/dev/null | grep -qx "kaddy-dev"; then
      kind export kubeconfig --name kaddy-dev --kubeconfig "${KUBECONFIG}" >/dev/null 2>&1 || true
    fi
  fi
  if _smoke_cluster_reachable; then
    kubectl config use-context "kind-kaddy-dev" >/dev/null 2>&1 || true
    # Hard guard — never run assertions against a non-kind context.
    local ctx; ctx="$(kubectl config current-context 2>/dev/null || true)"
    [[ "${ctx}" == "kind-kaddy-dev" ]] || smoke_fail "active context '${ctx}' is not kind-kaddy-dev"
    return 0
  fi
  if [[ "${E1E_SMOKE_ALLOW_SKIP:-0}" == "1" ]]; then
    echo "SKIP: kaddy-dev cluster not reachable (E1E_SMOKE_ALLOW_SKIP=1)"
    exit 0
  fi
  smoke_fail "kaddy-dev cluster not reachable — run 'task cluster:up' first"
}

_smoke_cluster_reachable() {
  [[ -f "${KUBECONFIG}" ]] \
    && kubectl cluster-info --context "kind-kaddy-dev" >/dev/null 2>&1
}

# Phase-2 GSK opt-in. smoke_require_cluster hard-pins kind-kaddy-dev (the local
# prod-nuke guard); the gridscale live demo runs against a GSK cluster instead.
# This helper preserves the guard by requiring the caller to NAME the target
# context explicitly (E8B_GSK_CONTEXT) and honouring the operator's exported
# KUBECONFIG — it NEVER auto-selects, so it can't wander onto a prod context.
# The active context must already equal the named one (operator selected it).
smoke_require_named_context() {
  local want="${1:-}"
  [[ -n "${want}" ]] || smoke_fail "smoke_require_named_context: no context name given"
  local ctx; ctx="$(kubectl config current-context 2>/dev/null || true)"
  [[ "${ctx}" == "${want}" ]] \
    || smoke_fail "active context '${ctx}' != required '${want}' — export KUBECONFIG to the GSK kubeconfig and 'kubectl config use-context ${want}'"
  kubectl cluster-info >/dev/null 2>&1 \
    || smoke_fail "context '${want}' not reachable"
  smoke_ok "GSK context '${want}' active + reachable"
}

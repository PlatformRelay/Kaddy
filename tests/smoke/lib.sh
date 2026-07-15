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
  if [[ -f "${KUBECONFIG}" ]] && kubectl cluster-info --context "kind-kaddy-dev" >/dev/null 2>&1; then
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

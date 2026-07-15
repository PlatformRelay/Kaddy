#!/usr/bin/env bash
# REQ-E1e-S02-01: Cilium CNI Ready; kube-proxy replaced; no kindnet.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
kubectl -n kube-system rollout status ds/cilium --timeout=180s
kubectl -n kube-system get ds kindnet >/dev/null 2>&1 && smoke_fail "kindnet DaemonSet present (Cilium should own CNI)" || true

# Spec S02-01 Then: no kube-proxy DaemonSet exists. This is the secure default we
# ship (kubeProxyReplacement=true). Only the DOCUMENTED fallback keeps kube-proxy,
# gated behind an explicit opt-in env — otherwise a kube-proxy DS is a hard fail.
if kubectl -n kube-system get ds kube-proxy >/dev/null 2>&1; then
  [[ "${CILIUM_KUBE_PROXY_REPLACEMENT:-true}" == "false" ]] \
    || smoke_fail "kube-proxy DaemonSet present but not the documented fallback (CILIUM_KUBE_PROXY_REPLACEMENT!=false)"
  echo "NOTE: kube-proxy kept — documented fallback (CILIUM_KUBE_PROXY_REPLACEMENT=false)"
else
  kubectl -n kube-system exec ds/cilium -- cilium-dbg status 2>/dev/null \
    | grep -qiE 'KubeProxyReplacement:\s*True' \
    || smoke_fail "KubeProxyReplacement not True and no kube-proxy DS — inconsistent state"
fi
smoke_ok "REQ-E1e-S02-01 Cilium Ready + kube-proxy replaced (no kube-proxy DS)"

#!/usr/bin/env bash
# REQ-E1e-S02-01: Cilium CNI Ready; kube-proxy replaced; no kindnet.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
kubectl -n kube-system rollout status ds/cilium --timeout=180s
kubectl -n kube-system get ds kindnet >/dev/null 2>&1 && smoke_fail "kindnet DaemonSet present (Cilium should own CNI)" || true
# kube-proxy replacement: either no kube-proxy DS, or cilium reports it active.
if kubectl -n kube-system get ds kube-proxy >/dev/null 2>&1; then
  echo "NOTE: kube-proxy DaemonSet present — checking whether this is the documented fallback"
fi
kubectl -n kube-system exec ds/cilium -- cilium-dbg status 2>/dev/null \
  | grep -qiE 'KubeProxyReplacement:\s*True' \
  || smoke_fail "KubeProxyReplacement not True (see spec deviation note if kube-proxy kept)"
smoke_ok "REQ-E1e-S02-01 Cilium Ready + kube-proxy replaced"

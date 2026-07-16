#!/usr/bin/env bash
# REQ-E6-S02-01 — Website XRD (Crossplane v2, namespaced — D-027) Established,
# Composition present, function-patch-and-transform installed + healthy.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/smoke/lib.sh
source "${DIR}/lib.sh"
smoke_require_cluster

kubectl wait --for=condition=Established xrd/websites.platform.kaddy.io --timeout=120s \
  || smoke_fail "XRD websites.platform.kaddy.io not Established"

# D-027: the XRD must be a v2 NAMESPACED XR (no v1 Claim duality).
scope="$(kubectl get xrd websites.platform.kaddy.io -o jsonpath='{.spec.scope}')"
[[ "${scope}" == "Namespaced" ]] || smoke_fail "XRD scope=${scope} (want Namespaced, D-027)"

kubectl get composition website.platform.kaddy.io >/dev/null \
  || smoke_fail "Composition website.platform.kaddy.io missing"

kubectl wait --for=condition=Healthy function/function-patch-and-transform --timeout=120s \
  || smoke_fail "function-patch-and-transform not Healthy"
kubectl wait --for=condition=Installed function/function-patch-and-transform --timeout=120s \
  || smoke_fail "function-patch-and-transform not Installed"

smoke_ok "REQ-E6-S02-01 Website XRD Established (Namespaced) + Composition + function healthy"

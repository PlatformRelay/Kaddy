#!/usr/bin/env bash
# REQ-E1-S01-01: Handoff runbook exists and is complete.
# The operator-facing runbook docs/runbooks/local-substrate-handoff.md must exist
# and cover: `task cluster:up`, kubeconfig export, Gateway API / Cilium
# GatewayClass, reaching ArgoCD via its Gateway HTTPRoute through the kind
# port-mapping / port-forward (macOS-safe), and the default StorageClass.
# It must NOT reference the load balancer we deliberately do not use (LB-IPAM
# from Cilium replaces it) — asserted by the negative grep in the spec Verify.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"

DOC="${SMOKE_ROOT}/docs/runbooks/local-substrate-handoff.md"

[[ -f "${DOC}" ]] || smoke_fail "handoff runbook missing: ${DOC}"

# Must NOT mention the LoadBalancer implementation we intentionally do not run.
if rg -i metallb "${DOC}" >/dev/null 2>&1; then
  smoke_fail "runbook must not reference metallb (Cilium LB-IPAM is used instead)"
fi

# Required coverage — each topic must appear (case-insensitive).
require() {
  rg -qi "$1" "${DOC}" || smoke_fail "runbook missing coverage: $2"
}
require 'task cluster:up'                 "task cluster:up bring-up"
require 'kubeconfig'                      "kubeconfig export"
require 'gatewayclass|gateway api'        "Gateway API / Cilium GatewayClass"
require 'argocd'                          "reaching ArgoCD"
require 'httproute'                       "ArgoCD Gateway HTTPRoute"
require '127\.0\.0\.1:30443|port-forward' "macOS-safe loopback reachability"
require 'storageclass'                    "default StorageClass"

smoke_ok "REQ-E1-S01-01 handoff runbook present and complete"

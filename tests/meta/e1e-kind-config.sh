#!/usr/bin/env bash
# REQ-E1e-S01-01: Kind config is Cilium-ready and loopback-bound.
# Offline meta test — scans hack/cluster/kind/cluster.yaml, no cluster required.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cfg="${ROOT}/hack/cluster/kind/cluster.yaml"

fail() { echo "FAIL: $*" >&2; exit 1; }

test -f "$cfg" || fail "missing $cfg"

rg -q 'disableDefaultCNI:\s*true' "$cfg" || fail "disableDefaultCNI: true not set"
rg -q 'kubeProxyMode:\s*"?none"?' "$cfg" || fail "kubeProxyMode none not set"
rg -q 'listenAddress:\s*"127.0.0.1"' "$cfg" || fail "extraPortMappings not bound to 127.0.0.1"
rg -q '0\.0\.0\.0' "$cfg" && fail "cluster.yaml binds 0.0.0.0 (must be loopback only)"
rg -q 'kindest/node:latest' "$cfg" && fail "node image pinned to :latest"
rg -q 'image:\s*kindest/node:v[0-9]+\.[0-9]+\.[0-9]+' "$cfg" || fail "node image not pinned to kindest/node:vX.Y.Z"
rg -q 'containerPort:\s*30080' "$cfg" || fail "30080 port mapping missing"
rg -q 'containerPort:\s*30443' "$cfg" || fail "30443 port mapping missing"

echo "OK: REQ-E1e-S01-01 kind config Cilium-ready + loopback-bound"

#!/usr/bin/env bash
# REQ-E1e-S05-01: Secure install — pinned, no :latest, no secrets in git.
# Offline meta test — scans hack/cluster/ and .gitignore, no cluster required.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*" >&2; exit 1; }

# 1) Pinned versions file exists AND is actually tracked (not swallowed by *.env).
test -f hack/cluster/versions.env || fail "hack/cluster/versions.env missing"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git check-ignore -q hack/cluster/versions.env \
    && fail "hack/cluster/versions.env is gitignored (needs a negation in .gitignore)"
fi

# 2) No :latest anywhere under hack/cluster/ (reproducible installs).
if rg -q ':latest' hack/cluster/; then
  echo "--- offending :latest matches ---" >&2
  rg -n ':latest' hack/cluster/ >&2
  fail "':latest' found under hack/cluster/"
fi

# 3) Local cluster state (kubeconfig, generated certs) is gitignored.
rg -q '^\.state/' .gitignore || fail ".state/ not gitignored"

echo "OK: REQ-E1e-S05-01 secure install — pinned, no :latest, .state gitignored"

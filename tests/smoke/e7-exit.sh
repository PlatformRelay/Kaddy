#!/usr/bin/env bash
# REQ-E7-EXIT: E7 epic exit gate — progressive delivery through the Gateway API.
# Runs the per-REQ smokes (blue/green strategy + promote, canary live weight
# shift + track label, recording hook, chaos deferral), then asserts the chainsaw
# rollouts suites EXIST (they are skip:true in CI — live-cluster-only substrate).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
REPO_ROOT="$(cd "${DIR}/../.." && pwd)"

# 1) Per-REQ smokes.
for t in e7-s01-01.sh e7-s01-03.sh e7-s02-03.sh e7-s03-02.sh e7-s04-01.sh ; do
  echo "=== ${t} ==="
  bash "${DIR}/${t}" || smoke_fail "smoke ${t} failed"
done

# 2) The live weight-mutation demo (both acts) — the headline E7 gate.
echo "=== hack/demo/mulligan.sh (blue/green + canary live weight shift) ==="
bash "${REPO_ROOT}/hack/demo/mulligan.sh" || smoke_fail "mulligan demo failed"

# 3) In-boundary chaos: abort a canary → auto-rollback of live HTTPRoute weights.
echo "=== hack/demo/mulligan-abort.sh (auto-rollback) ==="
bash "${REPO_ROOT}/hack/demo/mulligan-abort.sh" || smoke_fail "canary abort auto-rollback failed"

# 4) Chainsaw rollouts suites must EXIST (STRICT_TEST_FILES traceability). They
#    are intentionally skip:true in CI — the ephemeral chainsaw kind cluster has
#    no Argo Rollouts / Gateway API plugin / Cilium Gateway (cert-manager only).
#    Each suite documents its verified-live run command in its annotations.
for suite in rollouts/canary-weights rollouts/canary-rollback rollouts/bluegreen-blocks-bad-promotion ; do
  f="${REPO_ROOT}/tests/chainsaw/${suite}.yaml"
  [[ -f "${f}" ]] || smoke_fail "chainsaw suite ${suite} missing"
done
echo "E7 chainsaw suites present (skipped in CI — live-cluster-only; see suite annotations)"

smoke_ok "REQ-E7-EXIT"

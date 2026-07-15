#!/usr/bin/env bash
# REQ-E3-EXIT: E3 epic exit gate — the full E3 live smoke bundle plus the CI-enable
# check. Runs the app-of-apps sync proof first (it applies the branch-overridden
# root and waits for children Synced/Healthy), then the per-component asserts.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

# 1) Component + app-of-apps smokes, in dependency order.
for t in \
  e3-s01-02.sh \
  e3-s03-00.sh \
  e3-s01-01.sh \
  e3-s02-01.sh \
  e3-s02-02.sh \
  e3-s02-03.sh \
  e3-s02-04.sh \
  e3-s02-05.sh \
  e3-s03-01.sh ; do
  echo "=== ${t} ==="
  bash "${DIR}/${t}" || smoke_fail "smoke ${t} failed"
done

# 2) Chainsaw CI must be enabled (not path-gated off) and the monitoring/tls
#    suites must no longer be hard-skipped placeholders.
REPO_ROOT="$(cd "${DIR}/../.." && pwd)"
WF="${REPO_ROOT}/.github/workflows/chainsaw.yaml"
[[ -f "${WF}" ]] || smoke_fail "chainsaw workflow missing"
grep -q 'pull_request' "${WF}" || smoke_fail "chainsaw workflow not triggered on PR"
grep -q 'task test:chainsaw' "${WF}" || smoke_fail "chainsaw workflow does not run task test:chainsaw"
echo "chainsaw CI workflow present and PR-triggered"

# The E3 suites we authored must exist and be un-skipped.
for suite in monitoring/stack-ready monitoring/loki-ready \
             monitoring/alloy-daemonset monitoring/grafana-loki-datasource \
             tls/cert-manager-ready tls/clusterissuer-staging ; do
  f="${REPO_ROOT}/tests/chainsaw/${suite}.yaml"
  [[ -f "${f}" ]] || smoke_fail "chainsaw suite ${suite} missing"
  # must not be a hard skip
  if yq e '.spec.skip' "${f}" 2>/dev/null | grep -qx 'true'; then
    smoke_fail "chainsaw suite ${suite} still skip: true"
  fi
done
echo "E3 chainsaw suites present and enabled"

smoke_ok "REQ-E3-EXIT"

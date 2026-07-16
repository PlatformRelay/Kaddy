#!/usr/bin/env bash
# REQ-E8-S04-01/03/05/06 — offline docs contract for Getting Started + honest
# five-minute reviewer path. No cluster required.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GS="${ROOT}/docs/getting-started.md"
README="${ROOT}/README.md"

fail() { echo "FAIL: $*" >&2; exit 1; }

test -f "$GS" || fail "missing docs/getting-started.md"
test -f "$README" || fail "missing README.md"

# REQ-E8-S04-01 — reproducible local path
grep -qF 'kind-kaddy-dev' "$GS" || fail "getting-started missing kind-kaddy-dev context"
grep -qF 'task cluster:up' "$GS" || fail "getting-started missing task cluster:up"
grep -qF 'task bootstrap:argocd' "$GS" || fail "getting-started missing task bootstrap:argocd"
grep -qF '.state/kubeconfig' "$GS" || fail "getting-started missing isolated .state/kubeconfig"
grep -qF 'task cluster:down' "$GS" || fail "getting-started missing task cluster:down teardown"

# README links Getting Started before deep architecture (REQ-E8-S04-01 / S04-06)
readme_gs_line="$(grep -n 'docs/getting-started.md' "$README" | head -1 | cut -d: -f1 || true)"
readme_arch_line="$(grep -n 'docs/ARCHITECTURE.md' "$README" | head -1 | cut -d: -f1 || true)"
[[ -n "$readme_gs_line" ]] || fail "README does not link docs/getting-started.md"
[[ -n "$readme_arch_line" ]] || fail "README does not link docs/ARCHITECTURE.md"
[[ "$readme_gs_line" -lt "$readme_arch_line" ]] \
  || fail "README must link Getting Started before ARCHITECTURE (five-minute path order)"

# REQ-E8-S04-03 — service catalogue (honest local access)
for needle in \
  'https://127.0.0.1:30443/applications' \
  'https://clubhouse.kaddy.local/' \
  'https://clubhouse.kaddy.local/putting-green/' \
  'http://127.0.0.1:23000/' \
  'http://127.0.0.1:29090/' \
  'http://127.0.0.1:29093/' \
  'task demo' \
  'task demo:chaos' \
  'task test:smoke:e4' \
  'task test:smoke:e6'
do
  grep -qF "$needle" "$GS" || fail "getting-started catalogue missing: $needle"
done

# macOS honesty — do not curl LB-IPAM / port-forward selectorless Gateway Services
grep -qiE 'do not.*(curl|port-forward).*LB|never curl.*LB|selectorless' "$GS" \
  || fail "getting-started must warn against curling LB-IPAM / selectorless Gateway Services"

# REQ-E8-S04-05 — recovery + idempotent rerun
grep -qF 'task demo:fire' "$GS" || fail "getting-started missing task demo:fire recovery context"
grep -qi 'idempotent' "$GS" || fail "getting-started missing idempotent rerun note"
grep -qiE 'port.?forward|E5_GRAFANA_PORT|PROM_PORT|AM_PORT' "$GS" \
  || fail "getting-started missing port-forward / port override docs"

# REQ-E8-S04-06 — honest unavailable labels for unpublished surfaces
grep -qiE 'unavailable|not yet published|Pages.*not' "$GS" \
  || fail "getting-started must label unpublished surfaces honestly"
grep -qiE 'unavailable|not yet published|Pages' "$README" \
  || fail "README five-minute path must label unpublished scorecard/Pages honestly"

echo "OK: E8-S04 Getting Started docs contract (meta offline)"

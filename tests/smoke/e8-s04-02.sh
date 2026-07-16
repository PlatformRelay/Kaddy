#!/usr/bin/env bash
# REQ-E8-S04-02 — gridscale monthly cost / footprint table in README.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
README="${ROOT}/README.md"

fail() { echo "FAIL: $*" >&2; exit 1; }

test -f "$README" || fail "missing README.md"
grep -qE 'EUR|monthly' "$README" || fail "README missing EUR/monthly cost estimate (REQ-E8-S04-02)"
grep -qiE 'GSK|gridscale' "$README" || fail "README cost table must mention GSK/gridscale"
grep -qiE 'LBaaS' "$README" || fail "README cost table must mention LBaaS"
grep -qiE 'Object Storage|object storage' "$README" || fail "README cost table must mention Object Storage"

echo "OK: E8-S04-02 cost table present in README"

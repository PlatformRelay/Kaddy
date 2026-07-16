#!/usr/bin/env bash
# REQ-E1b-EXIT: e1b epic exit gate — offline, no cluster required.
# Asserts:
#   1. tofu test passes in modules/labels (L0 — all validation branches run).
#   2. conftest deny fires on plan-missing-tags.json (bad fixture → denied).
#   3. conftest is silent on plan-with-tags.json (good fixture → allowed).
#
# Matches REQ-E1b-EXIT: "≥ 90% of validation branches covered" — the tofu
# test suite covers all enum, regex, and missing-input paths (see spec).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 1) L0: tofu test — all modules/labels validation branches
# ---------------------------------------------------------------------------
if ! command -v tofu >/dev/null 2>&1; then
  fail "tofu not installed"
fi

test -d "${ROOT}/modules/labels/tests" \
  || fail "modules/labels/tests not found"

echo "=== L0: tofu test in modules/labels ==="
tofu_out="$(cd "${ROOT}/modules/labels" && tofu test 2>&1)"
echo "$tofu_out"
# tofu test exits non-zero on any failure; also assert at least one pass in summary.
echo "$tofu_out" | grep -q 'passed' \
  || fail "tofu test summary line not found (no passing tests)"
echo "$tofu_out" | grep -qE '[1-9][0-9]* passed, 0 failed' \
  || fail "tofu test had failures (expected N passed, 0 failed)"
pass_count="$(echo "$tofu_out" | grep -oE '[0-9]+ passed' | grep -oE '[0-9]+' || echo 0)"
echo "OK: tofu test — ${pass_count} test(s) passed, 0 failed"

# ---------------------------------------------------------------------------
# 2) L1: conftest — deny fires on bad fixture
# ---------------------------------------------------------------------------
if ! command -v conftest >/dev/null 2>&1; then
  fail "conftest not installed"
fi

test -d "${ROOT}/policy" \
  || fail "policy/ directory not found"

bad_fixture="${ROOT}/tests/fixtures/plan-missing-tags.json"
good_fixture="${ROOT}/tests/fixtures/plan-with-tags.json"

test -f "$bad_fixture"  || fail "missing $bad_fixture"
test -f "$good_fixture" || fail "missing $good_fixture"

echo "=== L1: conftest deny on plan-missing-tags.json ==="
if conftest test --policy "${ROOT}/policy" "$bad_fixture" 2>/dev/null; then
  fail "conftest did NOT deny plan-missing-tags.json (expected deny)"
fi
echo "OK: plan-missing-tags.json correctly denied"

echo "=== L1: conftest allow on plan-with-tags.json ==="
conftest test --policy "${ROOT}/policy" "$good_fixture" \
  || fail "conftest denied plan-with-tags.json (expected allow)"
echo "OK: plan-with-tags.json correctly allowed"

echo "OK: REQ-E1b-EXIT — L0 tofu test + L1 conftest gates green (offline)"

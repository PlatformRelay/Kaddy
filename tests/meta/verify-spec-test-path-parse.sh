#!/usr/bin/env bash
# Meta — STRICT_TEST_FILES path extraction must not leave a trailing backtick
# when **Test:** carries prose after the first `path` (E12c-S01-01 style).
# Regression for the advisory CI false-positive:
#   MISSING file: tests/deck/appendix-boundary.sh`
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../../hack/lib/spec-test-path.sh
source "${ROOT}/hack/lib/spec-test-path.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }

got="$(spec_test_path_from_line \
  '**Test:** `tests/deck/appendix-boundary.sh` (new) + edits to `script-wordcount.sh` + `narrative-beats.sh')" \
  || fail "expected a path from E12c-S01-01-style Test: line"
[[ "$got" == "tests/deck/appendix-boundary.sh" ]] \
  || fail "expected tests/deck/appendix-boundary.sh, got [$got]"

got="$(spec_test_path_from_line \
  '**Test:** `tests/deck/script-wordcount.sh` + `tests/deck/narrative-beats.sh` (ranges raised)')" \
  || fail "expected a path from multi-path Test: line"
[[ "$got" == "tests/deck/script-wordcount.sh" ]] \
  || fail "expected first path only, got [$got]"

got="$(spec_test_path_from_line '**Test:** `tests/deck/spoken-path.sh`')" \
  || fail "expected a path from bare Test: line"
[[ "$got" == "tests/deck/spoken-path.sh" ]] || fail "bare path mismatch: [$got]"

if spec_test_path_from_line '**Test:** manual verification (outward-facing — not a Kaddy CI gate)'; then
  fail "manual / non-path Test: must not yield a filesystem path"
fi

# End-to-end: if the appendix-boundary gate exists, STRICT must not report it missing
# (trailing-backtick false positive). Other future-epic misses may still exit 1.
[[ -f "${ROOT}/tests/deck/appendix-boundary.sh" ]] \
  || fail "tests/deck/appendix-boundary.sh missing — REQ-E12c-S01-01 is still active"

out="$(STRICT_TEST_FILES=1 bash "${ROOT}/hack/verify-spec-coverage.sh" 2>&1 || true)"
echo "$out" | grep -E 'MISSING file:.*`' \
  && fail "STRICT path parse left a trailing backtick in a MISSING line"
echo "$out" | grep -F 'MISSING file: tests/deck/appendix-boundary.sh' \
  && fail "false-positive MISSING for tests/deck/appendix-boundary.sh (file exists; REQ retained by E12d)"

echo "OK: Test: path parse strips prose; appendix-boundary is not a STRICT false-positive"

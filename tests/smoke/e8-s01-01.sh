#!/usr/bin/env bash
# REQ-E8-S01-01: k6 load profile exists and documents the RATE threshold.
# Offline structural gate — does not require a live cluster or k6 binary.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"

SCRIPT="${SMOKE_ROOT}/tests/load/marshal-threshold.js"

[[ -f "${SCRIPT}" ]] || smoke_fail "k6 profile missing: ${SCRIPT}"

# Documented lab threshold is 100 rps; profile must drive RATE=150 (above).
rg -q 'RATE' "${SCRIPT}" || smoke_fail "profile must document RATE env / threshold"
rg -q '100' "${SCRIPT}" || smoke_fail "profile must document the 100 rps marshal threshold"
rg -q '150' "${SCRIPT}" || smoke_fail "profile must target RATE=150 (above threshold)"

# Minimal valid k6 JS shape (options + default VU function).
rg -q 'export const options' "${SCRIPT}" \
  || smoke_fail "profile missing 'export const options' (invalid k6 JS)"
rg -q 'export default function' "${SCRIPT}" \
  || smoke_fail "profile missing 'export default function' (invalid k6 JS)"

smoke_ok "REQ-E8-S01-01 k6 marshal-threshold profile present and documents RATE"

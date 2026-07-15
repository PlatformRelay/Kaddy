#!/usr/bin/env bash
# REQ-E7-S03-02 — the mulligan demo has a recording hook.
#
# The demo (hack/demo/mulligan.sh) is asciinema-ready; the recording command is
# documented in evidence/demo/README.md and the demo script header. A committed
# .cast is optional (should-priority) — this smoke asserts the recording HOOK is
# present and documented so the evidence path is real, without requiring a large
# binary asset in git.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"

ROOT="${SMOKE_ROOT}"
demo="${ROOT}/hack/demo/mulligan.sh"
readme="${ROOT}/evidence/demo/README.md"

[[ -x "${demo}" ]] || smoke_fail "demo script ${demo} missing or not executable"
[[ -f "${readme}" ]] || smoke_fail "recording hook doc ${readme} missing"
grep -q "asciinema" "${readme}" || smoke_fail "recording doc does not document the asciinema hook"
grep -q "asciinema" "${demo}" || smoke_fail "demo script header does not carry the recording hook"

# If an actual cast was captured, it must be non-empty.
cast="${ROOT}/evidence/demo/mulligan.cast"
if [[ -e "${cast}" ]]; then
  [[ -s "${cast}" ]] || smoke_fail "evidence/demo/mulligan.cast exists but is empty"
fi

smoke_ok "REQ-E7-S03-02 demo recording hook documented (asciinema-ready)"

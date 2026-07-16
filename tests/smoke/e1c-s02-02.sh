#!/usr/bin/env bash
# REQ-E1c-S02-02: Filesystem scan on merge (offline structure gate).
# Asserts the Trivy CI workflow includes an fs scan of first-party paths
# (deploy/) with secret/vuln scanners — complements gitleaks. Does not run
# Trivy itself; meta covers CRITICAL exit-code structure.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"

wf="${SMOKE_ROOT}/.github/workflows/trivy.yaml"

[[ -f "$wf" ]] || smoke_fail "missing $wf (REQ-E1c-S02-02)"

# Filesystem scan present.
grep -qE "scan-type:\s*['\"]?fs['\"]?" "$wf" \
  || smoke_fail "trivy.yaml missing scan-type: fs"

# First-party focus: scan-ref under deploy/ (avoid monorepo/vendored noise).
grep -qE "scan-ref:\s*['\"]?deploy" "$wf" \
  || smoke_fail "trivy.yaml must scan deploy/ (scan-ref: deploy…)"

# Secret scanner complements gitleaks (scanners include secret).
grep -qiE "scanners:.*secret" "$wf" \
  || smoke_fail "trivy.yaml must enable secret scanner (complements gitleaks)"

smoke_ok "REQ-E1c-S02-02 trivy.yaml fs scan of deploy/ with secret scanner"

#!/usr/bin/env bash
# Fail if sanitize denylist patterns appear in paths that will be committed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DENYLIST="${ROOT}/hack/tooling/sanitize-denylist.txt"

if [[ ! -f "${DENYLIST}" ]]; then
  echo "denylist missing: ${DENYLIST}" >&2
  exit 1
fi

# Paths to scan (product + docs + deploy/CI/hack/tests; exclude harness).
# SEC-2: deploy/ (secrets live here), .github/ (workflows), hack/ (tooling),
# tests/ (fixtures) were previously omitted so the CI sanitizer never scanned
# where secrets could land.
PATHS=(
  "${ROOT}/docs"
  "${ROOT}/openspec"
  "${ROOT}/slides"
  "${ROOT}/evidence"
  "${ROOT}/modules"
  "${ROOT}/stacks"
  "${ROOT}/deploy"
  "${ROOT}/.github"
  "${ROOT}/hack"
  "${ROOT}/tests"
  "${ROOT}/README.md"
  "${ROOT}/AGENTS.md"
)

shopt -s globstar nullglob
found=0

while IFS= read -r pattern || [[ -n "${pattern}" ]]; do
  [[ -z "${pattern}" ]] && continue
  [[ "${pattern}" =~ ^# ]] && continue
  for base in "${PATHS[@]}"; do
    [[ -e "${base}" ]] || continue
    # Exclude the denylist itself and this scrubber: they contain every
    # pattern verbatim, so scanning them would self-match (SEC-2 broadening).
    if grep -RIn --exclude-dir=.git --exclude='*.sample' \
        --exclude='sanitize-denylist.txt' --exclude='scrub-denylist.sh' \
        "${pattern}" "${base}" 2>/dev/null; then
      echo "DENYLIST HIT: pattern '${pattern}'" >&2
      found=1
    fi
  done
done < "${DENYLIST}"

if [[ "${found}" -ne 0 ]]; then
  echo "scrub-denylist: remove or anonymize matches before commit" >&2
  exit 1
fi

echo "scrub-denylist: OK"

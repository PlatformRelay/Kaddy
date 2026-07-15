#!/usr/bin/env bash
# Fail if sanitize denylist patterns appear in paths that will be committed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DENYLIST="${ROOT}/hack/tooling/sanitize-denylist.txt"

if [[ ! -f "${DENYLIST}" ]]; then
  echo "denylist missing: ${DENYLIST}" >&2
  exit 1
fi

# Paths to scan (product + docs; exclude harness)
PATHS=(
  "${ROOT}/docs"
  "${ROOT}/openspec"
  "${ROOT}/slides"
  "${ROOT}/evidence"
  "${ROOT}/modules"
  "${ROOT}/stacks"
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
    if grep -RIn --exclude-dir=.git --exclude='*.sample' "${pattern}" "${base}" 2>/dev/null; then
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

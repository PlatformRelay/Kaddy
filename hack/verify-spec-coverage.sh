#!/usr/bin/env bash
# Verify every OpenSpec REQ has **Test:** and **Verify:** fields.
# STRICT_TEST_FILES=1 — also require test artifact paths to exist on disk.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPECS_DIR="${ROOT}/openspec/changes"
STRICT_TEST_FILES="${STRICT_TEST_FILES:-0}"

req_count=0
verify_count=0
test_count=0

while IFS= read -r spec; do
  while IFS= read -r req; do
    [[ -z "$req" ]] && continue
    req_count=$((req_count + 1))
    block="$(awk -v r="$req" '
      $0 == "## " r { found=1 }
      found && /^## REQ-/ && $0 != "## " r { exit }
      found { print }
    ' "$spec")"
    if ! grep -q '^\*\*Verify:\*\*' <<<"$block"; then
      echo "MISSING Verify: $req in $spec"
      exit 1
    fi
    verify_count=$((verify_count + 1))
    if ! grep -q '^\*\*Test:\*\*' <<<"$block"; then
      echo "MISSING Test: $req in $spec"
      exit 1
    fi
    test_count=$((test_count + 1))
    if [[ "$STRICT_TEST_FILES" == "1" ]]; then
      path="$(grep '^\*\*Test:\*\*' <<<"$block" | head -1 | sed 's/^\*\*Test:\*\* `//;s/`$//;s/ .*//')"
      path="${path%%#*}"
      [[ -e "${ROOT}/${path}" ]] || { echo "MISSING file: $path ($req)"; exit 1; }
    fi
  done < <(grep '^## REQ-' "$spec" | sed 's/^## //')
done < <(find "$SPECS_DIR" -path '*/specs/*/*.md' | sort)

echo "---"
echo "REQ sections: $req_count"
echo "Verify blocks: $verify_count"
echo "Test blocks:   $test_count"
echo "OK: spec coverage — every REQ has Verify + Test"

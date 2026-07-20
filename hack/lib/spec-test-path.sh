#!/usr/bin/env bash
# Extract the first filesystem artifact path from an OpenSpec **Test:** line.
#
# Specs often write prose after the path, e.g.
#   **Test:** `tests/deck/appendix-boundary.sh` (new) + edits to `script-wordcount.sh`
# A naive "strip opening backtick, then strip space-tail" left a trailing
# backtick and STRICT_TEST_FILES=1 reported a false MISSING. Always take the
# first backtick-quoted token.
#
# Returns 0 and prints the path when a backtick-quoted path is present.
# Returns 1 when the Test: line is non-path prose (manual / existing / …) so
# STRICT can skip the on-disk existence check.

spec_test_path_from_line() {
  local line="$1"
  local path=""

  if [[ "$line" =~ ^\*\*Test:\*\*[[:space:]]+\`([^\`]+)\` ]]; then
    path="${BASH_REMATCH[1]}"
    path="${path%%[[:space:]]*}"
    path="${path%%#*}"
    printf '%s\n' "$path"
    return 0
  fi
  return 1
}

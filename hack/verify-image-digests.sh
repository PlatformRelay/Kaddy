#!/usr/bin/env bash
# REQ-E1c-S03-01 (board-narrowed) — first-party deploy image gate.
#
# HARD FAIL: container `image:` refs under deploy/ that use the floating
# `:latest` tag.
#
# ADVISORY: inventory tag-only (non-@sha256:) image refs. Exit 0 even when
# tag-only refs exist — a hard digest mandate would break Helm/vendor releases
# and fight the release process. Full digest pin is a later lane.
#
# EXCLUSIONS (huge third-party vendor dumps / CRD installs — not first-party):
#   - deploy/kyverno/install.yaml
#   - deploy/rollouts/install.yaml
#   - any path matching **/install.yaml under deploy/ (same class of dump)
#
# Also skips non-image noise: comments, Kyverno match patterns (*:latest),
# OpenAPI/CRD schema keys (bare `image:` with no value), and prose.
#
# Override scan root with DEPLOY_ROOT=<dir> (used by smoke negative fixtures).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_ROOT="${DEPLOY_ROOT:-${ROOT}/deploy}"

fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -d "${DEPLOY_ROOT}" ]] || fail "deploy root missing: ${DEPLOY_ROOT}"

# Returns 0 if path is an excluded vendor dump.
is_excluded() {
  local f="$1"
  case "${f}" in
    */install.yaml|*/install.yml) return 0 ;;
  esac
  return 1
}

# True if the YAML value looks like a container image reference we should gate.
# Rejects Kyverno wildcards, empty/schema keys, and prose fragments.
is_image_ref() {
  local v="$1"
  [[ -n "${v}" ]] || return 1
  case "${v}" in
    \*|\!\*|*\***) return 1 ;;  # Kyverno patterns like *:latest, !*:latest
  esac
  # Must look like registry/name or name:tag (has a slash or a colon tag).
  [[ "${v}" == *"/"* || "${v}" == *":"* ]] || return 1
  return 0
}

# Strip optional quotes from a YAML scalar.
unquote() {
  local v="$1"
  v="${v#\"}"
  v="${v%\"}"
  v="${v#\'}"
  v="${v%\'}"
  printf '%s' "${v}"
}

# Tag is :latest (case-insensitive; optional digest suffix :latest@sha256:...).
has_latest_tag() {
  local v="$1" lower
  # bash 3.2-safe lowercase (macOS /bin/bash)
  lower="$(printf '%s' "${v}" | tr '[:upper:]' '[:lower:]')"
  [[ "${lower}" == *:latest || "${lower}" == *:latest@* ]]
}

# Has an immutable digest pin.
has_digest() {
  local v="$1"
  [[ "${v}" == *@sha256:* ]]
}

latest_hits=()
tag_only=()

# Portable file list (no GNU sort -z); bash 3.2-safe.
while IFS= read -r file; do
  [[ -n "${file}" ]] || continue
  is_excluded "${file}" && continue

  # Collect image: <value> lines (skip comments / empty values / schema keys).
  while IFS= read -r line; do
    raw="${line#*image:}"
    raw="${raw#"${raw%%[![:space:]]*}"}"  # ltrim
    [[ -n "${raw}" ]] || continue
    case "${raw}" in
      Example:*|example:*) continue ;;
    esac
    val="$(unquote "${raw%%[[:space:]]*}")"
    is_image_ref "${val}" || continue

    rel="${file#"${DEPLOY_ROOT}/"}"
    if has_latest_tag "${val}"; then
      latest_hits+=("${rel}: image: ${val}")
    elif ! has_digest "${val}"; then
      tag_only+=("${rel}: image: ${val}")
    fi
  done < <(grep -E '^[[:space:]]*image:[[:space:]]+[^[:space:]#]' "${file}" 2>/dev/null || true)
done < <(find "${DEPLOY_ROOT}" \( -name '*.yaml' -o -name '*.yml' \) -type f | LC_ALL=C sort)

if [[ ${#latest_hits[@]} -gt 0 ]]; then
  echo "FAIL: :latest image tag(s) in first-party deploy/ (REQ-E1c-S03-01):" >&2
  printf '  %s\n' "${latest_hits[@]}" >&2
  echo "Pin a version tag (digest pin optional for now). Excluded: **/install.yaml vendor dumps." >&2
  exit 1
fi

echo "OK: no :latest in first-party deploy image refs"

if [[ ${#tag_only[@]} -gt 0 ]]; then
  echo "ADVISORY: tag-only (non-digest) first-party image refs — not failing yet:"
  printf '  %s\n' "${tag_only[@]}" | LC_ALL=C sort -u
  echo "(Hard @sha256: mandate deferred — board-narrowed E1c-S03-01.)"
fi

exit 0

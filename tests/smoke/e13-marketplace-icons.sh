#!/usr/bin/env bash
# REQ-E13-S06-01 — OFFLINE gate: Marketplace vendor icons are panel-renderable.
#
# Gridscale's tenant panel renders official logos from CDN paths; our
# meta_icon is inline base64. Empirically, 16-bit/color RGBA PNGs upload
# successfully but show as a blank mark in the panel, while the module's
# bundled kaddy logo (8-bit RGB) works. This gate locks that contract.
#
# Asserts (no API, no creds):
#   1. Every engine stack that ships a vendor mark has icon_path → a present PNG
#   2. Those PNGs are ≤8-bit (IHDR bit depth)
#   3. Vendor PNG bytes ≠ the module default kaddy logo (no silent fallback)
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
MODULE_ICON="${ROOT}/modules/marketplace-template/assets/icon.png"
STACKS_ROOT="${ROOT}/stacks/gridscale-marketplace"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

# PNG IHDR bit depth lives at absolute offset 24 (sig 8 + len 4 + type 4 + w 4 + h 4).
png_bit_depth() {
  local f="$1"
  # Prefer ImageMagick when present (clearer diagnostics); fall back to raw IHDR.
  if command -v identify >/dev/null 2>&1; then
    identify -format '%z' "$f" 2>/dev/null && return 0
  fi
  od -An -tu1 -N1 -j24 "$f" | tr -d ' \n'
}

png_sha() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

[[ -f "${MODULE_ICON}" ]] || fail "missing module default icon ${MODULE_ICON}"
DEFAULT_SHA="$(png_sha "${MODULE_ICON}")"
DEFAULT_DEPTH="$(png_bit_depth "${MODULE_ICON}")"
[[ "${DEFAULT_DEPTH}" -le 8 ]] || fail "module default icon must itself be ≤8-bit (got ${DEFAULT_DEPTH})"

# engine icon_file pairs (bash-3.2 portable — no associative arrays)
ENGINES="caddy nix nginx"
icon_for() {
  case "$1" in
    caddy) echo "caddy-512.png" ;;
    nix)   echo "nixos-512.png" ;;
    nginx) echo "nginx-512.png" ;;
    *) fail "unknown engine $1" ;;
  esac
}

for engine in ${ENGINES}; do
  stack="${STACKS_ROOT}/${engine}"
  icon_name="$(icon_for "${engine}")"
  icon="${stack}/${icon_name}"
  main="${stack}/main.tf"

  [[ -d "${stack}" ]] || fail "missing stack ${engine}"
  [[ -f "${main}" ]] || fail "missing ${main}"
  grep -q "icon_path" "${main}" || fail "${engine} stack must set icon_path (no silent kaddy fallback)"
  grep -q "${icon_name}" "${main}" || fail "${engine} icon_path must reference ${icon_name}"
  [[ -f "${icon}" ]] || fail "missing vendor icon ${icon}"

  depth="$(png_bit_depth "${icon}")"
  [[ -n "${depth}" ]] || fail "could not read PNG bit depth for ${icon}"
  [[ "${depth}" -le 8 ]] || fail "${icon} is ${depth}-bit — panel needs ≤8-bit (see E13-S06 / working ${MODULE_ICON})"

  sha="$(png_sha "${icon}")"
  [[ "${sha}" != "${DEFAULT_SHA}" ]] || fail "${icon} is identical to the module default kaddy logo — vendor mark missing"

  ok "${engine}: ${icon_name} depth=${depth} distinct-from-default"
done

ok "e13 marketplace icon contract"
echo "PASS: e13 marketplace icons gate green"

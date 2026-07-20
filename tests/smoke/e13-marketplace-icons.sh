#!/usr/bin/env bash
# REQ-E13-S06-01 — OFFLINE gate: Marketplace vendor icons are panel-renderable.
#
# Gridscale's tenant panel renders official logos from CDN paths
# (`/img/assets/logos_marketplace/…`). Custom apps store `metadata.icon` as
# whatever string we POST — the API does NOT convert uploads to CDN paths.
# Empirically the panel uses the icon string as an <img src>, so:
#   - CDN / absolute URL → renders
#   - raw base64 (no scheme) → blank (browser treats it as a relative URL)
#   - data:image/png;base64,… → renders
#
# Provider docs only say "base64 encoded image" (no MIME/size/dim). The working
# contract for custom apps is therefore a data-URI-prefixed PNG. Keep PNGs
# ≤8-bit RGB (smaller payload; 16-bit RGBA also uploaded historically).
#
# Asserts (no API, no creds):
#   1. Module wires meta_icon as data:image/…;base64, + filebase64(...)
#   2. Every engine stack that ships a vendor mark has icon_path → a present PNG
#   3. Those PNGs are ≤8-bit (IHDR bit depth) and ≤200 KiB raw
#   4. Vendor PNG bytes ≠ the module default kaddy logo (no silent fallback)
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
MODULE_MAIN="${ROOT}/modules/marketplace-template/main.tf"
MODULE_ICON="${ROOT}/modules/marketplace-template/assets/icon.png"
STACKS_ROOT="${ROOT}/stacks/gridscale-marketplace"
MAX_ICON_BYTES=$((200 * 1024))

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

# PNG IHDR bit depth lives at absolute offset 24 (sig 8 + len 4 + type 4 + w 4 + h 4).
png_bit_depth() {
  local f="$1"
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

[[ -f "${MODULE_MAIN}" ]] || fail "missing ${MODULE_MAIN}"
# Panel needs a scheme on metadata.icon — data URI for filebase64 payloads.
grep -E 'meta_icon\s*=\s*"data:image/' "${MODULE_MAIN}" >/dev/null \
  || fail "module must set meta_icon to a data:image/…;base64,\${filebase64(...)} URI (raw base64 renders blank in the panel)"
grep -q 'filebase64' "${MODULE_MAIN}" \
  || fail "module meta_icon must still use filebase64 for the image bytes"

[[ -f "${MODULE_ICON}" ]] || fail "missing module default icon ${MODULE_ICON}"
DEFAULT_SHA="$(png_sha "${MODULE_ICON}")"
DEFAULT_DEPTH="$(png_bit_depth "${MODULE_ICON}")"
[[ "${DEFAULT_DEPTH}" -le 8 ]] || fail "module default icon must itself be ≤8-bit (got ${DEFAULT_DEPTH})"

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
  [[ "${depth}" -le 8 ]] || fail "${icon} is ${depth}-bit — keep ≤8-bit RGB for compact data-URI payloads"

  bytes="$(wc -c < "${icon}" | tr -d ' ')"
  [[ "${bytes}" -le "${MAX_ICON_BYTES}" ]] \
    || fail "${icon} is ${bytes} bytes — keep vendor icons ≤${MAX_ICON_BYTES} for panel data URIs"

  sha="$(png_sha "${icon}")"
  [[ "${sha}" != "${DEFAULT_SHA}" ]] || fail "${icon} is identical to the module default kaddy logo — vendor mark missing"

  ok "${engine}: ${icon_name} depth=${depth} bytes=${bytes} distinct-from-default"
done

ok "e13 marketplace icon contract (data-URI + ≤8-bit PNG)"
echo "PASS: e13 marketplace icons gate green"

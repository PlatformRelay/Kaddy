#!/usr/bin/env bash
# REQ-E12 — Slidev PDF export via Playwright (mirrors kubernetes-workshop
# `pnpm exec slidev export` + playwright-chromium). Asserts `pnpm export`
# exits 0, that slides/kaddy-deck.pdf exists and was REFRESHED by this run,
# and that the PDF is non-hollow (CI previously shipped ~2.6KB empty PDFs
# when Vite re-optimized deps mid-export).
#
# CI installs Chromium OS libs then the browser binary
# (`pnpm exec playwright install-deps chromium` +
# `pnpm exec playwright install chromium` in .github/workflows/deck.yaml
# and release.yml). Locally, playwright-chromium's postinstall usually
# suffices on macOS; on Linux you may need the same install-deps + install.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SLIDES="${ROOT}/slides"
OUT="kaddy-deck.pdf"
# Hollow CI exports were ~2.6KB; a real deck with surfaces is multi-MB.
# 100 KiB rejects empty shells without false-failing a minimal text deck.
MIN_BYTES="${MIN_DECK_PDF_BYTES:-102400}"

fail() { echo "FAIL: $*" >&2; exit 1; }

command -v pnpm >/dev/null 2>&1 || fail "pnpm not installed (required to export the deck)"
[ -f "${SLIDES}/package.json" ] || fail "slides/package.json missing"
[ -f "${SLIDES}/slides.md" ] || fail "slides/slides.md missing"

cd "${SLIDES}"
if [ ! -d node_modules ]; then
  echo "node_modules missing — pnpm install --frozen-lockfile"
  pnpm install --frozen-lockfile
fi

stamp="$(mktemp "${TMPDIR:-/tmp}/deck-export-stamp.XXXXXX")"
trap 'rm -f "${stamp}"' EXIT

export_once() {
  pnpm export || fail "pnpm export (slidev export slides.md) exited non-zero"
  [ -f "${OUT}" ] || fail "slides/${OUT} not produced"
  [ "${OUT}" -nt "${stamp}" ] || fail "slides/${OUT} is stale (not refreshed by this export)"
}

# First pass can hollow the PDF when Vite prints
# "optimized dependencies changed. reloading" mid-export (observed in CI).
# Warm dep cache with pass 1; size-guard; retry once if hollow.
export_once
bytes="$(wc -c < "${OUT}" | tr -d '[:space:]')"
if [ "${bytes}" -lt "${MIN_BYTES}" ]; then
  echo "WARN: slides/${OUT} is ${bytes} bytes (< ${MIN_BYTES}) — retrying export after Vite dep warm-up" >&2
  rm -f "${OUT}"
  touch "${stamp}"
  export_once
  bytes="$(wc -c < "${OUT}" | tr -d '[:space:]')"
fi

[ "${bytes}" -ge "${MIN_BYTES}" ] \
  || fail "slides/${OUT} is hollow (${bytes} bytes < ${MIN_BYTES} MIN_DECK_PDF_BYTES) — refusing to publish"

echo "OK: slidev export green — slides/${OUT} present, refreshed, ${bytes} bytes"

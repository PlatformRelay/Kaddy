#!/usr/bin/env bash
# REQ-E12 — Slidev PDF export via Playwright (mirrors kubernetes-workshop
# `pnpm exec slidev export` + playwright-chromium). Asserts `pnpm export`
# exits 0 and that slides/kaddy-deck.pdf exists and was REFRESHED by this run.
#
# CI installs Chromium OS libs then the browser binary
# (`pnpm exec playwright install-deps chromium` +
# `pnpm exec playwright install chromium` in .github/workflows/deck.yaml).
# Locally, playwright-chromium's postinstall usually suffices on macOS; on
# Linux you may need the same install-deps + install once.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SLIDES="${ROOT}/slides"
OUT="kaddy-deck.pdf"

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

pnpm export || fail "pnpm export (slidev export slides.md) exited non-zero"

[ -f "${OUT}" ] || fail "slides/${OUT} not produced"
[ "${OUT}" -nt "${stamp}" ] || fail "slides/${OUT} is stale (not refreshed by this export)"

echo "OK: slidev export green — slides/${OUT} present and refreshed"

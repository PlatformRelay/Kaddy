#!/usr/bin/env bash
# REQ-E12-S01-01 — Slidev scaffold builds a reproducible static SPA (meta).
# Asserts `slidev build` (via `pnpm build` in slides/) exits 0 and that
# slides/dist/index.html exists and was REFRESHED by this run (newer than a
# stamp taken before the build) — not a stale artifact from a previous build.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SLIDES="${ROOT}/slides"

fail() { echo "FAIL: $*" >&2; exit 1; }

command -v pnpm >/dev/null 2>&1 || fail "pnpm not installed (required to build the deck)"
[ -f "${SLIDES}/package.json" ] || fail "slides/package.json missing"
[ -f "${SLIDES}/slides.md" ] || fail "slides/slides.md missing"

cd "${SLIDES}"
if [ ! -d node_modules ]; then
  echo "node_modules missing — pnpm install --frozen-lockfile"
  pnpm install --frozen-lockfile
fi

stamp="$(mktemp "${TMPDIR:-/tmp}/deck-build-stamp.XXXXXX")"
trap 'rm -f "${stamp}"' EXIT

pnpm build || fail "pnpm build (slidev build slides.md) exited non-zero"

[ -f dist/index.html ] || fail "slides/dist/index.html not produced"
[ dist/index.html -nt "${stamp}" ] || fail "slides/dist/index.html is stale (not refreshed by this build)"

echo "OK: slidev build green — slides/dist/ present and refreshed"

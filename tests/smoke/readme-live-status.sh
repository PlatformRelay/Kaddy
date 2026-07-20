#!/usr/bin/env bash
# README live-demo honesty — offline gate.
# After portal NetPol + caddy-lab HTTPRoute rename landed on main, the root
# README must not claim stale HTTPS 404 for portal.lab / caddy.lab, and must
# record the live sticky HTTPS 200 status (board + external probe 2026-07-20).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
README="${ROOT}/README.md"

fail() { echo "FAIL: $*" >&2; exit 1; }
[ -f "${README}" ] || fail "README.md missing"

# Stale 404 claims must fail the gate.
if grep -Fi 'caddy.lab' "${README}" | grep -Eqi 'currently.*(HTTPS )?404|returns.*(HTTPS )?404|HTTPS 404'; then
  fail "README claims stale caddy.lab HTTPS 404 — expect sticky HTTPS 200 after caddy-lab rename"
fi
if grep -Fi 'portal.lab' "${README}" | grep -Eqi 'currently.*(HTTPS )?404|returns.*(HTTPS )?404|HTTPS 404'; then
  fail "README claims stale portal.lab HTTPS 404 — expect sticky HTTPS 200 after portal NetPol"
fi

grep -F 'caddy.lab' "${README}" | grep -F '200' >/dev/null \
  || fail "README must record caddy.lab HTTPS 200"
grep -F 'portal.lab' "${README}" | grep -F '200' >/dev/null \
  || fail "README must record portal.lab HTTPS 200"

# Deck is consumed from Releases, not a build-first reviewer path.
grep -F 'github.com/PlatformRelay/Kaddy/releases' "${README}" >/dev/null \
  || fail "README must link GitHub Releases for the pitch deck"
grep -Eqi 'Download.*(from )?[Rr]eleases|[Rr]eleases.*(deck|pitch)' "${README}" \
  || fail "README must prefer Download … from Releases for the deck"

# Scannable status (not a single prose blob only).
grep -F '✅' "${README}" | grep -F '|' >/dev/null \
  || fail "README Status section must use a scannable table with ✅ rows"

echo "OK: README live-status honesty (caddy.lab + portal.lab 200; Releases deck link)"

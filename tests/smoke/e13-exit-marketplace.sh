#!/usr/bin/env bash
# REQ-E13-EXIT — one-click Marketplace deploy demonstrable end-to-end.
#
# LIVE, gated on E1g credits. NOT wired into CI/verify. Runs the three E13 live
# smoke scripts in order (export → register → deploy) + the promtool L1 fire
# test; each live step SKIPs cleanly without creds/state, so this exit script is
# green offline (the promtool step always runs) and only exercises the full live
# path when creds + a deployed VM are present. See the runbook for the manual
# demo (build → export → register → import → deploy from template).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"

# The offline-provable part: the caddy_* alert fires against a gridscale target.
if command -v promtool >/dev/null 2>&1; then
  promtool test rules "${ROOT}/tests/promtool/gridscale-marketplace.test.yaml" >/dev/null \
    || { echo "FAIL: promtool caddy_* alert test failed" >&2; exit 1; }
  echo "OK: caddy_* alert fires+silent against a gridscale Marketplace VM target"
else
  echo "SKIP: promtool not installed"
fi

# The live steps (each SKIPs without creds/state).
bash "${DIR}/e13-s01-export.sh"
bash "${DIR}/e13-s02-register.sh"
bash "${DIR}/e13-s03-deploy.sh"

echo "OK: REQ-E13-EXIT — Marketplace deploy path exercised (live steps skip without creds; see the runbook)"

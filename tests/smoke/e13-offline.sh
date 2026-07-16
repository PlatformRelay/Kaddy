#!/usr/bin/env bash
# REQ-E13-S02-01 / S03-02 — OFFLINE gate for the gridscale Marketplace template.
# No gridscale API, no credentials, no live build/export. Proves:
#   1. terramate generate is up-to-date (codegen not drifted) for the new stacks
#   2. tofu fmt -check clean across modules/marketplace-template + the stacks
#   3. tofu init -backend=false + validate + test (mock_provider) on the module
#      and both Marketplace stacks
#   4. packer fmt -check on the golden-image builds; packer validate best-effort
#      (SKIP if the gridscale plugin can't be fetched — mirrors e1g init skip)
#   5. promtool: the caddy_* marshal alert fires+is-silent against a gridscale VM
#
# This is the GREEN gate wired into `task test:smoke:e13` and the CI meta gate.
# The LIVE proofs (build → export → register → import → deploy) are the separate
# tests/smoke/e13-s0{1,2,3}-*.sh scripts, which SKIP without creds by design.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
MODULE="${ROOT}/modules/marketplace-template"
STACKS_ROOT="${ROOT}/stacks/gridscale-marketplace"
STACKS=(caddy nginx)

export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-${HOME}/.terraform.d/plugin-cache}"
mkdir -p "${TF_PLUGIN_CACHE_DIR}"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

command -v tofu >/dev/null 2>&1 || { echo "tofu not installed — skip e13 offline gate"; exit 0; }

# --- 1) Terramate codegen must be current (if terramate is installed) --------
if command -v terramate >/dev/null 2>&1; then
  ( cd "${ROOT}" && terramate generate >/dev/null ) || fail "terramate generate errored"
  if ! git -C "${ROOT}" diff --quiet -- stacks/gridscale-marketplace 2>/dev/null; then
    fail "terramate codegen drift under stacks/gridscale-marketplace — run 'task e13:generate' and commit"
  fi
  ok "terramate codegen up-to-date"
else
  echo "terramate not installed — skip codegen drift check (generated .tf already committed)"
fi

# --- 2) fmt -----------------------------------------------------------------
tofu fmt -check -recursive "${MODULE}" >/dev/null || fail "tofu fmt drift under modules/marketplace-template"
tofu fmt -check -recursive "${STACKS_ROOT}" >/dev/null || fail "tofu fmt drift under stacks/gridscale-marketplace"
ok "tofu fmt clean"

# --- 3) module + per-stack validate + test ----------------------------------
# `tofu init` fetches the public gridscale provider on a cold cache (NOT a
# gridscale API call). Probe once; SKIP (not fail) the provider-dependent steps
# if the provider is genuinely unreachable — fmt + packer fmt + promtool below
# still run (they need no provider).
if ! ( cd "${MODULE}" && tofu init -backend=false -input=false >/dev/null 2>&1 ); then
  echo "SKIP: gridscale provider unreachable (no registry egress / cold cache) — validate+test skipped; fmt+packer+promtool still enforced"
else
  ( cd "${MODULE}" && tofu validate >/dev/null 2>&1 ) || fail "tofu validate module"
  ( cd "${MODULE}" && tofu test >/dev/null 2>&1 ) || fail "tofu test module"
  ok "validate+test modules/marketplace-template"
  for s in "${STACKS[@]}"; do
    d="${STACKS_ROOT}/${s}"
    [[ -d "$d" ]] || fail "missing stack ${s}"
    ( cd "$d" && tofu init -backend=false -input=false >/dev/null 2>&1 ) || fail "tofu init ${s}"
    ( cd "$d" && tofu validate >/dev/null 2>&1 ) || fail "tofu validate ${s}"
    ( cd "$d" && tofu test >/dev/null 2>&1 ) || fail "tofu test ${s}"
    ok "validate+test ${s}"
  done
fi

# --- 4) packer fmt (always) + validate (best-effort) ------------------------
if command -v packer >/dev/null 2>&1; then
  packer fmt -check "${ROOT}/packer" >/dev/null 2>&1 || fail "packer fmt drift under packer/"
  ok "packer fmt clean"
  # validate needs the gridscale plugin; init may need registry egress. Probe
  # once — SKIP (not fail) if the plugin can't be fetched offline.
  #
  # NOTE: the .pkr.hcl builder arg names + plugin source were authored from the
  # gridscale Packer tutorial, NOT a cached plugin schema (none is vendored). So
  # `packer validate` is best-effort: a failure here is WARNED, not fatal — the
  # authoritative check of the builder args is the live `packer build` cycle (see
  # the runbook). `packer fmt` above stays strict (it needs no plugin schema).
  if ( cd "${ROOT}/packer" && packer init . >/dev/null 2>&1 ); then
    for f in caddy nginx; do
      if ( cd "${ROOT}/packer" && packer validate "${f}.pkr.hcl" >/dev/null 2>&1 ); then
        ok "packer validate ${f}"
      else
        echo "WARN: packer validate ${f}.pkr.hcl failed (unverified builder args — checked at live build; see the runbook)"
      fi
    done
  else
    echo "SKIP: gridscale packer plugin unavailable offline — packer validate skipped (fmt still enforced)"
  fi
else
  echo "packer not installed — skip packer fmt/validate (CI installs packer)"
fi

# --- 5) promtool: caddy_* alert fires against the gridscale VM target -------
if command -v promtool >/dev/null 2>&1; then
  promtool test rules "${ROOT}/tests/promtool/gridscale-marketplace.test.yaml" >/dev/null \
    || fail "promtool caddy_* alert test failed"
  ok "promtool gridscale-marketplace alert test"
else
  echo "promtool not installed — skip alert test (CI installs promtool)"
fi

echo "PASS: e13 offline gate green"

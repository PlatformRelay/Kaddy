#!/usr/bin/env bash
# REQ-E13-S02-02 — Marketplace application registered + imported into the tenant.
#
# LIVE, gated on E1g credits. NOT wired into CI/verify (green gate is
# tests/smoke/e13-offline.sh). SKIPs (exit 0) without creds/state by design so it
# never reddens CI — real assertions run at the live register/import cycle.
#
# Asserts: after `tofu apply` of stacks/gridscale-marketplace/${engine}, the
# application has an id + unique_hash and the private-tenant import id is set
# (D-032: is_publish_* stay false — no global publication).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
: "${MARKETPLACE_ENGINE:=caddy}"
STACK="${ROOT}/stacks/gridscale-marketplace/${MARKETPLACE_ENGINE}"

# --- Gate: need gridscale creds + tofu + applied live state -------------------
if [[ -z "${GRIDSCALE_USER_UUID:-}" || -z "${GRIDSCALE_API_KEY:-}" ]]; then
  echo "SKIP: gridscale creds unset (GRIDSCALE_USER_UUID/GRIDSCALE_API_KEY) — live register not run; see the runbook"
  exit 0
fi
command -v tofu >/dev/null 2>&1 || { echo "SKIP: tofu not installed"; exit 0; }
[[ -d "${STACK}" ]] || { echo "FAIL: stack ${STACK} missing" >&2; exit 1; }

# Read outputs from the applied stack (task e13:up applies it first).
app_id="$(cd "${STACK}" && tofu output -raw application_id 2>/dev/null || true)"
uniq="$(cd "${STACK}" && tofu output -raw unique_hash 2>/dev/null || true)"
import_id="$(cd "${STACK}" && tofu output -raw import_id 2>/dev/null || true)"

if [[ -z "${app_id}" ]]; then
  echo "SKIP: no applied state for ${MARKETPLACE_ENGINE} (application_id empty) — run 'task e13:up' first; see the runbook"
  exit 0
fi

[[ -n "${uniq}" ]]      || { echo "FAIL: application registered but unique_hash empty" >&2; exit 1; }
[[ -n "${import_id}" ]] || { echo "FAIL: application not imported into tenant (import_id empty)" >&2; exit 1; }

echo "OK: REQ-E13-S02-02 ${MARKETPLACE_ENGINE} app registered (id=${app_id}) + imported (import_id=${import_id}, private tenant)"

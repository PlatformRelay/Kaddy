#!/usr/bin/env bash
# REQ-E13-S03-01 — server deployed from the template serves the sample page.
#
# LIVE, gated on E1g credits. NOT wired into CI/verify (green gate is
# tests/smoke/e13-offline.sh). SKIPs (exit 0) without a deployed VM host by
# design so it never reddens CI — real assertions run at the live deploy cycle.
#
# Asserts: the gridscale_server deployed from the imported Marketplace template
# serves the sample page (HTTP 200) and exposes /metrics — the serve→scrape half
# of serve→scrape→fire (the fire half is the promtool L1 + Prometheus scrape).
set -euo pipefail

# MARKETPLACE_VM_HOST is set by task e13:up (from the deployed server's IP).
if [[ -z "${MARKETPLACE_VM_HOST:-}" ]]; then
  echo "SKIP: MARKETPLACE_VM_HOST unset (no deployed Marketplace VM) — live deploy not run; see the runbook"
  exit 0
fi
command -v curl >/dev/null 2>&1 || { echo "SKIP: curl not installed"; exit 0; }

# 1) sample page served (HTTP 200).
code="$(curl -sf -o /dev/null -w '%{http_code}' "http://${MARKETPLACE_VM_HOST}/" || true)"
[[ "${code}" == "200" ]] \
  || { echo "FAIL: sample page not served (HTTP ${code:-none}) from ${MARKETPLACE_VM_HOST}" >&2; exit 1; }

# 2) /metrics exposed (feeds the caddy_* marshal alerts).
if ! curl -sf "http://${MARKETPLACE_VM_HOST}:2019/metrics" >/dev/null 2>&1 \
   && ! curl -sf "http://${MARKETPLACE_VM_HOST}:9113/metrics" >/dev/null 2>&1; then
  echo "FAIL: /metrics not exposed on ${MARKETPLACE_VM_HOST} (:2019 caddy or :9113 nginx-exporter)" >&2
  exit 1
fi

echo "OK: REQ-E13-S03-01 Marketplace VM serves the sample page (200) + exposes /metrics — ${MARKETPLACE_VM_HOST}"

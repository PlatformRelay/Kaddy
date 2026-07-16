#!/usr/bin/env bash
# REQ-CADDY-S01-04 — VM variant: in-cluster Prometheus scrapes the VM's external
# metrics endpoint (up{job="caddy"}==1; stopping the VM fires CaddyTargetDown).
#
# BLOCKED on phase-2 E6g (Upjet provider-gridscale `gridscale_server`) + E1g
# (gridscale day-0 / credentials). No VM is provisioned in phase 1, so there is
# no external target to scrape yet. This is a skip stub (the smoke-test analog of
# the `skip: true` Chainsaw convention) so STRICT_TEST_FILES=1 spec coverage
# resolves the REQ's `Test:` path; the S01 lane replaces this body with the live
# assertion below once E6g/E1g land.
set -euo pipefail

echo "SKIP REQ-CADDY-S01-04 — blocked on phase-2 E6g/E1g (no gridscale VM in phase 1)."
echo "When unblocked, assert (via port-forwarded Prometheus):"
echo "  curl -s 'http://127.0.0.1:9090/api/v1/query?query=up{job=\"caddy\"}' \\"
echo "    | jq -e '.data.result[0].value[1]==\"1\"'"
exit 0

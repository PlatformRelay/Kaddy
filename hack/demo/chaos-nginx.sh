#!/usr/bin/env bash
# REQ-E7-S04-02 — chaos: stop the legacy gridscale nginx VM → /legacy unhealthy,
# / still 200, Crossplane/manual reconcile.
#
# STATUS: DOCUMENTED / DEFERRED — out of the E7 lane boundary.
#
# This chaos beat targets the legacy nginx server running on a gridscale VM and
# the /legacy proxy path, which belong to the Caddy-MVP / gridscale epics
# (e-caddy-mvp, e13-gridscale-marketplace). Neither the gridscale VM nor the
# /legacy route is provisioned on the local kind cluster, so this script does NOT
# fake a passing run — it fails loudly unless the target exists, documenting the
# intended procedure. The IN-BOUNDARY chaos demo (abort a canary → Argo Rollouts
# auto-rollback) lives in hack/demo/mulligan-abort.sh and is real.
#
# Intended procedure once the gridscale substrate exists:
#   1. Stop the nginx VM:   gridscale/openstack stop <nginx-server-id>
#   2. curl https://<edge>/legacy  → expect 502/503 (backend down)
#   3. curl https://<edge>/        → expect 200 (clubhouse unaffected)
#   4. Reconcile: Crossplane re-applies the Server claim, or manual VM start.
set -euo pipefail

echo "REQ-E7-S04-02 chaos-nginx: DEFERRED — gridscale nginx VM + /legacy path are"
echo "out of the E7 lane boundary (Caddy-MVP / gridscale epics) and not deployed on"
echo "kind. See the header for the intended procedure. Running the IN-BOUNDARY"
echo "auto-rollback chaos instead: hack/demo/mulligan-abort.sh"

if [[ "${E7_CHAOS_STRICT:-0}" == "1" ]]; then
  echo "E7_CHAOS_STRICT=1 and gridscale substrate absent — failing as documented." >&2
  exit 1
fi
exit 0

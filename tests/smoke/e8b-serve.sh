#!/usr/bin/env bash
# REQ-E8b-S02 — LIVE serve + read-only posture check for the demo surfaces.
#
# Runs ONLY at the live cycle (needs a reachable cluster with the e8b-demo App
# synced). The offline gate (e8b-offline.sh) authors + validates the manifests;
# THIS script proves the routes actually serve and Grafana is genuinely
# read-only. It is invoked by e8b-offline.sh only when E8B_LIVE=1, and is a hard
# FAIL if the cluster is unreachable in that mode (a live gate must not silently
# pass).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
# The live demo runs against GSK, not kind. If the operator names a GSK context
# (E8B_GSK_CONTEXT, per the runbook), require exactly that; otherwise fall back
# to the kind-pinned guard (also lets you dry-run the demo on the local cluster).
if [[ -n "${E8B_GSK_CONTEXT:-}" ]]; then
  smoke_require_named_context "${E8B_GSK_CONTEXT}"
else
  smoke_require_cluster
fi

NS="${E8B_NS:-monitoring}"

# 1) The GitOps child Application is Synced/Healthy.
kubectl -n argocd get application e8b-demo \
  -o jsonpath='{.status.sync.status}/{.status.health.status}' 2>/dev/null \
  | grep -q 'Synced/Healthy' \
  || smoke_fail "e8b-demo Application not Synced/Healthy"
smoke_ok "e8b-demo Application Synced/Healthy"

# 2) Both demo Deployments are Available.
kubectl -n "${NS}" rollout status deploy/e8b-scorecard --timeout=120s \
  || smoke_fail "e8b-scorecard not Available"
kubectl -n "${NS}" rollout status deploy/e8b-grafana-readonly --timeout=180s \
  || smoke_fail "e8b-grafana-readonly not Available"
smoke_ok "scorecard + read-only Grafana Deployments Available"

# 3) Scorecard serves THROUGH the Gateway (not the Service root) — this is the
#    path S02 promises and the one where a missing prefix-strip 404s. Resolve the
#    Gateway's in-cluster address (cilium provisions a LoadBalancer Service
#    `cilium-gateway-clubhouse` in ns gateway) and curl the real demo URL with
#    the clubhouse Host header (TLS is terminated at the LBaaS on the cloud edge;
#    in-cluster we hit the HTTP path with the routed host). A prefix-strip bug
#    surfaces here as a 404, which the Service-root probe would have hidden.
GW_HOST="${E8B_GW_HOST:-clubhouse.kaddy.local}"
GW_ADDR="$(kubectl -n gateway get svc cilium-gateway-clubhouse \
  -o jsonpath='{.spec.clusterIP}' 2>/dev/null || true)"
[[ -n "${GW_ADDR}" ]] || smoke_fail "clubhouse Gateway Service (cilium-gateway-clubhouse) not found in ns gateway"
kubectl -n "${NS}" run e8b-probe --rm -i --restart=Never --image=curlimages/curl:8.10.1 -- \
  -sf -H "Host: ${GW_HOST}" "http://${GW_ADDR}/scorecard" >/dev/null \
  || smoke_fail "scorecard did not serve 200 at /scorecard THROUGH the Gateway (prefix-strip / route bug)"
smoke_ok "scorecard static evidence site serves through the Gateway at /scorecard"

# 4) Grafana is READ-ONLY: anonymous access works AND a write is rejected.
#    Paths carry the /grafana sub-path prefix (serve_from_sub_path=true) — the
#    prefix is NOT stripped for this route (contrast the scorecard rule).
#    Anonymous GET of the health endpoint must succeed.
kubectl -n "${NS}" run e8b-graf-probe --rm -i --restart=Never --image=curlimages/curl:8.10.1 -- \
  -sf "http://e8b-grafana-readonly.${NS}.svc:3000/grafana/api/health" >/dev/null \
  || smoke_fail "read-only Grafana /grafana/api/health did not respond"
#    An anonymous POST (create dashboard) MUST be denied (401/403) — proves the
#    Viewer role has no write. curl -o /dev/null -w status; assert non-2xx.
code="$(kubectl -n "${NS}" run e8b-graf-write --rm -i --restart=Never \
  --image=curlimages/curl:8.10.1 -- \
  -s -o /dev/null -w '%{http_code}' -X POST \
  -H 'Content-Type: application/json' -d '{}' \
  "http://e8b-grafana-readonly.${NS}.svc:3000/grafana/api/dashboards/db" 2>/dev/null || true)"
case "${code}" in
  401|403) smoke_ok "read-only Grafana rejects anonymous write (${code})" ;;
  *)       smoke_fail "read-only Grafana accepted/again a write attempt (HTTP ${code}) — not read-only" ;;
esac

echo "PASS: e8b live serve gate green"

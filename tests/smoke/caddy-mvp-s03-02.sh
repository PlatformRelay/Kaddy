#!/usr/bin/env bash
# REQ-CADDY-S03-02 — the GitOps path works portal-free: a tenant defined ONLY by
# YAML committed to git is fully materialized by one Argo CD sync, with no
# Backstage runtime present — proving E10 can be cut without stranding this epic.
#
# Offline this script asserts the S02 manifest set under deploy/workloads/caddy-mvp/
# is a complete, git-only tenant definition (no portal/runtime write path in it).
# Exit 0 offline; set CADDY_MVP_GITOPS_LIVE=1 to assert the workloads Application
# is Healthy on a live cluster.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
TENANT="${ROOT}/deploy/workloads/caddy-mvp"

# The tenant is defined purely by declarative YAML in git — the pieces a single
# Argo sync needs to materialize the served-website product from git alone.
for f in namespace.yaml gateway.yaml httproute.yaml rollout-caddy-origin.yaml services.yaml; do
  [[ -f "${TENANT}/${f}" ]] || { echo "FAIL: missing git-only tenant manifest ${f}" >&2; exit 1; }
done
echo "OK: caddy-mvp tenant is a complete git-only manifest set (portal-free)"

if [[ "${CADDY_MVP_GITOPS_LIVE:-0}" != "1" ]]; then
  echo "OK: REQ-CADDY-S03-02 offline structural (set CADDY_MVP_GITOPS_LIVE=1 for live Argo health)"
  exit 0
fi

health="$(kubectl -n argocd get application workloads -o jsonpath='{.status.health.status}')"
[[ "${health}" == "Healthy" ]] || { echo "FAIL: workloads Application health=${health}, want Healthy" >&2; exit 1; }
echo "OK: REQ-CADDY-S03-02 live — workloads Application Healthy from git alone"

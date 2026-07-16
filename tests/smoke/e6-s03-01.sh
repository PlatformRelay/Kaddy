#!/usr/bin/env bash
# REQ-E6-S03-01 — the demo Website XR (websites/putting-green, GitOps-synced via
# the workloads Application) reconciles: XR Synced+Ready, composed Deployment /
# Service / HTTPRoute / Certificate / ServiceMonitor exist with ADR-0301 labels.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/smoke/lib.sh
source "${DIR}/lib.sh"
smoke_require_cluster

NS="websites"
XR="putting-green"

kubectl -n "${NS}" get website "${XR}" >/dev/null \
  || smoke_fail "Website XR ${NS}/${XR} missing (workloads app not synced?)"

kubectl -n "${NS}" wait --for=condition=Synced "website/${XR}" --timeout=180s \
  || smoke_fail "Website XR not Synced"
kubectl -n "${NS}" wait --for=condition=Ready "website/${XR}" --timeout=300s \
  || smoke_fail "Website XR not Ready"

# Composed set — one claim = one monitored TLS site.
kubectl -n "${NS}" wait --for=condition=Available "deploy/${XR}" --timeout=180s \
  || smoke_fail "composed Deployment not Available"
kubectl -n "${NS}" get "service/${XR}" >/dev/null || smoke_fail "composed Service missing"
kubectl -n "${NS}" get "httproute/${XR}" >/dev/null || smoke_fail "composed HTTPRoute missing"
kubectl -n "${NS}" get "servicemonitor/${XR}" >/dev/null || smoke_fail "composed ServiceMonitor missing"
kubectl -n "${NS}" wait --for=condition=Ready "certificate/${XR}" --timeout=180s \
  || smoke_fail "composed Certificate not Ready (kaddy-local-ca)"

# HTTPRoute accepted by the clubhouse Gateway (cross-namespace attach).
acc="$(kubectl -n "${NS}" get httproute "${XR}" \
  -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}' 2>/dev/null || true)"
[[ "${acc}" == "True" ]] || smoke_fail "composed HTTPRoute not Accepted by Gateway (got '${acc}')"

# ADR-0301 labels propagated from the XR to composed resources (REQ-E1b story).
for kind in deploy service httproute servicemonitor certificate; do
  for key in owner service part-of managed-by data-classification business-criticality track; do
    v="$(kubectl -n "${NS}" get "${kind}/${XR}" -o jsonpath="{.metadata.labels.${key}}" 2>/dev/null)"
    [[ -n "${v}" ]] || smoke_fail "composed ${kind}/${XR} missing ADR-0301 label '${key}'"
  done
done

smoke_ok "REQ-E6-S03-01 Website XR Ready — composed site+cert+monitor live with ADR-0301 labels"

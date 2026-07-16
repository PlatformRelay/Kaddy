#!/usr/bin/env bash
# REQ-E5-S09-01 (ARCH-8): deploy/monitoring/ is GitOps-synced — the `monitoring`
# Argo CD child Application exists, is Synced/Healthy, and the kaddy-authored
# monitoring resources (marshal-http PrometheusRule, clubhouse Probe,
# ServiceMonitors, dashboard CM) are LIVE in ns monitoring.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

sync="$(kubectl -n argocd get application monitoring -o jsonpath='{.status.sync.status}' 2>/dev/null || true)"
health="$(kubectl -n argocd get application monitoring -o jsonpath='{.status.health.status}' 2>/dev/null || true)"
[[ "${sync}" == "Synced" ]] || smoke_fail "Application monitoring sync=${sync:-missing} (want Synced)"
[[ "${health}" == "Healthy" ]] || smoke_fail "Application monitoring health=${health:-missing} (want Healthy)"
smoke_ok "Application monitoring Synced/Healthy"

kubectl -n monitoring get prometheusrule marshal-http >/dev/null \
  || smoke_fail "PrometheusRule marshal-http not live (ARCH-8 regression)"
kubectl -n monitoring get probe clubhouse >/dev/null \
  || smoke_fail "Probe clubhouse not live"
kubectl -n monitoring get servicemonitor cilium-envoy argo-rollouts >/dev/null \
  || smoke_fail "edge/rollouts ServiceMonitors not live"
kubectl -n monitoring get configmap kaddy-marshal-dashboard >/dev/null \
  || smoke_fail "kaddy-marshal-dashboard ConfigMap not live"
smoke_ok "REQ-E5-S09-01 — kaddy-authored monitoring content is live via GitOps"

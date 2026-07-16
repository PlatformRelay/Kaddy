#!/usr/bin/env bash
# REQ-E5-S01-02 (re-pointed): the platform scrape plane covers the REAL edge —
# Cilium Envoy (edge listeners) and the Argo Rollouts controller are both
# scraped (up == 1). The original clubhouse /metrics leg is N/A: clubhouse is
# nginx-unprivileged serving static content and exposes no /metrics (spec note).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
# shellcheck disable=SC1091
source "${DIR}/e5-lib.sh"
e5_prom_up

v="$(e5_prom_query 'min(up{job="cilium-envoy"})')"
[[ "${v}" == "1" ]] || smoke_fail "cilium-envoy edge metrics not scraped (up=${v:-none})"
smoke_ok "cilium-envoy edge scraped (up==1)"

v="$(e5_prom_query 'min(up{job="argo-rollouts-metrics"})')"
[[ "${v}" == "1" ]] || smoke_fail "argo-rollouts metrics not scraped (up=${v:-none})"
smoke_ok "argo-rollouts scraped (up==1)"

smoke_ok "REQ-E5-S01-02 — edge + rollouts scrape targets live"

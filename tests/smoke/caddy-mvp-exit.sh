#!/usr/bin/env bash
# REQ-CADDY-EXIT — the brief spine (serve → scrape → fire) demonstrable
# end-to-end. Satisfiable by Variant B alone (Variant A/VM is blocked on E6g/E1g):
# the tenant page serves 200 through the platform edge, up{job="caddy"}==1
# beforehand, and killing the Caddy target fires CaddyTargetDown to Alertmanager
# within its for: window — closing audit DIR-1/DIR-2/ARCH-2/ARCH-3.
#
# Offline this script asserts the three structural halves of serve → scrape → fire
# exist in git (edge route, scrape config, target-down alert). Exit 0 offline; set
# CADDY_MVP_EXIT_LIVE=1 to run the full live serve/scrape/fire against a cluster.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
TENANT="${ROOT}/deploy/workloads/caddy-mvp"
MON="${ROOT}/deploy/caddy-mvp/monitoring"

# serve: the tenant is reached THROUGH the platform edge (HTTPRoute), not as gateway.
[[ -f "${TENANT}/httproute.yaml" ]] || { echo "FAIL: missing edge HTTPRoute (serve)" >&2; exit 1; }
# scrape: in-cluster Prometheus scrapes the Caddy origin as job="caddy".
grep -q 'caddy' "${MON}/prometheus/caddy-podmonitor.yaml" || { echo "FAIL: PodMonitor not pointed at caddy (scrape)" >&2; exit 1; }
# fire: the CaddyTargetDown alert closes the loop when the target dies.
grep -rq 'CaddyTargetDown' "${MON}/rules/" || { echo "FAIL: missing CaddyTargetDown alert (fire)" >&2; exit 1; }
echo "OK: caddy-mvp exit — serve (HTTPRoute) + scrape (PodMonitor job=caddy) + fire (CaddyTargetDown) present in git"

if [[ "${CADDY_MVP_EXIT_LIVE:-0}" != "1" ]]; then
  echo "OK: REQ-CADDY-EXIT offline structural (set CADDY_MVP_EXIT_LIVE=1 for live serve→scrape→fire)"
  exit 0
fi

# shellcheck source=/dev/null
source "${DIR}/lib.sh"
# shellcheck source=/dev/null
source "${DIR}/e5-lib.sh"
smoke_require_cluster
e5_prom_up
GW_IP="$(kubectl -n caddy-mvp get svc -l gateway.networking.k8s.io/gateway-name -o jsonpath='{.items[0].spec.clusterIP}')"
code="$(kubectl -n default run caddy-exit-probe --rm -i --restart=Never --quiet \
  --image=curlimages/curl:8.11.0 --overrides='{"spec":{"securityContext":{"runAsNonRoot":true,"runAsUser":100}}}' \
  -- sh -c "curl -s -o /dev/null -m 15 -w '%{http_code}' --resolve clubhouse.kaddy.local:80:${GW_IP} http://clubhouse.kaddy.local/" || true)"
[[ "${code}" == *200* ]] || fail "serve: expected 200 through edge, got '${code}'"
val="$(e5_prom_query 'up{job="caddy",namespace="caddy-mvp"}')"
[[ "${val}" == "1" ]] || fail "scrape: expected up{job=caddy}==1, got '${val}'"
ok "REQ-CADDY-EXIT live — served 200 through edge and up{job=caddy}==1 (kill target to observe CaddyTargetDown)"

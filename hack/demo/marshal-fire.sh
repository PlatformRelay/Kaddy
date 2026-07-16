#!/usr/bin/env bash
# marshal-fire.sh — REQ-E5-S03-05 / DIR-2: prove the serve→scrape→FIRE leg live.
#
# Choreography (idempotent; restores the site even on failure):
#   1. Baseline  — clubhouse healthy, probe_success == 1, ClubhouseDown inactive.
#   2. Break     — scale deploy/clubhouse to 0 (controlled outage behind the
#                  real Cilium Gateway edge; the blackbox probe starts failing).
#   3. Fire      — watch Prometheus take ClubhouseDown pending → firing, then
#                  assert it ACTIVE in the Alertmanager v2 API.
#   4. Restore   — scale back, wait for probe_success == 1 and the alert to
#                  leave Alertmanager (resolved).
#
# TIMING: probe interval 15s + rule eval ~30s + `for: 1m` + Alertmanager
# group_wait ⇒ firing typically lands in 2–3 minutes; the low `for:` on
# ClubhouseDown is a documented demo trade-off (deploy/monitoring/rules/README.md).
#
# Exit code is the verdict — this script doubles as the L3 live smoke for the
# fire leg (wrapped by tests/smoke/e5-s03-05.sh, `task demo:fire`).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/../../tests/smoke/lib.sh"
smoke_require_cluster

NS_APP="gateway"
NS_MON="monitoring"
ALERT="ClubhouseDown"
PROM_PORT="${PROM_PORT:-19090}"
AM_PORT="${AM_PORT:-19093}"
FIRE_TIMEOUT="${FIRE_TIMEOUT:-360}"     # seconds to reach firing
RESOLVE_TIMEOUT="${RESOLVE_TIMEOUT:-420}" # seconds to resolve after restore

PF_PIDS=()
cleanup() {
  # Always restore the site, then tear down port-forwards.
  kubectl -n "${NS_APP}" scale deploy/clubhouse --replicas=1 >/dev/null 2>&1 || true
  for pid in "${PF_PIDS[@]:-}"; do kill "${pid}" >/dev/null 2>&1 || true; done
}
trap cleanup EXIT

log() { printf '[%s] %s\n' "$(date -u +%H:%M:%SZ)" "$*"; }

# --- port-forwards ----------------------------------------------------------
kubectl -n "${NS_MON}" port-forward svc/kps-prometheus "${PROM_PORT}:9090" >/dev/null 2>&1 &
PF_PIDS+=($!)
kubectl -n "${NS_MON}" port-forward svc/kps-alertmanager "${AM_PORT}:9093" >/dev/null 2>&1 &
PF_PIDS+=($!)
sleep 3

prom_query() { # $1 = promql; prints first value or empty
  curl -sf --get "http://127.0.0.1:${PROM_PORT}/api/v1/query" --data-urlencode "query=$1" \
    | yq -p json '.data.result[0].value[1] // ""' 2>/dev/null || true
}

alert_state() { # ClubhouseDown state in Prometheus: inactive|pending|firing
  curl -sf "http://127.0.0.1:${PROM_PORT}/api/v1/rules?type=alert" \
    | yq -p json ".data.groups[].rules[] | select(.name == \"${ALERT}\") | .state" 2>/dev/null \
    | head -1 || true
}

am_active() { # 0 (true) when the alert is ACTIVE in Alertmanager
  local n
  n="$(curl -sf "http://127.0.0.1:${AM_PORT}/api/v2/alerts?filter=alertname%3D%22${ALERT}%22&active=true&silenced=false&inhibited=false" \
    | yq -p json 'length' 2>/dev/null || echo 0)"
  [[ "${n}" =~ ^[1-9] ]]
}

wait_for() { # $1 = timeout s, $2 = description, $3 = command (eval'd)
  local deadline=$(( $(date +%s) + $1 ))
  while true; do
    if eval "$3"; then log "OK: $2"; return 0; fi
    if (( $(date +%s) >= deadline )); then smoke_fail "timeout waiting for: $2"; fi
    sleep 5
  done
}

# --- 1. baseline -------------------------------------------------------------
log "=== 1/4 baseline — clubhouse healthy, probe green, ${ALERT} inactive ==="
kubectl -n "${NS_APP}" scale deploy/clubhouse --replicas=1 >/dev/null
kubectl -n "${NS_APP}" rollout status deploy/clubhouse --timeout=120s >/dev/null
wait_for 180 "probe_success == 1 (site healthy through the Gateway)" \
  '[[ "$(prom_query "min(probe_success{job=\"blackbox\",service=\"clubhouse\"})")" == "1" ]]'
wait_for 240 "${ALERT} inactive in Prometheus" '[[ "$(alert_state)" == "inactive" ]]'
! am_active || smoke_fail "${ALERT} unexpectedly already active in Alertmanager"
log "baseline good"

# --- 2. break ----------------------------------------------------------------
log "=== 2/4 break — scaling clubhouse to 0 (controlled outage) ==="
T_BREAK="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
kubectl -n "${NS_APP}" scale deploy/clubhouse --replicas=0 >/dev/null
wait_for 120 "probe_success == 0 (blackbox sees the outage)" \
  '[[ "$(prom_query "min(probe_success{job=\"blackbox\",service=\"clubhouse\"})")" == "0" ]]'

# --- 3. fire -----------------------------------------------------------------
log "=== 3/4 fire — waiting for ${ALERT} pending -> firing -> Alertmanager ==="
wait_for "${FIRE_TIMEOUT}" "${ALERT} state=firing in Prometheus" '[[ "$(alert_state)" == "firing" ]]'
T_FIRING="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
wait_for 120 "${ALERT} ACTIVE in the Alertmanager v2 API" 'am_active'
T_AM="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
log "FIRE PROVEN: broke at ${T_BREAK} -> firing at ${T_FIRING} -> Alertmanager active at ${T_AM}"
curl -sf "http://127.0.0.1:${AM_PORT}/api/v2/alerts?filter=alertname%3D%22${ALERT}%22&active=true" \
  | yq -p json '.[0] | {"alertname": .labels.alertname, "severity": .labels.severity, "service": .labels.service, "state": .status.state, "startsAt": .startsAt}' \
  || true

# --- 4. restore --------------------------------------------------------------
log "=== 4/4 restore — scaling clubhouse back, waiting for resolve ==="
kubectl -n "${NS_APP}" scale deploy/clubhouse --replicas=1 >/dev/null
kubectl -n "${NS_APP}" rollout status deploy/clubhouse --timeout=120s >/dev/null
wait_for 180 "probe_success == 1 (site restored)" \
  '[[ "$(prom_query "min(probe_success{job=\"blackbox\",service=\"clubhouse\"})")" == "1" ]]'
wait_for "${RESOLVE_TIMEOUT}" "${ALERT} inactive in Prometheus (resolved)" '[[ "$(alert_state)" == "inactive" ]]'
wait_for 300 "${ALERT} no longer active in Alertmanager" '! am_active'
T_RESOLVED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

log "=== marshal fire demo COMPLETE ==="
log "timeline: break=${T_BREAK} firing=${T_FIRING} alertmanager=${T_AM} resolved=${T_RESOLVED}"
smoke_ok "REQ-E5-S03-05 / DIR-2 — ${ALERT} fired end-to-end and resolved"

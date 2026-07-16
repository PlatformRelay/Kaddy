#!/usr/bin/env bash
# REQ-E6-S05-01 — the claimed site is MONITORED: the composed ServiceMonitor
# target is scraped by Prometheus (up == 1 for the putting-green service in ns
# websites) and the caddy_* metrics surface is present.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/smoke/lib.sh
source "${DIR}/lib.sh"
smoke_require_cluster
# shellcheck source=tests/smoke/e5-lib.sh
source "${DIR}/e5-lib.sh"
e5_prom_up

# Target discovery + scrape can lag a fresh claim by one SD refresh; retry.
v=""
for _ in $(seq 1 20); do
  v="$(e5_prom_query 'max(up{namespace="websites", job="putting-green"})')"
  [[ "${v}" == "1" ]] && break
  sleep 6
done
[[ "${v}" == "1" ]] || smoke_fail "putting-green scrape target not up in Prometheus (up=${v:-none})"
smoke_ok "putting-green scrape target up==1"

# The showcase Caddyfile serves /metrics; per-request caddy_http_* series
# additionally need Caddy's global `servers { metrics }` option — an image
# follow-up (e-caddy-mvp), not a platform concern. Assert the exporter lives.
m="$(e5_prom_query 'max(caddy_config_last_reload_successful{namespace="websites"})')"
[[ "${m}" == "1" ]] || smoke_fail "caddy_* metrics missing for the claimed site (got '${m:-none}')"
smoke_ok "caddy_* metrics flowing from the claimed site"

smoke_ok "REQ-E6-S05-01 one claim = one MONITORED site (Prometheus scrapes the composed ServiceMonitor)"

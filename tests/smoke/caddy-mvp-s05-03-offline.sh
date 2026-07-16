#!/usr/bin/env bash
# REQ-CADDY-S05-03 — offline structural gate for Gateway → nginx → Caddy topology.
#
# Dual-attachment design (preserves S02 canary AnalysisTemplate story):
#   - HTTPRoute `caddy-mvp`          → caddy-origin-stable/canary (canary weights)
#   - HTTPRoute `caddy-mvp-showcase` → nginx-proxy-active (showcase hop)
# nginx ConfigMap proxy_pass closes the hop to the Caddy origin Service.
#
# No cluster required. Live Chainsaw:
#   tests/chainsaw/caddy-mvp/showcase/proxy-topology/ (skip until live).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
TENANT="${ROOT}/deploy/workloads/caddy-mvp"
ROUTE="${TENANT}/httproute.yaml"
NGINX_CM="${TENANT}/configmap-nginx.yaml"
SERVICES="${TENANT}/services.yaml"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

need_file() { [[ -f "$1" ]] || fail "missing $1"; }

need_file "${ROUTE}"
need_file "${NGINX_CM}"
need_file "${SERVICES}"

# --- 1) Showcase HTTPRoute attaches to tenant Gateway (HTTPS) ---------------
grep -qE '^[[:space:]]*name:[[:space:]]*caddy-mvp-showcase[[:space:]]*$' "${ROUTE}" \
  || fail "httproute.yaml must define HTTPRoute caddy-mvp-showcase (S05-03 edge hop)"
# parentRef Gateway name (not the HTTPRoute metadata name alone)
awk '
  /^kind:[[:space:]]*HTTPRoute/ { in_route=1; name=""; showcase=0; next }
  in_route && /^metadata:/ { in_meta=1 }
  in_route && in_meta && /^[[:space:]]*name:[[:space:]]*caddy-mvp-showcase[[:space:]]*$/ { showcase=1 }
  in_route && /^spec:/ { in_meta=0 }
  showcase && /parentRefs:/ { want_gw=1 }
  want_gw && /^[[:space:]]*- name:[[:space:]]*caddy-mvp[[:space:]]*$/ { found_parent=1 }
  want_gw && /kind:[[:space:]]*Gateway/ { found_gw_kind=1 }
  want_gw && /sectionName:[[:space:]]*https/ { found_https=1 }
  /^---/ { if (showcase && !(found_parent && found_gw_kind && found_https)) exit 2;
            in_route=0; showcase=0; want_gw=0; found_parent=0; found_gw_kind=0; found_https=0 }
  END { if (!(found_parent && found_gw_kind && found_https)) exit 2 }
' "${ROUTE}" || fail "caddy-mvp-showcase must parentRef Gateway caddy-mvp sectionName https"
ok "caddy-mvp-showcase parentRef → Gateway caddy-mvp (https)"

# --- 2) Showcase route backends nginx-proxy-active (not origin directly) ----
awk '
  /^kind:[[:space:]]*HTTPRoute/ { in_route=1; showcase=0; in_backends=0; next }
  in_route && /^metadata:/ { in_meta=1 }
  in_route && in_meta && /^[[:space:]]*name:[[:space:]]*caddy-mvp-showcase[[:space:]]*$/ { showcase=1 }
  in_route && /^spec:/ { in_meta=0 }
  showcase && /backendRefs:/ { in_backends=1 }
  showcase && in_backends && /^[[:space:]]*- name:[[:space:]]*nginx-proxy-active[[:space:]]*$/ { hit=1 }
  showcase && in_backends && /caddy-origin-/ { bad=1 }
  /^---/ { if (showcase && !hit) exit 2; if (bad) exit 3;
            in_route=0; showcase=0; in_backends=0; hit=0; bad=0 }
  END { if (!hit) exit 2; if (bad) exit 3 }
' "${ROUTE}" || {
  rc=$?
  [[ $rc -eq 3 ]] && fail "caddy-mvp-showcase must not backendRef caddy-origin-* (nginx owns that hop)"
  fail "caddy-mvp-showcase must backendRef nginx-proxy-active"
}
grep -qE '^[[:space:]]*name:[[:space:]]*nginx-proxy-active[[:space:]]*$' "${SERVICES}" \
  || fail "services.yaml missing Service nginx-proxy-active"
ok "caddy-mvp-showcase backendRef → nginx-proxy-active"

# --- 3) S02 canary route still attached to origin weight pair ---------------
grep -qE '^[[:space:]]*name:[[:space:]]*caddy-mvp[[:space:]]*$' "${ROUTE}" \
  || fail "canary HTTPRoute caddy-mvp must remain (S02 AnalysisTemplate story)"
grep -q 'caddy-origin-stable' "${ROUTE}" \
  || fail "HTTPRoute must still backendRef caddy-origin-stable (S02 canary)"
grep -q 'caddy-origin-canary' "${ROUTE}" \
  || fail "HTTPRoute must still backendRef caddy-origin-canary (S02 canary)"
ok "S02 canary HTTPRoute caddy-mvp retains origin-stable/canary backends"

# --- 4) nginx proxy_pass closes the hop to Caddy origin ---------------------
grep -qiE 'proxy_pass' "${NGINX_CM}" \
  || fail "nginx ConfigMap must proxy_pass to caddy-origin"
grep -qE 'proxy_pass[[:space:]]+http://caddy-origin' "${NGINX_CM}" \
  || fail "nginx proxy_pass must target caddy-origin* Service"
ok "nginx ConfigMap proxy_pass → caddy-origin (closes Gateway→nginx→Caddy)"

echo "OK: REQ-CADDY-S05-03 offline topology gate green"

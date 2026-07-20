#!/usr/bin/env bash
# REQ-E10 / E1g-S05e follow-up — OFFLINE gate: Backstage portal is reachable on
# the GSK Traefik cloud-edge the same way as argocd/grafana/demo/caddy.
#
# Asserts (no cluster, no API):
#   1. clubhouse Gateway carries an https-portal HTTPS listener for
#      portal.lab.platformrelay.dev (port 8443, Traefik websecure).
#   2. A DNS-01 prod Certificate issues portal-tls in ns traefik for that host.
#   3. An HTTPRoute in ns portal attaches by sectionName https-portal and
#      backends the existing Service backstage:7007.
#   4. README + edge-up.sh document the fifth demo host (portal.lab).
#
# Kind stays on portal.kaddy.local (deploy/portal/backstage/certificate.yaml);
# this cloud-only overlay is excluded-by-location (recurse:false) and applied
# only via hack/gsk/edge-up.sh.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"

CLOUD="${ROOT}/deploy/gateway/cloud-only"
GW="${CLOUD}/gateway-clubhouse.yaml"
CERTS="${CLOUD}/certificates.yaml"
ROUTES="${CLOUD}/httproutes.yaml"
README="${CLOUD}/README.md"
EDGE_UP="${ROOT}/hack/gsk/edge-up.sh"

HOST="portal.lab.platformrelay.dev"
LISTENER="https-portal"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }
need_file() { [[ -f "$1" ]] || fail "missing $1"; }

need_file "${GW}"
need_file "${CERTS}"
need_file "${ROUTES}"
need_file "${README}"
need_file "${EDGE_UP}"

# --- 1) Gateway listener ----------------------------------------------------
grep -qE "name:[[:space:]]*${LISTENER}" "${GW}" \
  || fail "clubhouse Gateway missing listener ${LISTENER}"
grep -qF "hostname: ${HOST}" "${GW}" \
  || fail "clubhouse Gateway missing hostname ${HOST}"
# Listener cert Secret lives in the Gateway ns (traefik), same pattern as caddy-tls.
grep -qE 'name:[[:space:]]*portal-tls' "${GW}" \
  || fail "https-portal listener must certificateRef Secret portal-tls"
ok "Gateway listener ${LISTENER} → ${HOST} (portal-tls)"

# --- 2) LE Certificate in ns traefik ----------------------------------------
grep -qE 'name:[[:space:]]*portal-tls' "${CERTS}" \
  || fail "certificates.yaml missing Certificate portal-tls"
grep -qF "${HOST}" "${CERTS}" \
  || fail "portal-tls Certificate must list dnsName ${HOST}"
grep -qE 'letsencrypt-prod-dns01' "${CERTS}" \
  || fail "portal-tls must issue from letsencrypt-prod-dns01 (DNS-01 prod)"
# Certificate must land in traefik (Gateway ns), NOT portal (kind local-CA lives there).
awk '
  /^kind:[[:space:]]*Certificate$/ { in_cert=1; name=""; ns=""; next }
  in_cert && /^[[:space:]]*name:[[:space:]]*portal-tls[[:space:]]*$/ { name=$2 }
  in_cert && /^[[:space:]]*namespace:[[:space:]]*/ { ns=$2 }
  in_cert && /^---$/ {
    if (name=="portal-tls" && ns!="traefik") exit 2
    in_cert=0; name=""; ns=""
  }
  END {
    if (name=="portal-tls" && ns!="" && ns!="traefik") exit 2
  }
' "${CERTS}" || fail "portal-tls Certificate must be namespace: traefik (Gateway listener Secret resolve)"
ok "Certificate portal-tls (ns traefik) for ${HOST} via DNS-01 prod"

# --- 3) HTTPRoute in ns portal → Service backstage:7007 ---------------------
grep -qF "${HOST}" "${ROUTES}" \
  || fail "httproutes.yaml missing hostname ${HOST}"
grep -qE "sectionName:[[:space:]]*${LISTENER}" "${ROUTES}" \
  || fail "portal HTTPRoute must parentRefs sectionName ${LISTENER}"
# Backend must be the live GSK Service (name backstage, port 7007) in ns portal.
awk '
  /^kind:[[:space:]]*HTTPRoute$/ { in_r=1; host_ok=0; ns=""; svc=""; port=""; next }
  in_r && /^[[:space:]]*namespace:[[:space:]]*/ && ns=="" { ns=$2 }
  in_r && /portal\.lab\.platformrelay\.dev/ { host_ok=1 }
  in_r && /^[[:space:]]*name:[[:space:]]*backstage[[:space:]]*$/ { svc="backstage" }
  in_r && /^[[:space:]]*port:[[:space:]]*7007[[:space:]]*$/ { port="7007" }
  in_r && /^---$/ {
    if (host_ok) {
      if (ns!="portal") exit 2
      if (svc!="backstage" || port!="7007") exit 3
    }
    in_r=0; host_ok=0; ns=""; svc=""; port=""
  }
  END {
    if (host_ok) {
      if (ns!="portal") exit 2
      if (svc!="backstage" || port!="7007") exit 3
    }
  }
' "${ROUTES}"
case $? in
  2) fail "portal HTTPRoute must live in namespace: portal" ;;
  3) fail "portal HTTPRoute backendRefs must be Service backstage:7007" ;;
esac
grep -qF "${HOST}" "${ROUTES}" || fail "unreachable" # already checked; keeps set -e happy path clear
ok "HTTPRoute (ns portal) ${HOST} → Service backstage:7007 via ${LISTENER}"

# --- 4) Docs / apply path mention the fifth host ----------------------------
grep -qF "portal.lab" "${README}" \
  || fail "cloud-only README must document portal.lab as a demo host"
grep -qF "portal.lab" "${EDGE_UP}" \
  || fail "edge-up.sh must mention portal.lab in the Cloudflare A-record hint"
ok "README + edge-up.sh document portal.lab"

echo "PASS: e1g portal cloud-route offline gate green"

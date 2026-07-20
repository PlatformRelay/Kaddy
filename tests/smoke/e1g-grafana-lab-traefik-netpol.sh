#!/usr/bin/env bash
# E1g — OFFLINE gate: monitoring NetPol must admit GSK Traefik → Grafana :3000.
#
# grafana.lab.platformrelay.dev parents clubhouse/https-grafana → Service
# monitoring-grafana. After policies default-deny-ingress lands in ns monitoring,
# missing Traefik peer allows yield Traefik "no available server" / timeouts even
# when the HTTPRoute is Accepted and the Deployment is Ready (same class of bug
# as portal/caddy Traefik NetPol gaps).
#
# Asserts (no cluster, no API):
#   1. deploy/policies/network/monitoring.yaml defines allow-traefik-to-grafana
#      (K8s NetworkPolicy + CiliumNetworkPolicy).
#   2. NetPol peers namespace traefik and port 3000.
#   3. CNP fromEndpoints selects traefik ns and port 3000.
#   4. Cloud HTTPRoute still targets monitoring-grafana :80 / grafana.lab host.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"

NETPOL="${ROOT}/deploy/policies/network/monitoring.yaml"
ROUTES="${ROOT}/deploy/gateway/cloud-only/httproutes.yaml"
HOST="grafana.lab.platformrelay.dev"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }
need_file() { [[ -f "$1" ]] || fail "missing $1"; }

need_file "${NETPOL}"
need_file "${ROUTES}"

grep -qE 'name:[[:space:]]*allow-traefik-to-grafana' "${NETPOL}" \
  || fail "monitoring.yaml must define allow-traefik-to-grafana (GSK Traefik → Grafana :3000)"

# K8s NetworkPolicy: peer ns traefik + port 3000
awk '
  /^kind:[[:space:]]*NetworkPolicy$/ { in_np=1; name=""; next }
  in_np && /^[[:space:]]*name:[[:space:]]*/ && name=="" { name=$2 }
  in_np && name=="allow-traefik-to-grafana" && /kubernetes\.io\/metadata\.name:[[:space:]]*traefik/ { peer=1 }
  in_np && name=="allow-traefik-to-grafana" && /port:[[:space:]]*3000/ { port=1 }
  in_np && /^---$/ {
    if (name=="allow-traefik-to-grafana") { found=1; if (!peer||!port) exit 2 }
    in_np=0; name=""; peer=0; port=0
  }
  END {
    if (name=="allow-traefik-to-grafana") { found=1; if (!peer||!port) exit 2 }
    if (!found) exit 3
  }
' "${NETPOL}" || {
  rc=$?
  case ${rc} in
    2) fail "allow-traefik-to-grafana NetworkPolicy must peer traefik ns and port 3000" ;;
    3) fail "allow-traefik-to-grafana NetworkPolicy block not found" ;;
    *) fail "NetworkPolicy parse failed (rc=${rc})" ;;
  esac
}
ok "NetworkPolicy allow-traefik-to-grafana peers traefik :3000"

# CiliumNetworkPolicy: fromEndpoints traefik + port 3000
awk '
  /^kind:[[:space:]]*CiliumNetworkPolicy$/ { in_c=1; name=""; next }
  in_c && /^[[:space:]]*name:[[:space:]]*/ && name=="" { name=$2 }
  in_c && name=="allow-traefik-to-grafana" && /k8s:io\.kubernetes\.pod\.namespace:[[:space:]]*traefik/ { peer=1 }
  in_c && name=="allow-traefik-to-grafana" && /port:[[:space:]]*"?3000"?/ { port=1 }
  in_c && /^---$/ {
    if (name=="allow-traefik-to-grafana") { found=1; if (!peer||!port) exit 2 }
    in_c=0; name=""; peer=0; port=0
  }
  END {
    if (name=="allow-traefik-to-grafana") { found=1; if (!peer||!port) exit 2 }
    if (!found) exit 3
  }
' "${NETPOL}" || {
  rc=$?
  case ${rc} in
    2) fail "allow-traefik-to-grafana CNP must fromEndpoints traefik and port 3000" ;;
    3) fail "allow-traefik-to-grafana CiliumNetworkPolicy block not found" ;;
    *) fail "CNP parse failed (rc=${rc})" ;;
  esac
}
ok "CiliumNetworkPolicy allow-traefik-to-grafana fromEndpoints traefik :3000"

grep -q "${HOST}" "${ROUTES}" \
  || fail "httproutes.yaml missing hostname ${HOST}"
grep -qE 'name:[[:space:]]*monitoring-grafana' "${ROUTES}" \
  || fail "grafana HTTPRoute must backendRef monitoring-grafana"
ok "cloud HTTPRoute ${HOST} → monitoring-grafana"

ok "e1g-grafana-lab-traefik-netpol offline gate"

#!/usr/bin/env bash
# E1g-S05i — OFFLINE gate: caddy.lab cloud HTTPRoute must NOT share name/ns with
# the kind tenant route (deploy/workloads/caddy-mvp/httproute.yaml → caddy-mvp).
#
# ignoreDifferences on parentRefs/hostnames proved insufficient on GSK Argo
# (workloads reclobbered the clubhouse route within ~15s). Durable fix: distinct
# resource name `caddy-lab` in ns caddy-mvp, parented by clubhouse/https-caddy.
#
# Asserts (no cluster, no API):
#   1. Cloud HTTPRoute is named caddy-lab (not caddy-mvp) in ns caddy-mvp.
#   2. It parents clubhouse / https-caddy and hosts caddy.lab.platformrelay.dev.
#   3. BackendRefs target caddy-origin-stable / caddy-origin-canary :8080
#      (no Service named caddy-mvp exists in the tenant).
#   4. Kind tenant HTTPRoute remains name caddy-mvp (local Gateway).
#   5. README + edge-up.sh document the rename / no-collision rule.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"

CLOUD="${ROOT}/deploy/gateway/cloud-only"
ROUTES="${CLOUD}/httproutes.yaml"
README="${CLOUD}/README.md"
EDGE_UP="${ROOT}/hack/gsk/edge-up.sh"
KIND_ROUTE="${ROOT}/deploy/workloads/caddy-mvp/httproute.yaml"

HOST="caddy.lab.platformrelay.dev"
LISTENER="https-caddy"
CLOUD_NAME="caddy-lab"
KIND_NAME="caddy-mvp"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }
need_file() { [[ -f "$1" ]] || fail "missing $1"; }

need_file "${ROUTES}"
need_file "${README}"
need_file "${EDGE_UP}"
need_file "${KIND_ROUTE}"

# --- 1) Cloud route name is caddy-lab (collision avoidance) -----------------
# Extract the HTTPRoute whose hostname is caddy.lab — must be named caddy-lab.
set +e
awk -v want_host="${HOST}" -v want_name="${CLOUD_NAME}" '
  /^kind:[[:space:]]*HTTPRoute$/ { in_r=1; name=""; ns=""; host_ok=0; next }
  in_r && /^[[:space:]]*name:[[:space:]]*/ && name=="" { name=$2 }
  in_r && /^[[:space:]]*namespace:[[:space:]]*/ && ns=="" { ns=$2 }
  in_r && index($0, want_host) { host_ok=1 }
  in_r && /^---$/ {
    if (host_ok) {
      if (name != want_name) exit 2
      if (ns != "caddy-mvp") exit 3
      found=1
    }
    in_r=0; name=""; ns=""; host_ok=0
  }
  END {
    if (host_ok) {
      if (name != want_name) exit 2
      if (ns != "caddy-mvp") exit 3
      found=1
    }
    if (!found) exit 4
  }
' "${ROUTES}"
rc=$?
set -e
case ${rc} in
  0) ;;
  2) fail "caddy.lab HTTPRoute must be named ${CLOUD_NAME} (not ${KIND_NAME}) to avoid Argo name collision" ;;
  3) fail "caddy.lab HTTPRoute must live in namespace: caddy-mvp" ;;
  4) fail "httproutes.yaml missing hostname ${HOST}" ;;
  *) fail "caddy.lab HTTPRoute name check failed (rc=${rc})" ;;
esac
# Explicit: no cloud-only document may still declare name: caddy-mvp for this host.
set +e
awk '
  /^kind:[[:space:]]*HTTPRoute$/ { in_r=1; name=""; host_ok=0; next }
  in_r && /^[[:space:]]*name:[[:space:]]*/ && name=="" { name=$2 }
  in_r && /caddy\.lab\.platformrelay\.dev/ { host_ok=1 }
  in_r && /^---$/ {
    if (host_ok && name=="caddy-mvp") exit 2
    in_r=0; name=""; host_ok=0
  }
  END { if (host_ok && name=="caddy-mvp") exit 2 }
' "${ROUTES}"
rc=$?
set -e
[ "${rc}" -eq 0 ] || fail "cloud httproutes must not use name caddy-mvp for ${HOST}"
ok "Cloud HTTPRoute ${CLOUD_NAME} (ns caddy-mvp) owns ${HOST}"

# --- 2) Parent + listener ---------------------------------------------------
grep -qE "sectionName:[[:space:]]*${LISTENER}" "${ROUTES}" \
  || fail "caddy-lab HTTPRoute must parentRefs sectionName ${LISTENER}"
# Ensure the caddy-lab block parents clubhouse (not the kind Gateway name).
set +e
awk -v want_name="${CLOUD_NAME}" '
  /^kind:[[:space:]]*HTTPRoute$/ { in_r=1; name=""; parent=""; next }
  in_r && /^[[:space:]]*name:[[:space:]]*/ && name=="" { name=$2 }
  in_r && name==want_name && /^[[:space:]]*- name:[[:space:]]*clubhouse[[:space:]]*$/ { parent="clubhouse" }
  in_r && /^---$/ {
    if (name==want_name && parent!="clubhouse") exit 2
    in_r=0; name=""; parent=""
  }
  END { if (name==want_name && parent!="clubhouse") exit 2 }
' "${ROUTES}"
rc=$?
set -e
[ "${rc}" -eq 0 ] || fail "HTTPRoute ${CLOUD_NAME} must parentRefs Gateway clubhouse"
ok "HTTPRoute ${CLOUD_NAME} → clubhouse / ${LISTENER} / ${HOST}"

# --- 3) BackendRefs: origin stable/canary (no Service caddy-mvp) ------------
set +e
awk -v want_name="${CLOUD_NAME}" '
  /^kind:[[:space:]]*HTTPRoute$/ { in_r=1; name=""; stable=0; canary=0; next }
  in_r && /^[[:space:]]*name:[[:space:]]*/ && name=="" { name=$2 }
  in_r && name==want_name && /name:[[:space:]]*caddy-origin-stable/ { stable=1 }
  in_r && name==want_name && /name:[[:space:]]*caddy-origin-canary/ { canary=1 }
  in_r && /^---$/ {
    if (name==want_name && !(stable && canary)) exit 2
    in_r=0; name=""; stable=0; canary=0
  }
  END { if (name==want_name && !(stable && canary)) exit 2 }
' "${ROUTES}"
rc=$?
set -e
[ "${rc}" -eq 0 ] || fail "HTTPRoute ${CLOUD_NAME} must backendRef caddy-origin-stable + caddy-origin-canary (no Service named caddy-mvp)"
ok "BackendRefs caddy-origin-stable/canary :8080 (Rollouts canary weights)"
# --- 4) Kind tenant route keeps name caddy-mvp ------------------------------
grep -qE '^[[:space:]]*name:[[:space:]]*caddy-mvp[[:space:]]*$' "${KIND_ROUTE}" \
  || fail "kind tenant HTTPRoute must remain named ${KIND_NAME}"
grep -qF 'caddy-mvp.kaddy.local' "${KIND_ROUTE}" \
  || fail "kind tenant HTTPRoute must host caddy-mvp.kaddy.local"
ok "Kind HTTPRoute ${KIND_NAME} unchanged (local Gateway)"

# --- 5) Docs / apply path ---------------------------------------------------
grep -qiE 'caddy-lab' "${README}" \
  || fail "cloud-only README must document HTTPRoute name caddy-lab"
grep -qiE 'caddy-lab|collision|must not share' "${EDGE_UP}" \
  || fail "edge-up.sh must mention caddy-lab / no name collision with kind"
ok "README + edge-up.sh document caddy-lab rename"

echo "PASS: e1g caddy-lab cloud-route offline gate green"

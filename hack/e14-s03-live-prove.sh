#!/usr/bin/env bash
# ==============================================================================
# e14-s03-live-prove.sh — LIVE gridscale deploy -> prove -> teardown for E14-S03
# ==============================================================================
#
# WHAT THIS DOES (one ephemeral cycle, ruthless teardown):
#   1. Create a public IPv4 (de/fra2).
#   2. Create a storage FROM the caddy-nix Marketplace import template
#      (template.template_uuid = the kaddy-nix *consumer import* object_uuid).
#   3. Create a 1-core / 1-GiB server.
#   4. Attach: storage (bootdevice) + Public Network NIC + the IPv4, then power on.
#   5. PROVE the VM serves: GET / == 200, GET /healthz body "ok", :2019/metrics
#      == 200 with real caddy_ series.
#   6. ALWAYS tear everything down via a trap (server -> storage -> IPv4), then
#      assert 0 orphans matching the kaddy-e14-s03 name prefix.
#
# WHY IT IS SHAPED THIS WAY:
#   - The gridscale Terraform provider has no "deploy-from-marketplace" resource.
#     The proven deploy path (E13-S05, E14-S03) is: a gridscale_storage created
#     with template.template_uuid = <the imported (consumer) marketplace app
#     object_uuid> instantiates the golden boot disk. That import UUID is the
#     `import_id` terraform output of stacks/gridscale-marketplace/nix.
#   - Networking topology that is *proven to route the public IP* = a SINGLE
#     Public Network NIC + a public IPv4. A private NIC alone does NOT route the
#     public IP (evidence/live/e13-marketplace-deploy-2026-07-19.md).
#
# COST DISCIPLINE IS PARAMOUNT: a leaked VM/storage/IP bills continuously. The
# EXIT trap tears down EVERYTHING that was created, each step guarded with
# `|| true` so one failure never aborts the rest, and every created object is
# named with a greppable `kaddy-e14-s03-<epoch>` prefix so orphans are findable.
#
# THIS SCRIPT NEEDS NO TERRAFORM STATE beyond (optionally) reading the import
# UUID. It talks to the gridscale REST API directly with curl + jq.
#
# ------------------------------------------------------------------------------
# gridscale REST API cheat-sheet (authoritative: gsclient-go vendored source +
# agent-context/reference/gridscale/api-*.md):
#   Base URL   : https://api.gridscale.io
#   Auth       : header X-Auth-UserId: <user uuid>   (case-insensitive; libcloud
#                uses X-Auth-UserId, gsclient-go uses X-Auth-Userid — same header)
#                header X-Auth-Token:  <api token>
#   Mutations  : POST/PATCH/DELETE are ASYNC -> HTTP 202 + body {object_uuid,
#                request_uuid}. Poll GET /requests/{request_uuid} until
#                .["{request_uuid}"].status == "done".
#   Object ready: a "done" request only means the request was accepted; the
#                OBJECT still provisions. Gate attach/power-on on the object's own
#                status == "active" (GET /objects/<kind>/{id} -> .<kind>.status).
#   Single GET wrappers: server -> .server, storage -> .storage, ip -> .ip.
#   Storage DELETE returns 424 (Failed Dependency) while in-provisioning or while
#                still attached to a live server -> retry until it succeeds.
# ------------------------------------------------------------------------------

set -euo pipefail

# ------------------------------------------------------------------------------
# 0. Preconditions — fail fast, no half-runs.
# ------------------------------------------------------------------------------
API="${GRIDSCALE_API_URL:-https://api.gridscale.io}"
NAME_PREFIX="kaddy-e14-s03"
RUN_TAG="${NAME_PREFIX}-$(date +%s)"   # e.g. kaddy-e14-s03-1721390000 — greppable

# Tunables (all overridable via env).
SERVER_CORES="${SERVER_CORES:-1}"
SERVER_MEMORY_GIB="${SERVER_MEMORY_GIB:-1}"
STORAGE_CAPACITY_GIB="${STORAGE_CAPACITY_GIB:-10}"
STORAGE_TYPE="${STORAGE_TYPE:-storage_high}"
SERVE_TIMEOUT_SECS="${SERVE_TIMEOUT_SECS:-90}"   # fixed image should serve in ~20s
POLL_TIMEOUT_SECS="${POLL_TIMEOUT_SECS:-300}"    # per-object active poll ceiling
POLL_INTERVAL_SECS="${POLL_INTERVAL_SECS:-5}"

fail() { echo "ERROR: $*" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || fail "curl not installed"
command -v jq   >/dev/null 2>&1 || fail "jq not installed"

: "${GRIDSCALE_USER_UUID:?Set GRIDSCALE_USER_UUID (gridscale user UUID) in env}"
: "${GRIDSCALE_API_KEY:?Set GRIDSCALE_API_KEY (gridscale API token) in env}"

# The caddy-nix consumer IMPORT object_uuid — the template the storage boots from.
# Prefer the env var; otherwise tell the operator exactly how to get it.
if [[ -z "${IMPORT_TEMPLATE_UUID:-}" ]]; then
  cat >&2 <<HOWTO
ERROR: IMPORT_TEMPLATE_UUID is unset.

  It is the caddy-nix Marketplace *consumer import* object_uuid — the template the
  boot storage is created from. Get it from the nix marketplace stack's output:

    export IMPORT_TEMPLATE_UUID="\$(terraform -chdir=stacks/gridscale-marketplace/nix output -raw import_id)"

  (The stack uses OpenTofu in this repo; 'tofu -chdir=... output -raw import_id'
   works identically. Prior live runs used 3aa9777e-... for kaddy-nix.)

  Then re-run this script.
HOWTO
  exit 1
fi

# --- auth curl wrapper ---------------------------------------------------------
# gs() runs an authenticated curl. Usage: gs <METHOD> <path> [json-body]
# Prints the response body to stdout. Auth + content-type headers are constant.
gs() {
  local method="$1" path="$2" body="${3:-}"
  if [[ -n "$body" ]]; then
    curl -fsS -X "$method" "${API}${path}" \
      -H "X-Auth-UserId: ${GRIDSCALE_USER_UUID}" \
      -H "X-Auth-Token: ${GRIDSCALE_API_KEY}" \
      -H "Content-Type: application/json" \
      -d "$body"
  else
    curl -fsS -X "$method" "${API}${path}" \
      -H "X-Auth-UserId: ${GRIDSCALE_USER_UUID}" \
      -H "X-Auth-Token: ${GRIDSCALE_API_KEY}" \
      -H "Content-Type: application/json"
  fi
}

# gs_quiet() — like gs() but never fails the script (for teardown / best-effort
# GETs). Returns curl's exit code; caller decides. Body still goes to stdout.
gs_quiet() {
  local method="$1" path="$2" body="${3:-}"
  if [[ -n "$body" ]]; then
    curl -sS -X "$method" "${API}${path}" \
      -H "X-Auth-UserId: ${GRIDSCALE_USER_UUID}" \
      -H "X-Auth-Token: ${GRIDSCALE_API_KEY}" \
      -H "Content-Type: application/json" \
      -d "$body" || true
  else
    curl -sS -X "$method" "${API}${path}" \
      -H "X-Auth-UserId: ${GRIDSCALE_USER_UUID}" \
      -H "X-Auth-Token: ${GRIDSCALE_API_KEY}" \
      -H "Content-Type: application/json" || true
  fi
}

# wait_request <request_uuid> — poll GET /requests/{uuid} until status == "done".
# This confirms the async request was *processed*, not that the object is usable.
wait_request() {
  local rid="$1" deadline status
  [[ -z "$rid" || "$rid" == "null" ]] && return 0   # some ops omit a request_uuid
  deadline=$(( $(date +%s) + POLL_TIMEOUT_SECS ))
  while :; do
    status="$(gs_quiet GET "/requests/${rid}" | jq -r --arg r "$rid" '.[$r].status // empty' 2>/dev/null || true)"
    [[ "$status" == "done" ]] && return 0
    [[ $(date +%s) -ge $deadline ]] && fail "request ${rid} not done within ${POLL_TIMEOUT_SECS}s (last status: ${status:-none})"
    sleep "$POLL_INTERVAL_SECS"
  done
}

# wait_active <kind> <id> — poll the OBJECT until its own status == "active".
# kind is the wrapper key: servers/server, storages/storage, ips/ip.
# Usage: wait_active servers "$SERVER_UUID"  (endpoint) with wrapper key derived.
wait_active() {
  local base="$1" id="$2" wrapper="$3" deadline status
  deadline=$(( $(date +%s) + POLL_TIMEOUT_SECS ))
  while :; do
    status="$(gs_quiet GET "/objects/${base}/${id}" | jq -r ".${wrapper}.status // empty" 2>/dev/null || true)"
    [[ "$status" == "active" ]] && return 0
    [[ $(date +%s) -ge $deadline ]] && fail "${base}/${id} not active within ${POLL_TIMEOUT_SECS}s (last status: ${status:-none})"
    sleep "$POLL_INTERVAL_SECS"
  done
}

# ------------------------------------------------------------------------------
# 1. Teardown trap — the cost-discipline heart of the script.
#    Order matters: server MUST be gone (or powered off) before its storage can
#    be deleted; the public NIC + IP relations go away with the server. So:
#      power off server -> delete server -> retry-delete storage -> delete IP.
#    Every step is guarded `|| true`: one failure never aborts the rest.
#    The ORIGINAL exit code is preserved so a SERVE-FAILED still exits non-zero
#    even though teardown succeeds.
# ------------------------------------------------------------------------------
IP_UUID=""
STORAGE_UUID=""
SERVER_UUID=""
SERVE_RESULT="UNKNOWN"

teardown() {
  local rc=$?
  echo ""
  echo "=== TEARDOWN (ruthless — cost discipline) ==="

  # --- server: power off then delete ---------------------------------------
  if [[ -n "$SERVER_UUID" ]]; then
    echo "-> powering off + deleting server ${SERVER_UUID}"
    # Best-effort power off (ignore 'already off' errors) so storage can detach.
    gs_quiet PATCH "/objects/servers/${SERVER_UUID}/power" '{"power":false}' >/dev/null 2>&1 || true
    # Give the power-off request a moment; deletion of a running server can 409.
    sleep 3
    gs_quiet DELETE "/objects/servers/${SERVER_UUID}" >/dev/null 2>&1 || true
  fi

  # --- storage: retry delete (424/409 while in-provisioning or still linked) --
  if [[ -n "$STORAGE_UUID" ]]; then
    echo "-> deleting storage ${STORAGE_UUID} (retrying on 424/409)"
    local sdeadline http
    sdeadline=$(( $(date +%s) + POLL_TIMEOUT_SECS ))
    while :; do
      http="$(curl -sS -o /dev/null -w '%{http_code}' -X DELETE \
        "${API}/objects/storages/${STORAGE_UUID}" \
        -H "X-Auth-UserId: ${GRIDSCALE_USER_UUID}" \
        -H "X-Auth-Token: ${GRIDSCALE_API_KEY}" 2>/dev/null || echo 000)"
      # 204 = deleted; 404 = already gone. Both are success.
      if [[ "$http" == "204" || "$http" == "404" ]]; then
        echo "   storage delete HTTP ${http}"
        break
      fi
      if [[ $(date +%s) -ge $sdeadline ]]; then
        echo "   WARNING: storage ${STORAGE_UUID} still not deleted (last HTTP ${http}) — CHECK THE PANEL" >&2
        break
      fi
      sleep "$POLL_INTERVAL_SECS"
    done
  fi

  # --- IPv4: delete last (server relation is already gone) -------------------
  if [[ -n "$IP_UUID" ]]; then
    echo "-> deleting IPv4 ${IP_UUID} (retrying on 409 while still attached)"
    local ideadline ihttp
    ideadline=$(( $(date +%s) + POLL_TIMEOUT_SECS ))
    while :; do
      ihttp="$(curl -sS -o /dev/null -w '%{http_code}' -X DELETE \
        "${API}/objects/ips/${IP_UUID}" \
        -H "X-Auth-UserId: ${GRIDSCALE_USER_UUID}" \
        -H "X-Auth-Token: ${GRIDSCALE_API_KEY}" 2>/dev/null || echo 000)"
      # 204 = deleted; 404 = already gone. Both are success.
      if [[ "$ihttp" == "204" || "$ihttp" == "404" ]]; then
        echo "   ipv4 delete HTTP ${ihttp}"
        break
      fi
      if [[ $(date +%s) -ge $ideadline ]]; then
        echo "   WARNING: IPv4 ${IP_UUID} still not deleted (last HTTP ${ihttp}) — CHECK THE PANEL" >&2
        break
      fi
      sleep "$POLL_INTERVAL_SECS"
    done
  fi

  # --- orphan check: assert nothing with our RUN_TAG prefix survives ----------
  # List each collection and count objects whose name starts with kaddy-e14-s03.
  # (We match the shared NAME_PREFIX, not just this run's epoch, to also flag
  #  leaks from any prior aborted run — belt and braces.)
  echo ""
  echo "=== ORPHAN CHECK (name prefix: ${NAME_PREFIX}) ==="
  local srv_orphans sto_orphans ip_orphans
  srv_orphans="$(gs_quiet GET /objects/servers  | jq -r --arg p "$NAME_PREFIX" '[.servers[]?  | select(.name|type=="string") | select(.name|startswith($p))] | length' 2>/dev/null || echo "?")"
  sto_orphans="$(gs_quiet GET /objects/storages | jq -r --arg p "$NAME_PREFIX" '[.storages[]? | select(.name|type=="string") | select(.name|startswith($p))] | length' 2>/dev/null || echo "?")"
  ip_orphans="$( gs_quiet GET /objects/ips      | jq -r --arg p "$NAME_PREFIX" '[.ips[]?      | select(.name|type=="string") | select(.name|startswith($p))] | length' 2>/dev/null || echo "?")"
  echo "   servers/storages/ips named ${NAME_PREFIX}*: ${srv_orphans} / ${sto_orphans} / ${ip_orphans}"
  if [[ "$srv_orphans" == "0" && "$sto_orphans" == "0" && "$ip_orphans" == "0" ]]; then
    echo "   ORPHAN CHECK: CLEAN (0 / 0 / 0)"
  else
    echo "   ORPHAN CHECK: ***NOT CLEAN*** — inspect https://my.gridscale.io and delete leftovers by hand" >&2
  fi

  echo ""
  echo "=== FINAL ==="
  echo "RESULT: ${SERVE_RESULT}"
  [[ -n "${VM_IP:-}" ]] && echo "VM public IP: ${VM_IP}"
  echo "teardown done"
  exit "$rc"
}
trap teardown EXIT

# ------------------------------------------------------------------------------
# 2. Resolve the Public Network + location UUIDs (look up, don't hardcode).
# ------------------------------------------------------------------------------
# Public Network: the single L2 network whose .public_net == true. Attaching the
# server to THIS network is what routes the public IPv4. (Override with
# PUBLIC_NETWORK_UUID if you already know it — e.g. c1295d84-... in de/fra2.)
echo "=== RESOLVE public network + location ==="
if [[ -z "${PUBLIC_NETWORK_UUID:-}" ]]; then
  PUBLIC_NETWORK_UUID="$(gs GET /objects/networks \
    | jq -r 'first(.networks[]? | select(.public_net==true) | .object_uuid) // empty')"
  [[ -n "$PUBLIC_NETWORK_UUID" ]] || fail "could not find the Public Network (.public_net==true) — set PUBLIC_NETWORK_UUID"
fi
echo "   public network: ${PUBLIC_NETWORK_UUID}"

# Location: default de/fra2. We pass location_uuid on create. If unset, resolve
# it from the Public Network's own location (guarantees same-location placement).
if [[ -z "${LOCATION_UUID:-}" ]]; then
  LOCATION_UUID="$(gs GET "/objects/networks/${PUBLIC_NETWORK_UUID}" \
    | jq -r '.network.location_uuid // empty')"
  [[ -n "$LOCATION_UUID" ]] || fail "could not resolve LOCATION_UUID from the public network — set LOCATION_UUID (de/fra2)"
fi
echo "   location: ${LOCATION_UUID}"
echo "   run tag (name prefix): ${RUN_TAG}"
echo "   import template: ${IMPORT_TEMPLATE_UUID}"

# ------------------------------------------------------------------------------
# 3. PROVISION.
# ------------------------------------------------------------------------------

# --- 3a. IPv4 (public, family=4) ----------------------------------------------
# POST /objects/ips  {name, family:4, location_uuid}. Response: {object_uuid,...}.
echo ""
echo "=== PROVISION 1/5: IPv4 ==="
IP_RESP="$(gs POST /objects/ips "$(jq -nc \
  --arg name "${RUN_TAG}-ip" --arg loc "$LOCATION_UUID" \
  '{name:$name, family:4, location_uuid:$loc}')")"
IP_UUID="$(echo "$IP_RESP" | jq -r '.object_uuid')"
wait_request "$(echo "$IP_RESP" | jq -r '.request_uuid // empty')"
[[ -n "$IP_UUID" && "$IP_UUID" != "null" ]] || fail "IPv4 create returned no object_uuid"
# Read back the assigned address (single-object GET is wrapped: .ip.ip).
VM_IP="$(gs GET "/objects/ips/${IP_UUID}" | jq -r '.ip.ip')"
[[ -n "$VM_IP" && "$VM_IP" != "null" ]] || fail "IPv4 ${IP_UUID} has no address"
echo "   IPv4 ${IP_UUID} -> ${VM_IP}"

# --- 3b. Storage from the Marketplace template --------------------------------
# POST /objects/storages {name, capacity, storage_type, template:{template_uuid}}.
# The template block instantiates the golden boot disk from the caddy-nix import.
echo ""
echo "=== PROVISION 2/5: storage from template ==="
STORAGE_RESP="$(gs POST /objects/storages "$(jq -nc \
  --arg name "${RUN_TAG}-storage" \
  --argjson cap "$STORAGE_CAPACITY_GIB" \
  --arg stype "$STORAGE_TYPE" \
  --arg loc "$LOCATION_UUID" \
  --arg tpl "$IMPORT_TEMPLATE_UUID" \
  '{name:$name, capacity:$cap, storage_type:$stype, location_uuid:$loc, template:{template_uuid:$tpl}}')")"
STORAGE_UUID="$(echo "$STORAGE_RESP" | jq -r '.object_uuid')"
wait_request "$(echo "$STORAGE_RESP" | jq -r '.request_uuid // empty')"
[[ -n "$STORAGE_UUID" && "$STORAGE_UUID" != "null" ]] || fail "storage create returned no object_uuid"
# Gate on the OBJECT being active (provisioning lags the request; delete is 424
# until active anyway).
wait_active storages "$STORAGE_UUID" storage
echo "   storage ${STORAGE_UUID} active"

# --- 3c. Server ---------------------------------------------------------------
# POST /objects/servers {name, cores, memory, location_uuid}. memory is in GiB.
echo ""
echo "=== PROVISION 3/5: server ==="
SERVER_RESP="$(gs POST /objects/servers "$(jq -nc \
  --arg name "${RUN_TAG}-server" \
  --argjson cores "$SERVER_CORES" \
  --argjson mem "$SERVER_MEMORY_GIB" \
  --arg loc "$LOCATION_UUID" \
  '{name:$name, cores:$cores, memory:$mem, location_uuid:$loc}')")"
SERVER_UUID="$(echo "$SERVER_RESP" | jq -r '.object_uuid')"
wait_request "$(echo "$SERVER_RESP" | jq -r '.request_uuid // empty')"
[[ -n "$SERVER_UUID" && "$SERVER_UUID" != "null" ]] || fail "server create returned no object_uuid"
wait_active servers "$SERVER_UUID" server
echo "   server ${SERVER_UUID} active"

# --- 3d. Attach storage (bootdevice) + Public Network NIC + IPv4 --------------
# Each relation is its own POST sub-endpoint. The storage is the boot device.
echo ""
echo "=== PROVISION 4/5: attach storage + public NIC + IPv4 ==="
# POST /objects/servers/{id}/storages {object_uuid, bootdevice:true}
ATT="$(gs POST "/objects/servers/${SERVER_UUID}/storages" "$(jq -nc \
  --arg s "$STORAGE_UUID" '{object_uuid:$s, bootdevice:true}')")"
wait_request "$(echo "$ATT" | jq -r '.request_uuid // empty')"
echo "   storage attached (boot device)"
# POST /objects/servers/{id}/networks {object_uuid}  (the single Public Network NIC)
ATT="$(gs POST "/objects/servers/${SERVER_UUID}/networks" "$(jq -nc \
  --arg n "$PUBLIC_NETWORK_UUID" '{object_uuid:$n}')")"
wait_request "$(echo "$ATT" | jq -r '.request_uuid // empty')"
echo "   public network NIC attached"
# POST /objects/servers/{id}/ips {object_uuid}
ATT="$(gs POST "/objects/servers/${SERVER_UUID}/ips" "$(jq -nc \
  --arg i "$IP_UUID" '{object_uuid:$i}')")"
wait_request "$(echo "$ATT" | jq -r '.request_uuid // empty')"
echo "   IPv4 attached"

# --- 3e. Power on -------------------------------------------------------------
# PATCH /objects/servers/{id}/power {power:true}. Then poll .server.power==true.
echo ""
echo "=== PROVISION 5/5: power on ==="
PWR="$(gs PATCH "/objects/servers/${SERVER_UUID}/power" '{"power":true}')"
wait_request "$(echo "$PWR" | jq -r '.request_uuid // empty' 2>/dev/null || true)"
pdeadline=$(( $(date +%s) + POLL_TIMEOUT_SECS ))
while :; do
  power="$(gs_quiet GET "/objects/servers/${SERVER_UUID}" | jq -r '.server.power // empty' 2>/dev/null || true)"
  [[ "$power" == "true" ]] && break
  [[ $(date +%s) -ge $pdeadline ]] && fail "server ${SERVER_UUID} did not reach power=true within ${POLL_TIMEOUT_SECS}s"
  sleep "$POLL_INTERVAL_SECS"
done
echo "   server powered on (power=true) — public IP ${VM_IP}"

# ------------------------------------------------------------------------------
# 4. PROVE SERVE (HTTP against the real public IP).
#    A fixed image serves in ~20s; we poll GET / for a 200 up to SERVE_TIMEOUT.
#    Then assert /healthz body == "ok" and :2019/metrics == 200 with caddy_ series.
#    On any failure we set SERVE_RESULT and exit non-zero — the trap STILL tears
#    everything down.
# ------------------------------------------------------------------------------
echo ""
echo "=== PROVE SERVE (http://${VM_IP}) ==="

# 4a. Poll GET / for HTTP 200.
serve_ok=0
sdeadline=$(( $(date +%s) + SERVE_TIMEOUT_SECS ))
while :; do
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://${VM_IP}/" 2>/dev/null || echo 000)"
  if [[ "$code" == "200" ]]; then serve_ok=1; break; fi
  [[ $(date +%s) -ge $sdeadline ]] && break
  sleep 3
done
if [[ "$serve_ok" == "1" ]]; then
  echo "   GET /            -> HTTP 200  [PASS]"
else
  echo "   GET /            -> HTTP ${code:-000} (no 200 within ${SERVE_TIMEOUT_SECS}s)  [FAIL]"
  SERVE_RESULT="SERVE FAILED"
  echo "RESULT: SERVE FAILED"
  exit 1
fi

# 4b. GET /healthz -> body "ok" (200). Assert body, not just status.
health_body="$(curl -s --max-time 5 "http://${VM_IP}/healthz" 2>/dev/null || true)"
health_code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://${VM_IP}/healthz" 2>/dev/null || echo 000)"
health_trim="$(printf '%s' "$health_body" | tr -d '[:space:]')"
if [[ "$health_code" == "200" && "$health_trim" == "ok" ]]; then
  echo "   GET /healthz     -> 200 body \"ok\"  [PASS]"
else
  echo "   GET /healthz     -> HTTP ${health_code} body \"${health_body}\" (want 200/\"ok\")  [FAIL]"
  SERVE_RESULT="SERVE FAILED"
  echo "RESULT: SERVE FAILED"
  exit 1
fi

# 4c. GET :2019/metrics -> 200 AND body contains real caddy_ series.
metrics_code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://${VM_IP}:2019/metrics" 2>/dev/null || echo 000)"
metrics_body="$(curl -s --max-time 8 "http://${VM_IP}:2019/metrics" 2>/dev/null || true)"
if [[ "$metrics_code" == "200" ]] && printf '%s' "$metrics_body" | grep -qE '^caddy_'; then
  caddy_series="$(printf '%s\n' "$metrics_body" | grep -cE '^caddy_' || true)"
  echo "   GET :2019/metrics -> 200 with ${caddy_series} caddy_ series  [PASS]"
else
  echo "   GET :2019/metrics -> HTTP ${metrics_code}; caddy_ series present: no  [FAIL]"
  SERVE_RESULT="SERVE FAILED"
  echo "RESULT: SERVE FAILED"
  exit 1
fi

# ------------------------------------------------------------------------------
# 5. Success. The trap will tear down + orphan-check + print the FINAL block.
#    The VM public IP is echoed for the follow-up Prometheus ScrapeConfig step
#    (a SEPARATE GSK kubectl action the operator runs — NOT in this script).
# ------------------------------------------------------------------------------
SERVE_RESULT="SERVE PROVEN"
echo ""
echo "RESULT: SERVE PROVEN"
echo "VM public IP (for the follow-up Prometheus ScrapeConfig, :2019/metrics, job=\"caddy\"): ${VM_IP}"
# Normal exit -> trap runs teardown, preserves rc=0.

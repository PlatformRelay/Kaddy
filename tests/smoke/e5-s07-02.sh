#!/usr/bin/env bash
# REQ-E5-S07-02: Loki log streams carry the kaddy correlation labels — the
# {part_of="kaddy"} selector returns streams that also carry `service`
# (ADR-0301 underscore mirror; Alloy relabeling), correlating logs <-> metrics.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
# shellcheck disable=SC1091
source "${DIR}/e5-lib.sh"
e5_port_forward loki 13100 3100
L="http://127.0.0.1:13100"

start="$(( $(date +%s) - 3600 ))000000000"
out="$(curl -sf --get "${L}/loki/api/v1/query_range" \
  --data-urlencode 'query={part_of="kaddy"}' \
  --data-urlencode "start=${start}" \
  --data-urlencode 'limit=10')"

n="$(yq -p json '.data.result | length' <<<"${out}")"
[[ "${n}" =~ ^[1-9] ]] || smoke_fail "no {part_of=\"kaddy\"} streams in Loki"

svc="$(yq -p json '.data.result[0].stream.service // ""' <<<"${out}")"
[[ -n "${svc}" ]] || smoke_fail "kaddy stream missing the service label"
smoke_ok "REQ-E5-S07-02 — streams carry part_of=kaddy + service=${svc}"

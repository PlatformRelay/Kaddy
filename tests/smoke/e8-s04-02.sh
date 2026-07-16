#!/usr/bin/env bash
# REQ-E8-S04-02: README documents a gridscale monthly cost / footprint table.
# Offline structural gate — no cluster required.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"

README="${SMOKE_ROOT}/README.md"
[[ -f "${README}" ]] || smoke_fail "missing ${README}"

rg -q 'EUR|monthly' "${README}" \
  || smoke_fail "README.md must document monthly cost (EUR|monthly) — REQ-E8-S04-02"

rg -qi 'GSK|node pool' "${README}" \
  || smoke_fail "README cost table must mention GSK / node pools"
rg -qi 'LBaaS|load balancer' "${README}" \
  || smoke_fail "README cost table must mention LBaaS"
rg -qi 'Object Storage|object storage' "${README}" \
  || smoke_fail "README cost table must mention Object Storage"

smoke_ok "REQ-E8-S04-02 README monthly cost table (GSK / LBaaS / Object Storage)"

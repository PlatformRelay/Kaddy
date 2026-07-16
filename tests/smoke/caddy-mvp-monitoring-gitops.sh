#!/usr/bin/env bash
# REQ-CADDY-S05-04 follow-up — deploy/caddy-mvp/monitoring must be GitOps-synced.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
APP="${SMOKE_ROOT}/deploy/apps/caddy-mvp-monitoring.yaml"
[[ -f "${APP}" ]] || smoke_fail "missing ${APP} (caddy-mvp monitoring Application)"
grep -qE '^[[:space:]]*name:[[:space:]]*caddy-mvp-monitoring[[:space:]]*$' "${APP}" \
  || smoke_fail "Application metadata.name must be caddy-mvp-monitoring"
grep -qE 'path:[[:space:]]*deploy/caddy-mvp/monitoring' "${APP}" \
  || smoke_fail "Application must sync path deploy/caddy-mvp/monitoring"
grep -qE 'recurse:[[:space:]]*true' "${APP}" \
  || smoke_fail "directory.recurse must be true"
grep -qE "exclude:.*marshal-caddy\\.rules\\.yaml" "${APP}" \
  || smoke_fail "directory.exclude must omit marshal-caddy.rules.yaml (promtool projection)"
grep -qE 'project:[[:space:]]*observability' "${APP}" \
  || smoke_fail "Application must use project observability"
grep -qE 'namespace:[[:space:]]*monitoring' "${APP}" \
  || smoke_fail "destination.namespace must be monitoring"
smoke_ok "caddy-mvp monitoring GitOps Application present"

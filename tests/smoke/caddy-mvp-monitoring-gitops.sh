#!/usr/bin/env bash
# REQ-CADDY-S05-04 follow-up — deploy/caddy-mvp/monitoring must be GitOps-synced.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
APP="${SMOKE_ROOT}/deploy/apps/caddy-mvp-monitoring.yaml"
[[ -f "${APP}" ]] || smoke_fail "missing ${APP} (caddy-mvp monitoring Application)"
grep -qE 'path:[[:space:]]*deploy/caddy-mvp/monitoring' "${APP}" \
  || smoke_fail "Application must sync path deploy/caddy-mvp/monitoring"
grep -qE 'recurse:[[:space:]]*true' "${APP}" \
  || smoke_fail "directory.recurse must be true"
grep -qE 'name:[[:space:]]*caddy-mvp-monitoring' "${APP}" \
  || smoke_fail "Application metadata.name must be caddy-mvp-monitoring"
[[ "$(dirname "${APP}")" == "${SMOKE_ROOT}/deploy/apps" ]] \
  || smoke_fail "Application must live under deploy/apps/ for root recurse"
smoke_ok "caddy-mvp monitoring GitOps Application present"

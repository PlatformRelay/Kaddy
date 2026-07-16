#!/usr/bin/env bash
# REQ-E8-S04-04: Demo choreography proves the platform claims.
# Offline: asserts the Getting Started demo runbook exists in the required order.
# Live (optional): when kind-kaddy-dev is reachable, asserts Applications and the
# Website claim look healthy before the reviewer runs the demos. Skips live checks
# when E1E_SMOKE_ALLOW_SKIP=1 and no cluster (design-phase / CI hosts).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"

GS="${SMOKE_ROOT}/docs/getting-started.md"
[[ -f "${GS}" ]] || smoke_fail "missing ${GS} (REQ-E8-S04-04)"

# --- Offline contract: runbook order + evidence fields ----------------------
for cmd in 'task test:smoke:e6' 'task demo:fire' 'task demo' 'task demo:chaos'; do
  rg -qF "${cmd}" "${GS}" || smoke_fail "demo runbook missing ${cmd}"
done

# Extract the Demo section (from ## Demo through next ##) and assert order.
demo_block="$(awk '
  /^## Demo/ {on=1}
  on && /^## / && !/^## Demo/ {exit}
  on {print}
' "${GS}")"
[[ -n "${demo_block}" ]] || smoke_fail "docs/getting-started.md missing ## Demo section"

web_ln="$(printf '%s\n' "${demo_block}" | rg -n 'Website|putting-green|test:smoke:e6' | head -1 | cut -d: -f1)"
fire_ln="$(printf '%s\n' "${demo_block}" | rg -n 'demo:fire' | head -1 | cut -d: -f1)"
demo_ln="$(printf '%s\n' "${demo_block}" | rg -n 'task demo[^:]|`task demo`' | head -1 | cut -d: -f1)"
chaos_ln="$(printf '%s\n' "${demo_block}" | rg -n 'demo:chaos' | head -1 | cut -d: -f1)"
[[ -n "${web_ln}" && -n "${fire_ln}" && -n "${demo_ln}" && -n "${chaos_ln}" ]] \
  || smoke_fail "Demo section must cover Website, demo:fire, demo, demo:chaos"
[[ "${web_ln}" -lt "${fire_ln}" && "${fire_ln}" -lt "${demo_ln}" && "${demo_ln}" -lt "${chaos_ln}" ]] \
  || smoke_fail "Demo order must be Website → fire → demo → chaos"

printf '%s\n' "${demo_block}" | rg -qi 'baseline' \
  || smoke_fail "Demo section must record a healthy baseline first"
printf '%s\n' "${demo_block}" | rg -qi 'duration|minute|~[0-9]|timeout' \
  || smoke_fail "Demo section must state expected duration per act"
printf '%s\n' "${demo_block}" | rg -qi 'success|expect|signal|pass' \
  || smoke_fail "Demo section must state a success signal per act"
printf '%s\n' "${demo_block}" | rg -qi 'fallback' \
  || smoke_fail "Demo section must document a fallback when a surface is unavailable"

smoke_ok "REQ-E8-S04-04 offline — demo runbook order + evidence fields"

# --- Live readiness (skip-friendly) -----------------------------------------
if ! _smoke_cluster_reachable; then
  if [[ "${E1E_SMOKE_ALLOW_SKIP:-0}" == "1" ]]; then
    echo "SKIP: live demo readiness (no kind-kaddy-dev; E1E_SMOKE_ALLOW_SKIP=1)"
    exit 0
  fi
  smoke_require_cluster
fi
smoke_require_cluster

# Baseline the reviewer would see before Act 1.
apps="$(kubectl -n argocd get applications -o jsonpath='{range .items[*]}{.metadata.name}={.status.sync.status}/{.status.health.status}{"\n"}{end}' 2>/dev/null || true)"
[[ -n "${apps}" ]] || smoke_fail "no Argo CD Applications found — finish Getting Started bootstrap first"
echo "${apps}" | while IFS= read -r line; do
  [[ -n "${line}" ]] || continue
  name="${line%%=*}"
  rest="${line#*=}"
  sync="${rest%%/*}"
  health="${rest#*/}"
  [[ "${sync}" == "Synced" && "${health}" == "Healthy" ]] \
    || smoke_fail "Application ${name} is ${sync}/${health} (want Synced/Healthy)"
done

kubectl -n websites get website putting-green >/dev/null 2>&1 \
  || smoke_fail "Website claim websites/putting-green missing — run task bootstrap:e6 / sync workloads"

smoke_ok "REQ-E8-S04-04 live — Applications Synced/Healthy + Website claim present"
echo "Next (manual / task): demo:fire → demo → demo:chaos per docs/getting-started.md"

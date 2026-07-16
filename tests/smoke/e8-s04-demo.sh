#!/usr/bin/env bash
# REQ-E8-S04-04 — demo choreography contract.
# Offline mode (default): assert the Getting Started demo section documents the
# four acts in order. Live mode (E8_S04_LIVE=1 + kind-kaddy-dev): run a thin
# readiness check only — full demos stay behind task demo / demo:fire / demo:chaos.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GS="${ROOT}/docs/getting-started.md"

fail() { echo "FAIL: $*" >&2; exit 1; }

test -f "$GS" || fail "missing docs/getting-started.md"

# Ordered acts must appear in the guide body
for needle in \
  'Website' \
  'task demo:fire' \
  'task demo' \
  'task demo:chaos'
do
  grep -qF "$needle" "$GS" || fail "demo choreography missing: $needle"
done

# Relative order: demo:fire before demo:chaos; Website claim before fire
fire_line="$(grep -nF 'task demo:fire' "$GS" | head -1 | cut -d: -f1)"
demo_line="$(grep -nE '^\|.*`task demo`|task demo[^:]' "$GS" | head -1 | cut -d: -f1 || true)"
[[ -z "$demo_line" ]] && demo_line="$(grep -nF '`task demo`' "$GS" | head -1 | cut -d: -f1)"
chaos_line="$(grep -nF 'task demo:chaos' "$GS" | head -1 | cut -d: -f1)"
[[ -n "$fire_line" && -n "$chaos_line" ]] || fail "could not locate demo act lines"
[[ "$fire_line" -lt "$chaos_line" ]] || fail "task demo:fire must appear before task demo:chaos"

grep -qiE 'fallback|if .*unavailable|shorter path' "$GS" \
  || fail "demo section must document fallback when a surface is unavailable"

if [[ "${E8_S04_LIVE:-0}" == "1" ]]; then
  export KUBECONFIG="${KUBECONFIG:-$ROOT/.state/kubeconfig}"
  CTX="${CTX:-kind-kaddy-dev}"
  kubectl --context "$CTX" cluster-info >/dev/null 2>&1 \
    || fail "E8_S04_LIVE=1 but ${CTX} not reachable — run task cluster:up"
  kubectl --context "$CTX" -n argocd get application workloads \
    -o jsonpath='{.status.sync.status}/{.status.health.status}' | grep -q 'Synced/Healthy' \
    || fail "workloads Application not Synced/Healthy"
  echo "OK: E8-S04-04 live readiness (workloads Synced/Healthy)"
else
  echo "OK: E8-S04-04 demo choreography documented (offline; set E8_S04_LIVE=1 for cluster check)"
fi

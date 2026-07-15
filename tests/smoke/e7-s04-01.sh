#!/usr/bin/env bash
# REQ-E7-S04-01 — kill Caddy pod → CaddyTargetDown fires; pod reschedules.
#
# STATUS: DEFERRED (out of E7 lane boundary). The Caddy Deployment lives in
# ns gateway-system and its CaddyTargetDown marshal rule belong to the Caddy-MVP
# epic (e-caddy-mvp), which is NOT deployed on this cluster. This smoke does NOT
# fake a pass: if the Caddy target is absent it reports SKIP (documented deferral)
# rather than asserting a rule that does not exist. The IN-BOUNDARY chaos —
# aborting a canary to prove Argo Rollouts auto-rollback — is real and covered by
# hack/demo/mulligan-abort.sh.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

if ! kubectl get deploy -n gateway-system -l app.kubernetes.io/name=caddy 2>/dev/null | grep -q caddy; then
  echo "SKIP: REQ-E7-S04-01 — Caddy (ns gateway-system) not deployed; out of E7 boundary (e-caddy-mvp)."
  echo "      In-boundary chaos (canary abort → auto-rollback) is proven by hack/demo/mulligan-abort.sh."
  exit 0
fi

# If Caddy IS present (future integration), run the real chaos.
kubectl delete pod -n gateway-system -l app.kubernetes.io/name=caddy >/dev/null
kubectl -n gateway-system rollout status deploy -l app.kubernetes.io/name=caddy --timeout=120s >/dev/null \
  || smoke_fail "Caddy did not reschedule after pod kill"
smoke_ok "REQ-E7-S04-01 Caddy pod killed and rescheduled"

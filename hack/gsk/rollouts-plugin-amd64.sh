#!/usr/bin/env bash
# E1g-S05i — override the Argo Rollouts Gateway API trafficRouter plugin arch
# for the gridscale GSK cloud-edge (CLOUD-ONLY; proven live 2026-07-18).
#
# ⚠️ SUPERSEDED-BY-OVERLAY (break-glass only): the amd64 variant is now
#   GitOps-owned declaratively at deploy/rollouts/cloud-only/ (kustomize root;
#   `kubectl apply -k deploy/rollouts/cloud-only`), drift-guarded offline by
#   tests/smoke/rollouts-plugin-arch-overlay.sh. Prefer the overlay. Keep this
#   script for break-glass live patching AND for the controller restart the
#   ConfigMap change alone cannot trigger (the controller only reads the
#   trafficRouterPlugins ConfigMap at startup).
#
# WHY THIS EXISTS (the failure mode it fixes):
#   deploy/rollouts/config.yaml pins the plugin binary to `...-linux-arm64`
#   because the LOCAL kind cluster runs on Apple-Silicon (arm64) nodes. GSK
#   worker nodes are **amd64** (Ubuntu 22.04 / x86-64). If the arm64 binary is
#   downloaded onto an amd64 node the controller aborts with `exec format error`
#   when it tries to run the plugin, which stalls ALL Rollout reconciliation —
#   no canary weights are ever shifted, and the rollout hangs Progressing. GSK
#   needs the `...-linux-amd64` binary of the SAME pinned release (v0.16.0).
#
#   The amd64 ConfigMap is now COMMITTED at deploy/rollouts/cloud-only/ (a
#   kustomize root excluded from the kind rollouts App by location — recurse is
#   OFF, so Argo CD never sees two same-named resources in one Application).
#   This script remains the imperative break-glass path mirroring edge-up.sh's
#   apply model, and still owns the controller restart. The kind arm64 default
#   in git is left UNTOUCHED either way.
#
# kind-safety: this MUTATES the target cluster (patches the ConfigMap + restarts
# the controller), so it is guarded by hack/lib/guard-context.sh (E1g-S05a) — it
# REFUSES to run against kind-kaddy-dev (or any non-GSK context) unless you opt
# in to the named GSK context via KADDY_GSK_CONTEXT.
#
# Usage:
#   export KUBECONFIG=<GSK kubeconfig>
#   kubectl config use-context kaddy-gsk-admin@kaddy-gsk
#   export KADDY_GSK_CONTEXT="$(kubectl config current-context)"
#   hack/gsk/rollouts-plugin-amd64.sh
set -euo pipefail

# Refuse to mutate a non-opted-in context (default kind-only guard; GSK requires
# the KADDY_GSK_CONTEXT opt-in). Shared with the bootstrap:* tasks + edge-up.sh.
_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=hack/lib/guard-context.sh disable=SC1091
. "${_root}/hack/lib/guard-context.sh"
guard_writable_context

: "${KUBECONFIG:?export KUBECONFIG=<GSK kubeconfig> before running (never run against kind)}"

# Same pinned release as deploy/rollouts/config.yaml — only the arch differs.
PLUGIN_VERSION="${ROLLOUTS_GWAPI_PLUGIN_VERSION:-v0.16.0}"
PLUGIN_URL="https://github.com/argoproj-labs/rollouts-plugin-trafficrouter-gatewayapi/releases/download/${PLUGIN_VERSION}/gatewayapi-plugin-linux-amd64"

echo "==> Argo Rollouts gatewayAPI plugin ${PLUGIN_VERSION} (linux-amd64) — target context: $(kubectl config current-context)"

# Rewrite ONLY the plugin location to the amd64 binary. The plugin `name`
# ("argoproj-labs/gatewayAPI") must stay identical — it keys the Rollout's
# trafficRouting.plugins map.
kubectl -n argo-rollouts patch configmap argo-rollouts-config --type merge -p "$(cat <<JSON
{"data":{"trafficRouterPlugins":"- name: \"argoproj-labs/gatewayAPI\"\n  location: \"${PLUGIN_URL}\"\n"}}
JSON
)"

# The controller only reads this ConfigMap at startup, so it MUST restart to load
# the amd64 binary (same requirement as the kind bootstrap:e7 one-time restart).
echo "==> restarting the controller to reload the plugin ConfigMap"
kubectl -n argo-rollouts rollout restart deploy/argo-rollouts
kubectl -n argo-rollouts rollout status deploy/argo-rollouts --timeout=180s

echo "OK: plugin location set to linux-amd64 and controller restarted."
echo "    Verify: kubectl -n argo-rollouts logs deploy/argo-rollouts | grep -i plugin"
echo "    (no 'exec format error'; a caddy-origin rollout should shift HTTPRoute weights)."

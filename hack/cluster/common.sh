#!/usr/bin/env bash
# Shared helpers for the kaddy E1e local kind substrate. Source this file.
# Adapted from kollect/hack/kind/common.sh — podman-first for this harness.
set -euo pipefail

CLUSTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${CLUSTER_DIR}/../.." && pwd)"

# shellcheck disable=SC1091
source "${CLUSTER_DIR}/versions.env"

# Local, never-committed state (kubeconfig, rendered manifests). Gitignored (.state/).
STATE_DIR="${REPO_ROOT}/.state"
mkdir -p "${STATE_DIR}"

# SAFETY: isolate the kind kubeconfig from the developer's shared ~/.kube/config,
# which on this workstation carries 100+ real GKE contexts. Every kubectl/helm in
# these scripts targets ONLY the kaddy-dev kind cluster via this file — a stray
# apply can never reach a production context.
export KUBECONFIG="${STATE_DIR}/kubeconfig"

KIND_CLUSTER_WAIT="${KIND_CLUSTER_WAIT:-300s}"
# 600s: a cold-cache clean bring-up pulls Cilium + cert-manager images on a fresh
# node while Cilium is still settling; 300s was too tight and timed out cert-manager.
HELM_TIMEOUT="${HELM_TIMEOUT:-600s}"

log() { echo "[e1e] $*" >&2; }
fail() { echo "[e1e] ERROR: $*" >&2; exit 1; }

require() {
  local cmd="$1" hint="${2:-}"
  command -v "$cmd" >/dev/null 2>&1 || fail "${cmd} is required.${hint:+ $hint}"
}

require_tools() {
  require kind "https://kind.sigs.k8s.io/"
  require kubectl "https://kubernetes.io/docs/tasks/tools/"
  require helm "https://helm.sh/"
  require jq "https://jqlang.github.io/jq/"
}

# Detect a container runtime and export KIND_EXPERIMENTAL_PROVIDER.
# Order matches the task note: this harness runs rootless podman.
detect_provider() {
  if [[ -n "${KIND_EXPERIMENTAL_PROVIDER:-}" ]]; then
    return 0
  fi
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    return 0 # docker is kind's default provider
  fi
  if command -v podman >/dev/null 2>&1; then
    export KIND_EXPERIMENTAL_PROVIDER="podman"
  elif command -v nerdctl >/dev/null 2>&1; then
    export KIND_EXPERIMENTAL_PROVIDER="nerdctl"
  else
    fail "A container runtime is required (docker, podman, or nerdctl)."
  fi
  log "container runtime: ${KIND_EXPERIMENTAL_PROVIDER:-docker}"
}

# Preflight: Cilium's agent must mount /sys/fs/bpf, which rootless podman denies
# (the agent crashloops for ~5 min then Helm --wait fails). Under podman we require
# a ROOTFUL machine and fail fast with the remedy rather than crashlooping silently.
# See the "Implementation deviations" note in the E1e spec.
assert_podman_rootful() {
  [[ "${KIND_EXPERIMENTAL_PROVIDER:-}" == "podman" ]] || return 0
  command -v podman >/dev/null 2>&1 || return 0
  local rootful
  rootful="$(podman machine inspect --format '{{.Rootful}}' 2>/dev/null | head -1 || true)"
  # Empty means no machine abstraction (e.g. native Linux podman) — nothing to assert.
  [[ -z "${rootful}" ]] && return 0
  [[ "${rootful}" == "true" ]] && return 0
  fail "rootless podman cannot mount /sys/fs/bpf for Cilium — run: podman machine stop && podman machine set --rootful && podman machine start (see E1e spec deviations)"
}

# The CLI used to inspect the kind bridge network (podman/nerdctl/docker).
runtime_cli() {
  case "${KIND_EXPERIMENTAL_PROVIDER:-docker}" in
    podman) echo "podman" ;;
    nerdctl) echo "nerdctl" ;;
    *) echo "docker" ;;
  esac
}

kind_cluster_exists() {
  kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"
}

use_context() {
  kubectl config use-context "kind-${CLUSTER_NAME}" >/dev/null
}

export_kubeconfig() {
  # Write the cluster kubeconfig to the isolated .state/ path (== $KUBECONFIG).
  kind export kubeconfig --name "${CLUSTER_NAME}" --kubeconfig "${KUBECONFIG}" >/dev/null 2>&1
}

# Hard guard: refuse to proceed unless the active context is the kind cluster.
# Called before any mutating kubectl/helm so we can never hit a GKE prod context.
assert_kind_context() {
  local ctx
  ctx="$(kubectl config current-context 2>/dev/null || true)"
  [[ "${ctx}" == "kind-${CLUSTER_NAME}" ]] \
    || fail "refusing to continue: active context is '${ctx}', expected 'kind-${CLUSTER_NAME}' (KUBECONFIG=${KUBECONFIG})"
}

# The control-plane container IP — used as k8sServiceHost for Cilium kube-proxy
# replacement (kind's in-cluster API VIP is not reachable before Cilium is up).
control_plane_ip() {
  local cli node
  cli="$(runtime_cli)"
  node="${CLUSTER_NAME}-control-plane"
  "${cli}" inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${node}" 2>/dev/null \
    | tr -d '[:space:]'
}

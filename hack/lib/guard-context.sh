# shellcheck shell=sh
# Shared kube-context safety guard for bootstrap:* tasks (E1g-S05a).
#
# Default (no opt-in): the ONLY writable context is kind-kaddy-dev — the local
# prod-nuke guard that keeps `task bootstrap:*` from ever mutating an ambient
# remote (prod) context that happens to sit in the workstation KUBECONFIG.
#
# Opt-in (live gridscale demo): export KADDY_GSK_CONTEXT=<gsk-context-name> to
# permit EXACTLY that one named context. This mirrors E8B_GSK_CONTEXT in
# tests/smoke/e8b-serve.sh. It NEVER blanket-disables the guard: the active
# context must equal the named value, so it cannot wander onto an unrelated
# context. When KADDY_GSK_CONTEXT is unset the behaviour is equivalent to the
# original kind-only guard (same proceed/refuse decision + exit codes; the
# refuse message gains a GSK opt-in hint).
#
# POSIX sh (Taskfile runs cmds under sh); no bashisms.
guard_writable_context() {
  _gwc_ctx="$(kubectl config current-context 2>/dev/null || true)"
  if [ -n "${KADDY_GSK_CONTEXT:-}" ]; then
    if [ "${_gwc_ctx}" != "${KADDY_GSK_CONTEXT}" ]; then
      echo "refusing: context '${_gwc_ctx}' != opted-in GSK context '${KADDY_GSK_CONTEXT}' (KADDY_GSK_CONTEXT) — 'kubectl config use-context ${KADDY_GSK_CONTEXT}'" >&2
      exit 1
    fi
  else
    if [ "${_gwc_ctx}" != "kind-kaddy-dev" ]; then
      echo "refusing: context '${_gwc_ctx}' is not kind-kaddy-dev (run 'task cluster:up', or export KADDY_GSK_CONTEXT for the GSK live demo)" >&2
      exit 1
    fi
  fi
}

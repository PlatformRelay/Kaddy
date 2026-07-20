#!/usr/bin/env bash
# Offline gate: every deploy/apps Application intended for autosync MUST declare
# syncPolicy.automated. Manual-sync is the exception and must be named below
# with a documented reason (comment in the Application YAML + this allow-list).
#
# Wired into `task test:meta:ci` / `task verify`. No cluster required.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
REPO_ROOT="$(cd "${DIR}/../.." && pwd)"
APPS="${REPO_ROOT}/deploy/apps"

# Apps that MAY omit automated: — empty by default. Add a name only with a
# durable reason recorded in the Application header AND deploy/apps/README.md.
# shellcheck disable=SC2034  # reserved allow-list for future exceptions
MANUAL_SYNC_ALLOWLIST=()

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

shopt -s nullglob
found=0
for f in "${APPS}"/*.yaml; do
  base="$(basename "${f}" .yaml)"
  [[ "${base}" == "README" ]] && continue
  kind="$(yq e '.kind // ""' "${f}")"
  [[ "${kind}" == "Application" ]] || continue
  found=$((found + 1))

  allow=0
  for m in "${MANUAL_SYNC_ALLOWLIST[@]+"${MANUAL_SYNC_ALLOWLIST[@]}"}"; do
    [[ "${base}" == "${m}" ]] && allow=1 && break
  done
  if [[ "${allow}" -eq 1 ]]; then
    auto="$(yq e '.spec.syncPolicy.automated // "null"' "${f}")"
    [[ "${auto}" == "null" ]] \
      || fail "${base} is on MANUAL_SYNC_ALLOWLIST but still has automated: (remove from allow-list)"
    ok "${base} manual-sync (allow-listed)"
    continue
  fi

  yq e '.spec.syncPolicy.automated' "${f}" >/dev/null 2>&1 \
    || fail "${base} missing syncPolicy.automated (add automated or document + allow-list)"
  auto="$(yq e '.spec.syncPolicy.automated // "null"' "${f}")"
  [[ "${auto}" != "null" ]] \
    || fail "${base} missing syncPolicy.automated (add automated or document + allow-list)"
  # prune is the platform default for autosync apps (matches sibling children).
  prune="$(yq e '.spec.syncPolicy.automated.prune // "unset"' "${f}")"
  [[ "${prune}" == "true" ]] || fail "${base} automated.prune must be true (got '${prune}')"
  ok "${base} has syncPolicy.automated (prune=true)"
done

[[ "${found}" -ge 1 ]] || fail "no Application manifests under deploy/apps/"
ok "argocd autosync defaults (${found} Applications checked)"

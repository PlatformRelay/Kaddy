#!/usr/bin/env bash
# REQ-E3-S01-02: selfHeal is enabled on platform-core ONLY; documented exceptions
# elsewhere. This is a manifest-truth check (does not need the cluster) so it runs
# fast in the bundle; it asserts the committed policy, not live drift behaviour.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
REPO_ROOT="$(cd "${DIR}/../.." && pwd)"
APPS="${REPO_ROOT}/deploy/apps"

pc="$(yq e '.spec.syncPolicy.automated.selfHeal' "${APPS}/platform-core.yaml")"
[[ "${pc}" == "true" ]] || smoke_fail "platform-core selfHeal must be true (got '${pc}')"
smoke_ok "platform-core selfHeal=true"

# Every OTHER app-of-apps child must NOT have selfHeal:true.
for f in "${APPS}"/*.yaml; do
  base="$(basename "${f}")"
  [[ "${base}" == "platform-core.yaml" || "${base}" == "root.yaml" ]] && continue
  sh="$(yq e '.spec.syncPolicy.automated.selfHeal // "unset"' "${f}")"
  [[ "${sh}" != "true" ]] || smoke_fail "${base} must not enable selfHeal (documented exception)"
done
smoke_ok "no other child enables selfHeal"

# The exceptions must be documented.
grep -q "selfHeal" "${APPS}/README.md" || smoke_fail "selfHeal policy not documented in deploy/apps/README.md"
smoke_ok "REQ-E3-S01-02"

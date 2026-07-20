#!/usr/bin/env bash
# REQ-E3-S01-02: selfHeal is enabled on the CONTROL-PLANE apps (root +
# platform-core + identity) — declarative Argo/config/KSOPS CRs, so drift snaps
# back safely. Workload-facing children (observability, gateway, workloads,
# policies, kyverno, …) keep selfHeal OFF (human-in-the-loop). Manifest-truth
# check (no cluster); asserts committed policy, not live drift behaviour.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
REPO_ROOT="$(cd "${DIR}/../.." && pwd)"
APPS="${REPO_ROOT}/deploy/apps"

# Control-plane apps MUST self-heal (positively asserted — not skipped).
for base in root platform-core identity; do
  sh="$(yq e '.spec.syncPolicy.automated.selfHeal' "${APPS}/${base}.yaml")"
  [[ "${sh}" == "true" ]] || smoke_fail "${base} selfHeal must be true (got '${sh}')"
  smoke_ok "${base} selfHeal=true"
done

# Every other child MUST NOT have selfHeal:true.
for f in "${APPS}"/*.yaml; do
  base="$(basename "${f}")"
  case "${base}" in
    platform-core.yaml|root.yaml|identity.yaml) continue ;;
  esac
  sh="$(yq e '.spec.syncPolicy.automated.selfHeal // "unset"' "${f}")"
  [[ "${sh}" != "true" ]] || smoke_fail "${base} must not enable selfHeal (documented exception)"
done
smoke_ok "no workload-facing child enables selfHeal"

# The exceptions must be documented.
grep -q "selfHeal" "${APPS}/README.md" || smoke_fail "selfHeal policy not documented in deploy/apps/README.md"
smoke_ok "REQ-E3-S01-02"

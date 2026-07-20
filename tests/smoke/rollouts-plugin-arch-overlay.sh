#!/usr/bin/env bash
# E1g-S05i — OFFLINE gate: GSK amd64 variant of the Argo Rollouts Gateway API
# plugin config (deploy/rollouts/cloud-only/) vs the kind arm64 base
# (deploy/rollouts/config.yaml).
#
# Asserts (no cluster, no API):
#   1. Base still pins the linux-arm64 plugin binary (kind / Apple-Silicon) and
#      never mentions amd64; cloud-only pins linux-amd64 and never arm64.
#   2. Both pin the SAME exact release v0.16.0 (SEC-4 — no floating tag) and
#      neither carries a floating "latest".
#   3. Drift guard: cloud-only/config.yaml is a byte-copy of the base modulo the
#      `linux-arm64` -> `linux-amd64` substring (bump both together).
#   4. The overlay RENDERS (kustomize build / kubectl kustomize) and the ONLY
#      rendered delta vs the base is the arch substring in the plugin
#      `location:` URL (one changed line per side, both the plugin URL).
#   5. Kind path unchanged: deploy/rollouts/ stays a PLAIN directory source (no
#      top-level kustomization.yaml) and the rollouts Application does not set
#      directory.recurse — so cloud-only/ is excluded by location and the kind
#      rendered output is byte-identical to before this overlay existed.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"

BASE="${ROOT}/deploy/rollouts/config.yaml"
OVERLAY_DIR="${ROOT}/deploy/rollouts/cloud-only"
OVERLAY="${OVERLAY_DIR}/config.yaml"
APP="${ROOT}/deploy/apps/rollouts.yaml"
PIN="v0.16.0"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

[[ -f "${BASE}" ]]    || fail "missing ${BASE}"
[[ -f "${OVERLAY}" ]] || fail "missing ${OVERLAY} (amd64 cloud-only variant)"
[[ -f "${OVERLAY_DIR}/kustomization.yaml" ]] || fail "missing ${OVERLAY_DIR}/kustomization.yaml"

# 1) arch pins: base=arm64 only, overlay=amd64 only.
grep -q 'gatewayapi-plugin-linux-arm64' "${BASE}" \
  || fail "base must pin the linux-arm64 plugin binary (kind path)"
! grep -q 'linux-amd64' "${BASE}" \
  || fail "base must not mention linux-amd64 (that is the cloud-only variant)"
grep -q 'gatewayapi-plugin-linux-amd64' "${OVERLAY}" \
  || fail "cloud-only must pin the linux-amd64 plugin binary (GSK nodes are amd64)"
! grep -q 'linux-arm64' "${OVERLAY}" \
  || fail "cloud-only must not mention linux-arm64"
ok "base pins linux-arm64; cloud-only pins linux-amd64"

# 2) same exact release in both, no floating tags (SEC-4).
grep -q "download/${PIN}/gatewayapi-plugin-linux-arm64" "${BASE}" \
  || fail "base plugin URL must pin ${PIN}"
grep -q "download/${PIN}/gatewayapi-plugin-linux-amd64" "${OVERLAY}" \
  || fail "cloud-only plugin URL must pin ${PIN}"
! grep -qi 'download/latest' "${BASE}" "${OVERLAY}" \
  || fail "plugin URLs must not float on latest"
ok "both variants pin plugin release ${PIN} (no floating tag)"

# 3) drift guard: overlay == base modulo the arch substring, in BOTH directions.
diff <(sed 's/linux-arm64/linux-amd64/g' "${BASE}") "${OVERLAY}" >/dev/null \
  || fail "cloud-only/config.yaml drifted from base: it must be a byte-copy of deploy/rollouts/config.yaml modulo linux-arm64->linux-amd64 (bump both together)"
diff <(sed 's/linux-amd64/linux-arm64/g' "${OVERLAY}") "${BASE}" >/dev/null \
  || fail "base config.yaml drifted from cloud-only (arch-swap round-trip mismatch)"
ok "cloud-only is a byte-copy of base modulo the arch substring"

# 4) the overlay renders, and the rendered delta vs base is EXACTLY the arch
#    substring in the plugin location URL. The base is rendered through the same
#    kustomize normalization (temp kustomization over a copy of the base file)
#    so comments/formatting cannot mask or fake a delta.
KBUILD=""
if command -v kustomize >/dev/null 2>&1; then
  KBUILD="kustomize build"
elif command -v kubectl >/dev/null 2>&1; then
  KBUILD="kubectl kustomize"
fi
if [[ -n "${KBUILD}" ]]; then
  TMP="$(mktemp -d)"
  trap 'rm -rf "${TMP}"' EXIT
  mkdir -p "${TMP}/base"
  cp "${BASE}" "${TMP}/base/config.yaml"
  printf 'apiVersion: kustomize.config.k8s.io/v1beta1\nkind: Kustomization\nresources:\n  - config.yaml\n' \
    > "${TMP}/base/kustomization.yaml"
  ${KBUILD} "${TMP}/base" > "${TMP}/base.rendered" \
    || fail "base config.yaml failed to render under kustomize"
  ${KBUILD} "${OVERLAY_DIR}" > "${TMP}/overlay.rendered" \
    || fail "cloud-only overlay failed to render (${KBUILD} ${OVERLAY_DIR})"

  # arch-swapped rendered base must equal rendered overlay byte-for-byte...
  diff <(sed 's/linux-arm64/linux-amd64/g' "${TMP}/base.rendered") "${TMP}/overlay.rendered" >/dev/null \
    || fail "rendered overlay differs from rendered base beyond the arch substring"
  # ...and the raw rendered diff must be exactly one changed line per side,
  # both of them the pinned plugin location URL.
  DELTA="$(diff "${TMP}/base.rendered" "${TMP}/overlay.rendered" | grep '^[<>]' || true)"
  [[ "$(printf '%s\n' "${DELTA}" | wc -l | tr -d ' ')" == "2" ]] \
    || fail "rendered delta is not exactly one changed line per side: ${DELTA}"
  printf '%s\n' "${DELTA}" | grep -q "< .*download/${PIN}/gatewayapi-plugin-linux-arm64" \
    || fail "rendered base side of the delta is not the arm64 plugin URL"
  printf '%s\n' "${DELTA}" | grep -q "> .*download/${PIN}/gatewayapi-plugin-linux-amd64" \
    || fail "rendered overlay side of the delta is not the amd64 plugin URL"
  ok "overlay renders; only rendered delta is the arch substring in the plugin URL"
else
  echo "SKIP: neither kustomize nor kubectl installed — render-delta check skipped (drift guard above still enforced)"
fi

# 5) kind path untouched: plain directory source, recurse OFF.
[[ ! -e "${ROOT}/deploy/rollouts/kustomization.yaml" ]] \
  || fail "deploy/rollouts/ must stay a PLAIN directory source (a top-level kustomization.yaml would change the kind path's rendering)"
! grep -q 'recurse: *true' "${APP}" \
  || fail "deploy/apps/rollouts.yaml must not set directory.recurse: true (cloud-only/ must stay excluded by location on kind)"
ok "kind path unchanged: plain directory source, recurse off — cloud-only/ excluded by location"

echo "PASS: rollouts-plugin-arch-overlay"

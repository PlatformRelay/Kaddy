#!/usr/bin/env bash
# REQ-E1c-S03-01 (board-narrowed): fail on :latest in first-party deploy image
# refs; inventory tag-only (non-digest) refs as advisory. Offline — no cluster.
#
# Full digest mandate (@sha256: on every image) is intentionally NOT enforced
# yet — that would break Helm/vendor releases. See OPERATOR-BOARD E1c-digest-latest.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"

SCRIPT="${SMOKE_ROOT}/hack/verify-image-digests.sh"

[[ -x "${SCRIPT}" ]] || smoke_fail "missing executable ${SCRIPT}"

# 1) Clean tree: first-party deploy must have no :latest image refs.
"${SCRIPT}" || smoke_fail "verify-image-digests.sh failed on current deploy/"
smoke_ok "no :latest in first-party deploy image refs"

# 2) Negative fixture: a slipped :latest must fail the gate (exclusions still apply).
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT
mkdir -p "${tmp}/workloads" "${tmp}/kyverno"
cat >"${tmp}/workloads/bad.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: slipped
spec:
  template:
    spec:
      containers:
        - name: app
          image: ghcr.io/platformrelay/kaddy-showcase:latest
EOF
# Vendored dump must NOT trip the gate even with :latest in Example prose / image.
cat >"${tmp}/kyverno/install.yaml" <<'EOF'
# Example: ghcr.io/kyverno/kyverno:latest
          image: "reg.kyverno.io/kyverno/kyverno:latest"
EOF

if DEPLOY_ROOT="${tmp}" "${SCRIPT}" >/dev/null 2>&1; then
  smoke_fail "verify-image-digests.sh accepted :latest in first-party deploy"
fi
smoke_ok "gate fails when :latest slips into first-party deploy"

# 3) Vendored-only :latest (no first-party bad refs) must pass.
rm -f "${tmp}/workloads/bad.yaml"
DEPLOY_ROOT="${tmp}" "${SCRIPT}" >/dev/null \
  || smoke_fail "vendored install.yaml :latest incorrectly failed the gate"
smoke_ok "vendored install.yaml excluded from :latest fail"

# 4) Case-insensitive :Latest must also fail (tag bypass).
cat >"${tmp}/workloads/case.yaml" <<'EOF'
          image: ghcr.io/platformrelay/kaddy-showcase:Latest
EOF
if DEPLOY_ROOT="${tmp}" "${SCRIPT}" >/dev/null 2>&1; then
  smoke_fail "verify-image-digests.sh accepted capitalized :Latest tag"
fi
smoke_ok "gate fails on capitalized :Latest"

smoke_ok "REQ-E1c-S03-01 digest/latest gate (narrowed)"

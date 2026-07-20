#!/usr/bin/env bash
# Offline gate for hack/gsk/roll-caddy-images.sh — no cluster, no creds.
# Asserts the script exists, refuses non-opted-in contexts, and dry-runs the
# intended image bumps (caddy-mvp showcase :0.6.0 + caddy-demo 2.11.4-alpine).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${ROOT}/hack/gsk/roll-caddy-images.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

[[ -f "${SCRIPT}" ]] || fail "missing ${SCRIPT}"
[[ -x "${SCRIPT}" ]] || fail "${SCRIPT} must be executable"

# --- mock kubectl: current-context + capture mutation argv -------------------
MOCK_DIR="$(mktemp -d)"
trap 'rm -rf "${MOCK_DIR}"' EXIT
LOG="${MOCK_DIR}/kubectl.log"
: >"${LOG}"
cat >"${MOCK_DIR}/kubectl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${KUBECTL_LOG:?}"
if [[ "$1" == "config" && "$2" == "current-context" ]]; then
  printf '%s\n' "${FAKE_CTX:-}"
  exit 0
fi
# dry-run path should never reach real mutations; allow benign gets
exit 0
EOF
chmod +x "${MOCK_DIR}/kubectl"
export PATH="${MOCK_DIR}:${PATH}"
export KUBECTL_LOG="${LOG}"
export KUBECONFIG="${MOCK_DIR}/fake-kubeconfig"
# guard-context / script require a file named by KUBECONFIG
: >"${KUBECONFIG}"

# 1) Refuse when GSK opt-in is unset (kind-default guard would allow kind, but
#    this script is cloud-only and always requires KADDY_GSK_CONTEXT).
unset KADDY_GSK_CONTEXT || true
export FAKE_CTX="kind-kaddy-dev"
if "${SCRIPT}" --dry-run >/dev/null 2>&1; then
  fail "script must refuse when KADDY_GSK_CONTEXT is unset (even on kind)"
fi
ok "refuses without KADDY_GSK_CONTEXT"

# 2) Refuse context mismatch
export KADDY_GSK_CONTEXT="kaddy-gsk-admin@kaddy-gsk"
export FAKE_CTX="some-other-context"
if "${SCRIPT}" --dry-run >/dev/null 2>&1; then
  fail "script must refuse when active context != KADDY_GSK_CONTEXT"
fi
ok "refuses context mismatch"

# 3) Dry-run on matching GSK context — prints target images, no mutations
export FAKE_CTX="kaddy-gsk-admin@kaddy-gsk"
: >"${LOG}"
out="$("${SCRIPT}" --dry-run 2>&1)" || fail "dry-run failed: ${out}"
echo "${out}" | grep -q 'ghcr.io/platformrelay/kaddy-showcase:0.6.0' \
  || fail "dry-run must mention showcase :0.6.0"
echo "${out}" | grep -q 'caddy:2.11.4-alpine' \
  || fail "dry-run must mention caddy:2.11.4-alpine"
echo "${out}" | grep -qiE 'dry[- ]?run|would' \
  || fail "dry-run must say it is a dry-run"
# No mutating kubectl verbs in the log (set/patch/apply/replace/edit/delete)
if grep -Eiq '(^| )(set|patch|apply|replace|edit|delete|rollout restart)( |$)' "${LOG}"; then
  fail "dry-run must not invoke mutating kubectl verbs; log=$(cat "${LOG}")"
fi
ok "dry-run prints :0.6.0 + 2.11.4-alpine without mutating"

echo "PASS: gsk-roll-caddy-images offline gate green"

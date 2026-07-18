#!/usr/bin/env bash
# E1g-S05a — offline guard test for hack/lib/guard-context.sh.
# Asserts all four branches of guard_writable_context with a MOCKED kubectl.
# Runs with NO cluster and NO creds (the mock never touches the network).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HELPER="${ROOT}/hack/lib/guard-context.sh"
[[ -f "${HELPER}" ]] || { echo "FAIL: missing ${HELPER}" >&2; exit 1; }

# --- mock kubectl: `kubectl config current-context` echoes $FAKE_CTX ----------
MOCK_DIR="$(mktemp -d)"
trap 'rm -rf "${MOCK_DIR}"' EXIT
cat >"${MOCK_DIR}/kubectl" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "config" && "$2" == "current-context" ]]; then
  printf '%s\n' "${FAKE_CTX:-}"
  exit 0
fi
exit 0
EOF
chmod +x "${MOCK_DIR}/kubectl"
export PATH="${MOCK_DIR}:${PATH}"

fails=0
# run the guard in a subshell (it calls `exit` on refusal) and report rc
# shellcheck disable=SC1090,SC1091
run_guard() { ( set +e; . "${HELPER}"; guard_writable_context ) >/dev/null 2>&1; echo $?; }

assert() { # <label> <expected-rc> <actual-rc>
  if [[ "$2" == "$3" ]]; then echo "ok   — $1 (rc=$3)"; else
    echo "FAIL — $1: expected rc=$2 got rc=$3" >&2; fails=$((fails+1)); fi
}

# 1) opt-in UNSET + non-kind context → refuse
unset KADDY_GSK_CONTEXT; export FAKE_CTX="prod-cluster"
assert "unset opt-in + non-kind → refuse" 1 "$(run_guard)"

# 2) opt-in set + active context MATCHES → proceed
export KADDY_GSK_CONTEXT="kaddy-gsk-admin@kaddy-gsk"; export FAKE_CTX="kaddy-gsk-admin@kaddy-gsk"
assert "named-match → proceed" 0 "$(run_guard)"

# 3) opt-in set + active context MISMATCH → refuse (opt-in is not a blanket disable)
export KADDY_GSK_CONTEXT="kaddy-gsk-admin@kaddy-gsk"; export FAKE_CTX="some-other-context"
assert "named-mismatch → refuse" 1 "$(run_guard)"

# 4) opt-in UNSET + kind context → proceed (default behaviour byte-for-byte unchanged)
unset KADDY_GSK_CONTEXT; export FAKE_CTX="kind-kaddy-dev"
assert "unset opt-in + kind → proceed" 0 "$(run_guard)"

# (edge) opt-in set to EMPTY string behaves as unset → kind-only
export KADDY_GSK_CONTEXT=""; export FAKE_CTX="kind-kaddy-dev"
assert "empty opt-in + kind → proceed (treated as unset)" 0 "$(run_guard)"
export KADDY_GSK_CONTEXT=""; export FAKE_CTX="prod-cluster"
assert "empty opt-in + non-kind → refuse (treated as unset)" 1 "$(run_guard)"

if [[ "${fails}" -ne 0 ]]; then echo "bootstrap-guard: ${fails} FAIL(s)" >&2; exit 1; fi
echo "bootstrap-guard: all branches OK"

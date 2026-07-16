#!/usr/bin/env bash
# REQ-E1d-S01-04: no GitHub OAuth plaintext in git — every stringData/data
# value in the committed secret manifests is a SOPS ciphertext, the scrub
# gate passes, and gitleaks (when installed) finds nothing in deploy/.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }

# 1) Every value under stringData/data in committed secret manifests is ENC[.
while IFS= read -r f; do
  plaintext="$(yq e '(.stringData // {}) + (.data // {}) | to_entries[] | select(.value | test("^ENC\\[") | not) | .key' "$f")"
  [[ -z "${plaintext}" ]] || fail "unencrypted value(s) in ${f}: ${plaintext}"
done < <(find "${ROOT}/deploy/secrets" -name '*.enc.yaml')
echo "OK: all deploy/secrets/**.enc.yaml values are SOPS ciphertexts"

# 2) Repo scrub gate (denylist).
bash "${ROOT}/hack/scrub-denylist.sh" >/dev/null || fail "scrub gate failed"
echo "OK: scrub denylist clean"

# 3) gitleaks over deploy/ (same config CI uses), best-effort locally.
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks detect --no-banner --no-git --source "${ROOT}/deploy" >/dev/null \
    || fail "gitleaks found secret material under deploy/"
  echo "OK: gitleaks clean on deploy/"
else
  echo "SKIP: gitleaks not installed (CI runs it)"
fi

#!/usr/bin/env bash
# REQ-E1d-S01-05 (ADR-0110/D-020): the committed Dex GitHub secret decrypts
# with the operator age key and carries EXACTLY the expected keys. Values are
# never printed — assertions run on key names only.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }

# macOS sops defaults to ~/Library/Application Support — pin the kaddy path.
export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-${HOME}/.config/sops/age/keys.txt}"
[[ -f "${SOPS_AGE_KEY_FILE}" ]] || { echo "SKIP: no operator age key on this host"; exit 0; }

f="${ROOT}/deploy/secrets/identity/dex-github.enc.yaml"
[[ -f "$f" && -f "${ROOT}/.sops.yaml" ]] || fail "encrypted manifest or .sops.yaml missing"

keys="$(sops --decrypt "$f" | yq e '(.stringData // {}) + (.data // {}) | keys | sort | join(",")' -)" \
  || fail "sops decrypt failed (wrong recipient / key)"
[[ "${keys}" == "client-id,client-secret" ]] \
  || fail "unexpected secret keys: ${keys} (want client-id,client-secret)"
echo "OK: dex-github.enc.yaml decrypts to exactly client-id + client-secret (values not shown)"

kind_ns="$(sops --decrypt "$f" | yq e '.kind + "/" + .metadata.namespace + "/" + .metadata.name' -)"
[[ "${kind_ns}" == "Secret/identity/dex-github-oauth" ]] \
  || fail "decrypted manifest is not Secret/identity/dex-github-oauth (${kind_ns})"
echo "OK: decrypted manifest shape Secret/identity/dex-github-oauth"

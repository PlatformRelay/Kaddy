#!/usr/bin/env bash
# REQ-E1e-EXIT: epic exit gate — the full E1e smoke bundle from a green cluster.
# Runs every story smoke test in order. `task cluster:up` must have brought the
# stack green (Cilium + Gateway API + LB-IPAM + cert-manager + default StorageClass).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tests=(
  e1e-s01-02.sh
  e1e-s02-01.sh
  e1e-s02-02.sh
  e1e-s02-03.sh
  e1e-s03-01.sh
  e1e-s03-02.sh
  e1e-s04-01.sh
)

fails=0
for t in "${tests[@]}"; do
  echo "=== ${t} ==="
  if ! bash "${DIR}/${t}"; then
    echo "!!! ${t} FAILED" >&2
    fails=$((fails + 1))
  fi
done

if (( fails > 0 )); then
  echo "E1e EXIT: ${fails} smoke test(s) failed" >&2
  exit 1
fi
echo "OK: REQ-E1e-EXIT — full E1e smoke bundle green"

#!/usr/bin/env bash
# REQ-E5-S03-05 / DIR-2 fire leg: run the full marshal fire demo — controlled
# clubhouse outage -> ClubhouseDown pending -> firing -> ACTIVE in Alertmanager
# -> restore -> resolved. The demo script IS the assertion (exit code verdict).
# NOTE: this is the slow one (~4-8 min end to end) — the whole point of E5.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${DIR}/../../hack/demo/marshal-fire.sh"

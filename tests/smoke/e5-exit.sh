#!/usr/bin/env bash
# E5 exit bundle — the marshal fire-leg live smoke suite (`task test:smoke:e5`).
# Order: GitOps wiring -> scrape plane -> probe -> Grafana -> Alertmanager path
# -> Loki -> THE FIRE DEMO last (slow, mutates+restores clubhouse).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tests=(
  e5-s09-01.sh   # monitoring child Application Synced/Healthy, content live
  e5-s02-03.sh   # blackbox exporter + CA trust converged
  e5-s01-02.sh   # edge + rollouts scrape targets up
  e5-s02-01.sh   # probe_success == 1
  e5-s02-02.sh   # probe_http_status_code == 200
  e5-s05-01.sh   # kaddy-marshal dashboard served by Grafana
  e5-s08-01.sh   # marshal alerts data-source-managed in Grafana
  e5-s04-01.sh   # Alertmanager receiver path
  e5-s07-01.sh   # clubhouse logs in Loki
  e5-s07-02.sh   # kaddy labels on log streams
  e5-s03-05.sh   # THE FIRE DEMO — ClubhouseDown fires + resolves end to end
)

for t in "${tests[@]}"; do
  echo ""
  echo "=== ${t} ==="
  bash "${DIR}/${t}"
done

echo ""
echo "OK: E5 exit bundle green — serve -> scrape -> FIRE proven live"

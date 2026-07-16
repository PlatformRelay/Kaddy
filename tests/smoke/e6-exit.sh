#!/usr/bin/env bash
# E6 exit bundle — the self-service demo proof (`task test:smoke:e6`).
# One GitOps-committed Website XR (deploy/workloads/website-demo/) becomes a
# Running, TLS-served, Prometheus-monitored site with NO manual kubectl edits:
# Crossplane core -> XRD/Composition -> claim reconciles -> edge 200 -> monitored.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tests=(
  e6-s01-01.sh   # Crossplane core Running + GitOps-managed
  e6-s02-01.sh   # Website XRD Established (v2 namespaced) + Composition + function
  e6-s03-01.sh   # demo Website XR Ready; composed site+cert+monitor with labels
  e6-s04-01.sh   # site answers 200 through the Cilium TLS edge at its path
  e6-s04-02.sh   # root path still clubhouse (no shadowing)
  e6-s05-01.sh   # Prometheus scrapes the composed ServiceMonitor (up==1)
)

for t in "${tests[@]}"; do
  echo ""
  echo "=== ${t} ==="
  bash "${DIR}/${t}"
done

echo ""
echo "OK: E6 exit bundle green — one claim = one monitored site, end to end"

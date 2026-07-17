#!/usr/bin/env bash
# REQ-E10-S05-01 — the software catalog registers the 4 platform components as
# static entities, AND the ingestor is configured to auto-ingest live Website
# XRs (no hand-written per-site catalog-info.yaml). Offline we can only assert
# the STATIC catalog + the ingestor config; the live auto-ingestion is a
# cluster step (chainsaw, skip-gated). We assert:
#   1. a static catalog-info.yaml declares clubhouse/marshal/mulligan/scorecard
#      as Backstage Components
#   2. app-config wires the catalog location(s) + the ingestor ingestAllClaims
#      (live Website XRs -> catalog entities, no per-site file)
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"

CATALOG_DIR="${ROOT}/deploy/portal/backstage/catalog"
CATALOG="${CATALOG_DIR}/catalog-info.yaml"
APPCONFIG="${ROOT}/deploy/portal/backstage/app-config.yaml"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

[[ -f "${CATALOG}" ]]   || fail "missing ${CATALOG}"
[[ -f "${APPCONFIG}" ]] || fail "missing ${APPCONFIG}"

# --- 1) static platform components -------------------------------------------
grep -qE 'kind:[[:space:]]*Component' "${CATALOG}" \
  || fail "catalog-info.yaml must declare Backstage Component entities"
for c in clubhouse marshal mulligan scorecard; do
  grep -qE "name:[[:space:]]*${c}\b" "${CATALOG}" \
    || fail "catalog must register the '${c}' platform component"
done
ok "static catalog registers clubhouse/marshal/mulligan/scorecard as Components"

# --- 2) ingestor ingestAllClaims + catalog location --------------------------
grep -qiE 'ingestAllClaims:[[:space:]]*true' "${APPCONFIG}" \
  || fail "app-config must set kubernetesIngestor ingestAllClaims: true (live Website XRs -> catalog)"
grep -qE '^[[:space:]]*catalog:' "${APPCONFIG}" \
  || fail "app-config must configure the catalog block (static locations)"
grep -qE 'catalog-info\.yaml' "${APPCONFIG}" \
  || fail "app-config catalog must reference the static catalog-info.yaml location"
ok "app-config wires ingestAllClaims + the static catalog location"

echo "PASS: catalog-entities — static platform components + ingestor auto-ingestion configured"

#!/usr/bin/env bash
# REQ-E10-S05-02 — TechDocs renders the repo docs/. Backstage TechDocs uses
# mkdocs; `mkdocs build --strict` must exit 0 (no broken nav / dangling refs).
# Offline: run mkdocs if present; skip-not-fail if the mkdocs toolchain is
# absent (CI installs it) — mirrors the docs-build gates elsewhere.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

# app-config wires TechDocs (asserted in the e10 offline gate); confirm here too
# so this test is self-contained for STRICT_TEST_FILES spec coverage.
APPCONFIG="${ROOT}/deploy/portal/backstage/app-config.yaml"
[[ -f "${APPCONFIG}" ]] || fail "missing ${APPCONFIG}"
grep -qiE 'techdocs' "${APPCONFIG}" || fail "app-config must configure the techdocs plugin"
ok "app-config configures techdocs"

if ! command -v mkdocs >/dev/null 2>&1; then
  echo "SKIP: mkdocs not installed — TechDocs build check skipped (CI installs mkdocs)"
  exit 0
fi

if [[ ! -f "${ROOT}/mkdocs.yml" && ! -f "${ROOT}/mkdocs.yaml" ]]; then
  echo "SKIP: no mkdocs.yml at repo root — TechDocs build check skipped"
  exit 0
fi

( cd "${ROOT}" && mkdocs build --strict >/dev/null ) \
  || fail "mkdocs build --strict failed (broken nav / dangling docs ref)"
ok "mkdocs build --strict exits 0 (TechDocs renders docs/)"

echo "PASS: techdocs-build"

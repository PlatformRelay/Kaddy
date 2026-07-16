#!/usr/bin/env bash
# REQ-E8-S03-01: GitHub Pages publish workflow for scorecard evidence.
#
# Offline publish contract (always):
#   - workflow present, SHA-pinned official Pages actions
#   - fixture capture produces index.html
#   - workflow stages that HTML at _site/ root for upload-pages-artifact
#
# Live Verify (optional, post-publish):
#   SCORECARD_PAGES_LIVE=1 bash tests/smoke/e8-s03-01.sh
#   → curl https://platformrelay.github.io/Kaddy/ must return 200
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"

WF="${SMOKE_ROOT}/.github/workflows/scorecard-pages.yaml"
README="${SMOKE_ROOT}/evidence/README.md"
CAPTURE="${SMOKE_ROOT}/hack/scorecard/capture.sh"
PAGES_URL="https://platformrelay.github.io/Kaddy/"

[[ -f "${WF}" ]] || smoke_fail "missing ${WF} (REQ-E8-S03-01)"
[[ -f "${README}" ]] || smoke_fail "missing ${README}"
[[ -x "${CAPTURE}" ]] || smoke_fail "capture.sh missing or not executable: ${CAPTURE}"

# Triggers: push to main and/or workflow_dispatch.
grep -qE '^\s*workflow_dispatch:' "${WF}" \
  || smoke_fail "scorecard-pages.yaml missing workflow_dispatch trigger"
grep -qE '^\s*push:' "${WF}" \
  || smoke_fail "scorecard-pages.yaml missing push trigger"
grep -qE 'branches:\s*\[main\]|-\s*main' "${WF}" \
  || smoke_fail "scorecard-pages.yaml push trigger must include main"
grep -qE "evidence/" "${WF}" \
  || smoke_fail "scorecard-pages.yaml push paths must include evidence/**"
# Capture/template changes must also republish (paths filter entry, not just the run: step).
grep -qE "^\s*-\s*'hack/scorecard/\*\*'" "${WF}" \
  || smoke_fail "scorecard-pages.yaml push paths must include hack/scorecard/**"

# SEC-5: every uses: line is pinned to a 40-char commit SHA.
while IFS= read -r line; do
  echo "${line}" | grep -qE 'uses:\s*[^@]+@[0-9a-f]{40}' \
    || smoke_fail "unpinned or non-SHA action ref: ${line}"
done < <(grep -E '^\s*-?\s*uses:' "${WF}")

# Official Pages deploy path (not peaceiris) — configure + upload + deploy.
grep -qE 'uses:\s*actions/configure-pages@[0-9a-f]{40}' "${WF}" \
  || smoke_fail "scorecard-pages.yaml must use SHA-pinned actions/configure-pages"
grep -qE 'uses:\s*actions/upload-pages-artifact@[0-9a-f]{40}' "${WF}" \
  || smoke_fail "scorecard-pages.yaml must use SHA-pinned actions/upload-pages-artifact"
grep -qE 'uses:\s*actions/deploy-pages@[0-9a-f]{40}' "${WF}" \
  || smoke_fail "scorecard-pages.yaml must use SHA-pinned actions/deploy-pages"

# Belt-and-suspenders: configure-pages enablement (Pages already on; no-op if present).
grep -qE 'enablement:\s*true' "${WF}" \
  || smoke_fail "configure-pages must set enablement: true (Pages site bootstrap)"

# Fixture-produced (or capture) bundle, not a hand-edited static site.
grep -qE 'hack/scorecard/capture\.sh|SCORECARD_FIXTURES' "${WF}" \
  || smoke_fail "workflow must build scorecard via fixture capture"

# Artifact layout: HTML at site root for project Pages URL.
grep -qE '_site/index\.html|cp .*index\.html.*_site' "${WF}" \
  || smoke_fail "workflow must stage scorecard HTML as _site/index.html"
grep -qE 'path:\s*_site' "${WF}" \
  || smoke_fail "upload-pages-artifact path must be _site"

# Offline: fixture capture produces a real index.html (same path the workflow publishes).
export SCORECARD_FIXTURES=1
RUN_DIR="$("${CAPTURE}" --fixtures --print-run-dir)"
[[ -n "${RUN_DIR}" && -d "${RUN_DIR}" ]] || smoke_fail "capture did not report a run directory"
[[ -f "${RUN_DIR}/index.html" ]] || smoke_fail "missing ${RUN_DIR}/index.html after fixture capture"
grep -qE '<html|scorecard|HighRequestRate|CAPTURE_MODE|fixtures' "${RUN_DIR}/index.html" \
  || smoke_fail "${RUN_DIR}/index.html looks empty or not a scorecard report"

# Pages URL documented for reviewers (evidence/README only in this lane).
grep -Fq "${PAGES_URL}" "${README}" \
  || smoke_fail "evidence/README.md must document Pages URL: ${PAGES_URL}"

# Optional live curl — only after a successful main publish.
if [[ "${SCORECARD_PAGES_LIVE:-0}" == "1" ]]; then
  code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 30 "${PAGES_URL}")" \
    || smoke_fail "live curl failed for ${PAGES_URL}"
  [[ "${code}" == "200" ]] \
    || smoke_fail "live Pages URL returned HTTP ${code}, want 200 (${PAGES_URL})"
  smoke_ok "REQ-E8-S03-01 live Pages URL HTTP 200 (${PAGES_URL})"
fi

smoke_ok "REQ-E8-S03-01 scorecard-pages publish contract (offline) + Pages URL documented"

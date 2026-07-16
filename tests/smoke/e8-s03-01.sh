#!/usr/bin/env bash
# REQ-E8-S03-01: GitHub Pages publish workflow for scorecard evidence.
# Offline structural gate — does not require live Pages (first publish may
# not have run yet). Live Verify path (post-publish):
#   curl -s -o /dev/null -w '%{http_code}' https://platformrelay.github.io/Kaddy/
# must return 200.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"

WF="${SMOKE_ROOT}/.github/workflows/scorecard-pages.yaml"
README="${SMOKE_ROOT}/evidence/README.md"
PAGES_URL="https://platformrelay.github.io/Kaddy/"

[[ -f "${WF}" ]] || smoke_fail "missing ${WF} (REQ-E8-S03-01)"
[[ -f "${README}" ]] || smoke_fail "missing ${README}"

# Triggers: push to main and/or workflow_dispatch.
grep -qE '^\s*workflow_dispatch:' "${WF}" \
  || smoke_fail "scorecard-pages.yaml missing workflow_dispatch trigger"
grep -qE '^\s*push:' "${WF}" \
  || smoke_fail "scorecard-pages.yaml missing push trigger"
grep -qE 'branches:\s*\[main\]|-\s*main' "${WF}" \
  || smoke_fail "scorecard-pages.yaml push trigger must include main"
grep -qE "evidence/" "${WF}" \
  || smoke_fail "scorecard-pages.yaml push paths must include evidence/**"

# SEC-5: every uses: line is pinned to a 40-char commit SHA.
while IFS= read -r line; do
  echo "${line}" | grep -qE 'uses:\s*[^@]+@[0-9a-f]{40}' \
    || smoke_fail "unpinned or non-SHA action ref: ${line}"
done < <(grep -E '^\s*-?\s*uses:' "${WF}")

# Official Pages deploy path (not peaceiris) — upload + deploy.
grep -qE 'uses:\s*actions/upload-pages-artifact@[0-9a-f]{40}' "${WF}" \
  || smoke_fail "scorecard-pages.yaml must use SHA-pinned actions/upload-pages-artifact"
grep -qE 'uses:\s*actions/deploy-pages@[0-9a-f]{40}' "${WF}" \
  || smoke_fail "scorecard-pages.yaml must use SHA-pinned actions/deploy-pages"

# Fixture-produced (or capture) bundle, not a hand-edited static site.
grep -qE 'hack/scorecard/capture\.sh|SCORECARD_FIXTURES' "${WF}" \
  || smoke_fail "workflow must build scorecard via fixture capture"

# Pages URL documented for reviewers (evidence/README only in this lane).
grep -Fq "${PAGES_URL}" "${README}" \
  || smoke_fail "evidence/README.md must document Pages URL: ${PAGES_URL}"

smoke_ok "REQ-E8-S03-01 scorecard-pages workflow SHA-pinned + Pages URL documented"
# Live curl 200 is deferred until first successful publish on main (see header).

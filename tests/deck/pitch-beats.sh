#!/usr/bin/env bash
# REQ-E12d-S02..S05 — content anchors for the five-minute spoken pitch and
# its checkable honesty appendix.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DECK="${ROOT}/slides/slides.md"
fail() { echo "FAIL: $*" >&2; exit 1; }
[ -f "${DECK}" ] || fail "slides/slides.md missing"
grep -qF '<!-- APPENDIX -->' "${DECK}" || fail "no <!-- APPENDIX --> sentinel"

MAIN="$(mktemp "${TMPDIR:-/tmp}/deck-pitch-main.XXXXXX")"
APPX="$(mktemp "${TMPDIR:-/tmp}/deck-pitch-appx.XXXXXX")"
trap 'rm -f "${MAIN}" "${APPX}"' EXIT
sed '/<!-- APPENDIX -->/,$d' "${DECK}" > "${MAIN}"
sed -n '/<!-- APPENDIX -->/,$p' "${DECK}" > "${APPX}"

main_has() { grep -Eqi "$1" "${MAIN}" || fail "MAIN missing: $2"; }
appx_has() { grep -Eqi "$1" "${APPX}" || fail "APPENDIX missing: $2"; }
main_lacks() { grep -Eqi "$1" "${MAIN}" && fail "MAIN must not contain: $2" || true; }

main_has 'Caddy.*Prometheus|Prometheus.*Caddy' "exercise opening"
main_has 'platform engineer|built a platform' "platform framing"
main_has 'provider-gridscale' "early provider contribution"
main_has 'marketplace\.upbound\.io' "Marketplace link"
main_has 'pull/(509|510|511)' "upstream PR links"
main_has 'contribution|customer value|value' "positive contribution framing"
main_has 'filed.*open|open.*review|not merged' "PR honesty"
main_lacks 'D-042' "D-042 spoken arc"
main_lacks 'Known cloud risk|GSK node public exposure' "cloud-exposure card"
main_has 'teardown|time-boxed|cost' "cost-governance language"
main_has 'Website (claim|intent)|Website intent' "Website input"
main_has 'Composition' "composition"
main_has 'HTTPRoute|ServiceMonitor' "concrete governed resource"
main_has 'portal.*designed|designed.*portal' "portal design"
main_has 'platform API|XRD' "portal API"
main_lacks 'runtime remains open|not running yet' "stale portal runtime wording"
main_has 'Prometheus|metrics' "delivery signal"
main_has 'blue-green|canary' "delivery mode"
main_has 'promote|rollback' "delivery outcome"
main_has 'AI|assistant|agent' "AI working method"
main_has 'OpenSpec|spec-to-test|REQ-|Verify:' "spec-to-test loop"

appx_has 'Nix.*build|build.*Nix' "Nix build honesty"
appx_has 'boot-to-serve.*(open|remain)|boot proof' "Nix boot gap"
appx_has 'filed.*open|open.*not merged|filed.*not merged' "upstream PR honesty"
appx_has 'Backstage.*(narrative|talk).*(proof|E10)|E10.*(proof|runtime)' "Backstage narrative/proof boundary"

# Humorous deck title (frontmatter + opening CoverArt) — keep the joke, polish the wording.
grep -Eq 'title:.*gone wildly overboard into platform engineering' "${DECK}" \
  || fail "deck frontmatter title must use the overboard joke"
grep -A6 '<CoverArt' "${DECK}" | head -8 | grep -Fq 'gone wildly overboard into platform engineering' \
  || fail "opening CoverArt title must use the overboard joke"
grep -Eqi 'two[- ]VM.*monitoring|monitoring.*two[- ]VM' "${DECK}" \
  || fail "deck title must keep the two-VM monitoring exercise joke"

# Live honesty after caddy-lab rename + portal NetPol + grafana route (2026-07-20 probes).
# Stale 404 claims for caddy.lab must fail; deck + slides README + root README record 200s.
if grep -Eqi 'caddy\.lab\.platformrelay\.dev.*(currently.*(HTTPS )?404|returns.*(HTTPS )?404)' "${DECK}"; then
  fail "deck claims stale caddy.lab HTTPS 404 — expect sticky HTTPS 200"
fi
if grep -Eqi 'caddy\.lab\.platformrelay\.dev.*(currently.*(HTTPS )?404|returns.*(HTTPS )?404)' "${ROOT}/slides/README.md"; then
  fail "slides README claims stale caddy.lab HTTPS 404 — expect sticky HTTPS 200"
fi
if grep -Eqi 'caddy\.lab\.platformrelay\.dev.*(currently.*(HTTPS )?404|returns.*(HTTPS )?404)' "${ROOT}/README.md"; then
  fail "root README must not claim stale caddy.lab HTTPS 404 (live sticky 200)"
fi
grep -Eqi 'caddy\.lab\.platformrelay\.dev.*(HTTPS )?200|caddy\.lab.*(HTTPS )?200' "${DECK}" \
  || fail "deck must record caddy.lab HTTPS 200"
grep -Eqi 'caddy\.lab\.platformrelay\.dev.*(HTTPS )?200|caddy\.lab.*(HTTPS )?200' "${ROOT}/slides/README.md" \
  || fail "slides README must record caddy.lab HTTPS 200"
grep -Eqi 'caddy\.lab\.platformrelay\.dev.*HTTPS \*\*200\*\*|caddy\.lab.*HTTPS \*\*200\*\*|caddy\.lab.*(HTTPS )?200' "${ROOT}/README.md" \
  || fail "root README must record caddy.lab HTTPS 200"
grep -Eqi 'portal\.lab.*(HTTPS )?200|portal\.lab.*HTTPS \*\*200\*\*' "${ROOT}/README.md" \
  || fail "root README must record portal.lab HTTPS 200"
grep -Eqi 'grafana\.lab.*(HTTPS )?200|grafana\.lab.*HTTPS \*\*200\*\*' "${ROOT}/README.md" \
  || fail "root README must record grafana.lab HTTPS 200"

echo "OK: E12d pitch and honesty anchors are present"

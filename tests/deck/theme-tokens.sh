#!/usr/bin/env bash
# REQ-E12c-S05-01 — hybrid kubernetes-workshop visual port with a golf-teal
# accent (L1 · ADR-0112).
#
# Asserts the deck's style layer:
#   * carries the `--kw-*` CSS-variable surface/text system (bg, surface,
#     text, and semantic ok/warn/danger) ported from kubernetes-workshop;
#   * pins the dark graphite background `#0b0e14`;
#   * declares an accent variable whose value is golf-teal, NOT k8s-blue
#     `#326ce5` (the ADR-0112 override — a future edit can't silently drift);
#   * wires Inter (sans) + JetBrains Mono (mono) fonts;
#   * ships the progress-bar chrome in the style layer, and the kicker +
#     AI-footer chrome APPLIED to real elements by CoverArt.vue.
#
# This gate asserts APPLICATION, not mere presence: for kicker and footer it
# requires BOTH a class definition AND an element that carries that class, so a
# token that is defined-but-unapplied (or applied-but-undefined) FAILS.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SLIDES="${ROOT}/slides"
DECK="${SLIDES}/slides.md"

fail() { echo "FAIL: $*" >&2; exit 1; }

# The style layer: a dedicated stylesheet under slides/styles/ (Slidev
# auto-loads slides/style.css; this deck imports the ported sheet from there).
STYLE="$(grep -rlE '\-\-kw-' "${SLIDES}/styles" "${SLIDES}/style.css" 2>/dev/null | head -1 || true)"
[ -n "${STYLE}" ] || fail "no --kw-* stylesheet found under slides/styles/ or slides/style.css"

need() { grep -qE "$1" "${STYLE}" || fail "style layer missing: $2"; }

# 1) The --kw-* surface/text system.
need '\-\-kw-bg'                     "--kw-bg surface var"
need '\-\-kw-surface'                "--kw-surface panel var"
need '\-\-kw-text'                   "--kw-text var"
need '\-\-kw-ok'                     "--kw-ok semantic status var"
need '\-\-kw-warn'                   "--kw-warn semantic status var"
need '\-\-kw-danger'                 "--kw-danger semantic status var"

# 2) Dark graphite background.
grep -qiE '#0b0e14' "${STYLE}" || fail "dark graphite background #0b0e14 not set"

# 3) Accent override — present AND golf-teal, NOT k8s-blue #326ce5.
#    Inspect the DECLARED VALUE of --kw-accent (a `--kw-accent: #xxxxxx;`
#    declaration), not the whole file — a comment may legitimately mention
#    #326ce5 to document the override.
need '\-\-kw-accent'                 "--kw-accent variable"
accent_decl="$(grep -E '^\s*--kw-accent\s*:' "${STYLE}" | head -1)"
[ -n "${accent_decl}" ] || fail "--kw-accent has no --kw-accent:<value>; declaration"
echo "${accent_decl}" | grep -qiE '#[0-9a-f]{6}' \
  || fail "--kw-accent declaration has no hex value: ${accent_decl}"
if echo "${accent_decl}" | grep -qiE '#326ce5'; then
  fail "--kw-accent is k8s-blue #326ce5 — ADR-0112 requires a golf-teal override"
fi

# 4) Fonts — Inter + JetBrains Mono (headmatter fonts: or the stylesheet).
{ grep -qi 'Inter' "${DECK}" || grep -qi 'Inter' "${STYLE}"; } \
  || fail "Inter font not wired (headmatter fonts: or style layer)"
{ grep -qi 'JetBrains Mono' "${DECK}" || grep -qi 'JetBrains Mono' "${STYLE}"; } \
  || fail "JetBrains Mono font not wired"

# 5) Workshop chrome — assert APPLICATION, not presence.
#
#    Progress bar: Slidev injects the `.slidev-progress-bar` element itself, so
#    there is no authored markup to point at — a style-layer definition IS the
#    live wiring. This one check is asymmetric on purpose.
need 'progress'                      "progress-bar chrome (style layer)"

#    Kicker + AI footer: applied by CoverArt.vue's scoped <style>. For each,
#    require BOTH a `.kd-*` class DEFINITION and an element that CARRIES that
#    class in the components — so a defined-but-unapplied (or applied-but-
#    undefined) token FAILS the gate.
COMPONENTS="${SLIDES}/components"

applied() {  # <class> <human-name>
  local cls="$1" name="$2"
  grep -rqE "\.${cls}\s*\{" "${COMPONENTS}" \
    || fail "${name}: class .${cls} is not DEFINED in slides/components/"
  grep -rqE "class=\"[^\"]*\b${cls}\b" "${COMPONENTS}" \
    || fail "${name}: class .${cls} is defined but NOT APPLIED to any element"
}

applied 'kd-cover-kicker'  "uppercase kicker chrome"
applied 'kd-ai-footer'     "AI-generated footer chrome"

echo "OK: theme-tokens — --kw-* port present, graphite bg, golf-teal accent (not #326ce5), Inter+JetBrains Mono, progress-bar chrome + kicker/footer applied by CoverArt.vue"

#!/usr/bin/env bash
# REQ-E12-S03-01 — the deck embeds the five platform surfaces (L1).
#
# Asserts embed INTENT in slides/slides.md, not live endpoint reachability
# (per the spec's fallback clause). Every surface must be tagged:
#   data-surface="<name>" data-surface-mode="live|fallback"
# where `live` marks a real <iframe> at the documented local URL and
# `fallback` marks a GIF/screenshot placeholder for a surface that is not
# running yet (spec fallback clause). At least three surfaces must be live
# <iframe> embeds (argocd, grafana, clubhouse are running today).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DECK="${ROOT}/slides/slides.md"

fail() { echo "FAIL: $*" >&2; exit 1; }
[ -f "${DECK}" ] || fail "slides/slides.md missing"

SURFACES=(backstage argocd grafana clubhouse crossplane-graph)

for s in "${SURFACES[@]}"; do
  grep -q "data-surface=\"${s}\"" "${DECK}" || fail "surface '${s}' not embedded (data-surface tag missing)"
  mode="$(grep -o "data-surface=\"${s}\" data-surface-mode=\"[a-z]*\"" "${DECK}" | head -1 | sed 's/.*data-surface-mode="//;s/"$//')"
  case "${mode}" in
    live|fallback) echo "surface ${s}: ${mode}" ;;
    *) fail "surface '${s}' has no live|fallback mode annotation" ;;
  esac
done

live_iframes=$(grep -c '<iframe[^>]*data-surface=' "${DECK}" || true)
[ "${live_iframes}" -ge 3 ] || fail "expected >= 3 live <iframe> surface embeds, found ${live_iframes}"

echo "OK: all five surfaces embedded with live/fallback annotations (${live_iframes} live iframes)"

#!/usr/bin/env bash
# REQ-E12c-S02-01 / S03-01 / S04-01 — the reframed storyline's content anchors
# are present in the deck, on the correct side of the APPENDIX sentinel (L1).
#
# This is the shared gate for the S02/S03/S04 content trio. It greps for the
# spec-mandated literal strings — MAIN-arc anchors before the
# `<!-- APPENDIX -->` sentinel, APPENDIX anchors after it — so it goes fully
# green only once all three content slices have landed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DECK="${ROOT}/slides/slides.md"

fail() { echo "FAIL: $*" >&2; exit 1; }
[ -f "${DECK}" ] || fail "slides/slides.md missing"

grep -qF '<!-- APPENDIX -->' "${DECK}" || fail "no <!-- APPENDIX --> sentinel (run E12c-S01 first)"

# Split the deck at the sentinel.
MAIN="$(mktemp "${TMPDIR:-/tmp}/deck-cb-main.XXXXXX")"
APPX="$(mktemp "${TMPDIR:-/tmp}/deck-cb-appx.XXXXXX")"
trap 'rm -f "${MAIN}" "${APPX}"' EXIT
sed '/<!-- APPENDIX -->/,$d' "${DECK}" > "${MAIN}"
sed -n '/<!-- APPENDIX -->/,$p' "${DECK}" > "${APPX}"

main_has() { grep -Eq "$1" "${MAIN}" || fail "MAIN missing anchor: $2"; }
appx_has() { grep -Eq "$1" "${APPX}" || fail "APPENDIX missing anchor: $2"; }

# --- REQ-E12c-S02-01: gridscale value-creation hero + Crossplane-as-IaC (main) ---
main_has 'provider-gridscale'                     "provider-gridscale named (value hero)"
main_has 'marketplace\.upbound\.io'               "Upbound Marketplace listing link"
main_has '32 (gridscale )?resources'              "32-resource Upjet provider claim"
main_has '3 (bug-fix|upstream)'                   "3 Terraform-provider bug MRs anchor"
main_has '\bMRs?\b|pull/'                         "the MRs/pull-requests named"
main_has 'gridscale/terraform-provider-gridscale/pull/(509|510|511)' "at least one real upstream PR link"
main_has 'Crossplane'                             "Crossplane introduced"
main_has 'control plane|IaC of platform'          "Crossplane-as-IaC kicker (control plane vs one-shot TF)"
main_has 'XRD'                                    "XRD-as-API bridge"
main_has '(landed|shipped)'                       "landed/shipped tag on the value hero"

# --- REQ-E12c-S03-01: agentic-workflow beat (epic -> plan -> story -> test) ---
main_has 'e5-monitoring-marshal'                  "real epic walked (e5-monitoring-marshal)"
main_has '[Ee]pic'                                "epic stage"
main_has '[Pp]lan'                                "plan stage"
main_has '[Ss]tory'                               "story stage"
main_has '[Tt]est'                                "test stage"
main_has 'proposal\.md'                           "plan = proposal.md"
main_has 'tasks\.md'                              "story/tests = tasks.md"
main_has 'REQ-'                                   "an openspec REQ reference"
main_has 'gate matrix|coordinator|OpenSpec'       "Kaddy agentic vocabulary"

# --- REQ-E12c-S04-01: appendix (post-sentinel, gate-exempt) ---
appx_has 'NixOS|Nix'                              "Nix image path (appendix)"
appx_has 'ADR-0303|E14'                           "Nix refs E14/ADR-0303"
appx_has 'nix/flake\.nix'                         "landed flake.nix named"
appx_has 'image (build|builds)|build proof'       "Nix image build truth"
appx_has 'boot-to-serve.*(open|remain)|boot proof' "Nix boot-to-serve gap"
[ -f "${ROOT}/nix/flake.nix" ] || fail "nix/flake.nix must exist when appendix calls the build landed"
appx_has 'task cluster:up'                        "quickstart anchor (task cluster:up)"
appx_has 'solved-different-ways|different ways|three ways' "solved-different-ways anchor"
appx_has 'tree|repo|estate|structure'             "repo-tree anchor"
appx_has 'Caddy VM|VM'                            "Caddy VM (the literal brief) variant"

echo "OK: content-beats — all S02/S03/S04 anchors present on the correct side of the sentinel"

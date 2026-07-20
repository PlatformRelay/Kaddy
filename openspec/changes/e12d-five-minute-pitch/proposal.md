<!-- markdownlint-disable MD013 -->
# Proposal — E12d Five-minute pitch deck (exercise → platform)

## Problem

The current Slidev deck (worktree `kaddy-deck-refresh` / `slides/slides.md`) is strong as a
**~15–20 slide technical walkthrough**, but it is the wrong shape for a **~5-minute stakeholder
pitch**. Operators and interviewers who need the sales-friendly arc hear too much development
history (D-042 edge migration), too many live `127.0.0.1` iframes, and a portal slide that still
says runtime remains open — while the talk they want is: *exercise → I call myself a platform
engineer → I built a platform (and shipped real gridscale value early)*.

**E12c** ([e12c-deck-docs-refresh](../e12c-deck-docs-refresh/)) targeted a **~15-minute** main deck
plus appendix and is **partially stale vs the worktree deck**: appendix sentinel, provider-gridscale
hero, Nix flake honesty, agentic/OpenSpec beat, theme tokens, and several content anchors already
exist in the refresh worktree / `tests/deck/`. Continuing to chase E12c’s raised word/`sectionTime`
ceilings fights the new talk budget.

## Challenge / recommendation

| Option | Verdict |
| --- | --- |
| **A. Finish E12c as written (~15 min)** | Reject for the pitch use-case — wrong budget; narrative REQs drift from current deck reality. |
| **B. Patch E12c in place** | Risky — mixes polish (badges/styling) with a contradictory time envelope. |
| **C. New epic E12d (Recommended)** | Clean supersession of *narrative/budget* REQs; leave orthogonal E12c polish alone. |

**Recommend E12d.** It reframes the spoken path to **~5 minutes (~8–12 slides)**, supersedes
unfinished E12c *narrative/budget* REQs where they conflict, and does **not** duplicate E12c-S05 /
S07 / S08 / S09 (styling, README badges, provider-gridscale badge/release, docs hygiene) if those
remain open — they stay as optional polish lanes.

## Reframed storyline (spoken spine)

> **"The exercise was a Caddy VM + Prometheus. I call myself a platform engineer — so I built a
> platform around it. Early on I also shipped real value for gridscale customers."**

Spoken beat order (keep the seven canonical `beat:` markers as a *subsequence*; non-canonical
slides may sit between them, but the **spoken path** is short):

1. **Opening** — brief = Caddy VM + Prometheus; platform around it.
2. **Value early** — `provider-gridscale` + three upstream PRs to
   `terraform-provider-gridscale` (#509–#511) framed as **first contribution / customer value**,
   not “open leftovers”.
3. **Website intent → governed resources** — simple claim → composition → resources (no animation
   reliance).
4. **Controls** — secrets, policy, identity, audits; **teardown / time-boxed lab cost**; **no**
   “Known cloud risk / GSK node public exposure” card on the main path.
5. **Portal** — “portal designed, platform API already exists”; **narrative assumes Backstage
   deployed** for the talk (not “runtime remains open”).
6. **Delivery (mulligan)** — stakeholder language: Prometheus metrics drive automatic blue-green
   (or canary) promote / rollback.
7. **How I worked** — built with AI + spec-to-test loop; optional sample OpenSpec snippet on-slide
   (may replace/reframe the current agentic beat).
8. **Close** — evidence / what ships; Nix only brief or appendix (build landed, boot-to-serve open).

**Demote from main arc:** D-042 edge-controller migration slide (appendix OK). Deep architecture,
multi-path detail, and live iframe demos move behind `<!-- APPENDIX -->` or become static
screenshot/GIF surfaces.

## Scope

1. **Lower main budgets** — spoken path ≈ 5 min: main `sectionTime` in **[240, 360] s**, main
   spoken words in **[450, 900]**; main content slides before appendix in **[8, 12]** (covers may be
   extra if tagged). Reconcile E12 / E12c range notes in those specs.
2. **Narrative surgery** on `slides/slides.md` (+ `slides/README.md` honesty) per the spine above.
3. **Pitch-safe surfaces** — prefer static screenshots/GIFs or public lab URLs; **do not depend on
   live `127.0.0.1` / port-forward iframes** for the 5-minute path. Update
   `tests/deck/iframe-surfaces.sh` so the pitch path is not forced to keep ≥3 live iframes.
4. **Honesty boundaries** (must remain true somewhere reviewers can check — appendix, README, or an
   explicit footnote; never silently oversell):
   - Nix: image **build** landed; **boot-to-serve** still open (E14 / ADR-0303).
   - Upstream PRs: **filed and open** — contribution framed positively; merge not claimed.
   - Backstage: deck **narrative** may assume deploy; **runtime proof** remains E10 live cycle
     (not implemented by this epic).
5. **Gate updates** — extend/replace `content-beats.sh` anchors for contribution framing, portal
   assumed-deployed language, D-042 absence from main, cloud-risk card absence, teardown callout,
   and AI/OpenSpec sample.

## Non-goals

- **Do not implement Backstage runtime** (no portal image build, no Dex client live cycle).
- **Do not finish Nix boot-to-serve**.
- **Do not** re-litigate E12c-S05 / S07 / S08 / S09 polish unless blocked by this pitch.
- **No new presentation tool** — Slidev-in-repo stays.
- **No product-code lanes** beyond deck/docs/tests under `slides/` and `tests/deck/`.

## Dependencies / links

- **E12 / E12b / E12c** — E12d **supersedes** E12c-S01 budget REQs and conflicting S02/S03/S04
  *narrative* REQs for the pitch; appendix mechanism from E12c-S01 is retained.
- **E6g / `provider-gridscale`** + upstream TF PRs #509–#511 — value hero source of truth.
- **E7 mulligan** — delivery proof already landed; this epic only changes *how* it is told.
- **E10** — live Backstage bring-up is **out of scope**; optional **E10-S07** lists concrete
  remaining steps (see ROADMAP). Deck may *assume* deploy for talk narrative.
- **E14 / ADR-0303** — Nix honesty (build vs boot-to-serve).
- Surfaces protocol: reuse `slides/recording-guide.md` (E12c-S06) where helpful; do not re-author
  unless the pitch path needs a stricter “static-first” clause.
- Test gates: `tests/deck/{appendix-boundary,script-wordcount,narrative-beats,content-beats,iframe-surfaces,speaker-notes-coverage,slidev-build,exit-recording-ready}.sh` (+ new pitch-path helpers as specified).

## Counterpoints recorded

- Assuming Backstage “deployed” in the narrative risks overselling if a reviewer opens the open-list
  slide — mitigated by an explicit honesty boundary (appendix / README) and by keeping E10 live
  proof as a separate story.
- Dropping the ≥3 live-iframe floor weakens “show the running system” demos — acceptable for a
  5-minute pitch; deep demos remain in appendix / recording / E12b video.
- Positive framing of open upstream PRs must not imply merges — gates assert “filed” / PR links,
  not “merged”.

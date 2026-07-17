<!-- markdownlint-disable MD013 -->
# Proposal — E12c Deck + docs refresh (storyline, styling, badges, recording)

## Problem

The E12 deck (`slides/slides.md`, 15 sections, seriph theme, Mœbius CoverArt system, `tests/deck/`
gates) is honest and well-built, but it under-tells the story that matters most for a **gridscale
Platform Engineer** application. Three things are true today:

1. **The single strongest real story is missing.** The applicant has already *created external value
   for gridscale*: a published Crossplane provider (`provider-gridscale`, 32 gridscale resources via
   Upjet, on the Upbound Marketplace) and **three merge requests filed against the gridscale
   Terraform provider** fixing real bugs. The current deck mentions gridscale only as a **deferred
   Phase-2 substrate** — the value-creation story is absent. This is the biggest gap and it is
   genuinely *landed*, not designed.

2. **The "how" — the agentic engineering practice — is one footer line.** The project's defining
   differentiator is its way of working: OpenSpec-driven `epic → plan → story → test` with `Verify:`
   / `Test:` per requirement, TDD-first, a gate matrix, replayable audits, and a coordinator+worker
   subagent harness. The deck reduces this to a single sentence.

3. **Styling, badges, and reproducibility polish are thin.** The deck's covers are all placeholder
   SVGs (no art generated). The Kaddy `README.md` has **zero badges**. The sibling
   `provider-gridscale` README has a **failing Scorecard badge and a failing Release badge**. And
   several requested emphases — Crossplane-as-IaC-for-platform-engineering, the NixOS path, a
   repo-tree/quickstart/tools orientation, and "the exercise solved in different ways" — have no home
   in the deck.

## Reframed storyline (the spine this change installs)

> **"I call myself a platform engineer, so I submit a platform — and I made something genuinely
> useful for gridscale along the way."**

The arc keeps the existing golf/caddie metaphor and the radical **landed-vs-designed honesty** that
is the deck's credibility asset, and threads these beats through it:

- **Value first, not last.** The gridscale Crossplane provider + 3 Terraform-provider bug MRs become
  an early **hero** — real, shipped, external value for the audience's own product.
- **Crossplane as a first-class IaC tool for platform engineering** — introduced properly (control
  plane vs. one-shot Terraform; composition; the XRD-as-API that projects into the portal), not just
  as plumbing behind the portal slide.
- **The agentic practice, told as a workflow** — `epic → plan → story → test`, guardrails-wrap-a-
  nondeterministic-core, replayable audits — lifting the framing (not the org-specific theme) from
  `~/Projects/Presentations/agentic-coding-workspace/safe-agentic-coding`.
- **Solved-different-ways** — the same tenant delivered as a Caddy VM (the literal brief), a rich K8s
  variant, and (designed) a Nix golden image — deliberate multi-path engineering.
- **The NixOS path** — presented **as the designed Phase-3 path** (E14 / ADR-0303; Packer is today's
  image path, there is no `flake.nix` yet). Held to the honest-scorecard line so it strengthens
  credibility rather than spending it.

## Scope

Target shape (per operator decision 2026-07-17): a **~15-minute main deck plus a gate-exempt
appendix**, and a **hybrid k8s-workshop visual port** (workshop chrome + fonts, golf-teal accent).

1. **Storyline restructure** — add main-arc sections for gridscale value-creation, Crossplane-as-IaC,
   and the agentic workflow; move NixOS-path, repo-tree, quickstart+tools, and solved-different-ways
   detail into a new **appendix** (§A-*). Keep the 7 canonical `beat:` markers in subsequence order.
2. **Raise the time/word ceilings** for the *main* deck and make the **appendix exempt** from the
   `sectionTime` and word-count sums (a minimal `tests/deck/` change) — so "some aspects in the
   appendix" is a real escape hatch, not a budget trap. Main target ≈ 15 min (≤ 1000 s, ≤ 2200 words).
3. **Hybrid styling port** — adopt the kubernetes-workshop `--kw-*` surface/text system, dark graphite
   background, Inter + JetBrains Mono fonts, and the footer + progress-bar + kicker/chip chrome, but
   keep a **golf-teal accent** (fairway green / sea teal) so the chrome matches the coastal-links
   Mœbius covers. Recorded as **ADR-0112**.
4. **Badges** — add a CI/docs/license/Pages badge row to Kaddy `README.md`; **fix the two failing
   `provider-gridscale` badges** (Scorecard → durable score badge; Release → backfill GitHub Releases
   for existing tags + a tag-triggered `release.yml`). The provider-gridscale fixes are a **separate
   repo and partly outward-facing** — speced here, executed as their own lane with explicit go-ahead.
5. **New Mœbius cover prompts** for the added sections, in the *existing* established Mœbius/Giraud
   style (keep stable art IDs S00–S14, append S15+). Drafts in `new-cover-prompts.md`.
6. **GIF/screenshot recording protocol** — a durable operator guide (`slides/recording-guide.md`):
   what to record, how, and a strict naming convention wired to the `iframe-surfaces.sh` fallback
   contract, so recorded GIFs drop into named slots with zero code churn.
7. **Docs hygiene** — fix `docs/HIRING_EXERCICSE.md` typo (→ `HIRING_EXERCISE.md` with redirect note),
   fix the broken `openspec/changes/e14-nix-golden-images/` ROADMAP link, and caveat the unpublished
   deck Pages URL.

## Non-goals

- **No slide execution in the design lane.** This change is the durable, gated *spec*; rewriting
  `slides.md`, generating cover art, and recording GIFs are later `/agent-loop` lanes.
- **No new presentation tool** — stays Slidev-in-repo, built and tested like everything else.
- **No overselling.** NixOS stays *designed*; every added section is explicitly tagged landed vs
  designed against the §03 scorecard.
- **No full custom-layout theme rewrite** — the deck keeps its CoverArt/seriph base; the port is
  palette + chrome + kicker/chip motifs, not a from-scratch theme.

## Decisions (operator, 2026-07-17)

- **Talk length:** ~15-min main deck + gate-exempt appendix (raise caps, edit the two REQ specs).
- **Color identity:** Hybrid — workshop `--kw-*` surfaces/fonts/chrome, **golf-teal accent** (ADR-0112).

## Dependencies / links

- **E12 / E12b** — supersedes nothing; extends the deck scope and its `tests/deck/` gates.
- **E6g** (`provider-gridscale`, sibling repo) — the value-creation hero's source of truth.
- **E14 / ADR-0303** — the NixOS path presented as designed.
- **kubernetes-workshop** (`../../kubernetes-workshop`) — the visual reference being ported.
- **safe-agentic-coding** deck — the agentic-workflow framing being adapted.
- Test gates: `tests/deck/{narrative-beats,speaker-notes-coverage,script-wordcount,iframe-surfaces,slidev-build,exit-recording-ready}.sh`.

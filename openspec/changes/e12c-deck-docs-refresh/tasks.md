<!-- markdownlint-disable MD013 -->
# Tasks — E12c Deck + docs refresh

**Gate:** `task test:spec` + `tests/deck/exit-recording-ready.sh`
**Activation:** ready now (deck + docs exist; provider-gridscale fixes gated on operator go-ahead).
TDD-ordered vertical slices — failing test first, then content.

> **Boundary:** the design lane (this change) is spec-only. Each slice below is a later `/agent-loop`
> execution unit. Do not edit `slides.md` until executing S01+.

## E12c-S01 — Appendix-exempt gates + raised main budget

- [ ] Add failing `tests/deck/appendix-boundary.sh` (asserts `<!-- APPENDIX -->` sentinel splits main
      vs appendix; main-only sums honored)
- [ ] Edit `tests/deck/script-wordcount.sh` — stop summing at the sentinel; raise main range to
      `[1400, 2200]`
- [ ] Edit `tests/deck/narrative-beats.sh` — sum `sectionTime` + require the 7 beats only pre-sentinel;
      raise main range to `[600, 1000]`
- [ ] Update REQ-E12-S02-02 + REQ-E12-S04-01 ranges in `openspec/changes/e12-slidev-deck/specs/deck/spec.md`
      with a reconciliation note pointing at E12c
- [ ] Insert the `<!-- APPENDIX -->` sentinel + a first appendix divider into `slides.md`
- [ ] Gate: `tests/deck/appendix-boundary.sh` green

## E12c-S02 — gridscale value-creation hero + Crossplane-as-IaC (main arc)

- [ ] Add failing `tests/deck/content-beats.sh` (greps required anchors per REQ-E12c-S02/S03/S04)
- [ ] New section: **"Value already shipped for gridscale"** — provider-gridscale (32 resources,
      Upjet, Marketplace v0.1.1) + the 3 Terraform-provider bug MRs (link each). Tag **landed**.
- [ ] New section: **"Crossplane — the IaC of platform engineering"** — control plane vs one-shot TF,
      composition, XRD-as-API projecting into the portal (bridges into existing §08)
- [ ] Cover art: add S15/S16 prompts to `slides/image-prompts.md` from `new-cover-prompts.md`
- [ ] Speaker notes on both new slides (≥ 25 words); keep `beat:` subsequence intact
- [ ] Gate: `content-beats.sh` + `speaker-notes-coverage.sh` + `narrative-beats.sh` green

## E12c-S03 — Agentic-workflow beat (epic → plan → story → test)

- [ ] New section walking `e5-monitoring-marshal`: epic (change folder) → plan (`proposal.md`) →
      story/test (`tasks.md` + a REQ block with `Test:`/`Verify:`) → the real test artifact
- [ ] Adapt safe-agentic-coding framing: guardrails-wrap-nondeterminism; autonomy-is-earned;
      replayable audits. Kaddy vocabulary only (OpenSpec, gate matrix, coordinator+worker subagents)
- [ ] Cover art: S17 prompt from `new-cover-prompts.md`
- [ ] Speaker notes + gate: `content-beats.sh`

## E12c-S04 — Appendix (post-sentinel, gate-exempt)

- [ ] NixOS-path slide — tagged **designed** (E14/ADR-0303; Packer today; no `flake.nix`)
- [ ] Repo-tree slide — top-level dirs + one-line purpose (from proposal's tree)
- [ ] Quickstart + tools slide — `task cluster:up` → smoke → `task demo`; tool matrix
- [ ] Solved-different-ways slide — Caddy VM (brief) · rich K8s · Nix golden image (designed)
- [ ] Cover art: S18–S21 prompts (optional — appendix may reuse placeholder)
- [ ] Speaker notes on each (coverage still required); gate: `content-beats.sh` + `appendix-boundary.sh`

## E12c-S05 — Hybrid k8s-workshop styling port (ADR-0112)

- [ ] Write `docs/adr/0112-deck-visual-identity.md` (hybrid decision) — DONE in design lane
- [ ] Add `slides/styles/` (or headmatter) with the `--kw-*` palette, **teal accent override**,
      Inter + JetBrains Mono, footer + progress-bar + kicker/chip chrome
- [ ] Add failing `tests/deck/theme-tokens.sh` (greps `--kw-*` + asserts accent ≠ `#326ce5`)
- [ ] Gate: `slidev-build.sh` + `theme-tokens.sh` green

## E12c-S06 — GIF recording protocol

- [ ] Write `slides/recording-guide.md` (what/how/naming) — DONE in design lane
- [ ] Wire `data-surface-mode="fallback"` slots for the recorded surfaces; keep ≥ 3 live iframes
- [ ] Gate: `iframe-surfaces.sh` green

## E12c-S07 — Kaddy README badges

- [ ] Add failing `tests/deck/readme-badges.sh`
- [ ] Add CI/deck/license/docs badge row to `README.md`
- [ ] Gate: `readme-badges.sh` green

## E12c-S08 — provider-gridscale badge fixes (SEPARATE REPO — go-ahead required)

- [ ] **[BLOCKED on operator go-ahead — outward-facing]** In `../provider-gridscale`: swap README
      line 10 to the `api.securityscorecards.dev` score badge
- [ ] **[BLOCKED]** `gh release create v0.1.1 --generate-notes`; then `v0.1.0`
- [ ] **[BLOCKED]** Add `.github/workflows/release.yml` (tag-triggered `gh release create`)
- [ ] Verify: `gh release list` shows v0.1.1; scorecard badge SVG resolves

## E12c-S09 — Docs hygiene

- [ ] Rename `docs/HIRING_EXERCICSE.md` → `docs/HIRING_EXERCISE.md`; update nav + link refs
- [ ] Fix/remove broken ROADMAP `e14-nix-golden-images/` link; caveat unpublished Pages URL
- [ ] Gate: markdownlint clean; no `HIRING_EXERCICSE` refs remain

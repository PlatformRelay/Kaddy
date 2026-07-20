# Spec — E12 Slidev showcase deck

Epic: E12 (cuttable, late-parallel) · **Refs:** gridscale Platform Engineer exercise (recorded
5–10 min walkthrough) · `slides/` Slidev project · E10 (portal), E-Caddy-MVP (serves the deck),
E5 (marshal), E7 (mulligan), E8 (scorecard) · `docs/ROADMAP.md` ("E11, E12 in parallel")
**Levels:** meta build-check · L1 golden-file/lint (deck is a docs/deck epic — no cluster REQs)

> **Design-first / gated.** These REQs are authored now to durably record the deck-as-video-spine
> scope; **implementation is gated** on the platform surfaces the deck embeds existing (E10 portal,
> E-Caddy-MVP site, E5/marshal, E7/mulligan, E8/scorecard). Test artifacts live under `tests/deck/`
> and are enumerated so the epic-exit `STRICT_TEST_FILES` gate binds when the epic activates. Level
> tags per ADR-0701 (L0 tofu · L1 conftest/promtool/golden-file/lint · L2 Chainsaw · L3 k6 · L4
> scorecard).

---

## REQ-E12-S01-01: Slidev scaffold builds a reproducible static SPA

**Priority:** must · **Story:** E12-S01 · **Level:** meta · **TDD:** failing build check first
**Given** the Slidev project in `slides/` (`package.json` + `slides.md`)
**When** the deck build task runs in CI
**Then** `slidev build` exits 0 and emits a static SPA under `slides/dist/` — the deck can be served
as a static artifact (also the content the clubhouse/Caddy tenant serves)
**Test:** `tests/deck/slidev-build.sh`
**Verify:**

```bash
tests/deck/slidev-build.sh   # runs `npx slidev build slides/slides.md` (or `task deck:build`), asserts exit 0 + slides/dist/ present
```

---

## REQ-E12-S02-01: Word-by-word speaker notes on every slide

**Priority:** must · **Story:** E12-S02 · **Level:** L1 · **TDD:** failing coverage check first
**Given** every slide in `slides/slides.md`
**When** the coverage check counts `---` slide separators against `<!-- ... -->` presenter-note blocks
**Then** the note-block count equals the slide count (**every** slide has a note), and each note
exceeds a minimum word count so it is a **verbatim spoken script**, not a stub or bullet hints
**Test:** `tests/deck/speaker-notes-coverage.sh`
**Verify:**

```bash
tests/deck/speaker-notes-coverage.sh   # asserts note-block count == slide count AND each note >= min words
```

---

## REQ-E12-S02-02: Speaker notes form a coherent 5–10 minute spoken script

**Priority:** should · **Story:** E12-S02 · **Level:** L1
**Given** the presenter notes across all slides read aloud as one continuous voiceover
**When** the total spoken word count is summed
**Then** it falls in a range consistent with the recorded walkthrough at ~130–150 wpm —
not so short it is thin, not so long it overruns the window

> **Reconciled by E12d-S01 (2026-07-20):** the stakeholder pitch supersedes E12c's longer narrative
> budget. The MAIN spoken-word sum is **[450, 900]** and only counts slides before the
> `<!-- APPENDIX -->` sentinel; appendix slides carry notes but are exempt. See
> `openspec/changes/e12d-five-minute-pitch/specs/deck/spec.md` REQ-E12d-S01-01/02.
**Test:** `tests/deck/script-wordcount.sh`
**Verify:**

```bash
tests/deck/script-wordcount.sh   # sums MAIN (pre-APPENDIX) note words; asserts 450 <= total <= 900 (E12d-S01)
```

---

## REQ-E12-S03-01: Live iframes embed running platform surfaces

**Priority:** must · **Story:** E12-S03 · **Level:** L1 · **Refs:** fallback — if a surface is down at
record time, substitute a pre-recorded GIF/screenshot; this test asserts the embed *intent* in the
deck, not live endpoint reachability
**Given** named slides that embed live platform surfaces via Slidev iframes
**When** the deck is grepped for the required embed surfaces
**Then** live iframe/embed references are present for all five surfaces: the Backstage portal (E10),
the ArgoCD UI, Grafana/marshal (E5), the clubhouse/Caddy site (E-Caddy-MVP), and the Crossplane
resource graph — proving the platform is real and running, not screenshots
**Test:** `tests/deck/iframe-surfaces.sh`
**Verify:**

```bash
tests/deck/iframe-surfaces.sh   # greps slides/slides.md for iframe embeds of: backstage, argocd, grafana/marshal, clubhouse/caddy, crossplane-graph
```

---

## REQ-E12-S04-01: Deck covers the required narrative beats

**Priority:** must · **Story:** E12-S04 · **Level:** L1
**Given** the deck's fixed narrative arc for the recorded walkthrough
**When** the deck is grepped for each required section marker
**Then** all beats are present and ordered: pitch → architecture → security posture → the
auto-generated portal hero moment (edit XRD → form updates, E10) → progressive delivery
(mulligan, E7) → alerting (marshal, E5) → evidence (scorecard, E8) — each with a per-section time
budget so the whole lands inside the recorded window

> **Reconciled by E12c-S01 (2026-07-17):** the seven beats + `sectionTime` sum are now enforced over
> the MAIN deck only (before the `<!-- APPENDIX -->` sentinel); the raised main `sectionTime` range is
> **[600, 1000] s** (~11–15 min). Appendix sections carry neither canonical `beat:` nor `sectionTime:`
> markers. See `openspec/changes/e12c-deck-docs-refresh/specs/deck/spec.md` REQ-E12c-S01-01/02.
**Test:** `tests/deck/narrative-beats.sh`
**Verify:**

```bash
tests/deck/narrative-beats.sh   # greps for each required beat marker (pitch, architecture, security, portal-hero, mulligan, marshal, scorecard) in order
```

---

## REQ-E12-EXIT: Recorded 5–10 min video can be produced from the deck

**Priority:** could · **Story:** E12
**Given** E12 complete — deck builds clean, every slide has a verbatim note, iframes embed the live
surfaces, and the narrative beats are present
**When** the operator reads the notes aloud over the deck with the live platform up (or GIF/screenshot
fallbacks for any down surface) and records the screen
**Then** a 5–10 minute video walkthrough is produced end-to-end with no missing script or dead slides
**Test:** `tests/deck/exit-recording-ready.sh`
**Verify:**

```bash
tests/deck/exit-recording-ready.sh   # composite gate: slidev-build + speaker-notes-coverage + script-wordcount + iframe-surfaces + narrative-beats all pass
```

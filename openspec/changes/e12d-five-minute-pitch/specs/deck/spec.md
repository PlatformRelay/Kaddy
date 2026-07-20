<!-- markdownlint-disable MD013 -->
# Spec — E12d Five-minute pitch deck

Epic: E12d (extends E12; **supersedes** E12c narrative/budget REQs where they conflict) ·
**Refs:** `slides/` Slidev project · worktree deck refresh · E6g `provider-gridscale` · TF PRs
`#509–#511` · E7 mulligan · E10 portal (narrative assume-deploy only) · E14/ADR-0303 Nix honesty ·
ADR-0112 visual identity (unchanged)
**Levels:** L1 golden-file/lint (deck epic — no cluster REQs)

> **Gate:** `task test:spec` + `tests/deck/exit-recording-ready.sh`. Test paths under `tests/deck/`.
>
> **Supersession:** REQ-E12c-S01-02 (~15 min) and conflicting E12c-S02/S03/S04 narrative wording are
> superseded here for the **spoken pitch**. E12c-S05/S07/S08/S09 remain orthogonal polish. The
> `<!-- APPENDIX -->` exemption mechanism from E12c-S01-01 is retained.
>
> **Honesty:** narrative convenience ≠ runtime proof. Gates below encode the boundaries.

---

## REQ-E12d-S01-01: Spoken path fits a ~5-minute budget

**Priority:** must · **Story:** E12d-S01 · **Level:** L1 · **TDD:** failing budget tests first
**Given** stakeholders need a short pitch, not a 15–20 slide deep dive
**When** main (pre-`<!-- APPENDIX -->`) notes and `sectionTime` are summed
**Then** main spoken words land in **[450, 900]** and main `sectionTime` sum lands in
**[240, 360] s**; the seven canonical beats remain an ordered subsequence pre-sentinel; appendix
slides stay gate-exempt from those sums
**Test:** `tests/deck/script-wordcount.sh` + `tests/deck/narrative-beats.sh` (ranges lowered) +
`tests/deck/appendix-boundary.sh`
**Verify:**

```bash
tests/deck/narrative-beats.sh    # main sectionTime in [240,360]s; 7 beats in order pre-sentinel
tests/deck/script-wordcount.sh   # main spoken words in [450,900]
tests/deck/appendix-boundary.sh
```

---

## REQ-E12d-S01-02: Main spoken slide count is 8–12

**Priority:** must · **Story:** E12d-S01 · **Level:** L1 · **TDD:** failing spoken-path test first
**Given** ~20 spoken slides overrun a 5-minute talk
**When** `tests/deck/spoken-path.sh` counts main content slides (pre-appendix; exclude pure
`CoverArt`-only dividers if the helper documents that rule)
**Then** the count is in **[8, 12]** and detailed material lives after `<!-- APPENDIX -->`
**Test:** `tests/deck/spoken-path.sh` (new)
**Verify:**

```bash
tests/deck/spoken-path.sh   # asserts 8..12 main content slides + 7-beat subsequence
```

**Edge / error:** if a slide is needed for Q&A but not spoken, it must be post-sentinel — placing it
pre-sentinel without cutting another slide fails this REQ.

---

## REQ-E12d-S02-01: Opening is exercise → platform

**Priority:** must · **Story:** E12d-S02 · **Level:** L1
**Given** the hiring brief is Caddy-on-Linux + Prometheus scrape/alert
**When** the main pitch opens
**Then** early main slides state the exercise outcome and the platform-engineer framing
(“built a platform around it” / equivalent), before deep architecture history
**Test:** `tests/deck/content-beats.sh` or `tests/deck/pitch-beats.sh`
**Verify:**

```bash
tests/deck/pitch-beats.sh   # MAIN: Caddy+Prometheus (or brief) + platform-engineer/platform-around-it anchors before architecture beat
```

---

## REQ-E12d-S02-02: provider-gridscale + upstream PRs as early contribution value

**Priority:** must · **Story:** E12d-S02 · **Level:** L1
**Given** `provider-gridscale` and TF PRs #509–#511 are real external value
**When** the main deck presents gridscale work
**Then** a **pre-architecture** (first-third) main section names `provider-gridscale`, the Marketplace
listing, and links #509/#510/#511; framing is **contribution / customer value**; honesty states PRs
are **filed and open** (not merged); must **not** lead the value story as dismissive “still open
leftovers”
**Test:** `tests/deck/pitch-beats.sh`
**Verify:**

```bash
tests/deck/pitch-beats.sh   # MAIN early: provider-gridscale + marketplace + pull/509|510|511 + contribution|value framing; forbids leftover-dismissive primacy
```

**Edge / error:** claiming “merged upstream” or omitting open-review honesty fails; listing the three
PRs only under a gloomy open-list without the hero contribution slide also fails.

---

## REQ-E12d-S03-01: D-042 demoted from the spoken main arc

**Priority:** must · **Story:** E12d-S03 · **Level:** L1
**Given** D-042 is useful engineering history but not the stakeholder pitch
**When** the main (pre-appendix) deck is checked
**Then** no main slide title/kicker is the D-042 migration tale; if retained, it appears only after
`<!-- APPENDIX -->`
**Test:** `tests/deck/pitch-beats.sh`
**Verify:**

```bash
tests/deck/pitch-beats.sh   # MAIN must not match D-042 title/kicker; APPENDIX may contain D-042
```

---

## REQ-E12d-S03-02: Controls slide drops public-exposure card; keeps cost teardown

**Priority:** must · **Story:** E12d-S03 · **Level:** L1
**Given** the “Known cloud risk / GSK node public exposure” card distracts from the pitch
**When** the main controls slide is rendered
**Then** that card/text is absent from main; teardown / time-boxed lab / cost-governance language is
present
**Test:** `tests/deck/pitch-beats.sh`
**Verify:**

```bash
tests/deck/pitch-beats.sh   # MAIN: no 'Known cloud risk' / 'GSK node public'; has teardown|time-boxed|cost
```

**Edge / error:** moving the exposure card into speaker notes only is insufficient if the visible
card remains; appendix may still document the accepted risk for Q&A.

---

## REQ-E12d-S03-03: Website intent → resources is simple and static-clear

**Priority:** must · **Story:** E12d-S03 · **Level:** L1
**Given** “website intent becomes governed resources” is a core claim
**When** that slide is shown in the spoken path
**Then** the claim is understandable from static layout (claim/landing → composition → concrete
resources) without depending on click-step animations to convey the idea
**Test:** `tests/deck/pitch-beats.sh` (structure anchors) + manual spot-check in Verify notes
**Verify:**

```bash
tests/deck/pitch-beats.sh   # MAIN: Website claim/intent + Composition + HTTPRoute|ServiceMonitor (or equivalent resource set)
```

**Edge / error:** a slide that only works if the presenter clicks through v-clicks to reveal the
pipeline fails the spirit of this REQ — prefer always-visible steps.

---

## REQ-E12d-S03-04: Portal narrative assumes deploy (talk); no “runtime remains open” on portal slide

**Priority:** must · **Story:** E12d-S03 · **Level:** L1
**Given** the operator wants a stakeholder portal beat and E10 offline wiring already exists
**When** the main portal slide is rendered
**Then** it states portal designed + platform API already exists, and **does not** say runtime
remains open / not running yet; narrative may assume Backstage deployed for the talk
**Test:** `tests/deck/pitch-beats.sh`
**Verify:**

```bash
tests/deck/pitch-beats.sh   # MAIN portal: 'platform API' (or XRD) + designed/portal; forbids 'runtime remains open' / 'not running yet' on that slide region
```

**Edge / error (honesty):** the deck **must still** disclose elsewhere (appendix or README content
truth) that **E10 live runtime proof** is not claimed by this epic — overselling “production
Backstage proven in-lab” without that boundary fails REQ-E12d-S05-02.

---

## REQ-E12d-S04-01: Mulligan in stakeholder language

**Priority:** must · **Story:** E12d-S04 · **Level:** L1
**Given** progressive delivery is proven (E7) but jargon-heavy
**When** the main mulligan slide is spoken
**Then** it states that Prometheus/metrics analysis drives automatic blue-green or canary
**promote or rollback** (stakeholder-readable; Argo names optional)
**Test:** `tests/deck/pitch-beats.sh`
**Verify:**

```bash
tests/deck/pitch-beats.sh   # MAIN mulligan: Prometheus|metrics + (blue-green|canary) + (promote|rollback)
```

---

## REQ-E12d-S04-02: Pitch path does not depend on live localhost iframes

**Priority:** must · **Story:** E12d-S04 · **Level:** L1 · **TDD:** failing iframe gate change first
**Given** `127.0.0.1` / port-forward iframes are unreliable in a live talk
**When** the spoken/main path embeds platform surfaces
**Then** surfaces remain tagged `data-surface` + `data-surface-mode=live|fallback` (or `static`);
main-path embeds used in the pitch are screenshots/GIFs under `slides/public/surfaces/` or public
lab URLs; the gate **must not** require ≥3 live iframes for pitch readiness
**Test:** `tests/deck/iframe-surfaces.sh` (contract updated)
**Verify:**

```bash
tests/deck/iframe-surfaces.sh   # five surfaces tagged; pitch-safe (no mandatory >=3 live iframes)
# main path: prefer zero live 127.0.0.1 iframes before APPENDIX
```

**Edge / error:** appendix may keep live iframes for operator recording; a main-path live iframe to
localhost fails this REQ.

---

## REQ-E12d-S05-01: How-I-worked is AI + spec-to-test (OpenSpec sample optional)

**Priority:** must · **Story:** E12d-S05 · **Level:** L1
**Given** the working method is a differentiator
**When** the how-I-worked beat appears in main
**Then** it states built-with-AI (or equivalent) and the OpenSpec/spec-to-test loop; may show a
short sample REQ (`Given`/`When`/`Then` and/or `Test:`/`Verify:`) on-slide; may replace the prior
agentic-only framing
**Test:** `tests/deck/pitch-beats.sh`
**Verify:**

```bash
tests/deck/pitch-beats.sh   # MAIN: AI|assistant|agent + OpenSpec|spec-to-test|REQ-|Verify:
```

---

## REQ-E12d-S05-02: Honesty boundaries remain checkable

**Priority:** must · **Story:** E12d-S05 · **Level:** L1
**Given** narrative shortcuts must not become false claims
**When** appendix and/or `slides/README.md` content-truth are checked
**Then** all of the following are explicit: (a) Nix image **build** landed and **boot-to-serve
open**; (b) upstream TF PRs are **filed/open**, not merged; (c) Backstage talk narrative ≠ E10
**runtime proof** (point at E10 live cycle / runbook)
**Test:** `tests/deck/pitch-beats.sh` + `tests/deck/content-beats.sh` appendix Nix anchors
**Verify:**

```bash
tests/deck/pitch-beats.sh    # honesty anchors for Nix boot-to-serve open; PRs open/filed; Backstage narrative≠proof
tests/deck/content-beats.sh  # appendix Nix flake + boot-to-serve gap (retained)
```

**Edge / error:** portal main slide may assume deploy **and** honesty appendix must still exist —
one without the other fails.

---

## REQ-E12d-S05-03: Non-goals of this epic are not “done” by the deck

**Priority:** must · **Story:** E12d-S05 · **Level:** L1
**Given** E12d is deck-only
**When** reviewers read the epic proposal + honesty appendix
**Then** the materials do not claim Backstage runtime implemented or Nix boot-to-serve completed as
outcomes of E12d
**Test:** `tests/deck/pitch-beats.sh` (negative greps on oversell phrases in main scorecard/close if
present) + proposal non-goals (manual in Verify)
**Verify:**

```bash
tests/deck/pitch-beats.sh   # forbids main claims like 'Backstage live-proven by E12d' / 'Nix boot-to-serve done'
test -f openspec/changes/e12d-five-minute-pitch/proposal.md
```

<!-- markdownlint-disable MD013 -->
# Spec — E12c Deck + docs refresh

Epic: E12c (extends E12) · **Refs:** gridscale Platform Engineer exercise · `slides/` Slidev project ·
`provider-gridscale` (sibling repo, E6g) · `kubernetes-workshop` (visual reference) · ADR-0112 (deck
visual identity) · E14/ADR-0303 (NixOS path, designed)
**Levels:** meta build-check · L1 golden-file/lint (deck/docs epic — no cluster REQs)

> **Gate:** `task test:spec` + `tests/deck/exit-recording-ready.sh`. All Test paths under
> `tests/deck/`; the epic-exit `STRICT_TEST_FILES` gate binds when the epic activates. Levels per
> ADR-0701.
>
> **Binding vs flexible gates (read first).** The 7 `beat:` markers must stay in *subsequence order*
> (new non-canonical section markers are ignored by the beats test) — adding sections does NOT break
> it. The real ceilings are `sectionTime` and word-count sums; this change **raises them for the main
> deck and exempts the appendix**.

---

## REQ-E12c-S01-01: Appendix is exempt from the time and word-count sums

**Priority:** must · **Story:** E12c-S01 · **Level:** L1 · **TDD:** failing gate-boundary test first
**Given** the deck carries a main narrative followed by an appendix, and appendix slides must exist
without consuming the main-talk budget
**When** an appendix boundary sentinel (`<!-- APPENDIX -->` as the first line after the divider of the
first appendix section) is present in `slides/slides.md`
**Then** `script-wordcount.sh` sums notes only for slides **before** the sentinel, and
`narrative-beats.sh` sums `sectionTime` and requires all 7 beats only **before** the sentinel;
appendix slides still satisfy `speaker-notes-coverage.sh` (they carry notes) but do not count toward
either sum
**Test:** `tests/deck/appendix-boundary.sh` (new) + edits to `script-wordcount.sh` + `narrative-beats.sh`
**Verify:**

```bash
tests/deck/appendix-boundary.sh   # asserts sentinel present, and main-vs-appendix split honored by the two sum-gates
```

---

## REQ-E12c-S01-02: Main deck runs to a ~15-minute budget

**Priority:** must · **Story:** E12c-S01 · **Level:** L1
**Given** the raised main-deck envelope (operator decision: ~15 min)
**When** `narrative-beats.sh` sums `sectionTime` over main (pre-appendix) sections and
`script-wordcount.sh` sums main-section note words
**Then** `sectionTime` main total lands in **[600, 1000] s** and main spoken words in **[1400, 2200]**
(≈ 11–15 min at 130–150 wpm); the REQ-E12-S02-02 and REQ-E12-S04-01 ranges are updated to match and
the change is noted in those specs
**Test:** `tests/deck/script-wordcount.sh` + `tests/deck/narrative-beats.sh` (ranges raised)
**Verify:**

```bash
tests/deck/narrative-beats.sh    # main sectionTime in [600,1000]s, 7 beats in order
tests/deck/script-wordcount.sh   # main spoken words in [1400,2200]
```

---

## REQ-E12c-S02-01: gridscale value-creation hero (landed, external value)

**Priority:** must · **Story:** E12c-S02 · **Level:** L1 · **TDD:** failing content-assertion first
**Given** the applicant has shipped a Crossplane provider for gridscale (`provider-gridscale`, 32
resources via Upjet, Upbound Marketplace) and filed **3 bug-fix MRs against the gridscale Terraform
provider**
**When** the deck is rendered
**Then** a **main-arc** section presents this as *landed external value for gridscale* — names the
provider, the Marketplace listing, and links the 3 MRs — and introduces **Crossplane as a
platform-engineering IaC tool** (control plane vs one-shot Terraform; composition; XRD-as-API). The
section is tagged **landed** against the §03 scorecard
**Test:** `tests/deck/content-beats.sh` (new — greps required anchors)
**Verify:**

```bash
tests/deck/content-beats.sh   # asserts 'provider-gridscale', a marketplace link, '3 ' MRs anchor, and a Crossplane-IaC kicker present in a pre-appendix section
```

---

## REQ-E12c-S03-01: Agentic-workflow beat — epic → plan → story → test

**Priority:** must · **Story:** E12c-S03 · **Level:** L1
**Given** the project is built OpenSpec-first (`epic → plan → story → test`, `Verify:`/`Test:` per REQ,
TDD, gate matrix, replayable audits)
**When** the deck is rendered
**Then** a **main-arc** section walks the actual progression using a real epic (e.g. `e5-monitoring-
marshal`): change-folder = epic → `proposal.md` = plan → `tasks.md` = TDD slices → `specs/…/spec.md`
REQ story (Given/When/Then + `Test:` + `Verify:` + Level) → the concrete test artifact. It adapts the
safe-agentic-coding framing (guardrails-wrap-nondeterminism; autonomy-is-earned) in Kaddy's own
vocabulary
**Test:** `tests/deck/content-beats.sh`
**Verify:**

```bash
tests/deck/content-beats.sh   # asserts an 'epic', 'plan', 'story', 'test' progression anchor + an openspec REQ reference in a pre-appendix section
```

---

## REQ-E12c-S04-01: Appendix — NixOS path (designed), tree, quickstart, solved-different-ways

**Priority:** should · **Story:** E12c-S04 · **Level:** L1
**Given** depth material that should be available for Q&A without lengthening the main talk
**When** the appendix (post-sentinel) is rendered
**Then** it contains: (a) the **NixOS path tagged designed** (E14/ADR-0303; Packer is today's path,
no `flake.nix`), (b) a `tree`-style repo-structure slide (top-level dirs + one-line purpose), (c) a
quickstart + required-tools slide (`task cluster:up` → smoke → `task demo`; Task/kind/kubectl/helm/
OpenTofu/Terramate/Packer/conftest/promtool/k6/gitleaks/SOPS/cosign), (d) a "solved-different-ways"
slide (Caddy VM = the brief · rich K8s variant · Nix golden image = designed)
**Test:** `tests/deck/appendix-boundary.sh` + `tests/deck/content-beats.sh`
**Verify:**

```bash
tests/deck/content-beats.sh   # asserts NixOS-designed tag, a repo-tree anchor, a 'task cluster:up' quickstart anchor, and a 'solved-different-ways' anchor — all AFTER the appendix sentinel
```

---

## REQ-E12c-S05-01: Hybrid k8s-workshop visual port (golf-teal accent)

**Priority:** should · **Story:** E12c-S05 · **Level:** L1 · **Refs:** ADR-0112
**Given** the operator chose a hybrid port of the kubernetes-workshop look
**When** the deck styles are applied
**Then** the deck adopts the `--kw-*` surface/text CSS-variable system (dark graphite `#0b0e14`), the
Inter + JetBrains Mono fonts, and the footer + progress-bar + kicker/chip chrome, with the **accent
overridden to golf-teal** (not k8s-blue `#326ce5`); `slidev-build.sh` stays green and covers keep the
S00–S14 stable-ID + placeholder-fallback convention
**Test:** `tests/deck/slidev-build.sh` + `tests/deck/theme-tokens.sh` (new — greps the `--kw-*` vars + teal accent)
**Verify:**

```bash
tests/deck/slidev-build.sh     # deck still builds to slides/dist/
tests/deck/theme-tokens.sh     # asserts --kw-* palette present and accent is teal, not #326ce5
```

---

## REQ-E12c-S06-01: GIF/screenshot recording protocol + named fallback slots

**Priority:** should · **Story:** E12c-S06 · **Level:** L1
**Given** several surfaces (marketplace VM, mulligan weight-shift, k6 alert firing, scorecard report)
are better shown as recorded GIFs than live iframes
**When** the operator follows `slides/recording-guide.md`
**Then** each recording has a deterministic name `slides/public/surfaces/<surface>-<action>.gif`, the
guide states exactly what to capture per clip, and the deck references each via
`data-surface="<surface>" data-surface-mode="fallback"` so `iframe-surfaces.sh` still passes (≥ 3 live
iframes retained: argocd, grafana, clubhouse)
**Test:** `tests/deck/iframe-surfaces.sh` (unchanged contract) + presence of `slides/recording-guide.md`
**Verify:**

```bash
tests/deck/iframe-surfaces.sh   # all 5 surfaces tagged live|fallback, >= 3 live iframes
test -f slides/recording-guide.md
```

---

## REQ-E12c-S07-01: Kaddy README badge row

**Priority:** should · **Story:** E12c-S07 · **Level:** L1
**Given** `README.md` currently has no badges
**When** the badge row is added
**Then** `README.md` carries CI (verify.yaml workflow-status), deck-build, license, and a docs/Pages
badge — each a valid shields.io URL for `PlatformRelay/Kaddy` — and no badge points at an unpublished
resource without a caveat
**Test:** `tests/deck/readme-badges.sh` (new — validates shields URLs resolve to the repo)
**Verify:**

```bash
tests/deck/readme-badges.sh   # asserts >=3 badges with well-formed shields URLs for PlatformRelay/Kaddy
```

---

## REQ-E12c-S08-01: provider-gridscale failing badges fixed (separate repo, outward-facing)

**Priority:** should · **Story:** E12c-S08 · **Level:** manual/outward-facing · **Governance:** explicit go-ahead
**Given** the `provider-gridscale` README Scorecard badge shows *failing* (transient GitHub-API 503s;
config is correct, OpenSSF API already has data, score ~6) and the Release badge shows *no releases*
(git tags exist — `v0.1.1`, `v0.1.0` — but zero GitHub Releases were ever published)
**When** the fix lane runs **in the `provider-gridscale` repo with operator go-ahead**
**Then** (a) the Scorecard badge is swapped to the durable score badge
`https://api.securityscorecards.dev/projects/github.com/PlatformRelay/provider-gridscale/badge`
(linked to `scorecard.dev/viewer/?uri=github.com/PlatformRelay/provider-gridscale`); (b) GitHub
Releases are backfilled (`gh release create v0.1.1 --generate-notes`, then `v0.1.0`) and a
tag-triggered `.github/workflows/release.yml` publishes releases going forward
**Test:** manual verification (outward-facing — not a Kaddy CI gate)
**Verify:**

```bash
# in ../provider-gridscale, after go-ahead:
gh release list --repo PlatformRelay/provider-gridscale   # shows v0.1.1
curl -sI 'https://api.securityscorecards.dev/projects/github.com/PlatformRelay/provider-gridscale/badge' | grep -i image/svg
```

---

## REQ-E12c-S09-01: Docs hygiene — typo, broken links, caveats

**Priority:** should · **Story:** E12c-S09 · **Level:** L1
**Given** `docs/HIRING_EXERCICSE.md` is misspelled, ROADMAP links a nonexistent
`openspec/changes/e14-nix-golden-images/`, and the deck Pages URL is unpublished
**When** docs hygiene runs
**Then** the file is renamed to `docs/HIRING_EXERCISE.md` (nav/link references updated), the broken
ROADMAP link is fixed or removed, and the unpublished Pages URL is caveated
**Test:** existing markdownlint + a link-check over `docs/**` (`hack/verify-spec-coverage.sh` style)
**Verify:**

```bash
markdownlint-cli2 'docs/**/*.md'   # clean
! grep -rq 'HIRING_EXERCICSE' docs/ README.md AGENTS.md
```

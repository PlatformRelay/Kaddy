# Tasks — E12 Slidev showcase deck

**Gate:** `task test:spec` + `tests/deck/slidev-build.sh`

**Activation:** cuttable / late-parallel. Per `docs/ROADMAP.md`: "E11, E12 in parallel where
possible" — start once the platform surfaces the deck embeds exist (E10 portal, E-Caddy-MVP site,
E5/marshal, E7/mulligan, E8/scorecard). GIF/screenshot fallbacks cover any surface not yet up.

TDD-ordered, vertical slices — each story is independently verifiable via its gate command.

## Landed (2026-07-16 — deck v1, pre-dates the slice redesign below)

- [x] Slidev scaffold — `slides/package.json`, bundled themes, `pnpm build` produces
      `slides/dist/` cleanly (covers the S01 scaffold bullets below)
- [x] Deck content v1 — pitch, architecture, substrate, GitOps, observability,
      security/governance, Caddy-MVP tenant, demo cues, roadmap; anchored to README's
      landed-vs-designed line
- [x] E12b visual layer — `slides/image-prompts.md` (continuous golf/caddie story, global
      style + negative prompt, per-slide cover prompts S00–S13, branding prompts),
      `CoverArt.vue` section dividers wired to final `/covers/section-NN-<slug>.png`
      filenames with `placeholder-section.svg` fallback + mandatory "AI generated" footer
- [ ] E12b (operator/manual): generate the final art from `slides/image-prompts.md` and drop
      the PNGs into `slides/public/covers/` + `slides/public/branding/` (exact filenames in
      the prompts file; no code changes needed)
- [x] Gate: `slides.md` + `slides/README.md` + `slides/image-prompts.md` lint clean against
      `hack/tooling/.markdownlint-cli2.yaml`; `pnpm build` green

## E12-S01 — Slidev scaffold + reproducible build

- [x] Add failing `tests/deck/slidev-build.sh` (asserts `slidev build` exit 0 + `slides/dist/` refreshed)
- [x] `slides/package.json` (Slidev dep) — landed (deck v1); still open: wire `task deck:build`
- [ ] CI job builds the deck; static SPA is the artifact the clubhouse/Caddy tenant serves
      *(Taskfile/.github outside the E12 file-only lane — follow-up: `task deck:build` wrapping
      `tests/deck/slidev-build.sh` + a deck job in `verify.yaml` running `tests/deck/exit-recording-ready.sh`)*
- [x] Gate: `tests/deck/slidev-build.sh`

## E12-S02 — Word-by-word speaker notes on every slide

- [x] Add failing `tests/deck/speaker-notes-coverage.sh` (note-block count == slide count + per-note min words:
      content slides ≥ 25, CoverArt dividers ≥ 8 — a short spoken transition; note = LAST comment block per slide)
- [x] Add failing `tests/deck/script-wordcount.sh` (total spoken words in 650–1500 range)
- [x] Write verbatim `<!-- ... -->` presenter-note script on EVERY slide (voiceover, not hints) —
      30/30 slides, 1358 words ≈ 9–10 min at 130–150 wpm
- [x] Gate: `tests/deck/speaker-notes-coverage.sh` + `tests/deck/script-wordcount.sh`

## E12-S03 — Live iframes embed running platform surfaces (partial by design)

- [x] Add failing `tests/deck/iframe-surfaces.sh` (greps for backstage, argocd, grafana/marshal, clubhouse/caddy, crossplane-graph embeds)
- [x] Add named slides embedding the five surfaces — **live iframes:** argocd (`https://127.0.0.1:30443`),
      grafana (`http://127.0.0.1:3000` via documented port-forward), clubhouse (`https://clubhouse.kaddy.local:8443`
      via documented port-forward); **fallbacks (surfaces don't exist yet):** backstage + crossplane-graph (E10/E6
      designed) as GIF/screenshot drop-ins per the spec's fallback clause — flips to live iframes when E10 lands
- [x] Document the GIF/screenshot fallback for any surface down at record time (`slides/README.md`,
      "Live surfaces & fallbacks")
- [x] Gate: `tests/deck/iframe-surfaces.sh`

## E12-S04 — Narrative beats + time budget

- [x] Add failing `tests/deck/narrative-beats.sh` (greps ordered beat markers + sums `sectionTime` budgets)
- [x] Structure the deck to the arc: pitch → architecture → security → portal hero → mulligan → marshal → scorecard
      (`beat:` frontmatter markers on the section dividers; new portal-hero section added; marshal moved after mulligan)
- [x] Add per-section time budget so the walkthrough lands in 5–10 min (`sectionTime:` per divider, 590 s total)
- [x] Gate: `tests/deck/narrative-beats.sh`

## E12-EXIT — Recording-ready

- [x] Add `tests/deck/exit-recording-ready.sh` (composite: build + notes + wordcount + iframes + beats)
- [ ] Dry-run (operator/manual): read notes over the deck with live iframes (or fallbacks); confirm a
      5–10 min recording is producible — bring-up checklist in `slides/README.md`
- [x] Gate: `task test:spec` + `tests/deck/slidev-build.sh`

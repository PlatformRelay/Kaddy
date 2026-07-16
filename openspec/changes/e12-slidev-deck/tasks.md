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

- [ ] Add failing `tests/deck/slidev-build.sh` (asserts `slidev build` exit 0 + `slides/dist/`)
- [x] `slides/package.json` (Slidev dep) — landed (deck v1); still open: wire `task deck:build`
- [ ] CI job builds the deck; static SPA is the artifact the clubhouse/Caddy tenant serves
- [ ] Gate: `tests/deck/slidev-build.sh`

## E12-S02 — Word-by-word speaker notes on every slide

- [ ] Add failing `tests/deck/speaker-notes-coverage.sh` (note-block count == slide count + per-note min words)
- [ ] Add failing `tests/deck/script-wordcount.sh` (total spoken words in 650–1500 range)
- [ ] Write verbatim `<!-- ... -->` presenter-note script on EVERY slide (voiceover, not hints)
- [ ] Gate: `tests/deck/speaker-notes-coverage.sh` + `tests/deck/script-wordcount.sh`

## E12-S03 — Live iframes embed running platform surfaces

- [ ] Add failing `tests/deck/iframe-surfaces.sh` (greps for backstage, argocd, grafana/marshal, clubhouse/caddy, crossplane-graph embeds)
- [ ] Add named slides embedding live iframe URLs for the five surfaces
- [ ] Document the GIF/screenshot fallback for any surface down at record time
- [ ] Gate: `tests/deck/iframe-surfaces.sh`

## E12-S04 — Narrative beats + time budget

- [ ] Add failing `tests/deck/narrative-beats.sh` (greps ordered beat markers)
- [ ] Structure the deck to the arc: pitch → architecture → security → portal hero → mulligan → marshal → scorecard
- [ ] Add per-section time budget so the walkthrough lands in 5–10 min
- [ ] Gate: `tests/deck/narrative-beats.sh`

## E12-EXIT — Recording-ready

- [ ] Add `tests/deck/exit-recording-ready.sh` (composite: build + notes + wordcount + iframes + beats)
- [ ] Dry-run: read notes over the deck with live iframes (or fallbacks); confirm a 5–10 min recording is producible
- [ ] Gate: `task test:spec` + `tests/deck/slidev-build.sh`

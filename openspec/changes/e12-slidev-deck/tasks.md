# Tasks — e12-slidev-deck

See ROADMAP epic stories (E12-S01/S02/S03).

- [x] E12-S01 (local): Slidev scaffold — `slides/package.json`, bundled themes,
      `pnpm build` produces `slides/dist/` cleanly
- [ ] E12-S01 (CI): build the deck in a workflow — roadmap (needs `.github/` /
      Taskfile changes, outside the file-only slides lane)
- [x] E12-S02: Deck content — pitch, architecture, substrate, GitOps,
      observability, security/governance, Caddy-MVP tenant, demo cues, roadmap;
      anchored to README's landed-vs-designed line
- [ ] E12-S03: GitHub Pages deploy — roadmap (needs `.github/` workflow)
- [x] E12b: Visual layer delivered — `slides/image-prompts.md` (continuous
      golf/caddie story, global style + negative prompt, per-slide cover
      prompts S00–S13, branding prompts), `CoverArt.vue` section dividers
      wired to final `/covers/section-NN-<slug>.png` filenames with
      `placeholder-section.svg` fallback + mandatory "AI generated" footer
- [ ] E12b (operator/manual): generate the final art from
      `slides/image-prompts.md` and drop the PNGs into
      `slides/public/covers/` + `slides/public/branding/` (exact filenames in
      the prompts file; no code changes needed)
- [x] Gate: `slides.md` + `slides/README.md` + `slides/image-prompts.md` lint
      clean against `hack/tooling/.markdownlint-cli2.yaml`; `pnpm build` green

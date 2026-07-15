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
- [x] Gate: `slides.md` + `slides/README.md` lint clean against
      `hack/tooling/.markdownlint-cli2.yaml`; `pnpm build` green

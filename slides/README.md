# slides — kaddy interview deck (E12)

[Slidev](https://sli.dev) presentation that tells the kaddy platform story for the
**gridscale Platform Engineer exercise** interview. The deck is deliberately honest
about what is **landed and gated on `main`** vs **designed** (ADR + OpenSpec
spec + committed manifests, not yet running) — the maturity signal is the
artifacts, not claims of a running production cluster.

## Deck outline (`slides.md`)

1. Title — kaddy, a caddie for your websites
2. The brief, reframed — script vs platform question
3. From task to platform — the exercise as one tenant + the caddie metaphor
4. **Landed vs designed** — the credibility slide
5. Architecture — two phases, one set of GitOps manifests
6. Substrate — local kind + Cilium (E1e), and why not MetalLB
7. GitOps — ArgoCD app-of-apps + self-heal/prune
8. Observability spine — marshal (promtool-tested alerts, Loki/Alloy)
9. Security & governance — SOPS-age, Rego + Kyverno labels, gated CI
10. Caddy-MVP tenant (WaaS) + mulligan progressive delivery
11. Demo flow — five beats
12. Roadmap & honest status
13. Why this answers the exercise
14. Thank you

## Run it

```bash
cd slides
pnpm install     # installs Slidev + bundled themes (default, seriph)
pnpm dev         # slidev slides.md --open — live presenter
pnpm build       # slidev build → slides/dist (static, gitignored)
pnpm lint        # markdownlint-cli2 against the repo config
```

> `pnpm install` approves the `esbuild` / `vue-demi` native build scripts via
> `pnpm-workspace.yaml` (`onlyBuiltDependencies`) so the Vite build is hermetic.

## Gates

- **Build:** `pnpm build` must produce `slides/dist/` cleanly (E12-S01, local).
- **Lint:** `pnpm lint` (or `task lint` from repo root — `slides.md` is in the
  `**/*.md` glob; `slides/dist` is excluded). Slidev's per-slide `---` frontmatter
  and inline Vue/HTML trip several structural markdownlint rules, disabled at the
  top of `slides.md` (MD001/003/013/022/023/024/025/033/036/041).

## Roadmap (not in this lane's boundary)

- **CI build (E12-S01)** and **GitHub Pages deploy (E12-S03)** need `.github/` /
  Taskfile changes outside this file-only lane — tracked as roadmap.

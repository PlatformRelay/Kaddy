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

Each content slide is preceded by a **section-cover divider** (`§ 00`–`§ 13`) —
a full-bleed AI-artwork slide rendered by `components/CoverArt.vue`, telling one
continuous golf/caddie story (see [`image-prompts.md`](./image-prompts.md)).

## Generating the art

The visual layer is prompt-driven and drop-in:

- **Prompts** live in [`image-prompts.md`](./image-prompts.md) — one cover per
  slide (`S00`–`S13`) as a continuous Mœbius / *ligne claire* story in the
  platform's golf/caddie universe, plus a global style block, a global negative
  prompt, and a **Branding** section (logo dark/light, GitHub og-image).
- **Target filenames** are final and already referenced by the deck:
  - covers → `slides/public/covers/section-NN-<slug>.png` — **16:9** (e.g.
    1600×900); keep the left third calm for the title, bottom-right quiet
  - branding → `slides/public/branding/logo-dark.png` + `logo-light.png`
    (**1:1**, legible at 512 px and favicon scale) and `og-image.png`
    (**1280×640**, GitHub social preview)
- **Drop-in behaviour:** until a PNG exists, `components/CoverArt.vue` falls
  back to `public/covers/placeholder-section.svg` via an `onError` handler —
  the build stays green and generated art lands with zero code changes.
- **Guardrail (mandatory):** every rendered cover carries a small, low-opacity
  **"AI generated"** footer — `CoverArt` renders it on every divider; do not
  remove it, and do not bake fake footers into the images themselves.
- **Consistency:** generate `S00` first, lock the cast's look, then reuse it
  (seed / reference images) for `S01`–`S13` and the branding set.

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

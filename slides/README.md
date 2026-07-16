# slides — kaddy interview deck (E12)

[Slidev](https://sli.dev) presentation that tells the kaddy platform story for the
**gridscale Platform Engineer exercise** interview. The deck is deliberately honest
about what is **landed and gated on `main`** vs **designed** (ADR + OpenSpec
spec + committed manifests, not yet running) — the maturity signal is the
artifacts, not claims of a running production cluster.

## Deck outline (`slides.md`)

Restructured to the E12-S04 narrative arc — **pitch → architecture → security →
portal-hero → mulligan → marshal → scorecard** — with a `sectionTime` budget per
section (590 s total ≈ 9–10 min) and verbatim voiceover notes on every slide:

1. Title — kaddy, a caddie for your websites *(beat: pitch)*
2. The brief, reframed — script vs platform question
3. From task to platform — the exercise as one tenant *(live clubhouse iframe)*
4. **Landed vs designed** — the credibility slide
5. Architecture — two phases, one set of GitOps manifests *(beat: architecture)*
6. Substrate — local kind + Cilium (E1e), and why not MetalLB
7. GitOps — ArgoCD app-of-apps + self-heal/prune *(live ArgoCD iframe)*
8. Security & governance — SOPS-age, Rego + Kyverno, gated CI *(beat: security)*
9. Portal — auto-generated from the XRD *(beat: portal-hero; Backstage +
   Crossplane-graph fallbacks)*
10. Caddy-MVP tenant (WaaS) + mulligan progressive delivery *(beat: mulligan)*
11. Observability spine — marshal, promtool-tested alerts *(beat: marshal; live
    Grafana iframe)*
12. Demo flow — five beats *(beat: scorecard)*
13. Roadmap & honest status
14. Why this answers the exercise
15. Thank you

Each content slide is preceded by a **section-cover divider** —
a full-bleed AI-artwork slide rendered by `components/CoverArt.vue`, telling one
continuous golf/caddie story (see [`image-prompts.md`](./image-prompts.md)).
Cover **filenames are stable art IDs in generation order** (`S00`–`S14`) and are
not renamed when the display order changes — the prompts file documents the
mapping.

## Live surfaces & fallbacks (E12-S03)

Every embed is tagged `data-surface="<name>" data-surface-mode="live|fallback"`
(asserted by `tests/deck/iframe-surfaces.sh`). The gate checks embed *intent*,
not reachability — bring the live surfaces up before recording:

<!-- markdownlint-disable MD013 -->

| Surface | Mode | URL / stand-in | Bring-up |
| --- | --- | --- | --- |
| `argocd` | **live** | `https://127.0.0.1:30443/applications` | kind NodePort mapping (E1); accept the local cert once |
| `grafana` | **live** | `http://127.0.0.1:3000/alerting/list` | `kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80` |
| `clubhouse` | **live** | `https://clubhouse.kaddy.local:8443/` | `kubectl -n gateway port-forward svc/cilium-gateway-clubhouse 8443:443` + `/etc/hosts` entry `127.0.0.1 clubhouse.kaddy.local`; trust `kaddy-local-ca` |
| `backstage` | **fallback** | `public/surfaces/backstage-scaffolder.gif` (drop-in) | E10 not running yet — GIF/screenshot per the spec's fallback clause |
| `crossplane-graph` | **fallback** | `public/surfaces/crossplane-graph.gif` (drop-in) | E6/E10 not running yet — replaced by the live in-portal graph when E10 lands |

<!-- markdownlint-restore -->

If a live surface is down at record time, substitute a pre-recorded
GIF/screenshot the same way — the deck degrades to an empty frame and the gates
stay green either way (embed intent is what is asserted).

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

- **Build:** `tests/deck/slidev-build.sh` — `pnpm build` exits 0 and refreshes
  `slides/dist/` (REQ-E12-S01-01).
- **Speaker notes:** `tests/deck/speaker-notes-coverage.sh` — every slide's LAST
  `<!-- ... -->` block is its verbatim voiceover; content slides ≥ 25 words,
  CoverArt dividers ≥ 8 words (short spoken transitions) (REQ-E12-S02-01).
- **Script length:** `tests/deck/script-wordcount.sh` — total spoken words in
  650–1500 (5–10 min at 130–150 wpm) (REQ-E12-S02-02).
- **Surfaces:** `tests/deck/iframe-surfaces.sh` — five `data-surface` embeds with
  live/fallback annotations (REQ-E12-S03-01).
- **Narrative:** `tests/deck/narrative-beats.sh` — seven ordered `beat:`
  markers + `sectionTime` budgets summing to 300–600 s (REQ-E12-S04-01).
- **Exit:** `tests/deck/exit-recording-ready.sh` — composite of all of the above
  (REQ-E12-EXIT).
- **Lint:** `pnpm lint` (or `task lint` from repo root — `slides.md` is in the
  `**/*.md` glob; `slides/dist` is excluded). Slidev's per-slide `---` frontmatter
  and inline Vue/HTML trip several structural markdownlint rules, disabled at the
  top of `slides.md` (MD001/003/013/022/023/024/025/033/036/041).

## Roadmap (not in this lane's boundary)

- **`task deck:build`** Taskfile target wrapping `tests/deck/slidev-build.sh` and
  a **CI job** running the deck gates (build + notes + wordcount + iframes +
  beats) need Taskfile / `.github/` changes outside this file-only lane —
  tracked as follow-ups.
- **GitHub Pages deploy** of `slides/dist/` (the artifact the clubhouse/Caddy
  tenant serves) — same boundary, same follow-up.

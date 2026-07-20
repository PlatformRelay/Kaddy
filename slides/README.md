# Kaddy interview deck

This is an independent Slidev package for a concise, personal walkthrough of Kaddy: what I built,
what I proved, and what remains open. It uses the stronger card, chip, typography, diagram, and page
chrome grammar established by `kubernetes-workshop`, but does not import that theme.

## Structure

The main deck contains 20–24 slides and exactly five full-bleed `CoverArt` moments:

1. opening — the first tee;
2. architecture — shared platform applications, different edges;
3. platform controls — security and governance;
4. operations and delivery — mulligan and marshal;
5. evidence and next steps — scorecard and remaining work.

The seven ordered narrative markers remain `pitch → architecture → security → portal-hero →
mulligan → marshal → scorecard`. Every slide carries speaker notes. The appendix is outside the
main timing and script budgets and uses content layouts rather than more covers.

## Visual identity

`styles/theme.css` defines Kaddy's coastal semantic palette:

- deep navy and graphite surfaces;
- warm off-white primary text;
- sea green for action and healthy state;
- sand/gold for warnings and incomplete work;
- restrained coral for danger.

Reusable classes cover cards, chips, muted text, kickers, code, live surfaces, diagrams, grids, and
footer/page chrome. `components/KdIcon.vue` renders Material Symbols and MDI icons through
`@iconify/vue`. `components/CoverArt.vue` keeps the placeholder fallback and mandatory
`AI generated` attribution.

## Five cover assets

The deck references only these generated 16:9 files:

- `public/covers/section-00-first-tee.png`
- `public/covers/section-04-two-courses-one-blueprint.png`
- `public/covers/section-08-gatehouse-inspection.png`
- `public/covers/section-09-mulligans-second-chance.png`
- `public/covers/section-12-signed-scorecard.png`

Until an image exists, `CoverArt.vue` loads `public/covers/placeholder-section.svg`. Generate the
assets from [`image-prompts.md`](./image-prompts.md), keeping the left side calm for titles and the
bottom-right clear for attribution.

## Demo surfaces

Five compact surfaces are tagged for the deck gates:

| Surface | Mode | Purpose |
| --- | --- | --- |
| `argocd` | static | GitOps application view for appendix/recording |
| `grafana` | live | public GSK alerts and dashboards at `grafana.lab.platformrelay.dev` (appendix only) |
| `clubhouse` | live | public GSK served website at `demo.lab.platformrelay.dev` (appendix only) |
| `backstage` | live | GSK portal; public `portal.lab` HTTPRoute is proven live (200) |
| `crossplane-graph` | fallback | live portal graph remains open |

The five-minute spoken path contains no local or kind demo targets; live frames use public GSK
upstream URLs and remain optional appendix/recording aids. The evidence artifacts, manifests, and
tests must remain enough to evaluate a claim when a surface is unavailable.

## Commands

```bash
cd slides
pnpm install
pnpm exec playwright install chromium   # once, for PDF export
pnpm dev
pnpm lint
pnpm build
pnpm export                             # writes kaddy-deck.pdf
```

From the repository root, `task deck:export` wraps the PDF export gate. CI runs
`playwright install-deps chromium` then `playwright install chromium` before export.
`tests/deck/exit-recording-ready.sh` runs the composite deck gate. It
checks the build, visual tokens, global frontmatter, slide and cover counts, notes, script length,
surface markers, and ordered narrative timing.

## Content truth

Keep the main deck aligned with current evidence:

- local kind uses Cilium Gateway API;
- GSK uses Traefik v3 Gateway API because its managed Cilium cannot serve Gateway API (D-042);
- platform applications and workload intent are shared, while edge overlays differ;
- the Website XRD/demo claim, Dex GitHub OIDC, dashboards-as-code, Kyverno Enforce/default-deny,
  scorecard HTML/Pages, dated audits, public GSK HTTPS edge, Packer proof, the ephemeral Crossplane
  gridscale VM serve cycle, and the Nix image build are landed at their documented scope;
- Backstage runs on GSK; its public `portal.lab.platformrelay.dev` Gateway API HTTPRoute is live:
  it returns 200 through the fifth listener, a Ready Let's Encrypt certificate, and the
  `backstage:7007` backend (Cloudflare A → `185.241.34.187`). An external Alertmanager receiver,
  Loki ruler, Nix boot-to-serve, and upstream merges remain open.
- The GSK showcase image roll is **live-proven** (2026-07-20): caddy-mvp serves
  `ghcr.io/platformrelay/kaddy-showcase:0.6.0` (Rollout Healthy) and caddy-demo serves
  `caddy:2.11.4-alpine`; `caddy.lab` and `demo.lab` return HTTPS 200.
- E12d is a deck-only narrative change: the E10 public HTTPRoute proof landed independently, while
  the portal form-to-PR and read-path smoke remain E10 follow-on work. Upstream PRs remain filed
  and open, not merged; the Nix image build is landed while boot-to-serve remains open.

Do not turn fast-changing application or requirement totals into headline claims unless they are
derived from the authoritative repository script during the same refresh.

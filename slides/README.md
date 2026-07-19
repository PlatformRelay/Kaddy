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
| `argocd` | live | GitOps application view |
| `grafana` | live | alerts and dashboards |
| `clubhouse` | live | served website |
| `backstage` | fallback | portal runtime remains open |
| `crossplane-graph` | fallback | live portal graph remains open |

Live frames are optional recording aids. The evidence artifacts, manifests, and tests must remain
enough to evaluate a claim when a local endpoint is unavailable.

## Commands

```bash
cd slides
pnpm install
pnpm dev
pnpm lint
pnpm build
```

From the repository root, `tests/deck/exit-recording-ready.sh` runs the composite deck gate. It
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
- Backstage runtime, an external Alertmanager receiver, Loki ruler, Nix boot-to-serve, and upstream
  merges remain open.

Do not turn fast-changing application or requirement totals into headline claims unless they are
derived from the authoritative repository script during the same refresh.

# ADR-0112: Deck visual identity — hybrid kubernetes-workshop port

**Theme:** 01 · Platform · **Status:** Current · **Refs:** E12c, `../../kubernetes-workshop`

## Context

The E12 deck is engineered for a recorded gridscale-application walkthrough and should read as a
sibling to the operator's existing `kubernetes-workshop` Slidev deck for brand continuity. That deck
carries a distinctive dark, IDE-like identity driven by a `--kw-*` CSS-variable system (custom local
theme, Inter + JetBrains Mono, a footer + progress-bar + kicker/chip chrome). Its decorative accent
is **Kubernetes blue `#326ce5`**.

The Kaddy deck, however, has an established **golf/caddie identity in teal** — and its Mœbius
section-cover art (`slides/image-prompts.md`) uses a coastal-links palette (fairway green, sea teal).
Adopting k8s-blue wholesale would fight the cover art.

## Decision

**Hybrid port.** Adopt the kubernetes-workshop *structure* and keep Kaddy's *accent*:

| Adopt from kubernetes-workshop | Keep / override |
| --- | --- |
| `--kw-*` surface + text system (bg `#0b0e14`, panels, borders, `--kw-text*`) | — |
| Inter (sans) + JetBrains Mono (mono) via Slidev `fonts` | — |
| Footer + page-counter + 2px progress-bar chrome; uppercase mono kicker; chip/card motifs | — |
| Semantic status colors (`--kw-ok/warn/danger`) | — |
| Decorative accent `#326ce5` (k8s blue) | **Override to golf-teal** (fairway green / sea teal) to match the Mœbius covers |

Do **not** rewrite the deck's layout system: it keeps its seriph base + `CoverArt.vue` and the
S00–S14 stable-ID / placeholder-fallback cover convention. The port is palette + chrome + kicker/chip
motifs, not a from-scratch custom-layout theme.

## Consequences

- A `theme-tokens.sh` gate asserts the `--kw-*` vars are present and the accent is teal, not
  `#326ce5` — so a future edit can't silently drift to k8s-blue.
- Visual continuity with kubernetes-workshop (dark IDE look, same fonts, same chrome) without
  clashing with Kaddy's teal/coastal art identity.

## Counterpoints

- **Full k8s-blue** (maximum workshop continuity) — rejected: the blue chrome fights the fairway-green
  / sea-teal covers.
- **Palette-only, keep seriph, no chrome** — rejected: loses the signature workshop footer/progress/
  chip look that motivated the port.

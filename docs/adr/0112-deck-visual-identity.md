# ADR-0112: Independent coastal deck with five narrative covers

**Theme:** 01 · Platform · **Status:** Current · **Refs:** E12c, `../../kubernetes-workshop`

## Context

The interview deck needs the visual discipline of the existing Kubernetes workshop—strong type,
semantic cards and chips, restrained page chrome, readable diagrams, and clear status colors—without
coupling Kaddy to another package or copying its Kubernetes-blue identity.

The earlier one-cover-per-content-slide structure produced too many dividers and weakened the spoken
story. It also encouraged dense explanatory slides between decorative transitions. Kaddy already has
a coastal golf metaphor and should use it only where it improves the narrative.

## Decision

Keep the Kaddy deck as an independent Slidev package with its own components, dependencies, and CSS.
Adopt the workshop's design grammar, not its theme package:

- Inter and JetBrains Mono;
- tokenized surfaces, text, border, and semantic state colors;
- reusable card, chip, kicker, code, surface, diagram, grid, and footer/page chrome;
- readable Mermaid labels and dark framing around white live embeds;
- Material Symbols and MDI icons through a local `KdIcon.vue` wrapper.

Use Kaddy's accessible coastal palette: deep navy/graphite, warm off-white, sea-green accent,
sand/gold warning, and restrained coral danger. The compatibility `--kw-*` token names remain because
the existing quality gate verifies the workshop-derived grammar; their values and application are
owned by Kaddy.

Use exactly five `CoverArt` moments in the main deck:

1. opening;
2. architecture;
3. platform controls;
4. operations and delivery;
5. evidence and next steps.

The appendix uses content layouts. The five generated images retain the exact paths documented in
`slides/image-prompts.md`. `CoverArt.vue` keeps the placeholder fallback and visible
`AI generated` attribution.

## Consequences

- The main narrative stays concise while still carrying a continuous visual identity.
- Kaddy can evolve independently from the workshop package.
- Status is communicated through text, semantic color, and icons rather than decorative emoji.
- White embedded applications remain readable because each surface has dark framing and a caption.
- Any future sixth cover or stale cover path fails the deck quality gate.

## Counterpoints

- Importing the workshop theme would reduce local CSS, but would couple release cadence and carry
  visual assumptions that do not match Kaddy's coastal identity.
- Returning to a cover before every topic would create more artwork, but would slow the interview
  story and make the section hierarchy less clear.

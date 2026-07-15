# slides — kaddy interview deck (E12)

Slidev presentation showcasing the solution — conventions aligned with `kubernetes-workshop`.

## Planned sections

1. Pitch & caddie metaphor
2. Architecture (GSK → ArgoCD → Caddy → observability)
3. Security-first: netpols, labels, NIS2/KRITIS mapping
4. mulligan demo cue sheet (`task demo`)
5. scorecard evidence
6. Decisions & trade-offs (ADRs)
7. What's next (operator design)

## Scaffold (E12-S01)

```bash
cd slides
pnpm install   # after package.json added in E12
pnpm dev       # slidev slides.md --open
```

Placeholder deck: [`slides.md`](slides.md)

## Publish

GitHub Pages alongside scorecard (E12-S03).

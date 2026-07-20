---
name: design-architecture
description: >-
  Design a change and record the decision: ADR/AgDR, C4 sketch, weighted
  trade-off matrix, or a spec-first contract. Use when making a non-trivial
  design choice, when the operator says "design this", "write an ADR", "should
  we do X or Y", or before implementing anything with architectural weight.
---

# design-architecture — decisions, diagrams, trade-offs

Runs the `architect` role to turn a design question into a durable, queryable record. Use this
*before* `/agent-loop` when a choice has architectural weight, or *during* a lane when an unplanned
decision comes up.

## Step 1 — frame the decision
State the target repo, the decision to make, and its type: (a) choose-between-options → ADR +
trade-off matrix, (b) explain-the-shape → C4, (c) design-before-build → spec-first contract. If it's
a routine choice already covered by `GUIDELINES.md`, say so and skip — not everything needs an ADR.

**Challenge the premise first** (`AGENTS.md` → Adversarial collaboration): is this the right problem,
or is the framing itself wrong? If the direction looks mistaken, say so with reasoning before
producing the artifact — telling the operator they're solving the wrong thing is part of the job.

## Step 2 — dispatch the architect
Spawn the `architect` subagent with the repo path, the question, and pointers to `docs/adr/`,
`GUIDELINES.md`, and the relevant code. Ask for the specific artifact(s) from Step 1. It will read
prior ADRs first so it doesn't contradict a settled decision.

## Step 3 — record
Show the artifact. On confirmation:
- ADR → write to the repo's `docs/adr/NNNN-*.md` (this *is* product docs — it will be committed with
  the implementing lane, gitmoji `docs: :memo:`; not part of the local harness).
- C4 / trade-off matrix → into the ADR, the story, or `agent-context/` as appropriate.

## Step 4 — hand off
End with the implication for implementation (what the story/lane must now do) and, if the decision
touches security or the CRD API, flag maintainer-LGTM-required per GOVERNANCE. Append a **DECISION**
line to the INBOX so the ADR gets reviewed rather than merged unseen.

## Do not
- Manufacture an ADR for a decision already settled by GUIDELINES or an existing ADR — supersede
  explicitly or skip.
- Produce four vague C4 levels — one clear level is better.
- Decide without reading the prior `docs/adr/` corpus.

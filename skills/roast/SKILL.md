---
name: roast
description: >-
  Roast me — adversarial critique of a plan, design, or diff to find where it
  breaks, via pre-mortem, red-team, and steelman-then-destroy. Use when the
  operator says "roast this / roast me", "tear this apart", "where does this
  break", "red-team it", or wants a brutal-honesty review before committing.
---

# roast — adversarial critique

Dispatches the `roaster` role to attack the work from a fresh, unsentimental perspective. Use it
*before* committing to a plan, *before* opening a big PR, or whenever you want the failure modes
surfaced rather than discovered in production. Complements `/tech-review` (which gates a diff) and
`/grill-me` (which interviews you) — this one attacks the artifact.

## Step 1 — set the target and mode
Point at the artifact: a plan/design (paste or file), an ADR, or a diff/branch. Choose mode(s):
pre-mortem, red-team, steelman-then-destroy, or all three (default). State the goal it's supposed to
achieve so the roaster judges gaps against intent, not taste.

## Step 2 — dispatch the roaster
Spawn the `roaster` subagent with the artifact, its stated goal, the relevant repo context
(`GUIDELINES.md`, code paths), and the chosen mode(s).

## Step 3 — triage the findings
Present the critique. Separate **would-sink-this** (P0/P1) from optional taste items. For each real
finding, decide: fix now, turn into a backlog story (`/write-story`), record as accepted risk (in the
ADR / handoff), or refute with evidence. End with the single cheapest risk-reducer.

## Step 4 — log it for review
Save the critique to `agent-context/inbox/reports/<YYYY-MM-DD>-roast-<slug>.md` and append a
**REPORT** line to the INBOX (repo or workspace) so it's on the operator's review queue, not just in
scrollback.

## Do not
- Treat the roast as a verdict to act on blindly — weigh each finding; refute with evidence where the
  roaster is wrong.
- Let it pad the list with style nits dressed as risks — those go in a clearly-optional bucket.
- Use it to gate a PR — that's `/tech-review`.

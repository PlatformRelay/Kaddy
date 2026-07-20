---
name: write-story
description: >-
  Turn an epic, feature idea, or vague ask into INVEST-compliant vertical-slice
  stories with Given-When-Then acceptance criteria, mapped onto the target repo's
  backlog. Also writes well-formed fixes. Use when the operator says "write a
  story/epic/fix", "break this down", or "add this to the backlog".
---

# write-story — epics, stories, and fixes

Produces buildable, testable backlog items. Delegates the drafting to the `epic-writer` role so it
runs in fresh context and stays grounded in the target repo.

## Step 1 — scope
Identify the **target repo** and the raw intent (epic / feature / bug). If the intent is a wall of
requirements, note that multiple stories will come out. If you can't tell which repo or what outcome
is wanted, ask one sharp question first.

**Challenge the ask** (`AGENTS.md` → Adversarial collaboration): if the epic solves the wrong problem,
duplicates existing work, or a requested slice is a bad idea, say so — with a better alternative —
before writing stories. Don't dutifully spec work that shouldn't be built.

## Step 2 — dispatch the epic-writer
Spawn the `epic-writer` subagent with: the target repo path, the raw intent, and a pointer to that
repo's `AGENTS.md` + `agent-context/GUIDELINES.md` + existing backlog file (so it matches the ID
scheme and format). Ask it to return INVEST vertical-slice stories (or a well-formed fix) in the
repo's story format, grounded by grepping the code.

## Step 3 — place the result
Show the stories. On confirmation, append them to the target repo's backlog file (`daily-backlog.md`
/ `BACKLOG.md` / `roadmap.md`) under the right priority, using the next free ID in the scheme. This
is a local agent-context edit — never a product-code commit.

## Step 4 — recommend the first slice
End with: which slice to start first, why (priority × unblocks × risk), and the `/agent-loop` command
to begin it.

## Do not
- Write production code — this skill produces stories, not implementations.
- Invent a new ID scheme or story format — match the target repo's existing one.
- Emit happy-path-only criteria — every story needs an edge/error case.
- Create an epic-sized story — split it into vertical slices.

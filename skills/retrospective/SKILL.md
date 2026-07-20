---
name: retrospective
description: >-
  End-of-session learnings loop. Extract what worked, what failed, and what was
  newly discovered, then write it back into agent-context and propose concrete
  skill/guideline refinements so the harness compounds over time. Use at the end
  of a session, after a lane lands, or when the operator says "retro / capture
  learnings / what did we learn".
---

# retrospective — capture learnings, improve the harness

Turns a finished session into durable improvement. The harness should get better every time it runs;
this skill is how. Runs in the main session (it needs the session's own history) — not a subagent.

## Step 1 — reconstruct
Review what this session actually did: the lane(s), what landed, what got stuck, surprises, dead ends,
and any place a skill/guideline was wrong, missing, or slowed you down.

## Step 2 — extract (be specific, not generic)
- **Worked** — patterns/commands/approaches to keep. (Not "TDD is good" — "envtest `Eventually` with
  2s poll flaked; 5s fixed it".)
- **Failed / friction** — what wasted time; the root cause, not the symptom.
- **Newly discovered** — facts about the codebase/tooling not written down anywhere (a gotcha, a gate
  quirk, a hidden dependency).

## Step 3 — write it back
- Update `agent-context/coordination/SESSION-HANDOFF.md` (repo state, in-flight, next entry points).
- Durable project facts → the relevant repo's `agent-context/` (not here) or an ADR if it's a
  decision.
- Cross-session harness facts → propose a concrete edit to the specific skill/guideline that was
  wrong or missing, and (on confirmation) apply it. This is the self-improving loop — name the file
  and the change, don't just note "improve the skill".

## Step 4 — surface follow-ups & tidy the inbox
Anything discovered that deserves work → propose as backlog stories via `/write-story`. Then reconcile
the **INBOX**: tick or move to *Resolved* anything handled this session, and add any new open
question/report/PR the session produced, so the operator's review queue reflects reality.

## Do not
- Write vague, generic lessons — if it isn't specific enough to act on, cut it.
- Duplicate a fact the code or git history already records — capture what was non-obvious.
- Silently rewrite a skill — name the file and change, confirm, then apply.

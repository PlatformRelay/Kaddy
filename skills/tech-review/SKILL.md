---
name: tech-review
description: >-
  Review a lane/branch before opening (or while awaiting) a PR in any PlatformRelay
  repo. Runs the gate matrix and TDD/correctness/quality/security/docs review plus
  an AI-code failure-mode pass, and returns APPROVE / REQUEST CHANGES / BLOCK. Must
  run before every PR. Use when asked to "review the lane / check before merging".
---

# tech-review — pre-PR technical review

The shared review gate for the workspace. Runs the `tech-reviewer` role in fresh context, posts a
structured verdict, and **never self-approves**. Repo-specific wrappers (`/mkurator-review`,
`/kollect-mr-review`) call into this with the repo's gate set pre-filled.

## Step 1 — gather inputs
Target repo, lane name, branch, worktree path, base SHA (`origin/main`), and the story/board scope.
Run from inside the worktree.

## Step 2 — dispatch the tech-reviewer
Spawn the `tech-reviewer` subagent with those inputs and pointers to the repo's `AGENTS.md` +
`GUIDELINES.md`. It orients on intent, runs the gate matrix, reviews all dimensions + the AI-code
failure-mode pass, adversarially prunes its own findings, and returns a REVIEW block with a verdict.

## Step 3 — post and stop
- Post the REVIEW block to `agent-context/coordination/OPERATOR-BOARD.md` under RESULTS (audit trail).
- If a PR is open, post the same as a **PR comment** (`gh pr comment` — never `gh pr review
  --approve`). This is what the maintainer reads to decide.
- Update the board row to the verdict:
  - **APPROVE** — `🟢 PR open … reviewed APPROVE, awaiting maintainer merge`. Do nothing further, and
    append a **PR** line to the INBOX so the merge is on the operator's queue.
  - **REQUEST CHANGES** — leave `🔶 In flight`; list required items; worker fixes and re-runs this.
  - **BLOCK** — `🔴 BLOCKED`; escalate in SESSION-HANDOFF Blockers; do not re-run until the maintainer
    weighs in.

## Do not
- Let the review approve or merge — it produces findings; the maintainer merges.
- Skip it before a PR, or open a PR on a REQUEST CHANGES / BLOCK verdict.
- Re-review the same lane without a fresh gate run between changes.

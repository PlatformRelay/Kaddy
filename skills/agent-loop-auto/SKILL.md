---
name: agent-loop-auto
description: >-
  Autonomous variant of /agent-loop for ONE repo: thin coordinator + parallel implementer subagents +
  a coordinator-dispatched INDEPENDENT reviewer, plus an Integrator subagent that auto-merges each PR
  (rebase) without operator input once gates + independent APPROVE + CI are green — then loops to the
  next lanes until the backlog is exhausted or a stop condition hits.
  Invoking this skill is the operator's explicit authorization to merge autonomously. Use for hands-off
  progress on your OWN backlog; never for external-contributor PRs.
---

# agent-loop-auto — autonomous parallel loop (auto-merges)

Everything `/agent-loop` does (thin coordinator + **parallel** implementers + **coordinator-dispatched
independent review**, per-repo, TDD → gates → review), **plus**: it **auto-merges** each lane's PR when
it passes, then keeps picking new lanes until done. Read `/agent-loop` for the implementer procedure,
the independent-review step (3b), and the role schemas — this file only states what's different: the
auto-merge gate and a dedicated **Integrator subagent** that keeps merge work off the coordinator.

> **Autonomy is operator-authorized by invoking this skill.** It overrides the base loop's
> "operator merges" step — but only within the guardrails below. This is *your own* backlog being
> advanced hands-off; it is **not** a path to merge other people's code.

## When to use
- You want the harness to work through a repo's backlog and land the results without babysitting.
- **Not** for external-contributor PRs — those always need operator-visible review (`/merge-open-prs`).

## Auto-merge gate (ALL required, per lane)
A lane's PR auto-merges only when **all** hold:
1. Full gate matrix green (repo config) — `task verify/lint/test/coverage/scrub` or `pnpm build/export`.
2. The **coordinator-dispatched independent reviewer** (base Step 3b — a fresh subagent that saw only
   the diff, never the implementer's context) returned **APPROVE** with **no P0/P1** findings.
3. CI is **green on the PR's head commit** (`gh pr checks`), and the PR is **MERGEABLE** (no conflicts).
4. The lane's author is the harness/operator (never an external contributor's PR).

Then the coordinator hands the lane to an **Integrator subagent** (below) — it does not merge inline.

> **Permission-layer veto (learned 2026-07-16, mkurator):** in auto-permission/background environments
> the classifier may categorically deny `gh pr merge` to the default branch (public-deploy-triggering
> merges especially) — even when this gate is fully satisfied. Do not route around a denial. Fallback
> per gate-clean lane: record the PR in the repo INBOX 🟢 with the exact merge command, and ask the
> operator directly if they are live. True auto-merge requires the operator to add a `gh pr merge`
> allow rule to the repo's `.claude/settings.local.json` (mkurator has one since 2026-07-16).

## Integrator subagent (keeps merge work off the coordinator)
For each gate-clean lane the coordinator dispatches **one Integrator subagent** — the coordinator does
not rebase/merge inline. The integrator:
1. **Rebase onto current `main` first — isolation worktrees can come up on a STALE base.** An
   `isolation:"worktree"` worktree may be created at an earlier session HEAD, not the live `main` (seen
   this run: a worktree 7 commits behind). `git rebase main` the lane head; **never ff-merge an
   unrebased head**. (Tell implementers to `git merge --ff-only main` at lane start too.)
2. **Re-run the full gate matrix on the rebased head** (file-disjoint lanes rebase clean — verify anyway).
3. `gh pr merge <n> --rebase --delete-branch`. **If the classifier denies the merge (veto note above),
   do not route around it** — return `{merged:false, error:"classifier-veto"}` so the coordinator runs
   the INBOX-record fallback.
4. **Return** `{ lane, merged, mainSha, error? }`. On success the coordinator moves the board row to
   **Integrated**, clears any matching INBOX task, and updates `SESSION-HANDOFF`; on `error` it records
   and skips. The coordinator routes on this schema — it does not read the merge output itself.

Integrators run **serialized** (one merge to `main` at a time); implementers stay parallel.

## Stop conditions (halt the loop and hand back)
Stop and surface via the repo's INBOX (a **DECISION** with options) when any occur:
- Backlog empty, or no remaining **non-overlapping** lanes to parallelize.
- A lane hits **BLOCK / REQUEST CHANGES**, red or pending CI, or a merge conflict — leave that PR open,
  don't merge, record why.
- A change touches **security, public API/CRD, or release** — surface for a human look before merging
  even if gates pass (don't silently auto-merge high-blast-radius changes).
- `main` CI goes red after a merge — stop starting lanes, diagnose.
- A configured ceiling is reached: max lanes, max iterations, or the turn's token budget.

## Flow
1. **Steps 1–3b of `/agent-loop`** — orient, pick N non-overlapping lanes, dispatch parallel
   implementers, then dispatch the **independent reviewer** per lane; collect the structured returns.
2. For every lane meeting the auto-merge gate, **dispatch an Integrator subagent** (above); skip +
   record the rest. The coordinator routes on each integrator's `{merged, error?}` return — it does not
   rebase or merge inline.
3. **Loop:** pick the next batch of independent lanes and repeat, until a stop condition.
4. **Report + `/retrospective`:** what merged, what was skipped and why; log notable decisions to
   `decisions.md` (including any dissent). Leave the repo green.

## Do not
- Auto-merge on anything less than **gates green + independent APPROVE + green CI + mergeable**.
- Merge inline in the coordinator, or run integrators in parallel — merges to `main` are serialized.
- Auto-merge an **external contributor's** PR, or a security/API/release change without surfacing it.
- Run past the stop conditions / ceilings, or force-merge / use `--admin` / bypass branch protection.
- Parallelize machine-locked suites (e2e/integration), or coordinate across repos.
- Merge partial or self-unreviewed work — every merge still passes the same independent review gate as
  `/agent-loop` (a fresh reviewer that never saw the author's context).

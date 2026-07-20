---
name: handover
description: >-
  Wrap up a session cleanly and produce a copy-pasteable prompt to start the NEXT one. Snapshots where
  the repo is (tip, CI, release), TIDIES UP (lands/merges what's mergeable, deletes merged branches,
  removes stale worktrees and leftover files), UPDATES the coordination files (INBOX, SESSION-HANDOFF,
  OPERATOR-BOARD, decisions), works out what comes next (without stopping early), captures the
  operator's standing permissions/work-style/constraints to memory, and emits the ready-to-paste
  prompt. Use when the operator says "prepare a handover / give me a prompt for the next session /
  wrap up and hand off / leave it clean". Distinct from /retrospective (which captures learnings to
  improve the harness); handover produces the START-THE-NEXT-SESSION artifact + a clean repo.
---

# handover — leave it clean, hand the next session a running start

Two deliverables: (1) a repo left tidy and a coordination trail that reflects reality, and (2) a prompt
the operator can paste to resume with zero re-explaining, backed by durable state the next session
auto-loads. Runs in the main session (it needs this session's own history).

## Step 1 — snapshot the current state (verify, don't recall)
Check the repo, don't trust memory of it: current branch + tip SHA; `main` CI status (`gh run list
--branch main` — is it actually green?); latest tag / release; open PRs (`gh pr list`); local **and
remote** branches (`git branch -a`, `git ls-remote --heads origin`); worktrees (`git worktree list`);
uncommitted/untracked cruft (`git status`). Note anything in-flight (a lane mid-implementation, a PR
awaiting merge, a partial release).

## Step 2 — clean up (branches, worktrees, leftover files)
Leave the workspace as you'd want to find it. Only touch what is safely merged or genuinely scratch —
never discard unmerged work without flagging it.
- **Branches:** land/merge anything mergeable per the operator's permissions; then delete merged
  branches **on remote and local** (`git push origin --delete <b>`, `git branch -D <b>`) and
  `git fetch --prune`. Confirm each is merged first (`git merge-base --is-ancestor <b> origin/main`).
- **Worktrees:** `git worktree remove` any finished/idle worktrees; verify only the intended checkout
  remains.
- **Leftover files:** remove scratch/temp artifacts this session created (build junk, `$CLAUDE_JOB_DIR/tmp`
  outputs, botched/dangling commits, generated files not meant to land). Resolve or stash stray
  working-tree edits so `git status` is clean (mind that `agent-context/coordination/*` is untracked
  scratch — that's expected, not cruft).
- End state: ideally only `main` (local + remote), a single worktree, no open PRs, a clean tree.

## Step 3 — update the coordination files to reflect reality
Bring the paper trail current so the next session (and the operator) cold-start from truth:
- **`agent-context/INBOX.md`** (tracked — commit it): tick/resolve what this session handled; add new
  open decisions/tasks/PRs; record any decide-and-log calls; correct anything now stale.
- **`agent-context/coordination/SESSION-HANDOFF.md`**: repo tip, CI state, what this session did,
  next entry points. (Working-tree scratch — see Step 5 for the durable copy.)
- **`agent-context/coordination/OPERATOR-BOARD.md`**: move landed lanes to Integrated/Done; clear
  In-flight.
- **`agent-context/decisions.md`** (tracked): append any decisions made this session.

## Step 4 — work out what comes NEXT (and don't stop early)
From `docs/ROADMAP.md`, `agent-context/BACKLOG.md`, `openspec/changes/`, and the INBOX: what is the next
unblocked work, in dependency order? **Explicitly check whether there is a further phase / milestone
after the obvious next one** — if so, the next session should drive through to completion, not halt at
the first milestone. State the full remaining arc (E-x → E-y → … → optional/deferred) so the prompt
says "continue until the track is done", not "do E-x".

## Step 5 — capture standing decisions + persist durably
Gather from THIS session's history (only what the operator actually granted — never invent authority):
- **Permissions** — merging PRs, pushing to `main`, cutting releases, provisioning live infra, etc.
  Note what stays operator-only (force-push, deleting published tags/releases, history rewrites).
- **Work-style** — parallel lanes (how many), decide-and-log vs stop-to-ask, the gate/review cycle.
- **Constraints** — cost-sensitivity (tear down live infra after each test; smallest footprint),
  offline-gates-first, anything emphasized.
- **Classifier gotcha** — the auto-mode classifier does NOT treat a skill invocation as merge/push
  authorization; the next session must add explicit `.claude/settings.json` Bash allow-rules at start
  (the agent can't edit settings itself — that's classifier-blocked). Put this in the prompt.

Persist all of the above to the **memory dir** (`.../memory/<name>.md` + a MEMORY.md index line) —
memory is auto-loaded every session, so it survives even when working-tree scratch does not. **Do not
rely on `agent-context/coordination/*` alone**: those files are reset by `git checkout -B main` /
branch switches. Cross-link related memories with `[[name]]`.

## Step 6 — emit the prompt
Output a single fenced ```code block``` the operator can copy verbatim. Self-contained:
- **Goal** — drive the identified arc to completion (not stop at milestone 1 of N), same quality bar.
- **Scope, in order** — the epics/lanes with pointer files (ROADMAP, openspec change).
- **Work-style** — parallel lanes + decide-and-log, in the operator's own terms.
- **Permissions** — exactly what was granted + the "add the settings allow-rules at start" reminder.
- **Constraints** — cost/infra/offline-first, as hard rules.
- **First move** — "read the auto-loaded memory `<name>` and SESSION-HANDOFF.md for full state."
Then, in prose (not in the block), give a one-line status recap and flag any setup step the operator
must do that the agent can't (settings edits, `direnv allow`).

## Do not
- Delete or discard unmerged work, or delete a published tag/release, without flagging it — clean only
  what is merged or genuinely scratch.
- Invent permissions or scope the operator didn't grant — capture only what was actually said.
- Emit a vague prompt ("continue the work") — name the goal, scope, permissions, constraints.
- Skip the "is there a next phase?" check — a prompt that stops at milestone 1 of N wastes the session.
- Persist the handover only to `agent-context/coordination/*` — it gets reset; memory is the durable home.
- Duplicate /retrospective — handover is the next-session prompt + cleanup, not the harness-improvement
  loop; run both at end of session if useful.

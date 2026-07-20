---
name: agent-loop-local
description: >-
  Maximum-autonomy variant of /agent-loop-auto for ONE repo: no PRs — each lane is gated by a
  coordinator-dispatched INDEPENDENT reviewer, then a serialized non-isolated Integrator subagent
  rebases and ff-merges it into main LOCALLY and pushes; CI is watched in the background, non-blocking.
  Optimizes for many parallel implementers and fast completion until the backlog is exhausted.
  On questions/uncertainties the coordinator decides itself (best option) and logs the decision
  to the repo INBOX for later operator approval instead of stopping. Invoking this skill is
  explicit authorization to merge locally, merge open own MRs, and cut releases when timely.
  Never for external-contributor code.
---

# agent-loop-local — local-merge sprint loop (no PRs, decide-and-log)

Everything `/agent-loop` does (thin coordinator + parallel implementers + **coordinator-dispatched
independent review**, per-repo, TDD → gates → review), but lanes land by **local rebase + ff-merge into
`main`**, pushed directly — **no PRs**. CI runs **after** the push and is watched **in the background,
non-blocking**. The loop refills lanes continuously and runs until the backlog is exhausted. Read
`/agent-loop` for the implementer procedure, the independent-review step (3b), and the role schemas, and
`/agent-loop-auto` for the autonomy framing — this file states only what's different: the local merge
gate and a **serialized, non-isolated Integrator subagent** that keeps merge/push work off the coordinator.

> **Invoking this skill is the operator's authorization** to: merge lanes locally without PRs,
> resolve questions autonomously (with an INBOX note), merge the operator's own open MRs, and cut
> releases when the moment is right. It is still **never** a path to land other people's code.

## When to use
- You want the backlog burned down as fast as possible and are fine approving decisions after the fact.
- **Not** for external-contributor PRs/MRs, and not when you want to eyeball each change before it
  lands — use `/agent-loop` or `/agent-loop-auto` for that.

## Local overrides to base Steps 3 / 3b (NO PRs here)
Base Step 3/3b assume a PR; local has none. Override:
- **Implementer:** commit + push the **lane-head branch** (a ref for review), but **do not `gh pr
  create`** and do not open a PR. Return `{ lane, branch, headSha, gateResults, selfCheck, blocker? }`
  (no `prUrl`); leave the worktree open for the fix loop.
- **Independent reviewer:** the coordinator dispatches a fresh reviewer subagent given the **lane-head
  ref**; it reviews the change with `git diff main...<lane-head>` (there is no `gh pr diff` — no PR),
  and runs any lab/tutorial lane end-to-end. Its verdict feeds the **coordinator's routing + the
  board/INBOX log** — **not** a PR comment. On APPROVE the lane proceeds to the Integrator (below).

## Local merge gate (ALL required, per lane — CI is NOT in this gate)
1. Full gate matrix green **on the rebased head** (repo config in `/agent-loop`).
2. The **coordinator-dispatched independent reviewer** (base Step 3b — a fresh subagent that saw only
   the diff, never the implementer's context) returned **APPROVE** with **no P0/P1** findings
   (REQUEST CHANGES → resume the implementer, then a fresh re-review; on BLOCK the lane is parked).
3. The work is harness/operator-authored.

## Integrator subagent (serialized, NON-isolated — keeps merge/push off the coordinator)
Local merges land on the **real `main` in the shared checkout**, so the integrator is a
**non-isolated** helper (NOT `isolation:"worktree"` — a worktree is isolated *from* main and cannot
ff-merge it). The coordinator dispatches **one integrator at a time** (merges to `main` are serialized;
implementers stay parallel) and routes on its structured return — it does not run these git ops itself.
The integrator runs, via Bash:
```
git fetch && git rebase main <lane-head>      # worktrees can come up on a STALE base — always rebase
<re-run full gate matrix on the rebased head> # file-disjoint lanes rebase clean; verify anyway
git checkout main && git merge --ff-only <lane-head>
git push origin main
```
Never ff-merge an unrebased head; never batch-push multiple unverified merges. (Tell implementers to
`git merge --ff-only origin/main` at lane start too.) On success the integrator also does the
bookkeeping via **Bash writes** (board row → **Integrated**, clear matching INBOX task, update
`SESSION-HANDOFF`) — the background coordinator cannot Edit the shared checkout, but the integrator's
Bash writes can. It **returns** `{ lane, merged, mainSha, error? }`; the coordinator refills the next
lane on that return.

> **Classifier reality (do this at session START):** invoking this skill does **not** authorize the
> auto-mode classifier — `git push origin main` and `gh pr merge` are blocked until the operator adds
> explicit `.claude/settings.json` Bash allow-rules. Without them the loop deadlocks (a "CI green"
> goal-hook can never clear because you can't land the fix). You cannot add the rules yourself
> (settings edits are classifier-blocked); ask the operator up front, or the whole loop stalls at the
> first merge. **An explicit in-session sentence from the operator also clears it** (not only settings
> rules) — often faster — BUT it authorizes only the **specifically-named action classes**: a 2026-07-19
> kaddy loop confirmed "I authorize push + live gridscale/kubectl writes" unblocked exactly those, yet a
> later **remote-branch delete** stayed blocked (never named), and a blanket "authorize all the things"
> did **not** cover unnamed destructive ops. So name each class you'll need (push-to-main, live-infra
> writes, remote-branch delete, release-tag). `git push -f` and deleting published tags stay blocked
> regardless — for a bad pushed tag, `git push origin :refs/tags/<vX>` then re-push.
> **Compound-command gotcha:** a Bash call containing a blocked action fails **as a whole** — `git
> checkout main && git merge --ff-only <lane> && git push` does the *neither the merge nor the push* when
> push is blocked. Run the blocked/uncertain action as its **own final Bash call**, never chained after
> work you need to actually happen.

> **Implementer-startup 529s:** if background implementer subagents die on transient API 529 at launch
> (0 tool calls) more than ~2×, stop burning retries — implement the lanes **inline** in the main
> session instead (still one logical change per commit). This bends "thin coordinator" for throughput,
> and that's fine — **but independence must not bend**: inline work is still gated by a **fresh,
> coordinator-dispatched reviewer subagent** (Step 3b), never the coordinator reviewing its own inline
> code. Independent review is the guardrail that matters, not who typed the code.

## CI — background watch, non-blocking
After each push to `main`, start a **background watcher** (`gh run watch <run-id> --exit-status`
via Bash `run_in_background`, or poll `gh run list`) and **keep dispatching/merging** — do not wait.
When a watcher reports **red main**:
0. **First confirm it's a CODE failure, not GitHub infra.** Read the *failed step name*: a
   tooling-install step (e.g. `arduino/setup-task`, any action fetching from the API) failing means an
   **api.github.com incident** — every run false-reds at the install step before your code runs, and
   `gh` mis-reports "invalid token in keyring" (it validates against the dead API). Diagnose:
   `curl https://www.githubstatus.com/api/v2/status.json`. If it's an incident: do **NOT** fix-forward
   or revert (nothing is broken) — wait it out; `git push` is unaffected (different subsystem); read
   run status / trigger reruns / cut releases via the git-credential token
   (`TOKEN=$(printf 'protocol=https\nhost=github.com\n\n' | git credential fill | grep ^password | cut -d= -f2)`
   then `curl -H "Authorization: Bearer $TOKEN" https://api.github.com/...`). Re-verify green once the
   incident clears.
1. **Freeze merges** (implementers may keep implementing). The coordinator owns this fix-forward/revert
   **decision** (it's routing); the execution is a dispatched lane, not coordinator handiwork.
2. Dispatch a top-priority **fix-forward lane**; if no green fix within ~2 attempts, **revert** the
   offending commit (`git revert`, push) to restore green, park the lane, log an INBOX note.
3. Unfreeze once main is green.
Releases are the one exception where CI is blocking (below).

## Decide-and-log (replaces stop-and-ask)
Questions, ambiguities, and judgment calls do **not** halt the loop. The coordinator (or implementer):
pick the **best option** by the repo's goals/guidelines, proceed, and append to the repo's
`agent-context/INBOX.md`:
```
🟡 DECIDED (awaiting approval) — <one-line decision>
   Context: <why it came up> · Options: <A/B/C considered> · Chose: <X> because <one line>
   Revert: <concrete command/steps if the operator disagrees>
```
Also log to `decisions.md`. High-blast-radius calls (security, public API/CRD, release scope) are
still **decided, not blocked** — but flagged `🔴 DECIDED` so the operator reviews them first.

## Expanded authority (use when it advances the stories' goal)
- **Merge own open MRs/PRs:** apply `/merge-open-prs` rules — operator-authored + green CI merges;
  external-contributor MRs are never touched.
- **Releases:** when a natural point is reached (milestone done, meaningful user-facing changes
  accumulated, backlog section cleared) and **main CI is confirmed green** (blocking check here),
  cut one: `/changelog`, bump per repo convention, tag, push tag. Log a `🔴 DECIDED` INBOX note
  with the version and rationale.
- **Housekeeping:** backlog grooming, flaky-gate fixes, small doc/board corrections — anything
  cheap that unblocks throughput. Big refactors still need a lane of their own.

## Throughput rules
- **Continuous refill, no batch barrier:** the moment an implementer finishes (and its lane clears
  independent review), pick the next non-overlapping lane and dispatch — don't wait for the batch.
  Default **N=4** concurrent implementers, cap ~6 if lanes are small and disjoint.
- Lanes must own **disjoint file paths**; machine-locked suites (e2e/integration, live-cluster
  labs) still serialize per host.
- Loop until the **backlog is exhausted**, then: final CI check, optional release, `/retrospective`,
  and a report — merged lanes, decisions logged, anything parked and why.

## Stop conditions (the short list)
- Backlog exhausted (that's success, not failure).
- Main red and neither fix-forward nor revert restored green.
- An action would be destructive/irreversible (force-push, history rewrite, deleting released tags)
  — park it with a `🔴 DECIDED`-style INBOX question instead.
- A ceiling: token budget, session/account limit (check reset time before re-dispatching), max iterations.

## Do not
- Open PRs (that's the other loops), or merge anything skipping rebase + gates + independent APPROVE.
- Merge inline in the coordinator, or run integrators in parallel — merges are serialized; implementers
  are parallel. Let an implementer (or the coordinator's own inline work) skip a fresh independent review.
- Block on CI for ordinary merges, or ignore a red-main report from a watcher.
- Touch external-contributor code, force-push, use `--admin`, or bypass branch protection.
- Stop to ask when a reasonable best option exists — decide, log, continue.
- Commit `agent-context/` files (gitignored by design), add AI trailers, or modify git config.

---
name: agent-loop
description: >-
  Start or resume implementation in one PlatformRelay repo. A THIN coordinator picks lanes and delegates
  to implementer subagents — in PARALLEL when there are multiple independent (non-overlapping) lanes —
  each isolated in its own worktree, running TDD → gate-matrix → PR. Every lane is then gated by an
  INDEPENDENT reviewer the coordinator dispatches (the author never reviews its own code). Stops at PR
  for the operator to merge. The spine of the harness; use to start/resume any coding session.
---

# agent-loop — the session driver (thin coordinator + delegated roles)

A **thin coordinator** orchestrates three delegated subagent roles; it does not do their work itself.
Its whole job is **orient → pick lanes → delegate → route structured verdicts → refill**. It acts on
the **structured return** of each subagent (below) and does **not** re-read diffs or logs to decide —
that is what keeps the parent session lean.

| Role | Who | Does | Returns (schema) |
| --- | --- | --- | --- |
| **Implementer** | implementer subagent, own worktree, parallel | TDD → gates (for iteration) → commit → push → open PR. **Never reviews its own lane.** | `{ lane, branch, prUrl, headSha, gateResults, selfCheck, blocker? }` |
| **Independent reviewer** | fresh subagent the **coordinator** spawns on the pushed branch | adversarial, **diff-only** review (`/tech-review`); the author's reasoning is never in its context | `{ verdict: APPROVE\|REQUEST_CHANGES\|BLOCK, findings: [{sev: P0..P3, note}], summary }` |
| **Integrator** | (auto/local variants only) | rebase → re-run gates on rebased head → merge → push | `{ merged, mainSha, ciRunId?, error? }` |

When several independent lanes exist, implementers run **concurrently, each in its own git worktree**.
Parameterized by the target repo (reads its `AGENTS.md` + `GUIDELINES.md` for gates). **Repos are
independent — one loop targets one repo**; run separate loops for separate repos, never coordinate
across them.

## Repo config (resolve TARGET first)
| Target | Layer | Gate commands | Merge model |
| --- | --- | --- | --- |
| `mkurator` / `kollect` | Go (GUIDELINES §B) | `task verify` · `task lint` · `task test` · `task coverage` · `task scrub` | PR into `main`; operator merges (or `/merge-open-prs`) |
| `kubernetes-workshop` / `opentofu-workshop` | Content (§C) | `pnpm build` · `pnpm export` · `kubectl`/`tofu` dry-run | PR into `main`; operator merges |

If you cannot state in one sentence which repo and what each lane is *for*, **stop and ask**.

## Step 1 — orient (the TARGET repo's own agent-context — never other repos)
```
<TARGET>/agent-context/INBOX.md                          # what needs the operator here — check first
<TARGET>/agent-context/coordination/OPERATOR-BOARD.md    # this repo's lanes + locks
<TARGET>/agent-context/coordination/SESSION-HANDOFF.md   # this repo's state, in-flight, next
<TARGET>/agent-context/  (BACKLOG / daily-backlog / roadmap)
```
Confirm `main` is green: `cd <TARGET> && gh run list --limit 5`. **If main CI is red, don't start new
lanes — fix it first.** If a blocking question arises, file a **DECISION** in the repo's INBOX (with
options) rather than guessing silently.

## Step 2 — pick lanes (one, or several non-overlapping for parallel)
Use `/pick-next-story` or the backlog. For **parallel** work, select up to **N lanes (default 3, cap
~4)** that own **disjoint file paths** — no two lanes may touch the same package/file. If picks would
overlap, serialize them instead. Never pick a lane already `🔶 In flight`.

**Pressure-test the picks first** (`AGENTS.md` → Adversarial collaboration): if a pick, its approach,
or the parallelization carries a real risk, a hidden dependency, or a clearly better sequencing, say so
before dispatching. Record any dissent in the repo's `decisions.md`.

## Step 3 — dispatch implementers (parallel when >1 lane)
The coordinator **neither writes product code nor reviews its lanes** — implementers write, an
independent reviewer gates. For each lane:
1. **Claim it** on the repo's `OPERATOR-BOARD.md` **In flight** (before dispatch) so lanes can't collide.
2. **Spawn a background implementer subagent** (`Agent`, `run_in_background: true`,
   `isolation: "worktree"`) with the lane spec + the implementer procedure below. Each gets its **own
   worktree**.
Cap concurrency at N. **Machine-locked suites** (Go `e2e`/`integration`, workshop live-cluster labs)
run one-at-a-time per host — lanes needing them must serialize; parallelize only unit/envtest/build lanes.

### Implementer procedure (each subagent, in its own worktree)
- **TDD** (`GUIDELINES §A3`/§B4): red → green → refactor per unit of behaviour. No code before a red test.
- **Bounded test-replay:** track failing tests in a scratch `.agent-loop-status.json` (not committed);
  cap **3 fix-attempts per test**, then mark it blocked with a one-line hypothesis — don't hammer it.
- **Gate matrix** (per repo config): iterate on the fast gate, then run the full set before each commit
  (Go: `task verify && task lint && task scrub`; content: `pnpm build && pnpm export` + dry-run).
  Regenerate codegen (`task manifests && task generate && task verify`) after CRD/webhook/RBAC changes.
- **Lab/tutorial lanes — run the content end-to-end against the real tool before review.** For any lane
  authoring runnable learner content (a lab, tutorial, or step-by-step doc), the gate matrix is
  necessary but **not sufficient**: a config that is invalid but *commented out* — or a fabricated tool
  output — passes `validate`/build/lint yet detonates only when a learner runs the step. Execute the
  whole flow against the real tool (`tofu`/`kubectl`/etc.) and capture every documented output verbatim.
  The real run is the gate.
- **Commits:** `:gitmoji: <type>(<scope>): <summary>`, one logical change each, tree green; no AI trailers.
- **Push + PR:** `git push -u origin <branch>`; `gh pr create --base main …`. **Do not review your own
  lane and do not merge** — review is a separate, coordinator-dispatched step (3b).
- **Return the structured result** (the coordinator acts on this — do not narrate the diff):
  `{ lane, branch, prUrl, headSha, gateResults, selfCheck, blocker? }`. Set `blocker` if you couldn't
  reach green (e.g. a test hit its 3-attempt cap); leave the worktree open for the fix loop.

## Step 3b — independent review (coordinator-dispatched, NOT the implementer)
The gate is a review the **author did not run**. When an implementer returns green, the coordinator
spawns a **fresh** review subagent (`/tech-review`, or `/mkurator-review` · `/kollect-mr-review`)
pointed at the pushed branch / PR **diff only** — never `SendMessage` back to the implementer, so the
author's reasoning is never in the reviewer's context. The reviewer trusts the implementer's
`gateResults` (it does not re-run the multi-minute gate matrix) but **does** run any lab/tutorial lane
end-to-end against the real tool. Optionally give the reviewer a different `model` for a genuinely
independent lens. It returns the reviewer schema; the coordinator then routes on `verdict`:
- **APPROVE** → post the review as a **PR comment** (`gh pr comment` — never `--approve`); lane is
  ready for the operator to merge (Step 5).
- **REQUEST_CHANGES** → **resume the original implementer** (its worktree + context intact) with the
  findings to fix, then **re-dispatch a fresh reviewer** (never reuse the prior review). Independence
  holds because each review is fresh even though the author fixes.
- **BLOCK** → park the lane, post the findings, report — no merge.

The coordinator decides purely from `{verdict, findings}`; it does not read the diff to adjudicate.

## Step 4 — collect + report
As implementers finish and pass Step 3b, set each lane's board row to `🟢 PR open: <url>`. Report per
lane from the structured returns: ready-to-merge (APPROVE + green) · needs-changes · blocked. Keep
worktrees open until their PRs land.

**If an implementer dies mid-run** (API stream idle-timeout, crash — no final return but on-disk work
intact and gate-green): the coordinator may **salvage-commit** the on-disk work so it isn't lost, but
must then send it through the **same independent review (Step 3b)** exactly as if the implementer had
finished — **never** self-approve a salvage. A salvaged lane is not more trusted for having been
rescued; if it's a lab/tutorial, the reviewer runs it end-to-end. This session's P1 (a commented-out
but invalid config that every gate passed) was caught only because the salvage still went through review.

## Step 5 — merge (operator)
Leave PRs for the operator — merge via GitHub or `/merge-open-prs`. (For hands-off auto-merge, use the
**`/agent-loop-auto`** variant, which the operator invokes to authorize autonomous merging.)

## Step 6 — end of session
Run **`/retrospective`** to capture learnings. For any lane still in flight: leave its task
`in_progress` + worktree open, note the stop point on the board. Never merge partial work.

## Do not
- Dispatch two lanes that touch the same files — they must own disjoint paths.
- Exceed the concurrency cap, or parallelize machine-locked suites (e2e/integration).
- Start a lane already `🔶 In flight`, or before orienting (Step 1).
- Write code before a failing test; hammer a red test past 3 attempts.
- Let an **implementer review its own lane**, or reuse a prior review after a fix — the gate is always
  a **fresh, coordinator-dispatched** reviewer that saw only the diff.
- Hand a lane to the operator without an **APPROVE**, or with REQUEST CHANGES / BLOCK outstanding.
- Have the coordinator adjudicate by reading the diff itself — it routes on `{verdict, findings}`.
- **Self-approve or self-merge**, coordinate across repos, add AI trailers, or modify git config.
- Mark a task `completed` when a PR is merely opened — completion is the merge landing.

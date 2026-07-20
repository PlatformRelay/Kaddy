---
name: merge-open-prs
description: >-
  Review and merge all open PRs/MRs in ONE repo after checking CI. PRs authored by the maintainer
  (the authenticated operator) are trusted — green CI is enough to merge, no deep code analysis. PRs
  from any other contributor get a full /tech-review and merge only on APPROVE + green CI. Per-repo
  only; never merges a red, pending, or conflicted PR. Use when the operator says "merge my open PRs /
  clear the PR queue / review and merge the open MRs in <repo>".
---

# merge-open-prs — clear a repo's PR queue safely

Operates on **one repo** (the repos are independent — never batch across repos). It merges what's
safe, reviews what isn't, and never merges a red, pending, or conflicted PR. Merging here is
authorized by the operator invoking this skill.

## Who counts as "the operator" (trusted)
The maintainer = the **authenticated GitHub user**. Resolve once: `gh api user -q .login`. A PR is
trusted (the operator's own) if its author login equals that, or its commits are authored by
`Konrad Heimel <konrad.heimel@gmail.com>` / `konih`. **Anyone else is an external contributor — the
careful path.** If you can't confidently tell, treat it as external.

## Step 1 — enumerate open PRs (target repo)
```bash
cd <repo>
gh pr list --state open --json number,title,author,isDraft,mergeable,mergeStateStatus,reviewDecision
```
Skip drafts. Record author + number + mergeable state for each.

## Step 2 — check CI (mandatory for EVERY PR, including the operator's own)
```bash
gh pr checks <n>                                  # every required check must be green
gh pr view <n> --json mergeable,mergeStateStatus  # must be MERGEABLE, not CONFLICTING/BEHIND
```
If any required check is failing or pending, or the PR isn't cleanly mergeable → **skip it**, report
why. "After checking CI" is the whole point — a red or pending PR is never merged.

## Step 3 — classify and gate
- **Operator's own PR (trusted):** CI green + mergeable → **eligible to merge, no deep analysis**
  (operator's explicit policy: their own code is trusted). Still glance at title/scope; per the
  adversarial-collaboration ethos, if something looks obviously wrong or risky, say so before merging —
  but default to merge.
- **External contributor's PR:** run `/tech-review` (or the repo's review skill —
  `/mkurator-review`, `/kollect-mr-review`) in fresh context against the PR branch. Merge **only** if
  the verdict is **APPROVE and CI is green**. On REQUEST CHANGES / BLOCK: **do not merge** — post the
  findings as a PR comment (`gh pr comment`, never `--approve`) and report it as needs-changes.

## Step 4 — present the plan, then merge the eligible ones
Show the operator the plan first: which PRs will merge, which are skipped (with reason), which external
ones need changes. Then merge each eligible PR with the workspace default — **Rebase and merge**
(linear history, no squash, no merge commits), unless the repo's own `CONTRIBUTING` narrows it:
```bash
gh pr merge <n> --rebase --delete-branch
```
After each merge, in that repo's `agent-context/`: move the lane to **Integrated** on its OPERATOR-BOARD,
and clear any matching "merge PR #<n>" task from its INBOX.

## Step 5 — report (per repo)
One line per PR: **MERGED** · **SKIPPED** (red/pending/conflict) · **NEEDS-CHANGES** (external; findings
posted). End with the repo's new `origin/main` HEAD.

## Do not
- Merge a PR with red/pending CI or merge conflicts (not `MERGEABLE`).
- Merge an **external** contributor's PR without a passing `/tech-review` (APPROVE).
- Batch across repos — one repo per run.
- Force-merge, `--admin`, or override branch protection to push a merge through.
- Merge a draft PR, or skip the CI check on the operator's own PRs.

---
name: operator-inbox
description: >-
  Scan each PlatformRelay repo's INBOX independently and give the operator a per-repo digest of what
  needs them — decisions (with options), operator tasks, reviews, and PRs. The repos are fully
  independent; this never merges or coordinates items across repo boundaries. Presents open decisions
  as interactive pick-an-option questions (AskUserQuestion), each self-contained with summarized
  context and a reasoned recommendation. Also actions answered decisions (with pushback) and logs
  them to each repo's decisions.md. Use when the operator says "what needs me / check my inbox /
  operator review / any open decisions".
---

# operator-inbox — per-repo "what needs me?" digest

The operator's single command to see what's waiting — **kept strictly per-repo**. Repos are
independent products; this skill scans each one separately and never blends their items into one list.

## Step 1 — enumerate repos
List the workspace repos that have an `agent-context/INBOX.md` (mkurator, kollect,
kubernetes-workshop, opentofu-workshop, …). Also read the slim workspace `agent-context/INBOX.md` for
harness/workspace-level items — keep it as its own clearly-labeled section, separate from every repo.

## Step 2 — scan per repo (one subagent each)
For each repo, dispatch a subagent (`run_in_background`) that reads **only that repo's**
`agent-context/INBOX.md` (+ its `decisions.md` for context). It returns that repo's open items grouped:
Decisions (title · options · whether the answer field is filled), Operator tasks, Reviews, PRs. The
subagent must stay within its repo — it may not read or reference any other repo.

## Step 3 — present per-repo (self-contained, no other windows)
One section per repo, in priority order (repos with a filled-in decision answer or a blocking decision
first). Never merge items across repos. End with a one-line "nothing waiting" for quiet repos.

Presentation requirements (operator preference, confirmed 2026-07-16):
- **Every decision must be answerable from the digest alone.** Give a short summary + enough context
  (what triggered it, what's blocked, the trade-off) that the operator never has to open the INBOX,
  a PR, or a report in another window. If the INBOX block itself is thin, **do the summarization work
  yourself** — read the referenced files/PRs/reports and distill the missing context into the digest.
- **Recommendations always carry a why.** Never a bare "I recommend A" — state the reason in one
  clause ("A — zero churn, the sensitive part is already scrubbed"). Same for option descriptions:
  each option states its consequence, not just its label.

## Step 4 — ask open decisions interactively (operator preference)
The operator prefers **selecting** answers over typing them. After the digest, collect the open
decisions (unanswered Answer/instructions fields, override windows, ready-to-merge PRs needing
consent, approved-but-undispatched lanes) and present them with **AskUserQuestion** — batched up to
4 per call, more calls if needed — rather than asking in prose and waiting for free-text.
- One question per decision; options mirror the INBOX options (A/B/C…), concise labels, consequence
  in the description, the recommended option **first** and marked "(Recommended)" — with the reason
  visible per Step 3.
- Include the summarized context in the question text itself (self-contained, same rule as Step 3).
- The operator can always answer "Other" in their own words — treat that text as the answer verbatim.
- **Log every answer immediately** per Step 5 (decisions.md + INBOX removal) before moving on.

## Step 5 — action answered decisions (with pushback, not blind obedience)
For any decision the operator has answered — whether via a filled **Answer / instructions** field in
the INBOX or an interactive answer from Step 4:
- **First, pressure-test the answer** (`AGENTS.md` → Adversarial collaboration). If you see a real
  risk, a failure mode, or a clearly better alternative, say so *before* acting — the operator has
  explicitly asked to be challenged and corrected, not obeyed blindly. If they reaffirm, proceed.
- Action it, or hand to the right skill (`/agent-loop`, `/design-architecture`, `/tech-review`, …).
- **Record it in that repo's `agent-context/decisions.md`**: the choice, the options, **your
  counterpoints (kept even if overruled)**, rationale, and status. Then remove the block from the INBOX.

## Step 6 — offer next action
If the operator wants to start something, hand off: decision → the relevant skill; task → do it (in a
worktree); review → `/tech-review`; new work → `/agent-loop <repo>`.

## Do not
- Merge, compare, or cross-reference items across repos — each repo is independent.
- Blindly execute an answered decision you believe is wrong — challenge first, then comply and log.
- Leave an actioned decision in the INBOX — record it in `decisions.md` and remove it.
- Invent items — report only what's actually in each repo's INBOX.
- Ask decisions in prose when AskUserQuestion can offer them as selectable options.
- Present a decision whose context lives only in another file — summarize it into the digest/question.
- Recommend without a reason.

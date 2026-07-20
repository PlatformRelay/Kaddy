---
name: replayable-audit
description: >-
  Run a replayable health & direction audit of a PlatformRelay repo — architecture,
  tests, security, docs, and project direction — diffed against the previous dated
  run (new / fixed / regressed), with a maintained tech-debt register. Read-only.
  Use when the operator says "audit this", "criticize the project direction / design
  choices", "how healthy is this", or before a release.
---

# replayable-audit — health & direction, diffed over time

Runs the `design-auditor` role to produce a dated, **re-runnable** audit that compares to the last
one — so you see whether things are getting better or worse, not just a one-shot snapshot. Read-only:
it files findings, it does not change product code. Complements each repo's release-gate audit
(`/mkurator-audit`, `/kollect-audit`) — this one is broader and tracks trends.

## Step 1 — scope
Target repo + which dimensions (default: all — architecture, tests, security, docs, direction) + depth
(`quick` = direction + top risks; `deep` = fan out per-dimension sub-audits). Confirm read-only.

## Step 2 — dispatch the design-auditor
Spawn the `design-auditor` subagent with the repo path, chosen dimensions, and a pointer to the most
recent prior audit in `agent-context/archive/audits/` (so it diffs, not restarts). For `deep`, it may
fan out read-only sub-auditors per dimension and synthesize — the way each repo's local audit deep
mode already does.

## Step 3 — file the result
- Audit report → `agent-context/archive/audits/<AREA|HEALTH>-AUDIT-<YYYY-MM-DD>.md` with a **Delta vs
  prior** section.
- Tech-debt register → reconcile `agent-context/archive/audits/TECH-DEBT-REGISTER.md` (fixed /
  regressed / new).
- Top findings → propose as backlog stories via `/write-story`.

## Step 4 — report
Give the operator the verdict (READY / NEEDS-WORK / AT-RISK), the delta since last run (what improved,
what regressed), and the top 3 to fix next. Append an **AUDIT** line to the INBOX (repo or workspace)
linking the dated report, so it lands on the review queue.

## Do not
- Edit product code, ship, deploy, or touch a cluster — read-only.
- Quote cached gate results — re-run and re-read this session.
- Produce a one-shot report with no diff when a prior audit exists — the point is replayability.
- File a finding without a `path:line`.

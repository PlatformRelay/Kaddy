# kaddy agent skills

Committed skills for automated assistants working on this repository. The **source of truth** is
this `skills/` tree (tracked in git). Tooling that looks under `.claude/skills/` can symlink or
copy from here — `.claude/` stays gitignored (local harness scratch; see [AGENTS.md](../AGENTS.md)).

```bash
mkdir -p .claude/skills
for s in skills/*/; do
  name=$(basename "$s")
  [ "$name" = "*" ] && continue
  ln -sfn "../../skills/$name" ".claude/skills/$name"
done
```

## Catalogue

### Repo-local (kaddy-specific)

| Skill | When |
| --- | --- |
| [pick-next-story](pick-next-story/SKILL.md) | Pick the single next backlog item without starting the full loop |
| [evidence-capture](evidence-capture/SKILL.md) | Run or document scorecard / evidence capture (E8) |
| [kaddy-audit](kaddy-audit/SKILL.md) | Replayable security/compliance audit tailored to kaddy (E11) |

### Session drivers

| Skill | When |
| --- | --- |
| [agent-loop](agent-loop/SKILL.md) | Start/resume implementation: coordinator + parallel worktree lanes → TDD → gates → review → PR |
| [agent-loop-auto](agent-loop-auto/SKILL.md) | Same loop with auto-merge when gates + independent review + CI are green |
| [agent-loop-local](agent-loop-local/SKILL.md) | Maximum-autonomy local variant: review gate then ff-merge without opening PRs |
| [handover](handover/SKILL.md) | End-of-session tidy + copy-pasteable prompt for the next session |
| [retrospective](retrospective/SKILL.md) | Capture what worked/failed into agent-context so the harness compounds |

### Planning & design

| Skill | When |
| --- | --- |
| [write-story](write-story/SKILL.md) | INVEST vertical-slice stories with Given/When/Then, mapped to OpenSpec / backlog IDs |
| [design-architecture](design-architecture/SKILL.md) | ADR/AgDR, C4 sketch, trade-off matrix, or spec-first contract |
| [brainstorm](brainstorm/SKILL.md) | Diverge → cluster → converge before locking an approach |
| [grill-me](grill-me/SKILL.md) | One-question interview to stress-test a plan before building |

### Review & quality

| Skill | When |
| --- | --- |
| [tech-review](tech-review/SKILL.md) | Pre-merge gate matrix + TDD/correctness/quality/security/docs → APPROVE / RC / BLOCK |
| [security-review](security-review/SKILL.md) | Deeper data-flow security pass than the tech-review security dimension |
| [roast](roast/SKILL.md) | Adversarial critique (pre-mortem / red-team / steelman-then-destroy) |
| [replayable-audit](replayable-audit/SKILL.md) | Re-runnable health audit, diffed against the previous dated run |

### Operator / release helpers

| Skill | When |
| --- | --- |
| [operator-inbox](operator-inbox/SKILL.md) | Digest what needs the operator (decisions, reviews, PRs) from this repo's INBOX |
| [merge-open-prs](merge-open-prs/SKILL.md) | Clear the PR queue after CI; maintainer PRs merge on green, others need tech-review |
| [changelog](changelog/SKILL.md) | Turn gitmoji-conventional history into categorized release notes |

Spec-driven workflow (OpenSpec → REQs → TDD → gates):
[docs/development/DEVELOPMENT.md](../docs/development/DEVELOPMENT.md).
Also linked from [AGENTS.md](../AGENTS.md).

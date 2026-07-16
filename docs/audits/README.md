# Security & compliance audits — kaddy

Committed, **replayable** audit procedure (E11). Reports are **public** — the process is part of
the showcase. Run with repo skill `skills/kaddy-audit/SKILL.md` or manually.

## When to run

- After E1c security baseline merges
- Before interview submission
- After major GitOps changes to netpols or RBAC

## Dimensions

| ID | Area | Evidence to collect |
| --- | --- | --- |
| A1 | Network segmentation | NetworkPolicy manifests vs `kubectl get netpol -A` |
| A2 | Image supply chain | CI Trivy logs, digest pins, Kyverno verify policy |
| A3 | RBAC | Helm/Role manifests for Crossplane, ArgoCD, gateway |
| A4 | Label coverage | Sample resources missing mandatory keys (ADR-0301) |
| A5 | Classification | Query `data-classification` label presence on workloads |
| A6 | Secrets hygiene | gitleaks + scrub clean; no creds in Git |

## Severity (aligned with PlatformRelay HARNESS)

| Sev | Meaning | Blocks release? |
| --- | --- | --- |
| P0 | Trust-breaking, secret leak, wide-open netpol | Yes |
| P1 | Missing mandatory labels on prod-facing workload | Yes |
| P2 | Suboptimal but safe gap | No |
| P3 | Polish | No |

## Report format

File: `docs/audits/YYYY-MM-DD-audit.md`

```markdown
# kaddy audit — YYYY-MM-DD

## Summary
- Overall: PASS | PASS WITH NOTES | FAIL
- Compared to: YYYY-MM-DD-audit.md (or "first run")

## Findings
| ID | Sev | Area | Location | Blocks? |
| ... |

## Diff vs previous
- New: ...
- Fixed: ...
- Regressed: ...

## Compliance mapping
Brief note tying label coverage to public NIS2/KRITIS asset-management expectations.
```

## History

| Date | Summary | Report |
| --- | --- | --- |
| 2026-07-15 | Baseline health & direction audit (NEEDS-WORK; direction AT-RISK) | `agent-context/archive/audits/HEALTH-AUDIT-2026-07-15.md` |
| 2026-07-16 | Replay audit — 22 baseline findings fixed; status-truth recurrence flagged (DOC-10) | `agent-context/archive/audits/HEALTH-AUDIT-2026-07-16-final.md` |
| 2026-07-16 | Data-flow security review (pre-v0.1.0) | [security-review-2026-07-16.md](../security/security-review-2026-07-16.md) |

## Tooling language

Use **agent-assisted** / **automated assistant** — no vendor-specific AI branding in reports.

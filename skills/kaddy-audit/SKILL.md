---
name: kaddy-audit
description: Replayable agent-assisted security and compliance audit for kaddy (E11).
---

# kaddy-audit — security & compliance (E11)

Read-only audit procedure committed in [docs/audits/README.md](../docs/audits/README.md).

## Dimensions

| ID | Area | Checks |
| --- | --- | --- |
| A1 | Architecture | Trust boundaries, default-deny netpols documented vs cluster |
| A2 | Images | Digest pins, Trivy CI, cosign verify policy |
| A3 | RBAC | Least privilege for Crossplane, ArgoCD, gateway controller |
| A4 | Labels | Mandatory core present; `data-classification` queryable |
| A5 | Compliance mapping | Labels operationalise NIS2/KRITIS asset classification (public refs only) |
| A6 | Secrets | No credentials in Git; scrub + gitleaks clean |

## Output

- Dated report: `docs/audits/YYYY-MM-DD-audit.md`
- Diff section vs previous dated run: **new / fixed / regressed**
- Severity P0–P3 per workspace HARNESS taxonomy
- Tooling-neutral language only

## When to run

- Before interview submission
- After any E1c or E6 lane merges
- On demand via operator request

Do not merge audit findings into product code — file issues / backlog items instead.

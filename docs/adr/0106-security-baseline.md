# ADR-0106: Security baseline — netpols, images, policy

**Theme:** 01 · Foundations · **Status:** Current

## Context

kaddy is **security-first** for interview signal: default-open lab clusters fail compliance and
SRE credibility checks.

## Decision

### Network

- **Default-deny** NetworkPolicy in every namespace; explicit allow lists:
  - ingress from Gateway namespace to app pods
  - Prometheus → metrics ports
  - DNS egress to kube-system
  - Crossplane provider → gridscale API (443)

### Images

- **Trivy** scan in CI; fail on CRITICAL (configurable HIGH in E1c).
- Images referenced by **digest** in manifests where published.
- **cosign** sign on release images; **Kyverno** verifyImages policy in cluster.

### Admission & RBAC

- Kyverno **require-labels** policy for mandatory core (ADR-0301).
- Least-privilege RBAC for ArgoCD, Crossplane, gateway controller SA.
- **OIDC** for human access to Argo CD and Grafana via Dex + GitHub (ADR-0107).

### Repo hygiene

- **gitleaks** + **scrub-denylist** (`task scrub`) on every PR.
- No secrets in Git; gridscale creds via External Secrets or sealed secrets pattern in E1.

### Compliance posture (public bases)

Operationalise asset classification via labels — not policy PDFs:

| Regulation (public) | Requirement | kaddy label |
| --- | --- | --- |
| NIS2 Dir. 2022/2555 Art. 21(2)(i) | Asset management | `owner`, inventory via labels |
| EU 2024/2690 rec. 24–26 | Classification levels on assets | `data-classification` |
| § 8a BSIG / BSI KdA | Inventory, owner, uniform classification | `owner`, `data-classification` |
| GDPR Art. 30/32 | Know where data is processed | `personal-data` (optional key) |
| PCI-DSS scoping | Isolate CDE | `pci` (optional, default false) |

## Consequences

- E1c implements baseline before sample workloads go public.
- E1d wires OIDC (Dex + GitHub) before exposing Argo CD / Grafana on public URLs (ADR-0107).
- E11 audit procedure verifies drift.

## References

- [Kubernetes NetworkPolicies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Kyverno verifyImages](https://kyverno.io/docs/writing-policies/verify-images/)

# Architecture Decision Records — kaddy

Theme-numbered ADRs (`0Txx`) grouped by concern. Status: **Current** unless noted.

| Theme | Range | Topics |
| --- | --- | --- |
| 01 · Platform foundations | 0101–0111 | VM vs platform, GSK substrate, ArgoCD, **Cilium Gateway**, Crossplane, security, **identity**, **logging**, **portal/IDP**, **SOPS secrets**, **portal auto-gen** |
| 02 · Delivery & evidence | 0201–0202 | Rollouts, scorecard |
| 03 · IaC & labeling | 0301–0303 | Labels everywhere, Terramate, **Nix golden images** |
| 04 · Future operator | 0401 | Caddy operator (design-first) |
| 07 · Engineering | 0701 | Testing pyramid + Chainsaw |

**Start here:** [0101](0101-platform-over-vm.md) → [0701](0701-testing-strategy-chainsaw.md) → [0301](0301-resource-labeling-convention.md).

## Index

| ADR | Title |
| --- | --- |
| [0101](0101-platform-over-vm.md) | Platform over VM for the hiring exercise |
| [0102](0102-talos-immutable-substrate.md) | Two-phase substrate — **amended D-025**: phase 1 = kind + Cilium; Talos driving-range deferred |
| [0103](0103-argocd-gitops.md) | ArgoCD GitOps app-of-apps |
| [0104](0104-caddy-gateway-api.md) | Cilium Gateway API for platform ingress; Caddy as tenant product |
| [0105](0105-crossplane-self-service.md) | Crossplane self-service via Upjet provider-gridscale |
| [0106](0106-security-baseline.md) | Security baseline — netpols, images, policy |
| [0107](0107-identity-dex.md) | Identity — Dex OIDC + GitHub (**PlatformRelay**) |
| [0108](0108-logging-loki.md) | Logging — Loki + Grafana Alloy |
| [0109](0109-idp-portal-orchestrator.md) | IDP portal & orchestrator (Backstage + Crossplane) |
| [0110](0110-secrets-sops-age.md) | Secrets — SOPS + age encrypted in git (IaC) |
| [0111](0111-portal-auto-generation.md) | Portal auto-generation — templates from XRD, read-path plugins, v2 XR |
| [0201](0201-rollouts-blue-green-canary.md) | Blue/green and canary with Prometheus analysis |
| [0202](0202-evidence-as-artifact.md) | Evidence as reproducible artifact (scorecard) |
| [0301](0301-resource-labeling-convention.md) | Resource naming & labeling convention |
| [0302](0302-terramate-opentofu-stacks.md) | Terramate-managed OpenTofu stacks |
| [0303](0303-nix-golden-images.md) | Nix golden images for gridscale Marketplace (alongside Packer) — **Proposed** |
| [0401](0401-caddy-operator-design-first.md) | Caddy operator — design-first |
| [0701](0701-testing-strategy-chainsaw.md) | Testing strategy — pyramid, TDD, Chainsaw |

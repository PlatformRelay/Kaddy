# kaddy — a caddie for your websites

**Security-first · spec-driven · Kubernetes-native Website-as-a-Service.**

kaddy is an internal developer platform for **monitored, TLS-terminated websites**. One self-service
claim provisions a site behind Caddy with observability, alerting, and progressive delivery. The
[gridscale Platform Engineer exercise](docs/HIRING_EXERCICSE.md) (install Caddy, monitor with
Prometheus, alert on thresholds, optional nginx reverse proxy) is satisfied as **one tenant** of the
platform — `clubhouse` — not as a one-off VM script.

> **Local-first:** rehearse on a **3-node Talos cluster** ([driving-range](../driving-range/)) before
> spending gridscale credits. Promote to **GSK + LBaaS + Upjet Crossplane** in phase 2 — see
> [decisions D-017](agent-context/decisions.md) and [ROADMAP](docs/ROADMAP.md).

## Reviewer paths

**5 minutes** — [docs/requirements/exercise-traceability.md](docs/requirements/exercise-traceability.md)
maps every brief requirement to an epic, then skim [docs/ROADMAP.md](docs/ROADMAP.md).

**Deep dive** — [docs/adr/README.md](docs/adr/README.md) (architecture decisions) →
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) → [openspec/changes/](openspec/changes/) (specs with
`Verify:` + `Test:` per requirement).

## Stack

| Layer | Phase 1 (driving-range) | Phase 2 (gridscale lab) |
| --- | --- | --- |
| Substrate | [driving-range](../driving-range/) — local Talos 3-node | **GSK** managed k8s |
| Day-0 IaC | driving-range OpenTofu (sibling repo) | Terramate + `gridscale/gridscale` v2 (E1g) |
| Edge | **Cilium Gateway** + LB-IPAM/L2 | **LBaaS** + LE + Cilium/Envoy |
| GitOps | **ArgoCD** app-of-apps | Same manifests, re-sync on GSK |
| Identity | Dex + GitHub OAuth ([PlatformRelay](https://github.com/PlatformRelay)) | Same (update issuer URL for LBaaS domain) |
| Secrets | SOPS + age in git ([ADR-0110](docs/adr/0110-secrets-sops-age.md)) | Same |
| Observability | kube-prometheus-stack + Loki + Alloy | Same |
| TLS | cert-manager (staging) | LBaaS LE + cert-manager |
| Self-service | Crossplane `Website` XRD | + Upjet **provider-gridscale** (E6g) |
| Progressive delivery | Argo Rollouts + Gateway API | Same |
| Policy | Kyverno, default-deny NetworkPolicies | Same |

## Named components (the caddie metaphor)

| Component | Role |
| --- | --- |
| **clubhouse** | the sample website tenant (satisfies the brief) |
| **marshal** | alerting pipeline — PrometheusRules + Alertmanager |
| **mulligan** | blue/green + canary with automated rollback |
| **scorecard** | evidence harness — k6 + metrics/logs capture → HTML report |
| **driving-range** | local Talos practice cluster (sibling repo) |

## Testing (mandatory TDD)

Every requirement carries a `Test:` artifact and a `Verify:` command. See
[docs/development/testing.md](docs/development/testing.md) and
[ADR-0701](docs/adr/0701-testing-strategy-chainsaw.md).

```bash
task verify         # lint + scrub + openspec + spec-coverage
task test:spec      # every REQ has Test + Verify
task test           # L0 tofu test · L1 conftest + promtool · L2 Chainsaw
```

| Level | Tool | Proves |
| --- | --- | --- |
| L0 | `tofu test` | label module outputs |
| L1 | conftest · **promtool** | plan labels · **alert rules fire** |
| L2 | **Chainsaw** | policies, routes, rollouts, monitors on live cluster |
| L3 / L4 | k6 · scorecard | load/alerting · evidence bundle |

## Status

**Design phase.** Phase 1 starts after [driving-range](../driving-range/) cluster is Ready.
Implementation runs via `/agent-loop` per the [ROADMAP](docs/ROADMAP.md).

## Reference material

[`references/PocketIDP/`](references/PocketIDP/) is a local, un-vendored copy of
[PocketIDP](https://github.com/InternalDeveloperPlatform/PocketIDP), kept as a reference for the
**Gitea + Backstage** demo setup we will draw on for E10. It is gitignored — not part of kaddy's
committed tree.

## Cloud note

The brief provisions a **gridscale** lab. **Phase 1** develops on local Talos ($0) via
[driving-range](../driving-range/). **Phase 2** promotes to gridscale-native PaaS — GSK, LBaaS,
Object Storage, Upjet Crossplane — for the employer-facing demo (E8b). Reasoning in
[decisions D-013 / D-015 / D-016 / D-017](agent-context/decisions.md).

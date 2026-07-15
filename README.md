# kaddy — a caddie for your websites

**Security-first · spec-driven · Kubernetes-native Website-as-a-Service.**

kaddy is an internal developer platform for **monitored, TLS-terminated websites**. One self-service
claim provisions a site behind Caddy with observability, alerting, and progressive delivery. The
[gridscale Platform Engineer exercise](docs/HIRING_EXERCICSE.md) (install Caddy, monitor with
Prometheus, alert on thresholds, optional nginx reverse proxy) is satisfied as **one tenant** of the
platform — `clubhouse` — not as a one-off VM script.

> **Local-first:** phase-1 development runs on a local **kind + Cilium** cluster
> ([e1e-kind-local-cluster](openspec/changes/e1e-kind-local-cluster/), landed) — Cilium Gateway API +
> LB-IPAM/L2, so the edge matches phase 2. Promote to **GSK + LBaaS + Upjet Crossplane** in phase 2 —
> see [decisions D-025](agent-context/decisions.md) and [ROADMAP](docs/ROADMAP.md). The 3-node Talos
> [driving-range](../driving-range/) is a deferred optional maturity-contrast spike (D-025).

## Reviewer paths

**5 minutes** — [docs/requirements/exercise-traceability.md](docs/requirements/exercise-traceability.md)
maps every brief requirement to an epic, then skim [docs/ROADMAP.md](docs/ROADMAP.md).

**Deep dive** — [docs/adr/README.md](docs/adr/README.md) (architecture decisions) →
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) → [openspec/changes/](openspec/changes/) (specs with
`Verify:` + `Test:` per requirement).

## Stack

| Layer | Phase 1 (kind — local) | Phase 2 (gridscale lab) |
| --- | --- | --- |
| Substrate | **kind + Cilium** ([E1e](openspec/changes/e1e-kind-local-cluster/), landed) — single-node | **GSK** managed k8s |
| Day-0 IaC | `hack/cluster/` kind bring-up (E1e) | Terramate + `gridscale/gridscale` v2 (E1g) |
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
| **driving-range** | deferred optional 3-node Talos maturity-contrast spike (sibling repo; D-025) |

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

**Phase 1 underway.** The local **kind + Cilium** substrate (E1e), the **labels** module (E1b), and
the **marshal** monitoring rules (E5) are landed and gated on `main`; remaining epics run via
`/agent-loop` per the [ROADMAP](docs/ROADMAP.md). Phase 2 (gridscale GSK) is deferred.

## Reference material

[`references/PocketIDP/`](references/PocketIDP/) is a local, un-vendored copy of
[PocketIDP](https://github.com/InternalDeveloperPlatform/PocketIDP), kept as a reference for the
**Gitea + Backstage** demo setup we will draw on for E10. It is gitignored — not part of kaddy's
committed tree.

## Cloud note

The brief provisions a **gridscale** lab. **Phase 1** develops on a local **kind + Cilium** cluster
($0, [E1e](openspec/changes/e1e-kind-local-cluster/)). **Phase 2** promotes to gridscale-native PaaS —
GSK, LBaaS, Object Storage, Upjet Crossplane — for the employer-facing demo (E8b). Reasoning in
[decisions D-013 / D-015 / D-016 / D-025](agent-context/decisions.md).

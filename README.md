# kaddy — a caddie for your websites

<p align="center">
  <img src="slides/public/branding/logo-dark.png" alt="kaddy" width="128" height="128" />
</p>

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

**5 minutes** (honest order — skip anything labeled unavailable):

1. **Released demo / deck** — build the Slidev deck with `task deck:build` (sources in
   [`slides/`](slides/); CI `deck` workflow). A published Pages URL for the deck is
   **unavailable** until that publish path is enabled.
2. **Scorecard** — live URL
   [`https://platformrelay.github.io/Kaddy/`](https://platformrelay.github.io/Kaddy/)
   (HTTP 200; workflow
   [`.github/workflows/scorecard-pages.yaml`](.github/workflows/scorecard-pages.yaml)).

3. **Local services + demos** — follow
   [docs/getting-started.md](docs/getting-started.md) (kind bring-up, service catalogue,
   `task demo:fire` / `task demo` / `task demo:chaos`).
4. **Architecture** — [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and the
   [exercise traceability](docs/requirements/exercise-traceability.md) matrix; skim
   [docs/ROADMAP.md](docs/ROADMAP.md).

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

**Brief answered end-to-end — serve → scrape → fire, plus progressive delivery and an enforcing
security baseline, all GitOps.** Verified live: 15/15 GitOps apps Synced/Healthy; clubhouse served
over verified HTTPS through the Cilium Gateway (E4); observability spine
(Prometheus/Alertmanager/Grafana + Loki/Alloy, E3); the marshal fires a real alert against the
served site and resolves it — `task demo:fire` (E5) — with a provisioned Grafana dashboard and
data-source-managed alerts; Argo Rollouts shifts live HTTPRoute canary weights and auto-rolls-back
on abort (E7); Kyverno admission (5 Enforce policies), default-deny NetworkPolicies, and restricted
ArgoCD AppProjects are live (E1c). The gateway spike (E2), labels module (E1b), and recording-ready
Slidev showcase deck (E12) are also on `main`. A data-flow security review is at
[docs/security/security-review-2026-07-16.md](docs/security/security-review-2026-07-16.md). Next:
E6 Crossplane `Website` XRD (claim → monitored site) and E1d identity. Phase 2 (gridscale GSK) is
deferred. Full plan: [ROADMAP](docs/ROADMAP.md).

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

### Phase 2 monthly cost estimate (EUR)

Lab-sized footprint for the employer demo — **estimates** from public gridscale list pricing
(control plane free; billed per minute). Re-check [gridscale pricing](https://gridscale.io/en/pricing/)
before quoting. Phase 1 on kind is **€0 / month**.

| Resource | Size (typical lab) | Est. EUR / month |
| --- | --- | --- |
| GSK node pool | 2× 2C-4G workers (~€46/node) | ~92 |
| LBaaS | 1 load balancer | ~22.50 |
| Object Storage | evidence / marketplace `.gz` (per GB) | ~0.06 / GB |
| **Total (indicative, excl. storage GB)** | | **~115 EUR / month** |

Exact SKUs live in the gridscale console when phase 2 starts.

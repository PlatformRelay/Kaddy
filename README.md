<!-- markdownlint-disable MD013 MD033 MD041 -->
# kaddy — a caddie for your websites

<p align="center">
  <img src="slides/public/branding/logo-dark.png" alt="kaddy" width="128" height="128" />
</p>

<p align="center">
  <a href="https://github.com/PlatformRelay/Kaddy/actions/workflows/verify.yaml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/PlatformRelay/Kaddy/verify.yaml?branch=main&label=CI&logo=github" /></a>
  <a href="https://github.com/PlatformRelay/Kaddy/actions/workflows/deck.yaml"><img alt="deck build" src="https://img.shields.io/github/actions/workflow/status/PlatformRelay/Kaddy/deck.yaml?branch=main&label=deck&logo=slides" /></a>
  <a href="https://platformrelay.github.io/Kaddy/"><img alt="docs / Pages" src="https://img.shields.io/website?url=https%3A%2F%2Fplatformrelay.github.io%2FKaddy%2F&label=docs%20%C2%B7%20Pages&up_message=live&down_message=pending" /></a>
  <img alt="license" src="https://img.shields.io/badge/license-see%20repo-lightgrey" />
</p>

<!-- Badge caveats (REQ-E12c-S07-01): the CI/deck badges reflect the real
     verify.yaml + deck.yaml workflows on PlatformRelay/Kaddy. The docs/Pages
     badge points at the published GitHub Pages URL (E8-S03, live); it renders
     "pending" if Pages is ever down. The LICENSE file is not yet committed, so
     the license badge is a neutral "see repo" placeholder rather than an
     uncaveated claim — swap it to the real SPDX badge when LICENSE lands. -->

**Security-first · spec-driven · Kubernetes-native Website-as-a-Service.**

kaddy is an internal developer platform for **monitored, TLS-terminated websites**. One self-service
claim provisions a site behind Caddy with observability, alerting, and progressive delivery. The
[gridscale Platform Engineer exercise](docs/HIRING_EXERCISE.md) (install Caddy, monitor with
Prometheus, alert on thresholds, optional nginx reverse proxy) is satisfied as **one tenant** of the
platform — `clubhouse` — not as a one-off VM script.

> **Local-first:** phase-1 development runs on a local **kind + Cilium** cluster
> ([e1e-kind-local-cluster](openspec/changes/e1e-kind-local-cluster/), landed) — Cilium Gateway API +
> LB-IPAM/L2, so the edge matches phase 2. Promote to **GSK + LBaaS + Upjet Crossplane** in phase 2 —
> see [decisions D-025](agent-context/decisions.md) and [ROADMAP](docs/ROADMAP.md). The 3-node Talos
> [driving-range](../driving-range/) is a deferred optional maturity-contrast spike (D-025).

## Live demo

The platform runs on a real **gridscale GSK** cloud-edge with **publicly-trusted
Let's Encrypt certificates** (verified live 2026-07-18):

- **<https://argocd.lab.platformrelay.dev>** — the ArgoCD app-of-apps UI (the GitOps story).
- **<https://grafana.lab.platformrelay.dev>** — anonymous-viewer Grafana (dashboards + Prometheus).
- **<https://demo.lab.platformrelay.dev>** — the Caddy website tenant (the served demo).
- **<https://caddy.lab.platformrelay.dev>** — currently returns HTTPS 404 at `/` for the **caddy-mvp**
  Argo Rollouts canary (showcase image `ghcr.io/platformrelay/kaddy-showcase:0.6.0`, Rollout Healthy);
  fresh route evidence is pending in `agent-context`.

Served through a Traefik Gateway API edge behind a gridscale LoadBalancer, with
DNS-01 Let's Encrypt **prod** certs (the TLS chain verifies without `-k`). The
config is codified as GitOps overlays: the Traefik controller in
[`deploy/gateway-controller/traefik/`](deploy/gateway-controller/traefik/) and the
`clubhouse` Gateway + Certificates + HTTPRoutes in
[`deploy/gateway/cloud-only/`](deploy/gateway/cloud-only/).

> **On-demand, not 24/7 (DECIDED-B cost governance).** This is a reproducible
> **live demo edge** brought up around a demo and torn down immediately after
> (`task e8b:up` → demo → `task e8b:down`) — the GSK cluster + LoadBalancer cost
> real money every hour they run. The URLs above are live only while the edge is
> up; see [docs/runbooks/gridscale-live-demo.md](docs/runbooks/gridscale-live-demo.md).

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
security baseline, all GitOps.** Verified live in the phase-1 demo: the phase-1 GitOps app-of-apps
Synced/Healthy; clubhouse served
over verified HTTPS through the Cilium Gateway (E4); observability spine
(Prometheus/Alertmanager/Grafana + Loki/Alloy, E3); the marshal fires a real alert against the
served site and resolves it — `task demo:fire` (E5) — with a provisioned Grafana dashboard and
data-source-managed alerts; Argo Rollouts shifts live HTTPRoute canary weights and auto-rolls-back
on abort (E7); Kyverno admission (5 Enforce policies), default-deny NetworkPolicies, and restricted
ArgoCD AppProjects are live (E1c). The gateway spike (E2), labels module (E1b), recording-ready
Slidev showcase deck (E12), and the optional Caddy operator (E9, landed on `main` after v0.1.1) are
also on `main`. Two releases are tagged and published: **v0.1.0** (serve → scrape → fire) and
**v0.1.1**, which added Crossplane self-service (E6 `Website` XRD, claim → monitored site), Dex +
GitHub identity (E1d), and CI substrate parity. A data-flow security review is at
[docs/security/security-review-2026-07-16.md](docs/security/security-review-2026-07-16.md).

**Phase 2 (gridscale) landed as offline-authored IaC** — Terramate/OpenTofu stacks for the GSK
day-0 substrate (E1g), the Upjet `provider-gridscale` consumer (E6g), the on-demand live-demo env
(E8b), and the gridscale Marketplace template (E13) — each gated offline (`tofu test`/conftest/
kubeconform/promtool) with live provisioning ruthlessly cost-gated (create → verify → `tofu
destroy`). **E1g's GSK cluster was live-proven** on real gridscale (`kubectl get nodes` Ready, then
torn down, tenant left clean — see [evidence/live/e1g-gsk-2026-07-17.md](evidence/live/e1g-gsk-2026-07-17.md);
re-provisioned standing 2026-07-18, [evidence/live/e1g-gsk-2026-07-18.md](evidence/live/e1g-gsk-2026-07-18.md)).
A 2026-07-18 live standing-demo attempt surfaced that the **public cloud edge is not yet built**:
`task e8b:up` is guard-locked to the local kind context, and GSK has no ingress edge out of the box
(Gateway API / Cilium GatewayClass / LB-IPAM are installed only by the kind bring-up). That deferred
work is now decomposed into stories **E1g-S05a–h** (bootstrap opt-in, GSK Gateway API, LBaaS→node,
network-topology reconcile, real `*.platformrelay.dev` hostnames, DNS-01 issuer, DNS+LE serve, and a
node-public-IP security spike) in [agent-context/BACKLOG.md](agent-context/BACKLOG.md).
The **Backstage self-service portal** (E10, cuttable) landed its kaddy-side GitOps wiring
(`deploy/portal`); the Backstage app source lives in the separate
[PlatformRelay/kaddy-portal](https://github.com/PlatformRelay/kaddy-portal) repo. The remaining
live proofs (E6g provider install, E13 Marketplace deploy → **E13-S05**, the public E8b edge →
E1g-S05a–h, the running portal) are cost-gated follow-ups. Full plan: [ROADMAP](docs/ROADMAP.md).

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

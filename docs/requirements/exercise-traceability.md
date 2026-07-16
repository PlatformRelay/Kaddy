# Exercise traceability — gridscale brief → kaddy

Maps the **Platform Engineer hiring exercise** requirements to epics/stories.

## Core requirements

| Brief requirement | kaddy deliverable | Epic / story |
| --- | --- | --- |
| Install Caddy on Linux | **Tenant** Caddy via Backstage scaffold (not platform ingress) | [e-caddy-mvp](../../openspec/changes/e-caddy-mvp/); platform edge = Cilium (E2 ✅, ADR-0104) |
| Serve sample web app | clubhouse static site over verified HTTPS | E4-S01 ✅ (`deploy/workloads/clubhouse/`) |
| Prometheus monitoring | kube-prometheus-stack + PodMonitor — live, 14/14 leaf apps Synced (16 incl. the root/observability app-of-apps) | E3-S02 ✅, E5-S01 ✅ |
| HTTP response codes, latency, uptime | Gateway + app metrics + blackbox probes + rules | E5-S01 ✅, E5-S02 ✅ |
| Regular scrape intervals | Prometheus scrape config / OperatorMonitor | E5-S01 ✅ |
| Alerting on thresholds + server down | PrometheusRules + Alertmanager — fires + resolves live (`task demo:fire`) | E5-S03 ✅, E5-S04 ✅ |
| Alerting **correctness** (tested) | promtool rule unit tests in CI (`monitoring.yaml`) | E5-S06 ✅ |
| Logs as evidence | Loki + Grafana Alloy — live via GitOps | E3-S02 ✅, E5-S07 |
| IaC automation | Terramate + OpenTofu + GitOps + **SOPS secrets in git** | E1 ✅, E1c-S05, E3 ✅, ADR-0302, ADR-0110 |
| Documentation | README, docs/, ADRs, slides | E8-S04, E12 🚧 |
| Config files for Caddy & Prometheus | GitOps manifests in repo (tenant Caddy + Prometheus stack) | E3 ✅–E5, e-caddy-mvp |
| Screenshots/logs of monitoring & alerting | scorecard HTML (metrics + Loki logs) + optional live URLs | E8, E8b |

## Optional task

| Brief requirement | kaddy deliverable | Epic / story |
| --- | --- | --- |
| Additional VM with nginx Hello World | Phase 1: `Website` claim demo (`websites/putting-green`) ✅; nginx legacy stand-in re-scoped → E6g; Phase 2: Crossplane `gridscale_server` | E6-S03 ✅, E6g-S03 |
| Caddy/nginx web server — **gridscale-native delivery** | **Third way:** a gridscale **Marketplace 2.0 template** (Terraform: build → export `.gz` → `gridscale_marketplace_application` → import → deploy), monitored via marshal | E13 (`e13-gridscale-marketplace`) |
| Caddy reverse proxy path routing | HTTPRoute `/legacy` (platform Gateway) or tenant Caddy config — re-scoped → E6g | E6g, E10 |
| Health checks | Composed ServiceMonitor per Website ✅; Gateway backend health-check policy → E6g | E6-S05 ✅, E6g |
| SSL termination | cert-manager + Gateway TLS | E4-S03 ✅ |

## Bonus

| Brief requirement | kaddy deliverable | Epic / story |
| --- | --- | --- |
| Health checks / fault tolerance | K8s probes + canary auto-rollback + chaos demo (`task demo:chaos`) | E6-S05 ✅, E7-S04 🚧 (in-boundary canary auto-rollback ✅; VM chaos deferred → e-caddy-mvp/E6g) |
| SSL encryption | TLS at Gateway | E4-S03 ✅ |

## Beyond brief (interview signal)

| Capability | Epic |
| --- | --- |
| Spec-driven OpenSpec changes | meta — every epic (`openspec/changes/`) |
| Security baseline (netpols, scan, sign) | E1c |
| OIDC / SSO (Dex + GitHub **PlatformRelay**) | E1d |
| Labeling / NIS2-style classification | E1b, E11 |
| Blue/green + canary (mulligan) | E7 |
| Self-service Website XRD (orchestrator) | E6 |
| Developer portal / IDP (Backstage) | E10 |
| Centralized logging (Loki) | E3, E5 |
| Agent-assisted audit in repo | E11 |
| Slidev presentation | E12 |
| Caddy operator design | E9 (optional code) |

## Cloud note

**Phase 1:** local **kind + Cilium** cluster (`kaddy-dev`, [E1e](../../openspec/changes/e1e-kind-local-cluster/) ✅, D-025) — $0 cloud.  
**Phase 2:** gridscale-native (GSK, LBaaS, Object Storage, Upjet Crossplane) for employer demo (E8b).
Documented in README; reasoning D-013 / D-015 / D-016 / D-025 / D-019 / D-020.

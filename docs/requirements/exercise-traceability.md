# Exercise traceability — gridscale brief → kaddy

Maps the **Platform Engineer hiring exercise** requirements to epics/stories.

## Core requirements

| Brief requirement | kaddy deliverable | Epic / story |
| --- | --- | --- |
| Install Caddy on Linux | **Tenant** Caddy via Backstage scaffold (not platform ingress) | E10-S02; platform edge = Cilium (E2, ADR-0104) |
| Serve sample web app | clubhouse static site | E4-S01 |
| Prometheus monitoring | kube-prometheus-stack + PodMonitor | E3-S02, E5-S01 |
| HTTP response codes, latency, uptime | Gateway + app metrics + blackbox probes + rules | E5-S01, E5-S02 |
| Regular scrape intervals | Prometheus scrape config / OperatorMonitor | E5-S01 |
| Alerting on thresholds + server down | PrometheusRules + Alertmanager | E5-S03, E5-S04 |
| Alerting **correctness** (tested) | promtool rule unit tests in CI | E5-S06 |
| Logs as evidence | Loki + Grafana Alloy | E3-S02, E5-S07 |
| IaC automation | Terramate + OpenTofu + GitOps + **SOPS secrets in git** | E1, E1c-S05, E3, ADR-0302, ADR-0110 |
| Documentation | README, docs/, ADRs, slides | E8-S04, E12, design phase |
| Config files for Caddy & Prometheus | GitOps manifests in repo (tenant Caddy + Prometheus stack) | E3–E5, E10 |
| Screenshots/logs of monitoring & alerting | scorecard HTML (metrics + Loki logs) + optional live URLs | E8, E8b |

## Optional task

| Brief requirement | kaddy deliverable | Epic / story |
| --- | --- | --- |
| Additional VM with nginx Hello World | Phase 1: in-cluster nginx stand-in; Phase 2: Crossplane `gridscale_server` (E6g) | E6-S03, E6g-S03 |
| Caddy reverse proxy path routing | HTTPRoute `/legacy` (platform Gateway) or tenant Caddy config | E6-S04, E10 |
| Health checks | Gateway backend health checks | E6-S05 |
| SSL termination | cert-manager + Gateway TLS | E4-S03 |

## Bonus

| Brief requirement | kaddy deliverable | Epic / story |
| --- | --- | --- |
| Health checks / fault tolerance | Gateway checks + K8s probes + chaos demo | E6-S05, E7-S04 |
| SSL encryption | TLS at Gateway | E4-S03 |

## Beyond brief (interview signal)

| Capability | Epic |
| --- | --- |
| Spec-driven OpenSpec changes | design phase |
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

**Phase 1:** local 3-node Talos via [driving-range](../../driving-range/) ($0 cloud).  
**Phase 2:** gridscale-native (GSK, LBaaS, Object Storage, Upjet Crossplane) for employer demo (E8b).
Documented in README; reasoning D-013 / D-015 / D-016 / D-017 / D-019 / D-020.

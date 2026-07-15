# Tasks — E3

TDD: Chainsaw assert before each Helm/manifest sync.

- [x] App-of-apps incl. `identity` + `observability` (REQ-E3-S01-01/02)
      — root + platform-core/observability/gateway/workloads children live and
        Synced/Healthy; `identity` registered as a deferred placeholder (below).
- [x] kube-prometheus-stack — Prometheus + Grafana + Alertmanager (REQ-E3-S02-01/02)
- [x] **Loki + Grafana Alloy** log stack; Loki as Grafana datasource (REQ-E3-S02-03/04/05)
- [x] cert-manager (assert Available) + Let's Encrypt **staging** ClusterIssuer Ready;
      **prod** ClusterIssuer committed but documented not-Ready-on-kind (REQ-E3-S03-00/01/02)
- [x] Enable `.github/workflows/chainsaw.yaml` + `task test:smoke:e3` + `task bootstrap:e3` (REQ-E3-EXIT)
- [x] Gate: smoke bundle green live (`task test:smoke:e3`); chainsaw runs in CI

## DEFERRED (do NOT tick — follow-ups)

- [ ] **REQ-E3-S01-03 — KSOPS repo-server plugin** (ADR-0110, D-020). Not on the
      demoable path tonight. `identity` child Application is registered but has no
      automated sync and points at an empty `deploy/identity/` dir. Follow-up:
      add the KSOPS init-container/sidecar to the Argo CD repo-server, then
      repoint `deploy/apps/identity.yaml` at the decryptable Dex overlay and
      enable sync. Un-skip a future `tests/smoke/e3-s01-03.sh` / identity suite.
- [ ] **REQ-E3-S03-03 — ACME HTTP-01 solver via Gateway** requires a public
      inbound path kind lacks. The staging/prod issuers declare the
      `gatewayHTTPRoute` solver, but end-to-end challenge solving is not
      exercised on kind (documented). Follow-up when a routable env exists.
- [ ] **REQ-E3-S04-01/02 — Argo Rollouts + Gateway API traffic-router plugin.**
      Owned by **E7** (progressive delivery). Not installed here so selfHeal can
      stay simple; enabling it now would require `ignoreDifferences` on
      Rollouts-owned HTTPRoute weights (ADR-0103).

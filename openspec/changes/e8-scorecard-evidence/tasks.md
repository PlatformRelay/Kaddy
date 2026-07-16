# Tasks — E8

- [ ] k6 profile (REQ-E8-S01-*)
- [ ] capture.sh + HTML (REQ-E8-S02-*)
- [ ] Pages workflow (REQ-E8-S03-*)
- [ ] **E8-S04 · Getting Started + reviewer demo**
  - [ ] Write the failing documentation contract
        `tests/meta/e8-s04-getting-started.sh` (REQ-E8-S04-01/03/05/06).
  - [ ] Write the failing live choreography test
        `tests/smoke/e8-s04-demo.sh` (REQ-E8-S04-04).
  - [ ] Add `docs/getting-started.md`: prerequisites, safe `kind-kaddy-dev` bring-up,
        dependency-ordered bootstrap, readiness checks, rerun behavior, and teardown.
  - [ ] Add the service catalogue with exact access commands, authentication source, canonical
        URLs or CLI surfaces, and Gateway-vs-backend-path labels for Argo CD, clubhouse, the
        composed Website, Grafana, Prometheus, Alertmanager, and mulligan.
  - [ ] Add the demo runbook: Website claim → marshal fire/resolve → mulligan progressive delivery
        → abort rollback, with expected evidence, timings, fallback, and recovery per act.
  - [ ] Link Getting Started from the README five-minute path and label unpublished E8 artifacts
        honestly (REQ-E8-S04-06).
  - [ ] Add the gridscale monthly cost table (GSK node pools, LBaaS, Object Storage) to the
        README (REQ-E8-S04-02).
  - [ ] Green: `tests/meta/e8-s04-getting-started.sh` +
        `tests/smoke/e8-s04-demo.sh`.
- [ ] Gate: `task test:scorecard`

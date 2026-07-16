# Tasks — E8

- [x] k6 profile (REQ-E8-S01-*) — `tests/load/marshal-threshold.js` + `tests/smoke/e8-s01-01.sh` on main
- [x] capture.sh + HTML (REQ-E8-S02-*) — `hack/scorecard/capture.sh` + `template.html` + e8-s02-* smokes on main
- [x] Pages workflow (REQ-E8-S03-*) — `.github/workflows/scorecard-pages.yaml` + `tests/smoke/e8-s03-01.sh` on main
- [x] **E8-S04 · Getting Started + reviewer demo**
  - [x] Write the failing documentation contract
        `tests/meta/e8-s04-getting-started.sh` (REQ-E8-S04-01/03/05/06).
  - [x] Write the failing live choreography test
        `tests/smoke/e8-s04-demo.sh` (REQ-E8-S04-04).
  - [x] Add `docs/getting-started.md`: prerequisites, safe `kind-kaddy-dev` bring-up,
        dependency-ordered bootstrap, readiness checks, rerun behavior, and teardown.
  - [x] Add the service catalogue with exact access commands, authentication source, canonical
        URLs or CLI surfaces, and Gateway-vs-backend-path labels for Argo CD, clubhouse, the
        composed Website, Grafana, Prometheus, Alertmanager, and mulligan.
  - [x] Add the demo runbook: Website claim → marshal fire/resolve → mulligan progressive delivery
        → abort rollback, with expected evidence, timings, fallback, and recovery per act.
  - [x] Link Getting Started from the README five-minute path and label unpublished E8 artifacts
        honestly (REQ-E8-S04-06).
  - [x] Add the gridscale monthly cost table (GSK node pools, LBaaS, Object Storage) to the
        README (REQ-E8-S04-02).
  - [x] Green: `tests/meta/e8-s04-getting-started.sh` +
        `tests/smoke/e8-s04-demo.sh`.
- [ ] Gate: `task test:scorecard`

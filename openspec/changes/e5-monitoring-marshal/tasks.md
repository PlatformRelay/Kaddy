# Tasks — E5

TDD: write the **promtool** test (L1) for a rule before writing the rule; write the Chainsaw
assert (L2) before the ServiceMonitor/PrometheusRule manifest.

> **Reconciliation (D-026 · ARCH-2/ARCH-3, 2026-07-15).** The `caddy_*` target-down slice
> (`marshal-caddy.yaml` `CaddyTargetDown` + Caddy `PodMonitor` + their promtool test) **migrated
> out of active platform monitoring** into the `e-caddy-mvp` VM-variant slice
> (`deploy/caddy-mvp/monitoring/`, `tests/promtool/caddy-mvp-marshal.test.yaml`, REQ-CADDY-S01-03).
> The Cilium/Envoy edge never emits `job="caddy"` (ADR-0104, D-019); operator-confirmed Option A —
> park. The `marshal-http` alerts stay **active**. Below reflects that split.

- [x] ~~PodMonitors~~ ServiceMonitor (REQ-E5-S01-*) — `deploy/monitoring/prometheus/`; Caddy
      `PodMonitor` **parked → `deploy/caddy-mvp/monitoring/prometheus/`** (D-026)
- [x] blackbox probes (REQ-E5-S02-*) — `deploy/monitoring/blackbox/caddy-probe.yaml`
- [x] **promtool rule unit tests first** — `tests/promtool/marshal.test.yaml` (active marshal-http,
      REQ-E5-S06-02/03); `CaddyTargetDown` test **parked → `tests/promtool/caddy-mvp-marshal.test.yaml`** (REQ-E5-S06-01 → REQ-CADDY-S01-03)
- [x] PrometheusRules marshal (REQ-E5-S03-*) — `deploy/monitoring/rules/marshal-http.yaml` (active);
      `marshal-caddy.yaml` **parked → `deploy/caddy-mvp/monitoring/rules/`** (REQ-E5-S03-01, D-026)
- [x] `hack/monitoring/extract-rules.sh` + `assert-rule-coverage.sh`
- [ ] Alertmanager receiver smoke (REQ-E5-S04-*)
- [ ] Loki log-based checks (REQ-E5-S07-*)
- [ ] Grafana dashboards + Loki datasource (REQ-E5-S05-*)
- [ ] **[TEST-3]** Write missing smoke test artifacts referenced in spec but not yet on disk
      (landed slices S01–S03 only; S04/S05 tests ride with their still-pending bullets above):
      `tests/smoke/e5-s01-01.sh` (REQ-E5-S01 ServiceMonitor present),
      `tests/smoke/e5-s01-02.sh` (REQ-E5-S01 scrape endpoint reachable),
      `tests/smoke/e5-s02-01.sh` (REQ-E5-S02 blackbox probe up),
      `tests/smoke/e5-s02-02.sh` (REQ-E5-S02 probe target responds),
      `tests/smoke/e5-s03-03.sh` (REQ-E5-S03 PrometheusRule loaded). Gate: implement once a
      cluster is available (e1e green); S04/S05 tests (`e5-s04-01.sh`, `e5-s05-01.sh`) remain
      with their owning slices (Alertmanager receiver + Grafana).
- [ ] Gate: `task test:promrules` (promtool L1, `monitoring.yaml`) + rule-coverage assertion + PromQL smoke

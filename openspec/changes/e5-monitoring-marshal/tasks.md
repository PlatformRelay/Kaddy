# Tasks — E5

TDD: write the **promtool** test (L1) for a rule before writing the rule; write the Chainsaw
assert (L2) before the ServiceMonitor/PrometheusRule manifest.

- [ ] PodMonitors (REQ-E5-S01-*)
- [ ] blackbox probes (REQ-E5-S02-*)
- [ ] **promtool rule unit tests first** — `tests/promtool/marshal.test.yaml` (REQ-E5-S06-*)
- [ ] PrometheusRules marshal (REQ-E5-S03-*)
- [ ] `hack/monitoring/extract-rules.sh` + `assert-rule-coverage.sh`
- [ ] Alertmanager receiver smoke (REQ-E5-S04-*)
- [ ] Loki log-based checks (REQ-E5-S07-*)
- [ ] Grafana dashboards + Loki datasource (REQ-E5-S05-*)
- [ ] Gate: `task test:promrules` + `chainsaw test tests/chainsaw/monitoring` + PromQL smoke

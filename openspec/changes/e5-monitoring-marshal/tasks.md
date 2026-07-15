# Tasks — E5

TDD: write the **promtool** test (L1) for a rule before writing the rule; write the Chainsaw
assert (L2) before the ServiceMonitor/PrometheusRule manifest.

- [x] PodMonitors / ServiceMonitor (REQ-E5-S01-*) — `deploy/monitoring/prometheus/`
- [x] blackbox probes (REQ-E5-S02-*) — `deploy/monitoring/blackbox/caddy-probe.yaml`
- [x] **promtool rule unit tests first** — `tests/promtool/marshal.test.yaml` (REQ-E5-S06-*)
- [x] PrometheusRules marshal (REQ-E5-S03-*) — `deploy/monitoring/rules/marshal-*.yaml`
- [x] `hack/monitoring/extract-rules.sh` + `assert-rule-coverage.sh`
- [ ] Alertmanager receiver smoke (REQ-E5-S04-*)
- [ ] Loki log-based checks (REQ-E5-S07-*)
- [ ] Grafana dashboards + Loki datasource (REQ-E5-S05-*)
- [ ] Gate: `task test:promrules` (promtool L1, `monitoring.yaml`) + rule-coverage assertion + PromQL smoke

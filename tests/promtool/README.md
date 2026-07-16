# promtool rule tests — kaddy (marshal)

**L1** unit tests for `PrometheusRule` alerts per [ADR-0701](../../docs/adr/0701-testing-strategy-chainsaw.md).
No cluster required — `promtool` feeds synthetic series and asserts alert firing + labels.

## Run

```bash
task test:promrules                 # all *.test.yaml here
promtool test rules tests/promtool/marshal.test.yaml              # active: needs extract-rules.sh first
promtool test rules tests/promtool/caddy-mvp-marshal.test.yaml    # epic: TargetDown (S01-03), standalone
promtool test rules tests/promtool/caddy-mvp-showcase.test.yaml   # epic: re-homed set (S05-04), standalone
```

## Layout

```
tests/promtool/
  README.md
  marshal.test.yaml              # ACTIVE — deploy/monitoring/rules/marshal-http.yaml (E5)
  caddy-mvp-marshal.test.yaml    # EPIC — CaddyTargetDown (D-026, REQ-CADDY-S01-03)
  caddy-mvp-showcase.test.yaml   # EPIC — re-homed caddy_* vs K8s origin (REQ-CADDY-S05-04)
```

> Both `caddy-mvp-*.test.yaml` suites load a **committed** rule projection
> (`deploy/caddy-mvp/monitoring/rules/marshal-caddy.rules.yaml`) via a relative `rule_files:` path,
> so they run standalone with no `extract-rules.sh` step — matching the epic spec's bare Verify.
> Showcase covers TargetDown plus revived `HighHTTPErrorRate` / `HighHTTPLatency` /
> `HighRequestRate` against the Kubernetes Caddy origin in ns `caddy-mvp`.

## How it maps to specs

Each `PrometheusRule` REQ in `openspec/changes/e5-monitoring-marshal/` has a matching test group
here (referenced by its `**Test:**` field). A rule is not "done" until its promtool test proves it
fires on the intended condition and stays silent otherwise.

## Extracting rules from PrometheusRule CRs

`promtool test rules` expects plain Prometheus rule groups. Extract the `.spec` from the CR:

```bash
yq '.spec' deploy/monitoring/rules/marshal-http.yaml > /tmp/marshal-http.rules.yaml
```

`hack/monitoring/extract-rules.sh` does this for **active** rules in CI (globs
`deploy/monitoring/rules/marshal-*.yaml` → `/tmp/*.rules.yaml`). The **parked** epic suite instead
loads a committed projection directly (see the layout note above), so it needs no extract step.

## Example

```yaml
rule_files:
  - /tmp/marshal-http.rules.yaml
evaluation_interval: 1m
tests:
  - interval: 1m
    input_series:
      - series: 'caddy_http_requests_total{job="caddy",code="200"}'
        values: '0+9000x15'
    alert_rule_test:
      - eval_time: 10m
        alertname: HighRequestRate
        exp_alerts:
          - exp_labels:
              severity: warning
              service: caddy
```

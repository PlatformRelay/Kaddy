# promtool rule tests — kaddy (marshal)

**L1** unit tests for `PrometheusRule` alerts per [ADR-0701](../../docs/adr/0701-testing-strategy-chainsaw.md).
No cluster required — `promtool` feeds synthetic series and asserts alert firing + labels.

## Run

```bash
task test:promrules                 # all *.test.yaml here
promtool test rules tests/promtool/marshal.test.yaml
```

## Layout

```
tests/promtool/
  README.md
  marshal.test.yaml     # tests for deploy/monitoring/rules/marshal-*.yaml (E5)
```

## How it maps to specs

Each `PrometheusRule` REQ in `openspec/changes/e5-monitoring-marshal/` has a matching test group
here (referenced by its `**Test:**` field). A rule is not "done" until its promtool test proves it
fires on the intended condition and stays silent otherwise.

## Extracting rules from PrometheusRule CRs

`promtool test rules` expects plain Prometheus rule groups. Extract the `.spec` from the CR:

```bash
yq '.spec' deploy/monitoring/rules/marshal-caddy.yaml > /tmp/marshal-caddy.rules.yaml
```

The E5 implementation adds `hack/monitoring/extract-rules.sh` to do this in CI.

## Example

```yaml
rule_files:
  - /tmp/marshal-caddy.rules.yaml
evaluation_interval: 1m
tests:
  - interval: 1m
    input_series:
      - series: 'up{job="caddy"}'
        values: '1 1 0 0 0 0'
    alert_rule_test:
      - eval_time: 5m
        alertname: CaddyTargetDown
        exp_alerts:
          - exp_labels:
              severity: critical
              service: caddy
```

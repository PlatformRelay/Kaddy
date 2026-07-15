# Marshal alerting rules (E5) — ACTIVE platform monitoring

`PrometheusRule` CRs for the marshal HTTP alerts. Each alert is proved
by an L1 `promtool` unit test in [`tests/promtool/marshal.test.yaml`](../../../tests/promtool/marshal.test.yaml)
and every alert name is coverage-checked by
[`hack/monitoring/assert-rule-coverage.sh`](../../../hack/monitoring/assert-rule-coverage.sh)
(REQ-E5-S06-05).

> **Migrated out (ARCH-2/ARCH-3, D-026):** the `CaddyTargetDown` rule (`marshal-caddy.yaml`)
> and the Caddy `PodMonitor` were **parked** with the `e-caddy-mvp` epic — the platform's
> Cilium/Envoy edge never emits a Caddy target, so that alert cannot fire against the platform
> (operator-confirmed Option A — park). They now live under
> [`deploy/caddy-mvp/monitoring/`](../../caddy-mvp/monitoring/) with their promtool suite at
> [`tests/promtool/caddy-mvp-marshal.test.yaml`](../../../tests/promtool/caddy-mvp-marshal.test.yaml)
> (REQ-CADDY-S01-03). See [ADR-0104](../../../docs/adr/0104-caddy-gateway-api.md).

Rule files are fed to `promtool` by
[`hack/monitoring/extract-rules.sh`](../../../hack/monitoring/extract-rules.sh),
which projects `.spec` out of each CR into `/tmp/<name>.rules.yaml`.

All CRs carry the ADR-0301 mandatory label core set on `metadata.labels`, and each
alert carries `severity`, `service`, `owner` labels for self-routing.

## Files

| File | Alerts |
| --- | --- |
| `marshal-http.yaml` | `HighHTTPErrorRate`, `HighHTTPLatency`, `HighRequestRate` |

`CaddyTargetDown` (`marshal-caddy.yaml`) is parked with `e-caddy-mvp` — see the note above.

## Thresholds and PromQL

### HighHTTPErrorRate (REQ-E5-S03-02)

- Severity: `warning`
- Threshold: 5xx responses exceed `5%` of total requests over a `5m` rate window,
  sustained for `5m`.
- PromQL:

  ```promql
  sum(rate(caddy_http_requests_total{job="caddy",code=~"5.."}[5m]))
    / sum(rate(caddy_http_requests_total{job="caddy"}[5m])) > 0.05
  ```

  with `for: 5m`.

### HighHTTPLatency (REQ-E5-S03-03)

- Severity: `warning`
- Threshold: p99 request latency exceeds `500ms` (`0.5s`) over a `5m` window,
  sustained for `5m`.
- PromQL:

  ```promql
  histogram_quantile(
    0.99,
    sum by (le) (rate(caddy_http_request_duration_seconds_bucket{job="caddy"}[5m]))
  ) > 0.5
  ```

  with `for: 5m`.

### HighRequestRate (REQ-E5-S03-04)

- Severity: `warning`
- Threshold: request rate exceeds `100 rps` (`5m` rate), sustained for `2m`.
- PromQL:

  ```promql
  sum(rate(caddy_http_requests_total{job="caddy"}[5m])) > 100
  ```

  with `for: 2m`.

## Running the tests offline

```bash
bash hack/monitoring/extract-rules.sh
task test:promrules
bash hack/monitoring/assert-rule-coverage.sh
```

No Kubernetes cluster is required — `promtool` feeds synthetic series and asserts
alert firing plus labels.

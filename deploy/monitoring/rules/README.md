# Marshal alerting rules (E5) — ACTIVE platform monitoring

`PrometheusRule` CRs for the marshal alerts, watching the REAL served site
(clubhouse through the Cilium Gateway, via the blackbox probe) and the
Cilium/Envoy edge listeners. Each alert is proved by an L1 `promtool` fire +
silent unit test in
[`tests/promtool/marshal.test.yaml`](../../../tests/promtool/marshal.test.yaml)
and every alert name is coverage-checked by
[`hack/monitoring/assert-rule-coverage.sh`](../../../hack/monitoring/assert-rule-coverage.sh)
(REQ-E5-S06-05). Synced live by the `monitoring` child Application
([`deploy/apps/monitoring.yaml`](../../apps/monitoring.yaml), ARCH-8 fix).

> **Migrated out (ARCH-2/ARCH-3, D-026):** the `CaddyTargetDown` rule (`marshal-caddy.yaml`)
> and the Caddy `PodMonitor` were **parked** with the `e-caddy-mvp` epic — the platform's
> Cilium/Envoy edge never emits a Caddy target. They live under
> [`deploy/caddy-mvp/monitoring/`](../../caddy-mvp/monitoring/) with their promtool suite at
> [`tests/promtool/caddy-mvp-marshal.test.yaml`](../../../tests/promtool/caddy-mvp-marshal.test.yaml)
> (REQ-CADDY-S01-03). See [ADR-0104](../../../docs/adr/0104-caddy-gateway-api.md).
>
> **Re-pointed (ARCH-2 residual, 2026-07-16):** the former `caddy_http_*`-based
> `HighHTTPErrorRate` / `HighHTTPLatency` / `HighRequestRate` exprs were unfireable on this
> platform for the same reason. They are replaced by the probe/edge alerts below.

Rule files are fed to `promtool` by
[`hack/monitoring/extract-rules.sh`](../../../hack/monitoring/extract-rules.sh),
which projects `.spec` out of each CR into `/tmp/<name>.rules.yaml`.

All CRs carry the ADR-0301 mandatory label core set on `metadata.labels`, and each
alert carries `severity`, `service`, `owner` labels for self-routing.

## Files

| File | Alerts |
| --- | --- |
| `marshal-http.yaml` | `ClubhouseDown`, `ClubhouseProbeLatencyHigh`, `ClubhouseCertExpirySoon`, `EdgeHTTPErrorRate`, `EdgeRequestRateHigh` |

## Thresholds and PromQL

### ClubhouseDown (REQ-E5-S03-05) — the fire leg

- Severity: `critical`
- Fires when the blackbox probe of the served site fails for `1m` — on BOTH
  probe failure and total signal loss (`absent()` — exporter/Probe gone), so
  breaking the monitoring path cannot silence it.
- PromQL:

  ```promql
  min by (job, service) (probe_success{job="blackbox",service="clubhouse"}) == 0
    or absent(probe_success{job="blackbox",service="clubhouse"})
  ```

  with `for: 1m`.

- **Demo trade-off (documented):** `for: 1m` is deliberately low so the live
  fire demo (`task demo:fire`) is watchable in minutes. With the 15s probe
  interval it still needs 4 consecutive failures (not single-sample-noisy);
  production guidance would be 3–5m to ride out flaky probes.

### ClubhouseProbeLatencyHigh (REQ-E5-S03-03)

- Severity: `warning`
- Threshold: end-to-end probe duration (TLS + edge + app) averaged over `5m`
  exceeds `500ms`, sustained `5m`.
- PromQL:

  ```promql
  avg_over_time(probe_duration_seconds{job="blackbox",service="clubhouse"}[5m]) > 0.5
  ```

  with `for: 5m`.

### ClubhouseCertExpirySoon (REQ-E5-S03-06)

- Severity: `warning`
- Threshold: served certificate expires in under `21d` (1814400s). `clubhouse-tls`
  renews `30d` before expiry, so 21d of runway means renewal has failed.
- PromQL:

  ```promql
  (probe_ssl_earliest_cert_expiry{job="blackbox",service="clubhouse"} - time()) < 1814400
  ```

  with `for: 15m`.

### EdgeHTTPErrorRate (REQ-E5-S03-02)

- Severity: `warning`
- Threshold: Envoy edge-listener 5xx class exceeds `5%` of listener traffic over
  a `5m` rate window, sustained `5m`.
- PromQL:

  ```promql
  sum(rate(envoy_http_downstream_rq_xx{job="cilium-envoy",envoy_response_code_class="5",envoy_http_conn_manager_prefix=~"listener-.*"}[5m]))
    / sum(rate(envoy_http_downstream_rq_total{job="cilium-envoy",envoy_http_conn_manager_prefix=~"listener-.*"}[5m])) > 0.05
  ```

  with `for: 5m`.

### EdgeRequestRateHigh (REQ-E5-S03-04)

- Severity: `warning`
- Threshold: edge request rate exceeds `100 rps` (`5m` rate, lab threshold),
  sustained `2m`.
- PromQL:

  ```promql
  sum(rate(envoy_http_downstream_rq_total{job="cilium-envoy",envoy_http_conn_manager_prefix=~"listener-.*"}[5m])) > 100
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

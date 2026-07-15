# Spec — E5 monitoring (marshal)

Epic: E5 · **Refs:** gridscale brief (response codes, latency, uptime, alerting)

> **Reconciliation (ARCH-2/ARCH-3, D-026, 2026-07-15).** The `caddy_*` **target-down** slice —
> the `CaddyTargetDown` alert (`marshal-caddy.yaml`), the Caddy `PodMonitor`, and their promtool
> tests — **migrated out of active platform monitoring** into the `e-caddy-mvp` VM-variant alerting
> slice ([REQ-CADDY-S01-03](../../../e-caddy-mvp/specs/caddy-mvp/spec.md)). The platform edge is
> Cilium Gateway API (Envoy), which never emits a `job="caddy"` target (ADR-0104, D-019), so that
> alert can only fire against the Caddy **VM tenant**. Operator-confirmed **Option A — park** (D-026).
> Fire+silent rigor is preserved, now at `tests/promtool/caddy-mvp-marshal.test.yaml`. The affected
> REQs below (S01-01, S03-01, S06-01) are **fulfilled by the `e-caddy-mvp` slice**, not by active
> platform monitoring; their scope is reconciled, not deleted. The `marshal-http` alerts
> (S03-02/03/04, S06-02/03) remain in **active** platform monitoring.

---

## REQ-E5-S01-01: Caddy PodMonitor

> **Migrated (D-026 · ARCH-2):** the Caddy `PodMonitor` moved to
> `deploy/caddy-mvp/monitoring/prometheus/caddy-podmonitor.yaml`; it scrapes the Caddy **VM
> tenant**, not the platform edge. Fulfilled by the `e-caddy-mvp` VM-variant slice.

**Priority:** must  
**Given** Caddy pods expose metrics on documented port (typically admin/metrics)  
**When** Prometheus targets scraped  
**Then** metric `caddy_http_requests_total` or documented equivalent exists  
**Test:** `tests/smoke/e5-s01-01.sh`
**Verify:**
```bash
curl -s 'http://127.0.0.1:9090/api/v1/query?query=caddy_http_requests_total' | jq -e '.data.result | length > 0'
```

---

## REQ-E5-S01-02: clubhouse app metrics (if exposed)

**Priority:** should  
**Given** app exposes `/metrics`  
**When** ServiceMonitor applied  
**Then** `up{service="clubhouse"}` == 1  
**Test:** `tests/smoke/e5-s01-02.sh`

**Verify:** PromQL in REQ-E5-S01-01 pattern with `service="clubhouse"`

---

## REQ-E5-S02-01: blackbox probe success

**Priority:** must  
**Given** Probe targeting `https://$HOST/`  
**When** `probe_success{job="blackbox"}` queried  
**Then** value 1  
**Test:** `tests/smoke/e5-s02-01.sh`

**Verify:** `curl -s 'http://127.0.0.1:9090/api/v1/query?query=probe_success'` 

---

## REQ-E5-S02-02: probe_http_status_code

**Priority:** must · **Refs:** brief (HTTP response codes)  
**Given** blackbox probe  
**When** probe runs against healthy site  
**Then** `probe_http_status_code == 200`  
**Test:** `tests/smoke/e5-s02-02.sh`

**Verify:** PromQL `probe_http_status_code`

---

## REQ-E5-S03-01: CaddyTargetDown alert

> **Migrated (D-026 · ARCH-2/ARCH-3):** `marshal-caddy.yaml` (`CaddyTargetDown`) parked with the
> `e-caddy-mvp` VM-variant slice ([REQ-CADDY-S01-03](../../../e-caddy-mvp/specs/caddy-mvp/spec.md));
> now lives at `deploy/caddy-mvp/monitoring/rules/marshal-caddy.yaml`. Fires against the Caddy VM
> target, not the platform edge (which never emits `job="caddy"`).

**Priority:** must  
**Given** PrometheusRule `marshal-caddy-down`  
**When** Caddy targets absent for 2m  
**Then** alert `CaddyTargetDown` fires with labels `severity=critical`, `owner`, `service`  
**Test:** `tests/chainsaw/monitoring/prometheusrule-present.yaml`

**Verify:** Chainsaw `tests/chainsaw/monitoring/prometheusrule-present.yaml` + manual `amtool` or API check

---

## REQ-E5-S03-02: HighErrorRate alert

**Priority:** must  
**Given** rule on 5xx rate > threshold (e.g. 5% over 5m)  
**When** fault injected (E7/E8)  
**Then** `HighHTTPErrorRate` fires  
**Test:** `hack/demo/inject-5xx.sh`

**Verify:** k6 or `hack/demo/inject-5xx.sh` + Alertmanager API

---

## REQ-E5-S03-03: HighLatency alert

**Priority:** must · **Refs:** brief (latency)  
**Given** histogram metric available  
**When** p99 > threshold (documented, e.g. 500ms)  
**Then** `HighHTTPLatency` fires  
**Test:** `tests/smoke/e5-s03-03.sh`

**Verify:** PromQL documented in `deploy/monitoring/rules/README.md`

---

## REQ-E5-S03-04: HighRequestRate alert

**Priority:** must · **Refs:** brief (request threshold)  
**Given** rate threshold (e.g. > 100 rps for 2m in lab)  
**When** k6 load applied (E8)  
**Then** `HighRequestRate` fires  
**Test:** `tests/load/marshal-threshold.js`

**Verify:** `task test:load` triggers alert; scorecard captures

---

## REQ-E5-S04-01: Alertmanager receiver configured

**Priority:** must  
**Given** AlertmanagerConfig or secret receiver (ntfy/webhook)  
**When** test alert fired via `amtool alert add`  
**Then** notification received at configured endpoint  
**Test:** `tests/smoke/e5-s04-01.sh`

**Verify:** smoke script with webhook.site or ntfy topic (secrets not committed)

---

## REQ-E5-S07-01: Caddy access logs reach Loki

**Priority:** must · **Story:** E5-S07 · **ADR:** [0108](../../../docs/adr/0108-logging-loki.md) · **Level:** L2  
**Given** Caddy access logging enabled and Alloy shipping to Loki  
**When** a request hits the gateway and `logcli`/LogQL queries `{service="caddy"} | json` in Loki  
**Then** at least one matching log line returns within the scrape/ship window  
**Test:** `tests/chainsaw/monitoring/loki-caddy-logs.yaml`

**Verify:** Chainsaw `script` step queries Loki API `query_range` for `{service="caddy"}`; result non-empty

---

## REQ-E5-S07-02: Log streams carry kaddy labels

**Priority:** must · **Level:** L2  
**Given** Alloy relabeling config  
**When** a stream is queried  
**Then** labels include `service`, `track`, `part-of` (correlates logs↔metrics, ADR-0301)  
**Test:** `tests/chainsaw/monitoring/loki-labels.yaml`

**Verify:** LogQL `{part_of="kaddy"}` returns streams with `service` and `track` labels

---

## REQ-E5-S07-03: Log-based alert on Caddy 5xx spike

**Priority:** should · **Level:** L2  
**Given** Loki ruler rule counting 5xx access-log lines  
**When** injected 5xx (E7/E8) exceeds threshold  
**Then** a Loki-sourced alert reaches the same Alertmanager as Prometheus alerts  
**Test:** `tests/chainsaw/monitoring/loki-ruler-alert.yaml`

**Verify:** Alertmanager API shows the log-based alert during the injection window

---

## REQ-E5-S05-01: Grafana dashboard ConfigMap

**Priority:** should  
**Given** dashboard JSON in `deploy/monitoring/dashboards/`  
**When** sidecar or operator imports  
**Then** dashboard UID `kaddy-marshal` exists in Grafana  
**Test:** `tests/smoke/e5-s05-01.sh`

**Verify:** Grafana API or `kubectl get configmap -n monitoring -l grafana_dashboard=1`

---

## REQ-E5-S06-01: CaddyTargetDown rule unit test

> **Migrated (D-026 · ARCH-2):** the fire+silent unit test moved to
> `tests/promtool/caddy-mvp-marshal.test.yaml` (standalone, no extract step), scoped to the
> `e-caddy-mvp` slice ([REQ-CADDY-S01-03](../../../e-caddy-mvp/specs/caddy-mvp/spec.md)). Rigor
> preserved; no active platform alert lost its test.

**Priority:** must · **Story:** E5-S06 · **Level:** L1 · **TDD:** write test first  
**Given** `deploy/caddy-mvp/monitoring/rules/marshal-caddy.yaml` PrometheusRule  
**When** `promtool test rules` feeds `up{job="caddy"}` dropping to 0 for > 2m  
**Then** `CaddyTargetDown` fires with `severity=critical`, `service` label present  
**Test:** `tests/promtool/caddy-mvp-marshal.test.yaml`

**Verify:** `promtool test rules tests/promtool/caddy-mvp-marshal.test.yaml`

---

## REQ-E5-S06-02: HighHTTPErrorRate rule unit test

**Priority:** must · **Level:** L1  
**Given** error-rate rule in `marshal-http.yaml`  
**When** synthetic 5xx series exceeds threshold for the `for:` window  
**Then** `HighHTTPErrorRate` fires; stays silent below threshold  
**Test:** `tests/promtool/marshal.test.yaml`

**Verify:** `task test:promrules`

---

## REQ-E5-S06-03: HighHTTPLatency + HighRequestRate rule unit tests

**Priority:** must · **Level:** L1  
**Given** latency (p99) and request-rate rules  
**When** synthetic histogram / rate series cross documented thresholds  
**Then** `HighHTTPLatency` and `HighRequestRate` fire at expected `eval_time`  
**Test:** `tests/promtool/marshal.test.yaml`

**Verify:** `task test:promrules`

---

## REQ-E5-S06-04: Rule tests run in CI

**Priority:** must · **Level:** L1  
**Given** PR touching `deploy/monitoring/**` or `tests/promtool/**`  
**When** CI runs  
**Then** `.github/workflows/monitoring.yaml` executes `task test:promrules` and must pass  
**Test:** `.github/workflows/monitoring.yaml`

**Verify:** workflow green on rules-changing PR; `promtool test rules` exit 0

---

## REQ-E5-S06-05: No untested alert rule

**Priority:** must · **Level:** meta  
**Given** every alert in `deploy/monitoring/rules/`  
**When** reviewed before merge  
**Then** each `alert:` name appears in at least one `alert_rule_test` in `tests/promtool/`  
**Test:** `hack/monitoring/assert-rule-coverage.sh`

**Verify:** `hack/monitoring/assert-rule-coverage.sh` lists 0 untested alerts

---

## REQ-E5-EXIT: Chainsaw monitoring suite

**Priority:** must  
**Given** E5 manifests merged  
**When** `chainsaw test tests/chainsaw/monitoring`  
**Then** ServiceMonitor + PrometheusRule resources assert present  
**Test:** `tests/chainsaw/monitoring`

**Verify:** `chainsaw test tests/chainsaw/monitoring`

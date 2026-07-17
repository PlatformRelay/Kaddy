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
> platform monitoring; their scope is reconciled, not deleted.
>
> **Fire-leg re-point (ARCH-2/ARCH-8/DIR-2, 2026-07-16).** The remaining "active" marshal-http
> alerts still used `caddy_http_requests_total{job="caddy"}` — unfireable on this platform — and
> `deploy/monitoring/` was GitOps-orphaned (no Application synced it; ARCH-8). This revision
> re-points every active REQ at the **actually-served site**: the blackbox HTTPS probe of
> `clubhouse.kaddy.local` through the Cilium Gateway (`probe_*`) and the Cilium/Envoy edge
> listeners (`envoy_http_downstream_rq_*`). New stories: **S08** (operator request 2026-07-16 —
> Grafana dashboard as code, data-source-managed alerts, deferred Crossplane Grafana provider)
> and **S09** (GitOps sync of the monitoring content — the ARCH-8 fix).

---

## REQ-E5-S01-01: Caddy PodMonitor

> **Migrated (D-026 · ARCH-2):** the Caddy `PodMonitor` moved to
> `deploy/caddy-mvp/monitoring/prometheus/caddy-podmonitor.yaml`; it scrapes the Caddy **VM
> tenant**, not the platform edge. Fulfilled by the `e-caddy-mvp` VM-variant slice, tested by its
> parked promtool suite.

**Priority:** must  
**Given** Caddy pods expose metrics on documented port (typically admin/metrics)  
**When** Prometheus targets scraped  
**Then** metric `caddy_http_requests_total` or documented equivalent exists  
**Test:** `tests/promtool/caddy-mvp-marshal.test.yaml`
**Verify:**

```bash
promtool test rules tests/promtool/caddy-mvp-marshal.test.yaml
```

---

## REQ-E5-S01-02: platform scrape plane covers the real edge

> **Re-pointed (2026-07-16):** clubhouse is `nginxinc/nginx-unprivileged` serving static content
> and exposes **no `/metrics`** — the original "clubhouse app metrics" leg is N/A (the old
> ServiceMonitor pointed at a nonexistent `apps` namespace and was dead config). The scrape-plane
> REQ now targets the components that DO emit the platform's real HTTP signals.

**Priority:** must  
**Given** ServiceMonitors `cilium-envoy` (kube-system, port envoy-metrics) and `argo-rollouts`
(argo-rollouts, port metrics) under `deploy/monitoring/prometheus/`  
**When** Prometheus targets are scraped  
**Then** `up{job="cilium-envoy"} == 1` and `up{job="argo-rollouts-metrics"} == 1`, making
`envoy_http_downstream_rq_*` (edge traffic/response classes) and `rollout_info*` available  
**Test:** `tests/smoke/e5-s01-02.sh`

**Verify:** `bash tests/smoke/e5-s01-02.sh` (live) — asserts both `up` values == 1

---

## REQ-E5-S02-01: blackbox probe success against the served site

**Priority:** must  
**Given** Probe `monitoring/clubhouse` targeting the live clubhouse site through the Cilium
Gateway — in-cluster target `https://cilium-gateway-clubhouse.gateway.svc/` with SNI + Host
pinned to `clubhouse.kaddy.local` (the hostname only resolves host-side), module
`http_2xx_tls_kaddy` verifying the certificate chain against **kaddy-local-ca** (real TLS check,
no insecure skip)  
**When** `probe_success{job="blackbox",service="clubhouse"}` queried  
**Then** value 1  
**Test:** `tests/smoke/e5-s02-01.sh`

**Verify:** `bash tests/smoke/e5-s02-01.sh` (live PromQL via port-forward)

---

## REQ-E5-S02-02: probe_http_status_code

**Priority:** must · **Refs:** brief (HTTP response codes)  
**Given** the clubhouse blackbox probe (REQ-E5-S02-01)  
**When** probe runs against the healthy site  
**Then** `probe_http_status_code == 200`  
**Test:** `tests/smoke/e5-s02-02.sh`

**Verify:** `bash tests/smoke/e5-s02-02.sh` (live PromQL `probe_http_status_code`)

---

## REQ-E5-S02-03: blackbox exporter deployed with declarative CA trust

**Priority:** must  
**Given** the `blackbox-exporter` Helm Application (chart `prometheus-blackbox-exporter` 11.15.1,
pinned) under `deploy/monitoring/blackbox/`, and the `kaddy-ca-trust` Certificate issued by the
`kaddy-local-ca` ClusterIssuer into ns monitoring (cert-manager writes the issuing CA's `ca.crt`
into the Secret — a GitOps-converging CA courier, no out-of-band trust bootstrap)  
**When** the monitoring child Application syncs  
**Then** the exporter Deployment is Available with `/etc/blackbox/ca/ca.crt` mounted from the
`kaddy-ca-trust` Secret, and the `http_2xx_tls_kaddy` module performs CA-verified TLS probes  
**Test:** `tests/smoke/e5-s02-03.sh`

**Verify:** `bash tests/smoke/e5-s02-03.sh` — Certificate Ready, Secret has `ca.crt`, Deployment Available

---

## REQ-E5-S03-01: CaddyTargetDown alert

> **Migrated (D-026 · ARCH-2/ARCH-3):** `marshal-caddy.yaml` (`CaddyTargetDown`) parked with the
> `e-caddy-mvp` VM-variant slice ([REQ-CADDY-S01-03](../../../e-caddy-mvp/specs/caddy-mvp/spec.md));
> now lives at `deploy/caddy-mvp/monitoring/rules/marshal-caddy.yaml`. Fires against the Caddy VM
> target, not the platform edge (which never emits `job="caddy"`). The platform's target-down
> concern is covered by `ClubhouseDown` (REQ-E5-S03-05), whose `absent()` leg also fires on
> monitoring-path loss.

**Priority:** must  
**Given** PrometheusRule `marshal-caddy` (parked, e-caddy-mvp)  
**When** Caddy targets absent for 2m  
**Then** alert `CaddyTargetDown` fires with labels `severity=critical`, `owner`, `service`  
**Test:** `tests/chainsaw/monitoring/marshal-rules-present.yaml`

**Verify:** `chainsaw test tests/chainsaw/monitoring` (platform CRs assert) + `promtool test rules tests/promtool/caddy-mvp-marshal.test.yaml` (parked alert)

---

## REQ-E5-S03-02: EdgeHTTPErrorRate alert

> **Re-pointed (2026-07-16):** was `HighHTTPErrorRate` on `caddy_http_requests_total` — unfireable
> on the Cilium/Envoy edge. Now watches the real edge listener metrics.

**Priority:** must · **Refs:** brief (response codes)  
**Given** rule on the Envoy edge 5xx class ratio —
`envoy_http_downstream_rq_xx{envoy_response_code_class="5",envoy_http_conn_manager_prefix=~"listener-.*"}`
over total listener traffic > 5% over 5m, sustained 5m  
**When** the edge serves a sustained 5xx spike (fault injection, E7/E8)  
**Then** `EdgeHTTPErrorRate` fires with `severity=warning`, `service=gateway`, `owner`  
**Test:** `tests/promtool/marshal.test.yaml`

**Verify:** `task test:promrules` (fire + silent cases)

---

## REQ-E5-S03-03: ClubhouseProbeLatencyHigh alert

> **Re-pointed (2026-07-16):** was `HighHTTPLatency` on a Caddy histogram that does not exist on
> the platform. Now watches the end-to-end blackbox probe duration (TLS + edge + app).

**Priority:** must · **Refs:** brief (latency)  
**Given** rule on `avg_over_time(probe_duration_seconds{job="blackbox",service="clubhouse"}[5m])`
above the documented threshold 500ms, sustained 5m  
**When** the probed path degrades beyond 500ms for 5m  
**Then** `ClubhouseProbeLatencyHigh` fires with `severity=warning`, `service=clubhouse`  
**Test:** `tests/promtool/marshal.test.yaml`

**Verify:** `task test:promrules`; PromQL documented in `deploy/monitoring/rules/README.md`

---

## REQ-E5-S03-04: EdgeRequestRateHigh alert

> **Re-pointed (2026-07-16):** was `HighRequestRate` on `caddy_http_requests_total`. Now watches
> the real edge listener request rate.

**Priority:** must · **Refs:** brief (request threshold)  
**Given** rate threshold on the Envoy edge listeners — > 100 rps (5m rate, lab threshold),
sustained 2m  
**When** k6 load applied (E8) or a genuine traffic spike hits the edge  
**Then** `EdgeRequestRateHigh` fires with `severity=warning`, `service=gateway`  
**Test:** `tests/promtool/marshal.test.yaml`

**Verify:** `task test:promrules`; live trigger via `task test:load` (E8) captures in scorecard

---

## REQ-E5-S03-05: ClubhouseDown alert — the fire leg

**Priority:** must · **Refs:** brief (uptime, alerting); audit DIR-2  
**Given** rule `min by (job, service) (probe_success{job="blackbox",service="clubhouse"}) == 0 or
absent(probe_success{job="blackbox",service="clubhouse"})` with `for: 1m` and
`severity=critical` — the `absent()` leg also fires when the monitoring path itself dies
(exporter/Probe gone), so breaking the marshal cannot silence it. **`for: 1m` is a documented
demo trade-off:** with the 15s probe interval it still needs 4 consecutive failures, while
keeping the live fire demo watchable (production guidance: 3–5m); see
`deploy/monitoring/rules/README.md`  
**When** the served site goes down (demo: `deploy/clubhouse` scaled to 0 behind the live Gateway)  
**Then** `ClubhouseDown` transitions pending → **firing** in Prometheus and appears **ACTIVE in
the Alertmanager v2 API**, then resolves after restore — proven end-to-end by the scripted,
idempotent, self-restoring fire demo  
**Test:** `hack/demo/marshal-fire.sh`

**Verify:** `task demo:fire` (== `bash tests/smoke/e5-s03-05.sh`) exits 0, printing the
break → firing → Alertmanager-active → resolved timeline

---

## REQ-E5-S03-06: ClubhouseCertExpirySoon alert

**Priority:** should  
**Given** rule `(probe_ssl_earliest_cert_expiry{job="blackbox",service="clubhouse"} - time()) <
1814400` (21 days) — `clubhouse-tls` renews 30d before expiry (`renewBefore: 720h`), so < 21d of
runway means cert-manager renewal has failed  
**When** the served certificate's remaining lifetime drops under 21 days  
**Then** `ClubhouseCertExpirySoon` fires with `severity=warning`, `service=clubhouse`  
**Test:** `tests/promtool/marshal.test.yaml`

**Verify:** `task test:promrules` (fire + silent cases)

---

## REQ-E5-S04-01: Alertmanager receiver path

> **Lab-reconciled (2026-07-16):** external notification endpoints (ntfy/webhook) stay out of the
> lab — no secrets committed, no external dependency in gates. The receiver PATH is proven: a
> synthetic alert POSTed to the v2 API is accepted, routed to the configured receiver and listed
> ACTIVE; the real Prometheus→Alertmanager leg is proven by the fire demo (REQ-E5-S03-05).
> Wiring a real ntfy/webhook receiver is deferred to the hardening/evidence lane.

**Priority:** must  
**Given** the kube-prometheus-stack Alertmanager with its configured route/receiver  
**When** a synthetic alert is POSTed via `/api/v2/alerts` (amtool-equivalent)  
**Then** Alertmanager accepts it (HTTP 200), lists it ACTIVE and reports the routed receiver  
**Test:** `tests/smoke/e5-s04-01.sh`

**Verify:** `bash tests/smoke/e5-s04-01.sh` (live)

---

## REQ-E5-S07-01: served-site logs reach Loki

> **Re-pointed (2026-07-16):** "Caddy access logs" → the logs of the actually-served site
> (clubhouse / nginx-unprivileged behind the Cilium Gateway), shipped by Alloy.

**Priority:** must · **Story:** E5-S07 · **ADR:** [0108](../../../docs/adr/0108-logging-loki.md) · **Level:** L2  
**Given** clubhouse logging to stdout and Alloy shipping to Loki  
**When** a request hits the gateway and LogQL queries `{service="clubhouse"}` in Loki  
**Then** at least one matching log line returns within the ship window  
**Test:** `tests/smoke/e5-s07-01.sh`

**Verify:** `bash tests/smoke/e5-s07-01.sh` — Loki `query_range` for `{service="clubhouse"}` non-empty

---

## REQ-E5-S07-02: Log streams carry kaddy labels

**Priority:** must · **Level:** L2  
**Given** Alloy relabeling config  
**When** a stream is queried  
**Then** labels include `service` and `part_of` (underscore mirror of ADR-0301 — Loki/Prometheus
label names cannot contain dashes), correlating logs ↔ metrics  
**Test:** `tests/smoke/e5-s07-02.sh`

**Verify:** LogQL `{part_of="kaddy"}` returns streams carrying `service` — `bash tests/smoke/e5-s07-02.sh`

---

## REQ-E5-S07-03: Log-based alert on served-site 5xx spike

> **Deferred (2026-07-16):** the lab Loki single-binary runs with the ruler unconfigured; enabling
> it means resizing the observability values (outside the fire-leg lane boundary). The
> Prometheus-side alerting path is fully proven (REQ-E5-S03-05). Un-defer with a Loki-ruler lane.

**Priority:** should · **Level:** L2  
**Given** Loki ruler rule counting 5xx access-log lines  
**When** injected 5xx exceeds threshold  
**Then** a Loki-sourced alert reaches the same Alertmanager as Prometheus alerts  
**Test:** `tests/chainsaw/monitoring/loki-ruler-alert.yaml`

**Verify:** suite documents the deferral (`skip: true` + reason); Alertmanager API during injection once un-deferred

---

## REQ-E5-S05-01: Grafana dashboard ConfigMap

**Priority:** must (raised from should — operator request 2026-07-16)  
**Given** dashboard JSON in `deploy/monitoring/dashboards/kaddy-marshal.yaml` (ConfigMap labelled
`grafana_dashboard: "1"`, picked up by the kps Grafana dashboard sidecar which is enabled in
`deploy/observability/kube-prometheus-stack.yaml`)  
**When** the sidecar imports it  
**Then** dashboard UID `kaddy-marshal` exists in Grafana with the operator-requested panels:
clubhouse probe status + latency, TLS cert runway, edge traffic by listener + response classes,
rollouts replicas/phase, Prometheus/Alertmanager health, firing-alert count and marshal alert state  
**Test:** `tests/smoke/e5-s05-01.sh`

**Verify:** Grafana `/api/dashboards/uid/kaddy-marshal` returns the dashboard (creds read from the
chart Secret) — `bash tests/smoke/e5-s05-01.sh`

---

## REQ-E5-S08-01: kaddy Grafana dashboard provisioned as code

**Priority:** must · **Story:** E5-S08 (operator request 2026-07-16)  
**Given** the kaddy-marshal dashboard exists ONLY as committed code (REQ-E5-S05-01's ConfigMap) —
never hand-edited in the Grafana UI (`editable: false`)  
**When** the monitoring child Application syncs and the Grafana sidecar provisions  
**Then** the dashboard is reproducible from git alone: deleting it in Grafana or re-creating the
cluster converges back to the committed JSON  
**Test:** `tests/smoke/e5-s05-01.sh`

**Verify:** `kubectl -n monitoring get cm kaddy-marshal-dashboard -l grafana_dashboard=1` +
Grafana API uid lookup (same smoke)

---

## REQ-E5-S08-02: data-source-managed alerts visible in Grafana

**Priority:** must · **Story:** E5-S08 (operator request 2026-07-16)  
**Given** the marshal alerts are evaluated by the **Prometheus ruler** (PrometheusRule CRs — the
GitOps-owned path), NOT created as Grafana-managed (UI-clicked) rules  
**When** Grafana's unified alerting reads the Prometheus datasource
(`/api/prometheus/<ds-uid>/api/v1/rules`)  
**Then** the `marshal.http` group with all five alerts is visible in Grafana's Alerting UI as
**data-source-managed**, and is absent from the Grafana-managed ruler
(`/api/prometheus/grafana/api/v1/rules`)  
**Test:** `tests/smoke/e5-s08-02.sh`

**Verify:** `bash tests/smoke/e5-s08-02.sh` (live, both positive and negative assertion)

---

## REQ-E5-S08-03: Grafana resources via the Crossplane Grafana provider

> **OPTIONAL / DEFERRED — gated on E6 (Crossplane core).** Crossplane is NOT installed on the
> platform; nothing may be installed for this REQ until the E6 lane lands Crossplane core. Recorded
> now (operator request 2026-07-16) so the target state is specified before implementation.

**Priority:** could (deferred to E6)  
**Given** Crossplane core installed (E6) and `grafana/provider-grafana` configured against the
in-cluster Grafana (ProviderConfig sourcing the admin Secret)  
**When** Grafana dashboards/datasources/alert resources are declared as Crossplane managed
resources (e.g. `Dashboard`, `DataSource` CRs) instead of sidecar ConfigMaps  
**Then** Grafana state is fully reconciled by Crossplane with drift detection, superseding the
sidecar-ConfigMap mechanism of REQ-E5-S08-01 for managed objects  
**Test:** `openspec/changes/e5-monitoring-marshal/tasks.md`

**Verify:** deferred — no Crossplane resources exist in `deploy/` today (checked in review); once
E6 lands: `kubectl get providers.pkg.crossplane.io grafana-provider-grafana` + a Dashboard MR
Ready=True

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

## REQ-E5-S06-02: EdgeHTTPErrorRate + ClubhouseDown rule unit tests

**Priority:** must · **Level:** L1  
**Given** the error-rate and down rules in `marshal-http.yaml`  
**When** synthetic Envoy 5xx series exceed threshold for the `for:` window, and `probe_success`
drops to 0 / goes absent  
**Then** `EdgeHTTPErrorRate` and `ClubhouseDown` fire (the latter on BOTH the `== 0` and the
`absent()` leg); each stays silent below threshold / while healthy  
**Test:** `tests/promtool/marshal.test.yaml`

**Verify:** `task test:promrules`

---

## REQ-E5-S06-03: latency + request-rate + cert-expiry rule unit tests

**Priority:** must · **Level:** L1  
**Given** `ClubhouseProbeLatencyHigh`, `EdgeRequestRateHigh` and `ClubhouseCertExpirySoon` rules  
**When** synthetic probe-duration / edge-rate / cert-expiry series cross the documented thresholds  
**Then** each alert fires at expected `eval_time` with its labels, and stays silent below threshold  
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

## REQ-E5-S09-01: monitoring content GitOps-synced (ARCH-8)

**Priority:** must · **Refs:** audit ARCH-8 (P1)  
**Given** the `monitoring` child Application (`deploy/apps/monitoring.yaml`) pointing at
`deploy/monitoring/` with `directory.recurse: true`, `selfHeal: false` (consistent with the
observability child) and ADR-0301 labels — closing the gap where NO Application synced the
kaddy-authored monitoring content  
**When** the app-of-apps root syncs `main` (or a runtime-overridden lane branch for live
pre-merge proof — committed files stay `targetRevision: main`)  
**Then** the Application is Synced/Healthy and the marshal PrometheusRule, clubhouse Probe,
ServiceMonitors and dashboard ConfigMap are LIVE in ns monitoring  
**Test:** `tests/smoke/e5-s09-01.sh`

**Verify:** `bash tests/smoke/e5-s09-01.sh` (live)

---

## REQ-E5-EXIT: Chainsaw monitoring suite

**Priority:** must  
**Given** E5 manifests merged  
**When** `chainsaw test tests/chainsaw/monitoring`  
**Then** the stack suites pass and `marshal-rules-present.yaml` applies + asserts the marshal
PrometheusRule, Probe and ServiceMonitors  
**Test:** `tests/chainsaw/monitoring`

**Verify:** `chainsaw test tests/chainsaw/monitoring`

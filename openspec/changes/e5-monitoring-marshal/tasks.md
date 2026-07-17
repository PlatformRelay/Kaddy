# Tasks — E5

TDD: write the **promtool** test (L1) for a rule before writing the rule; write the Chainsaw
assert (L2) before the ServiceMonitor/PrometheusRule manifest.

> **Reconciliation (D-026 · ARCH-2/ARCH-3, 2026-07-15).** The `caddy_*` target-down slice
> (`marshal-caddy.yaml` `CaddyTargetDown` + Caddy `PodMonitor` + their promtool test) **migrated
> out of active platform monitoring** into the `e-caddy-mvp` VM-variant slice
> (`deploy/caddy-mvp/monitoring/`, `tests/promtool/caddy-mvp-marshal.test.yaml`, REQ-CADDY-S01-03).
> The Cilium/Envoy edge never emits `job="caddy"` (ADR-0104, D-019); operator-confirmed Option A —
> park.
>
> **Fire-leg completion (ARCH-2/ARCH-8/DIR-2, 2026-07-16).** All active marshal REQs re-pointed
> at the real served site (blackbox probe of clubhouse through the Cilium Gateway + Envoy edge
> metrics); `deploy/monitoring/` GitOps-wired via the `monitoring` child Application; the fire
> demo proves ClubhouseDown end to end. Operator requests S08 (Grafana) recorded below.

- [x] ~~PodMonitors~~ ServiceMonitor (REQ-E5-S01-*) — `deploy/monitoring/prometheus/`
      (cilium-envoy + argo-rollouts; the dead clubhouse ServiceMonitor removed — no `/metrics`);
      Caddy `PodMonitor` **parked → `deploy/caddy-mvp/monitoring/prometheus/`** (D-026)
- [x] blackbox probe of the SERVED site (REQ-E5-S02-*) —
      `deploy/monitoring/blackbox/clubhouse-probe.yaml` (CA-verified TLS, SNI/Host pinned) +
      `blackbox-exporter.yaml` Helm app + `ca-trust-certificate.yaml` (declarative CA courier)
- [x] **promtool rule unit tests first** — `tests/promtool/marshal.test.yaml` (fire + silent for
      all five re-pointed alerts, incl. the ClubhouseDown `absent()` leg; REQ-E5-S06-02/03);
      `CaddyTargetDown` test **parked → `tests/promtool/caddy-mvp-marshal.test.yaml`** (REQ-E5-S06-01)
- [x] PrometheusRules marshal (REQ-E5-S03-*) — `deploy/monitoring/rules/marshal-http.yaml`
      re-pointed: ClubhouseDown / ClubhouseProbeLatencyHigh / ClubhouseCertExpirySoon /
      EdgeHTTPErrorRate / EdgeRequestRateHigh (`marshal-caddy.yaml` parked, D-026)
- [x] `hack/monitoring/extract-rules.sh` + `assert-rule-coverage.sh`
- [x] GitOps sync (REQ-E5-S09-01, ARCH-8) — `deploy/apps/monitoring.yaml` child Application
      (recurse:true, selfHeal:false)
- [x] FIRE demo (REQ-E5-S03-05, DIR-2) — `hack/demo/marshal-fire.sh` + `task demo:fire`:
      controlled outage → pending → firing → Alertmanager ACTIVE → restore → resolved
- [x] Alertmanager receiver-path smoke (REQ-E5-S04-01, lab-reconciled) — `tests/smoke/e5-s04-01.sh`
- [x] Loki log checks (REQ-E5-S07-01/02) — `tests/smoke/e5-s07-01.sh` / `e5-s07-02.sh`
- [ ] Loki-ruler log-based alert (REQ-E5-S07-03) — **DEFERRED**: lab Loki single-binary runs with
      the ruler unconfigured; enabling it resizes observability values (outside the fire-leg
      lane boundary). Placeholder suite: `tests/chainsaw/monitoring/loki-ruler-alert.yaml` (skip: true)
- [x] Grafana dashboard as code (REQ-E5-S05-01 / S08-01) —
      `deploy/monitoring/dashboards/kaddy-marshal.yaml` (uid `kaddy-marshal`, sidecar-provisioned)
- [x] Data-source-managed alerts in Grafana (REQ-E5-S08-02) — `tests/smoke/e5-s08-02.sh`
- [ ] Crossplane Grafana provider (REQ-E5-S08-03) — **DEFERRED, gated on E6 Crossplane core**:
      do NOT install anything Crossplane before E6 lands; then wire `grafana/provider-grafana`
      (ProviderConfig from the Grafana admin Secret) and migrate dashboards/datasources to
      managed resources
- [x] Live smoke bundle — `task test:smoke:e5` (`tests/smoke/e5-exit.sh`, fire demo last)
- [x] Gate: `task test:promrules` (promtool L1, `monitoring.yaml` CI) + rule-coverage assertion

# deploy/monitoring — kaddy-authored monitoring content (E5 marshal)

The kaddy CONTENT layered on the observability STACK:

| Dir | What | Synced by |
| --- | --- | --- |
| `rules/` | marshal `PrometheusRule` alerts | `monitoring` child Application |
| `blackbox/` | blackbox exporter (nested Helm app), CA-trust Certificate, clubhouse `Probe` | `monitoring` child Application |
| `prometheus/` | `ServiceMonitor`s (cilium-envoy edge, argo-rollouts) | `monitoring` child Application |
| `dashboards/` | Grafana dashboard ConfigMaps (`grafana_dashboard: "1"`) | `monitoring` child Application |

The stack itself (kube-prometheus-stack, Loki, Alloy) lives in
[`deploy/observability/`](../observability/). This split fixes audit finding
**ARCH-8** (this directory previously had NO Application syncing it):
[`deploy/apps/monitoring.yaml`](../apps/monitoring.yaml) points here with
`directory.recurse: true` and `selfHeal: false` (consistent with the
observability child).

## The probe path (ARCH-2 re-point)

The blackbox probe exercises the REAL serve path: target
`https://cilium-gateway-clubhouse.gateway.svc/` (the Gateway's stable Service
DNS — `clubhouse.kaddy.local` only resolves host-side) with SNI + Host pinned
to `clubhouse.kaddy.local` and the certificate chain verified against
**kaddy-local-ca**. CA trust converges declaratively: the `kaddy-ca-trust`
Certificate is issued by the `kaddy-local-ca` ClusterIssuer into ns monitoring,
and cert-manager writes the issuing CA's `ca.crt` into the resulting Secret,
which the exporter mounts. No out-of-band trust bootstrap.

## Fire demo

`task demo:fire` (== `hack/demo/marshal-fire.sh`) proves the brief's
serve → scrape → **fire** leg live: controlled clubhouse outage →
`ClubhouseDown` pending → firing → ACTIVE in the Alertmanager v2 API →
restore → resolved. `task test:smoke:e5` runs the full live bundle
(`tests/smoke/e5-exit.sh`), fire demo last.

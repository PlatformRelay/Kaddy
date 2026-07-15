# ADR-0108: Logging — Loki + Alloy

**Theme:** 01 · Foundations · **Status:** Current

## Context

kaddy monitors metrics (Prometheus) but the gridscale brief also asks for **logs** as evidence
("screenshots or logs demonstrating successful monitoring"). Metrics answer *how much*; logs answer
*why* — Caddy access logs, 5xx bodies, Rollout controller events, Crossplane reconcile errors. A
platform story without centralized logs is incomplete.

Options:

| Option | Pros | Cons |
| --- | --- | --- |
| **Loki + Grafana Alloy** | Same Grafana pane as metrics; label model mirrors Prometheus; cheap object storage | Another stateful component |
| EFK (Elasticsearch) | Rich full-text search | Heavy for a lab; JVM footprint |
| Managed cloud logging | Managed | Vendor lock; less portable; weaker demo |

## Decision

Deploy **Grafana Loki** (single-binary / SimpleScalable for lab) with **Grafana Alloy** as the log
collector (DaemonSet), scraping pod logs and shipping to Loki. Loki is added as a **Grafana
datasource** so logs and metrics share one UI and one alerting engine.

- Namespace: `monitoring` (co-located with kube-prometheus-stack).
- Storage: filesystem or gridscale S3-compatible Object Storage (documented; creds via External Secrets).
- **Labels:** Alloy enriches streams with kaddy mandatory labels (`service`, `track`, `part-of`) so
  logs correlate with metrics and the label-based `marshal` routing (ADR-0301).
- **Log-based alerting:** Loki ruler evaluates LogQL alert rules (e.g. spike in Caddy 5xx log lines)
  routed through the same Alertmanager as Prometheus.
- **Retention:** short (lab) — documented in `deploy/monitoring/loki/`.

### Why Alloy over Promtail

Promtail is deprecated in favour of **Grafana Alloy** (OTel-native collector). Alloy also positions
kaddy for traces later without a third agent.

## Testing

- **L1:** LogQL rule unit tests where practical (`tests/promtool/`-style for Loki ruler, or documented
  query assertions).
- **L2:** Chainsaw asserts Loki `Ready`, Alloy DaemonSet scheduled on all nodes, Grafana datasource
  provisioned, and a known log line is queryable end-to-end.

## Consequences

- E3 observability app grows: kube-prometheus-stack **+ Loki + Alloy**.
- E5 gains log-based checks and a Grafana "logs" panel for the scorecard.
- Scorecard (E8) captures a LogQL query result alongside PromQL.

## Counterpoints

- Loki is another moving part for a hiring exercise — accepted: logs are an explicit brief deliverable
  and the Grafana-native path is low-friction (D-015 to record).

## References

- [Grafana Loki](https://grafana.com/docs/loki/latest/)
- [Grafana Alloy](https://grafana.com/docs/alloy/latest/)
- [Loki ruler / alerting](https://grafana.com/docs/loki/latest/alert/)

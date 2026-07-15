# ADR-0401: Caddy operator — design-first

**Theme:** 04 · Operator · **Status:** Current (design only — implementation E9 optional)

## Context

`caddyserver/gateway` is a **controller only** — operators must bring their own Caddy Deployment.
Upstream README states a future CRD may deploy and manage Caddy automatically.

A **kaddy Caddy operator** would close the loop: declare `Caddy` + `CaddySite` CRs; operator
deploys Caddy, drives Admin API, provisions observability assets per site.

## Decision — design-first

**Implement spec + ADR now; code in E9 only if E1–E8 are green.**

### CRDs (sketch)

| Kind | Scope | Purpose |
| --- | --- | --- |
| `Caddy` | namespaced | Gateway dataplane: Deployment, Service, PodMonitor, certs |
| `CaddySite` | namespaced | Binds hostname/paths → backend; generates HTTPRoute fragments |

### Reconciler model

- Watch `Caddy`, `CaddySite`, referenced Secrets
- Render Caddy JSON config → POST to Admin API (`/config/...`)
- Status conditions: `Ready`, `Configured`, `MetricsAvailable`
- Finalizers for graceful drain

### Observability contract (differentiator)

On each `CaddySite`, auto-create:

- `ServiceMonitor` scraping Caddy metrics
- `PrometheusRule` from templates (error rate, latency, down)
- Grafana dashboard ConfigMap (optional)

### Non-goals (v1 design)

- Replace `caddyserver/gateway` Gateway API controller — **complement** or embed later
- Multi-cluster federation

## Consequences

- Interview can walk CRD YAML + reconcile diagram without shipping Go.
- If E9 skipped, design still demonstrates operator thinking.

## References

- mkurator/kollect kubebuilder patterns for future implementation
- [caddyserver/gateway](https://github.com/caddyserver/gateway)

See OpenSpec: `openspec/changes/e9-caddy-operator/`

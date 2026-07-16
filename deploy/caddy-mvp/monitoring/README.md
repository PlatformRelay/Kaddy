# e-caddy-mvp — Caddy-origin alerting slice (re-homed E5 `caddy_*` marshal)

**Status:** re-homed against the **Kubernetes Caddy origin** in ns `caddy-mvp`
(REQ-CADDY-S05-04). PodMonitor scrapes the origin `/metrics`; promtool proves
fire + silent for every alert. GitOps Application `caddy-mvp-monitoring`
(`deploy/apps/caddy-mvp-monitoring.yaml`) syncs this tree — no longer orphaned
from Argo CD. Live serve→scrape→fire still needs the tenant Ready on cluster.
The same rules also cover the VM-variant path once that scrape target lands
(REQ-CADDY-S01-03).

These manifests live with the `e-caddy-mvp` epic, migrated **out of active
platform monitoring** by audit-remediation WS1 (operator-confirmed **Option A — park**,
`agent-context/decisions.md` D-026; audit ARCH-2/ARCH-3).

**Why they moved:** the platform edge is **Cilium Gateway API (Envoy)**, not Caddy
([ADR-0104](../../../docs/adr/0104-caddy-gateway-api.md), D-019). The Cilium/Envoy edge
never emits a `job="caddy"` scrape target, so the `caddy_*` alerts can never fire
against the platform as originally wired. Their real target is the **Caddy tenant
origin** (showcase Rollout in `caddy-mvp`, or the VM variant's external `/metrics`).

## Files

| File | Purpose |
| --- | --- |
| `rules/marshal-caddy.yaml` | `PrometheusRule` CR — `CaddyTargetDown` + revived `HighHTTPErrorRate` / `HighHTTPLatency` / `HighRequestRate` |
| `rules/marshal-caddy.rules.yaml` | Plain `groups:` projection of the CR `.spec`, committed so the epic promtool suite loads it directly (no `/tmp` extract) |
| `prometheus/caddy-podmonitor.yaml` | `PodMonitor` scraping the Caddy origin `/metrics` (pins `job="caddy"`; `namespaceSelector` → `caddy-mvp` — REQ-CADDY-S02-03 / S05-04) |

## Tests

| Suite | REQ | Notes |
| --- | --- | --- |
| [`tests/promtool/caddy-mvp-showcase.test.yaml`](../../../tests/promtool/caddy-mvp-showcase.test.yaml) | REQ-CADDY-S05-04 | Full re-homed set (TargetDown + HTTP alerts), framed on the K8s origin |
| [`tests/promtool/caddy-mvp-marshal.test.yaml`](../../../tests/promtool/caddy-mvp-marshal.test.yaml) | REQ-CADDY-S01-03 | TargetDown fire+silent (VM-variant path) |

Both are **standalone** — no extract step:

```bash
promtool test rules tests/promtool/caddy-mvp-showcase.test.yaml
promtool test rules tests/promtool/caddy-mvp-marshal.test.yaml
```

Keep `rules/marshal-caddy.rules.yaml` in sync with the CR `.spec` in
`rules/marshal-caddy.yaml` (the projection is the CR's `.spec` verbatim).

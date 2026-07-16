# e-caddy-mvp — VM-variant alerting slice (parked E5 `caddy_*` marshal)

**Status:** parked + promtool suite landed; live scrape target still pending (Variant A VM /
showcase Caddy origin — see `openspec/changes/e-caddy-mvp/tasks.md`).

These manifests are **parked with the `e-caddy-mvp` epic**, migrated **out of active
platform monitoring** by audit-remediation WS1 (operator-confirmed **Option A — park**,
`agent-context/decisions.md` D-026; audit ARCH-2/ARCH-3).

**Why they moved:** the platform edge is **Cilium Gateway API (Envoy)**, not Caddy
([ADR-0104](../../../docs/adr/0104-caddy-gateway-api.md), D-019). The Cilium/Envoy edge
never emits a `job="caddy"` scrape target, so the `CaddyTargetDown` alert can never fire
against the platform as originally wired. Its real target is the **Caddy VM tenant**, whose
external `/metrics` endpoint in-cluster Prometheus scrapes — the brief spine
**serve → scrape → fire** (REQ-CADDY-S01-03). They are **not dead code**: they light up
when the VM tenant lands.

## Files

| File | Purpose |
| --- | --- |
| `rules/marshal-caddy.yaml` | `PrometheusRule` CR — `CaddyTargetDown` (GitOps-applied when the VM tenant lands) |
| `rules/marshal-caddy.rules.yaml` | Plain `groups:` projection of the CR `.spec`, committed so the epic promtool suite loads it directly (no `/tmp` extract) |
| `prometheus/caddy-podmonitor.yaml` | `PodMonitor` scraping the Caddy metrics endpoint (pins `job="caddy"`; `namespaceSelector` → `caddy-mvp` for Variant B — REQ-CADDY-S02-03) |

## Tests

The promtool fire+silent suite lives at
[`tests/promtool/caddy-mvp-marshal.test.yaml`](../../../tests/promtool/caddy-mvp-marshal.test.yaml)
(REQ-CADDY-S01-03). It is **standalone** — no extract step — so the spec's Verify runs as-is:

```bash
promtool test rules tests/promtool/caddy-mvp-marshal.test.yaml
```

Keep `rules/marshal-caddy.rules.yaml` in sync with the CR `.spec` in
`rules/marshal-caddy.yaml` (the projection is the CR's `.spec` verbatim).

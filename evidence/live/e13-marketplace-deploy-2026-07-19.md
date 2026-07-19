# Evidence — E13-S05 one-shot Marketplace deploy (Caddy) LIVE — 2026-07-19

**Story:** E13-S05 · **Change:** `openspec/changes/e13-gridscale-marketplace/` · **Decision:** D-032 (private tenant)

Proves the "one-click gridscale Marketplace deploy" claim **end-to-end on real gridscale**: a
`gridscale_server` deployed **from the imported `kaddy-caddy` Marketplace template** serves the sample
page + `/metrics`, then torn down (cost discipline).

## The deploy mechanism (resolved)

The gridscale **Terraform provider exposes no "deploy-from-marketplace" resource** — only register
(`gridscale_marketplace_application`) + import (`_import`). The imported app does **not** appear in
`/objects/templates`. The deploy path is: **a `gridscale_storage` created with
`template.template_uuid = <the imported (consumer) marketplace application object_uuid>`** instantiates
the boot disk from the Marketplace `.gz`. Verified live: a storage created from
`752ef944-c30c-416f-a741-ab554dbc85ef` (the `kaddy-caddy` consumer import) provisions the golden image.

## What was provisioned (all ephemeral, torn down after)

| Resource | UUID | Notes |
| --- | --- | --- |
| IPv4 | `4efc566f-…` | public `185.241.34.52` (de/fra2) |
| Storage (from template) | `afa25590-…`'s disk | `template_uuid = 752ef944…` (kaddy-caddy import), 10 GiB storage_high |
| Server | `afa25590-1f1a-4605-b910-c5ec72d9a3ed` | 1 core / 1 GiB, **single public NIC** on the gridscale Public Network (`c1295d84-…`) — the proven serving topology (a private NIC alone does not route the public IP) |

## Serve proof (HTTP, real public IP `185.241.34.52`)

Booted from the Marketplace template, Caddy served within ~20 s of power-on:

```console
--- GET / ---   → HTTP 200
<!DOCTYPE html>
<title>kaddy — gridscale Marketplace template</title>
...

--- GET /healthz ---   → 200
ok

--- GET :2019/metrics ---   → 200 (job="caddy" scrape target)
# HELP caddy_config_last_reload_successful Whether the last configuration reload attempt was successful.
caddy_config_last_reload_successful 1
# HELP caddy_http_request_duration_seconds Histogram of round-trip request durations.
caddy_http_request_duration_seconds_bucket{code="200",handler="subroute",host="_other",method="GET",server="srv1",le="0.005"} 3
```

The `/metrics` endpoint exposes real `caddy_*` series — the exact contract the parked marshal `caddy_*`
alerts (`deploy/caddy-mvp/monitoring/rules/marshal-caddy.yaml`) and the promtool proof
(`tests/promtool/gridscale-marketplace.test.yaml`) target under `job="caddy"`. The alert-fire itself is
proven by `promtool test rules` (offline, in `task test:smoke:e13`) — a live Prometheus scrape of this
one-shot VM was out of scope for the ephemeral deploy (the standing-cluster scrape pattern is exercised
by E14-S03's ScrapeConfig).

## Teardown (ruthless — cost discipline)

```console
server del HTTP 204
storage del HTTP 204
ipv4 del HTTP 204
teardown done
```

Orphan check after teardown: `servers/storages/ips named kaddy-e13-s05: 0 / 0 / 0` — tenant clean.
Cost ≈ €0.05 (VM up ~2 min). The `kaddy-caddy` Marketplace application (register + import + the `.gz`)
**persists** by design — it is the durable deliverable; only the deploy-proof VM is ephemeral.

## Boundary

Live-proven: build (E13-S01, 2026-07-17) · register + import (2026-07-18) · **deploy → serve →
`/metrics` (E13-S05, this run)**. The Nix "fourth way" runs the same deploy path in E14-S03.

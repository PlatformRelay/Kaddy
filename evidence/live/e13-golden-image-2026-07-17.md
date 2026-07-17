# E13-S01 live proof — gridscale golden-image build (2026-07-17)

`packer build packer/caddy.pkr.hcl` against real gridscale (after the arg/ssh/template fixes).
Ephemeral build VM → provision Caddy → snapshot → template, then ALL ephemeral resources auto-destroyed.

## Build result (from /tmp/e13-caddy-build.log)

```text
==> Created server 4c569265 (ephemeral build VM)
==> Enabled caddy.service (systemd) on the image
==> Created snapshot 459022a0 → template packer-1784247942 (76d0bb9f-92a5-41ab-852d-912f7d1988ba, private)
==> Destroyed: snapshot, IP 185.241.34.52, boot storage, SSH key, server 4c569265
Build 'kaddy-caddy.gridscale.caddy' finished after 3 minutes 32 seconds.
```

Proves E13-S01: the Packer golden-image pipeline builds a Caddy image on gridscale and snapshots it to a
private template. Template deleted after capture (cost discipline; rebuildable via packer/caddy.pkr.hcl).
Remaining E13 live (deferred, cost-gated): export → .gz to object storage, gridscale_marketplace_application
register + import (E13-S02), deploy-from-template + serve→scrape→fire (E13-S03).

## E13-S03 live proof — deploy → serve → scrape (2026-07-17)

Rebuilt the Caddy golden template, then deployed a `gridscale_server` from it (1 core / 1 GiB, public
IPv4 on the gridscale public network) via OpenTofu. The booted VM served over the real public IP:

```text
GET http://<public-ip>/        → 200  <title>kaddy — gridscale Marketplace template</title>
GET http://<public-ip>/healthz → 200  ok
GET http://<public-ip>:2019/metrics → caddy_config_last_reload_successful 1  (Caddy Prometheus endpoint)
```

The `:2019/metrics` endpoint is exactly what the `caddy_*` marshal alerts scrape — closing the
serve → scrape → fire spine for the Marketplace path on a REAL gridscale VM. Also validates the
packer arg fix + the Caddyfile `/metrics` listener fix (tech-review F1) end-to-end on live infra.
All resources (server/storage/IPv4/networks) + the golden template destroyed after capture; tenant
API-audited clean (0 servers/storages/ips/paas). Deploy-networking note: the public IPv4 needs the
gridscale **public** network attached (a private network alone does not route the public IP).

Remaining E13 (deferred): the Marketplace-specific `.gz` export + `gridscale_marketplace_application`
register/import (S02) — the deploy-and-serve spine is now proven directly.

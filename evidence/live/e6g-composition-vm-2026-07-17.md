# E6g-S03/S04 — LIVE PROOF: Website Composition → real gridscale VM (2026-07-17)

**Epic:** E6g · **REQ:** REQ-E6g-S03-01 · **Substrate:** real gridscale tenant (de/fra2), kind-kaddy-dev + Crossplane 2.3.3 + provider-gridscale v0.1.1

## What was proven (end-to-end, ephemeral, tenant-clean-after)
A single `Website` XR (`variant=gridscale`) routed through `composition-website-gridscale.yaml`
provisioned a **real gridscale nginx VM** and served `/legacy` over the real public IP:

```
GET http://185.241.34.52/         → 200  "Hello World from gridscale" (kaddy /legacy page)
GET http://185.241.34.52/healthz  → 200  ok
GET http://185.241.34.52/metrics  → 200  nginx stub_status (Active connections / accepts handled requests)
```

## Composed graph (all SYNCED+READY, real gridscale UUIDs)
- Provider `provider-gridscale` **Healthy** (installed from a local registry by IP:5000 — Crossplane
  rejects non-dotted registry names; node containerd `config_path=/etc/containerd/certs.d` + insecure
  `certs.d/<ip>:5000/hosts.toml` + restart; recipe reproduced from the prior session).
- `Website/legacy` (namespaced v2 XR) → composition `website-gridscale.platform.kaddy.io` →
  IPv4 (public, 185.241.34.52) · Storage (Ubuntu 22.04 boot disk) · Server (1 core/1 GiB, server_uuid
  b7f222d1-1d80-414b-b6c5-a85fdf0642ca) on the gridscale **Public Network**.

## Real defects found + fixed live (the composition wiring that "remained")
1. **v1→v2 composition selection.** The example XR used top-level `spec.compositionSelector`; Crossplane
   2.x nests it under **`spec.crossplane.compositionSelector`** (strict-decode rejected the old shape).
2. **Public IP did not route** with only the composed private L2 NIC — the public IPv4 requires the
   gridscale **Public Network** attached (a private NIC alone → connection refused). Fix: attach the
   Public Network to the Server.
3. **nginx failed to start** (duplicate `listen 80 default_server`: Ubuntu's stock
   `sites-enabled/default` + our `conf.d`). This — NOT the cloud-init datasource — was the real cause of
   the first serve failure. cloud-init user_data on gridscale stock Ubuntu **works**. Fix: drop the stock
   default site before `systemctl restart nginx`.

## Topology finding (committed design)
Two attempts isolated the variables. **Dual-NIC** (public + composed private NIC on the Server) was
live-shown to **break serving** (public IPv4 stops routing — dual default-route ambiguity), even with
the nginx fix. **Single public NIC** on the Server serves cleanly. Committed design therefore attaches
ONLY the gridscale Public Network to the Server; the composed private `Network` MR is still provisioned
as part of the graph (satisfies the minimal-graph gate + is available for a private/east-west tier) but
is deliberately NOT the Server's default route. Verified `/legacy` + `/healthz` + `/metrics` = 200 on the
single-NIC topology, then destroyed.

## Cost discipline
Ephemeral create→verify→destroy. All MRs deleted (XR cascade); gridscale tenant API-audited **clean**
(0 servers / 0 ips / 0 storages / 0 kaddy networks). Debug sshkey object deleted.

# E13-S06 v2 — Marketplace icons as data URIs (2026-07-20)

## Problem

After the ≤8-bit RGB fix, tenant Marketplace icons for `caddy-ubuntu` /
`caddy-nix` were **still blank**. Operator then deleted the templates.

## Root cause (corrected)

| Finding | Evidence |
| --- | --- |
| Official apps that render | `metadata.icon` is a **CDN path**, e.g. `/img/assets/logos_marketplace/wordpress.png` |
| Our previous apps | `metadata.icon` was **raw base64** (no scheme). API accepts it and stores it unchanged — it does **not** rewrite uploads to CDN paths |
| Panel behaviour | Icon string is used as `<img src>`. Paths/URLs and `data:image/…` work; raw base64 is treated as a relative URL → blank mark |
| Previous mistake | Assumed blank icons were caused by 16-bit RGBA bit depth. Bit depth was a red herring once raw base64 was the stored form |

Docs only say “base64 encoded image” (provider:
`references/gridscale-terraform-provider/website/docs/r/marketplaceApp.html.md`;
tutorial requires an uploaded logo but gives no MIME/dim/size). Working custom
contract: **`data:image/png;base64,<bytes>`** from an ≤8-bit PNG.

## Fix

- Module `meta_icon = "data:image/png;base64,${filebase64(...)}"`
- Offline gate asserts data-URI wiring + ≤8-bit + ≤200 KiB vendor PNGs
- Live `tofu apply` re-registered deleted apps (caddy + nix)

## Live register (2026-07-20)

| App | Type | UUID | Icon |
| --- | --- | --- | --- |
| caddy-ubuntu | provider | `44c66788-7783-4e83-9494-ea77cf820283` | `data:image/png;base64,…` 512×512 8-bit RGB |
| caddy-ubuntu | consumer | `eb918c54-1ef8-4c7d-81cc-e2ba37ff0fdf` | same (import copy) |
| caddy-nix | provider | `5e4868a3-78a3-43d3-afdc-88008ef92601` | `data:image/png;base64,…` 512×512 8-bit RGB |
| caddy-nix | consumer | `8516ff3e-0401-4579-a81f-1f4d3fb4fdac` | same (import copy) |

`nginx` not registered live — no `nginx-golden.gz` in object storage (unchanged).

Provider+consumer pairs are intentional (D-047) — not a double-publish bug.

## Verify

1. Panel → Marketplace → hard-refresh → `caddy-ubuntu` / `caddy-nix` should show vendor logos.
2. `bash tests/smoke/e13-marketplace-icons.sh`
3. API: `metadata.icon` must start with `data:image/png;base64,`

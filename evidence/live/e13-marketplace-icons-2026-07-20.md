# E13-S06 — Marketplace vendor icons render (2026-07-20)

## Problem

Tenant Marketplace showed **blank icons** for `caddy-ubuntu` and `caddy-nix`,
and each name appeared **twice**.

## Root cause

| Finding | Evidence |
| --- | --- |
| Icons *were* registered | API `metadata.icon` was non-empty base64 for all four owned apps |
| Panel blank mark | Live icons decoded to **16-bit/color RGBA** PNG (512×512). Working module fallback `modules/marketplace-template/assets/icon.png` is **8-bit RGB**. Official marketplace apps use CDN paths (`/img/assets/logos_marketplace/…`), not inline base64 |
| “2×” listing | **Not a double-publish bug.** Each engine is one `provider` app + one `consumer` import sharing `unique_hash` (`caddy-ubuntu` `bd2e-4983-d79c`, `caddy-nix` `2803-bf7e-aeee`). That is the register+import pattern (`gridscale_marketplace_application` + `_import`). Do **not** delete either side |

## Fix (in-repo)

- Converted `stacks/gridscale-marketplace/{caddy,nix}/*-512.png` → 8-bit RGB
- Added `nginx-512.png` + `icon_path` on the nginx stack
- Offline gate `tests/smoke/e13-marketplace-icons.sh` (wired into `e13-offline.sh`)

## Live action (2026-07-20)

`PATCH /objects/marketplace/applications/{uuid}` with `{"metadata":{"icon":"<base64>"}}`
for both provider and consumer of each engine — all returned **HTTP 204**.

| App | Type | UUID | Post-PATCH `file` |
| --- | --- | --- | --- |
| caddy-ubuntu | provider | `1ed1e018-e244-44a3-9b3b-7403b93b6366` | 512×512, **8-bit/color RGB** |
| caddy-ubuntu | consumer | `d318d7f7-4441-4325-9990-1fdd1a9a775a` | 512×512, **8-bit/color RGB** |
| caddy-nix | provider | `7ca6706f-339c-42fb-a499-e57c50eeb5bd` | 512×512, **8-bit/color RGB** |
| caddy-nix | consumer | `2bfb228a-59d9-4ba7-b466-d7f5252c3a4b` | 512×512, **8-bit/color RGB** |

`b64` lengths dropped from ~355k/273k (16-bit) to ~80k/62k (8-bit).

**Decide-and-log:** used API PATCH instead of `tofu apply` this session because
marketplace stack `tofu init` needs object-storage `-backend-config` (gos3) that
was not wired in the worktree. Remote TF state may still list the old icon
hash until the next proper `e13:up` with backend-config — that apply will
re-push the same 8-bit bytes from the committed PNGs (convergent, not a revert).

**Not done live:** nginx Marketplace app (never registered in this tenant).

## Verify

1. Panel → Marketplace → `caddy-ubuntu` / `caddy-nix` show vendor logos (hard-refresh if cached).
2. `bash tests/smoke/e13-marketplace-icons.sh` / `task test:smoke:e13` offline.
3. Optional: re-decode `metadata.icon` and `file` → must stay 8-bit.

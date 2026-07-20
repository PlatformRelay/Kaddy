# Tasks — E13 gridscale Marketplace template (Caddy + nginx)

> **Phase 2 · gated on E1g** (gridscale provider + credentials + object-storage bucket). Terraform-native
> (operator-approved for this path). TDD: add the failing test before implement. Offline `tofu
> validate`/`test` keeps the stack CI-checkable before the live, credit-consuming path runs.

**Gate:** `task test:spec` + `tofu test` (`modules/marketplace-template`) + (live, gated) `tests/smoke/e13-*.sh`

> **Status (offline-authored):** the module, both stacks, the Packer builds, the promtool
> proof, and all smoke scripts are authored + green via `task test:smoke:e13`. The LIVE
> build → export → register → import → deploy steps are serialized + cost-gated (SKIP-by-design
> smoke scripts) — checked below as `[~]` = offline-authored, live-proof pending.

## E13-S01 — Golden image build + export to object storage

- [x] Add failing `tests/smoke/e13-s01-export.sh` (asserts a `.gz` snapshot exists at the `s3://` bucket path; SKIPs without creds)
- [x] Packer build (`packer/caddy.pkr.hcl`, `nginx.pkr.hcl`): Caddy/nginx + sample page + `/metrics` endpoint — **LIVE-PROVEN 2026-07-17** (caddy): `packer build` on gridscale built the Caddy golden image, enabled `caddy.service`, snapshotted → private template, then auto-destroyed all ephemeral resources (VM/IP/storage/snapshot/key); template deleted after capture; tenant clean. Evidence: `evidence/live/e13-golden-image-2026-07-17.md`.
- [x] Snapshot storage → export as `.gz` to the E1g object-storage bucket — **LIVE-DONE 2026-07-18**: `s3://kaddy-tfstate/marketplace/caddy-golden.gz` (the `kaddy-caddy` Marketplace app registers from it; E13-S05 deployed a VM from the resulting import)
- [x] Fallback (time-box): manual `gridscale_server` → configure → snapshot (documented in the runbook)

## E13-S02 — Register + import the Marketplace application (Terraform)

- [x] Add failing `modules/marketplace-template/tests/inputs.tftest.hcl` (L0: validates required args —
      `object_storage_path` is `.gz`/`s3://`, `category` in the allowed enum, icon present)
- [x] `modules/marketplace-template`: `gridscale_marketplace_application` (metadata + `meta_icon`) per engine
- [x] `gridscale_marketplace_application_import` (`unique_hash`) → import into our tenant (private, no
      global publish request)
- [x] Terramate stacks `stacks/gridscale-marketplace/{caddy,nginx}`
- [x] Add failing `tests/smoke/e13-s02-register.sh` (asserts the app is registered + imported, `id` set; SKIPs without state)

## E13-S03 — Deploy proof (serve → scrape → fire)

- [x] Add failing `tests/smoke/e13-s03-deploy.sh` + `tests/promtool/gridscale-marketplace.test.yaml`
- [x] `gridscale_server` from the imported template → serves the sample page (HTTP 200) + exposes `/metrics` — **LIVE-PROVEN 2026-07-19** (E13-S05): storage from `template_uuid=752ef944…` (kaddy-caddy import) → VM on the Public Network → `GET /`=200 (sample page), `/healthz`=ok, `:2019/metrics`=`caddy_config_last_reload_successful 1` + `caddy_http_request_duration_seconds{code="200"}`; torn down clean. Evidence: `evidence/live/e13-marketplace-deploy-2026-07-19.md`
- [x] Prometheus scrapes the VM `/metrics`; the parked `caddy_*` marshal alerts fire against a
      gridscale `job="caddy"` target (promtool fire + silent preserved) — closes D-026 on the Marketplace path (offline promtool green; live scrape pending)

## E13-S04 — Docs + traceability

- [x] `docs/runbooks/gridscale-marketplace-deploy.md` (build → export → publish → import → deploy)
- [x] Update `docs/requirements/exercise-traceability.md` optional-task row (third way = Marketplace template)
- [x] Note the enum/`.gz`/icon constraints + private-tenant-publish decision (D-032)

## Exit

- [x] One-click Marketplace deploy demonstrable end-to-end: register → import → deploy from template →
      served page + `caddy_*` metrics against the gridscale VM — **LIVE-PROVEN 2026-07-19** (E13-S05);
      `caddy_*` alert-fire proven by promtool (offline) against the `job="caddy"` contract the live VM serves.
  - [x] **E13-S05** (2026-07-18, operator request): live one-shot deploy validation — ran the full
        deploy→serve chain ONCE on real gridscale (the register+import were already live), captured
        evidence (`evidence/live/e13-marketplace-deploy-2026-07-19.md`), tore down clean. Deploy
        mechanism resolved: storage `template_uuid = <consumer import object_uuid>` (no TF-provider deploy resource).
- [x] Gate: `task test:spec` (structure) + `tofu test` + offline gate (`task test:smoke:e13`); live smoke gated on E1g credits.

## E13-S06 — Vendor logos render in the panel (data-URI meta_icon)

- [x] Offline gate `tests/smoke/e13-marketplace-icons.sh` (wired into `e13-offline.sh`): module
      `meta_icon` is `data:image/png;base64,…`; every engine stack has `icon_path` → present ≤8-bit
      PNG ≤200 KiB, distinct from module default kaddy logo
- [x] Convert `caddy-512.png` / `nixos-512.png` from 16-bit RGBA → 8-bit RGB; add `nginx-512.png` +
      `icon_path` on the nginx stack
- [x] Root cause v2: raw base64 blanks in panel (`<img src>`); prefix data URI. Live re-register
      `caddy-ubuntu` / `caddy-nix` after operator delete; evidence
      `evidence/live/e13-marketplace-icons-v2-2026-07-20.md` (nginx skipped — no `nginx-golden.gz`)

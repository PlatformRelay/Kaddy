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
- [~] Snapshot storage → export as `.gz` to the E1g object-storage bucket (runbook step; live-proof pending — the packer build produces a template; the marketplace `.gz` export is the remaining sub-step)
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
- [~] `gridscale_server` from the imported template → serves the sample page (HTTP 200) + exposes `/metrics` (runbook step; live-proof pending)
- [x] Prometheus scrapes the VM `/metrics`; the parked `caddy_*` marshal alerts fire against a
      gridscale `job="caddy"` target (promtool fire + silent preserved) — closes D-026 on the Marketplace path (offline promtool green; live scrape pending)

## E13-S04 — Docs + traceability

- [x] `docs/runbooks/gridscale-marketplace-deploy.md` (build → export → publish → import → deploy)
- [x] Update `docs/requirements/exercise-traceability.md` optional-task row (third way = Marketplace template)
- [x] Note the enum/`.gz`/icon constraints + private-tenant-publish decision (D-032)

## Exit

- [~] One-click Marketplace deploy demonstrable end-to-end: register → import → deploy from template →
      served page + `caddy_*` alert fires against the gridscale VM (offline-authored; live-proof pending, `task e13:up` + runbook).
  - [ ] **E13-S05** (2026-07-18, operator request): live one-shot deploy validation — run the full
        register→import→deploy→serve chain ONCE on real gridscale, capture evidence, then tear down.
        Full story body in `agent-context/BACKLOG.md` § "Phase-2 gridscale Marketplace live validation".
- [x] Gate: `task test:spec` (structure) + `tofu test` + offline gate (`task test:smoke:e13`); live smoke gated on E1g credits.

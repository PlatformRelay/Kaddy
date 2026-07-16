# Tasks — E13 gridscale Marketplace template (Caddy + nginx)

> **Phase 2 · gated on E1g** (gridscale provider + credentials + object-storage bucket). Terraform-native
> (operator-approved for this path). TDD: add the failing test before implement. Offline `tofu
> validate`/`test` keeps the stack CI-checkable before the live, credit-consuming path runs.

**Gate:** `task test:spec` + `tofu test` (`modules/marketplace-template`) + (live, gated) `tests/smoke/e13-*.sh`

## E13-S01 — Golden image build + export to object storage

- [ ] Add failing `tests/smoke/e13-s01-export.sh` (asserts a `.gz` snapshot exists at the `s3://` bucket path)
- [ ] Packer build (`packer/caddy.pkr.hcl`, `nginx.pkr.hcl`): Caddy/nginx + sample page + `/metrics` endpoint
- [ ] Snapshot storage → export as `.gz` to the E1g object-storage bucket
- [ ] Fallback (time-box): manual `gridscale_server` → configure → snapshot

## E13-S02 — Register + import the Marketplace application (Terraform)

- [ ] Add failing `modules/marketplace-template/tests/*.tftest.hcl` (L0: validates required args —
      `object_storage_path` is `.gz`/`s3://`, `category` in the allowed enum, icon present)
- [ ] `modules/marketplace-template`: `gridscale_marketplace_application` (metadata + `meta_icon`) per engine
- [ ] `gridscale_marketplace_application_import` (`unique_hash`) → import into our tenant (private, no
      global publish request)
- [ ] Terramate stacks `stacks/gridscale-marketplace/{caddy,nginx}`
- [ ] Add failing `tests/smoke/e13-s02-register.sh` (asserts the app is registered + imported, `id` set)

## E13-S03 — Deploy proof (serve → scrape → fire)

- [ ] Add failing `tests/smoke/e13-s03-deploy.sh` + `tests/promtool/gridscale-marketplace.test.yaml`
- [ ] `gridscale_server` from the imported template → serves the sample page (HTTP 200) + exposes `/metrics`
- [ ] Prometheus scrapes the VM `/metrics`; the parked `caddy_*` marshal alerts fire against the real
      gridscale target (promtool fire + silent preserved) — closes D-026 on the Marketplace path

## E13-S04 — Docs + traceability

- [ ] `docs/runbooks/gridscale-marketplace-deploy.md` (build → export → publish → import → deploy)
- [ ] Update `docs/requirements/exercise-traceability.md` optional-task row (third way = Marketplace template)
- [ ] Note the enum/`.gz`/icon constraints + private-tenant-publish decision (D-032)

## Exit

- [ ] One-click Marketplace deploy demonstrable end-to-end: register → import → deploy from template →
      served page + `caddy_*` alert fires against the gridscale VM.
- [ ] Gate: `task test:spec` (structure) + `tofu test` + live smoke (gated on E1g credits).

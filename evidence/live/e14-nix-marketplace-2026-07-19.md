# Evidence — E14-S02 Nix image `.gz` exported + `kaddy-nix` Marketplace app registered (LIVE) — 2026-07-19

**Story:** E14-S02 · **Change:** `openspec/changes/e14-nix-golden-images/` · **Decision:** D-032 (private tenant)

Exports the Nix-built golden image (E14-S01) as a `.gz` to object storage and registers it as a private
`gridscale_marketplace_application` — the same live-proven flow as the Caddy app (2026-07-18), reusing
`modules/marketplace-template`.

## 1. Image `.gz` exported to object storage

The E14-S01 image built **natively on CI** (the `e14-nix-image` workflow, `ubuntu-latest` + `/dev/kvm`,
run `29675711347` — SUCCESS) and uploaded its `nix-golden.gz` artifact. That artifact (the canonical
build) was pushed to the E1g object-storage bucket via the gridscale S3 endpoint:

```console
$ mc cp nix-golden.gz gos3/kaddy-tfstate/marketplace/nix-golden.gz
507.03 MiB … 5.69 MiB/s
$ mc ls gos3/kaddy-tfstate/marketplace/
  2.7GiB caddy-golden.gz
  507MiB nix-golden.gz          <-- new
```

`s3://kaddy-tfstate/marketplace/nix-golden.gz` now exists alongside the Caddy `.gz`.

## 2. `kaddy-nix` Marketplace application registered + imported

A new Terramate stack `stacks/gridscale-marketplace/nix` (reusing `modules/marketplace-template`,
`service = "nix"` → name `kaddy-nix`, `meta_os = "NixOS 24.11"`) registered + privately imported the app:

```console
$ tofu apply   # (S3 backend, gridscale creds)
module.marketplace.gridscale_marketplace_application.app: Creation complete [id=191fed42-…]
module.marketplace.gridscale_marketplace_application_import.imported: Creation complete [id=3aa9777e-…]
Outputs:
  application_id = "191fed42-db4b-4b3c-b356-f9df1ca5f4a7"
  import_id      = "3aa9777e-410f-4df1-8e4d-d88cee8d040a"
  unique_hash    = "f18c-29eb-62b8"
```

Tenant confirmation (`/objects/marketplace/applications`):

```console
provider  uuid=191fed42-…  hash=f18c-29eb-62b8  status=active  path=s3://kaddy-tfstate/marketplace/nix-golden.gz
consumer  uuid=3aa9777e-…  hash=f18c-29eb-62b8  status=active  path=hidden
```

Both `is_publish_*` stay false (private tenant, D-032). The consumer import `object_uuid`
`3aa9777e-410f-4df1-8e4d-d88cee8d040a` is the `template_uuid` E14-S03 deploys a `gridscale_server` from.

## Offline gate

`stacks/gridscale-marketplace/nix` is wired into `task test:smoke:e13` (`STACKS=(caddy nginx nix)`):
`tofu validate` + `tofu test` (mock provider — asserts the `.gz`/`s3://` path + rejects a non-`.gz`) pass
offline. `task verify` stays green.

## Persistence / boundary

The `kaddy-nix` app + its `.gz` **persist** by design (the durable deliverable, like `kaddy-caddy`).
E14-S02 does not deploy a VM — that is E14-S03 (deploy from `3aa9777e-…` → serve → Prometheus scrape →
teardown), which is also the first real **boot-contract** proof for the from-scratch Nix image (ADR-0303).

> ⚠️ **Status caveat:** as of E14-S03 (2026-07-19), a VM deployed from this `kaddy-nix` template
> **does not yet boot-to-serve** on gridscale (see `e14-nix-deploy-2026-07-19.md`). The app is a valid
> *registration* proof (private-tenant, so a non-booting template is low-harm), but it is a **published
> dud until E14-S03's boot contract is fixed** — hold or re-point its `.gz` once the Nix image boots.

# Tasks — E14 Nix golden images

> **Phase 3 · gated on supply-chain LGTM (D-037)** + E1g (object storage) + the standing GSK cluster
> (E14-S03). `nix` does not install on the macOS workstation (ADR-0303), so every nix step runs in a
> `nixos/nix` container (colima docker). TDD: `nix flake check` is the failing-first gate.

**Gate:** `task test:smoke:e14` (flake.lock tracked + `nixpkgs-fmt` + `nix flake check`; skip-not-fail),
and — live, gated — `tests/smoke/e14-s0{2,3}-*.sh`.

> **Status (offline-authored 2026-07-19):** the flake, the `caddy-golden` NixOS module, the offline gate,
> and the Taskfile targets are authored + green. `nix flake check` passes and the **full NixOS system
> closure builds green** in the container. The final **raw-disk assembly needs the `kvm` system feature**
> (a QEMU VM), which colima's Virtualization.framework containers do not expose — so the image build is
> proven on a **KVM-capable x86_64 host** (`task e14:build` locally where `/dev/kvm` exists, or the
> `e14-nix-image.yml` CI workflow on a GitHub-hosted runner). Live register/deploy (S02/S03) are
> serialized + cost-gated (SKIP-by-design), checked below as `[~]` = offline-authored, live-proof pending.

## E14-S01 — Nix golden image build

- [x] `nix/flake.nix` (nixpkgs 24.11 + nixos-generators, `format = "raw"`, x86_64) + `nix/flake.lock` committed
- [x] `nix/modules/caddy-golden.nix`: DHCP + serial console (boot contract) + declarative Caddy serving
      the sample page + `/healthz` on `:80` and `/metrics` on `:2019` (mirrors `packer/files/Caddyfile`)
- [x] `nix/srv/index.html` (sample page, mirrors `packer/files/index.html`)
- [x] `nix flake check` green (image derivation + standalone `nixosConfigurations` both evaluate)
- [x] Full NixOS system closure builds green in the `nixos/nix` container (kernel + initrd + system)
- [~] Raw-disk image assembly green — needs `kvm` (QEMU VM); proven on a KVM-capable x86_64 host /
      CI runner (`.github/workflows/e14-nix-image.yml`), not colima's KVM-less emulated container
- [x] `tests/smoke/e14-offline.sh` (skip-not-fail) + wired into `task test:smoke:e14` + `test:meta:ci`
- [x] `task e14:lock` / `e14:fmt` / `e14:build` Taskfile targets
- [x] Runbook `docs/runbooks/nix-golden-image.md` (container build + KVM note + export/register handoff)

## E14-S02 — Export the `.gz` + register/import as a Marketplace app

- [ ] Add failing `tests/smoke/e14-s02-register.sh` (asserts `kaddy-nix` app registered + imported, `id` set; SKIPs without state)
- [ ] Export the built image `.gz` to object storage (`s3://…/nix-golden.gz`) — direct S3 upload or `gridscale_snapshot.object_storage_export`
- [ ] `stacks/gridscale-marketplace/nix` (reuse `modules/marketplace-template`; `name = "kaddy-nix"`, `meta_os = "NixOS 24.11"`, `meta_components = ["Caddy","/metrics","Nix flake-locked closure"]`)
- [~] LIVE register + import (private, `is_publish_*` false) — evidence in `evidence/live/`

## E14-S03 — Deploy a VM from the Nix template + track in Prometheus

- [ ] Add failing `tests/smoke/e14-s03-deploy.sh` (asserts serve HTTP 200 + `/metrics` + Prometheus `up=1`; SKIPs without creds/cluster)
- [ ] Deploy a `gridscale_server` (public network) from the imported Nix template
- [ ] Prometheus-operator `ScrapeConfig` targeting `<ip>:2019/metrics` (GSK `monitoring` ns) → `up=1`
- [~] LIVE serve + scrape + marshal `caddy_*` evaluate; teardown; tenant clean — evidence in `evidence/live/`

## Exit

- [~] E14-S01 offline gate green in CI; image build proven on a KVM host / CI runner
- [ ] At least one live register→deploy→serve→scrape cycle captured to `evidence/live/`, then torn down
- [ ] `task verify` EXIT 0 (offline gate stays skip-not-fail)

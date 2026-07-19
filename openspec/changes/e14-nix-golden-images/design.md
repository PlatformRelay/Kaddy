# Design — E14 Nix golden images

The architectural decision (Nix as a *fourth* image-build way, weighted trade-off vs Packer, the
boot-contract hinge) lives in **[ADR-0303](../../../docs/adr/0303-nix-golden-images.md)**. This document
covers only the *implementation* choices made in E14-S01.

## Build environment: a `nixos/nix` container, not the host

`nix` does not install on the macOS workstation (`--no-daemon` unsupported; ADR-0303). So every nix
operation runs inside the official `nixos/nix` container on colima docker. Consequences:

- **flake.lock** is generated via `task e14:lock` (the container), committed, and enforced by the gate.
- **x86_64 target on an aarch64 host.** gridscale is KVM/x86_64, so the image must be x86_64. The build
  runs in a `--platform linux/amd64` container (rosetta/qemu). This is cheap: every heavy package comes
  **prebuilt from `cache.nixos.org`**; only the thin final steps run emulated.

## The one real constraint: disk assembly needs `kvm`

`nixos-generators`' `raw`/`qcow` formats assemble the disk with `make-disk-image`, which runs a **QEMU
VM** (`vmTools.runInLinuxVM`) to partition, install the store, and write the bootloader. That derivation
declares `requiredSystemFeatures = ["kvm"]`. colima's Virtualization.framework does **not** expose
`/dev/kvm` to containers, so a plain `nix build` fails with *"missing system features: {kvm}"* — after
building the entire system closure green.

Two resolutions, both wired:

1. **KVM-capable host / CI (canonical).** A native x86_64 Linux host with `/dev/kvm` (or a GitHub-hosted
   runner — Azure VMs expose nested KVM) builds the image directly. `.github/workflows/e14-nix-image.yml`
   is the reproducible build-of-record (`workflow_dispatch`, uploads the `.gz` artifact).
2. **TCG fallback (local, slow).** Claiming the `kvm` feature in `nix.conf` lets the QEMU VM fall back to
   TCG software emulation (`-machine accel=kvm:tcg`). Under rosetta this is *double* emulation — correct
   but slow — so it is a developer convenience, not the CI path. `task e14:build` uses the plain path;
   the TCG override is documented in the runbook.

**Why `raw` and not systemd-repart (which needs no VM):** `image.repart` builds without a VM/kvm, but
wiring a **BIOS-GRUB** bootable repart image is fiddly, and gridscale's proven boot path is BIOS/MBR
(the E13 Packer template). `raw` (MBR + GRUB) matches what gridscale imports today; switching to
`repart` + systemd-boot (UEFI) is a future option if the KVM constraint ever bites in CI.

## Serving contract parity with E13

`nix/modules/caddy-golden.nix` reproduces `packer/files/Caddyfile` intent exactly — `admin off`, a
dedicated `:2019` metrics listener with `per_host`, and the `:80` site serving `/srv` + `/healthz` — so
the Nix VM is a drop-in `job="caddy"` target and the parked marshal `caddy_*` rules
(`deploy/caddy-mvp/monitoring/rules/marshal-caddy.yaml`) and the `promtool` proof
(`tests/promtool/gridscale-marketplace.test.yaml`) apply with **zero** changes.

## Boot contract (from ADR-0303, as implemented)

- `networking.useDHCP = true` — gridscale runs DHCP; no cloud-init needed for connectivity.
- `console=ttyS0,115200n8` + GRUB serial — gridscale console + early-boot diagnostics.
- Caddy is a **baked systemd unit** (declarative) — serves on first boot with no injection.
- `services.cloud-init` is deliberately **off** in the demo image: `user_data` is management-only (SSH
  keys), and leaving it off keeps the closure minimal and removes the one empirical unknown (NoCloud vs
  config-drive datasource) from the serve path. The management path is documented in the runbook.
- `users.mutableUsers = false` + `allowNoPasswordLogin` — no baked secret; a shell is added via
  `user_data` at deploy time when needed.

## Reproducibility note

The **system closure** is bit-reproducible (flake-locked inputs). The **disk image** wrapper is *not*
bit-identical run-to-run (timestamps, filesystem layout) — ADR-0303 flags this. The provenance value is
the locked closure + full-closure SBOM, not a reproducible `.gz` checksum; a `nix path-info --closure-size`
/ SBOM step is a follow-up, not part of the S01 serve spike.

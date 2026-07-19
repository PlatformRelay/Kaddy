# Runbook — Nix golden image (E14, the reproducible "fourth way")

Deliver the exercise a **fourth way**: a **Nix-built**, flake-locked gridscale golden image — the same
serve→scrape→fire contract as the E13 Packer image, but built declaratively from a locked closure
(minimal CVE surface, full-closure SBOM). See [ADR-0303](../adr/0303-nix-golden-images.md).

Pipeline: **build (Nix) → export `.gz` → register → import → deploy → scrape → fire.**

## TL;DR

```bash
# OFFLINE (safe, no creds, no cost) — wired into task verify / CI meta gate.
task test:smoke:e14        # flake.lock tracked + nixpkgs-fmt + nix flake check (in a nixos/nix container)

# BUILD the image (no gridscale cost; needs docker; SLOW under emulation):
task e14:build             # -> nix/build/nixos.img  (x86_64 raw, BIOS-bootable)

# LIVE (costs money) — E14-S02/S03:
#   1. export nix/build/nixos.img as .gz to object storage
#   2. register + import the kaddy-nix Marketplace app
#   3. deploy a gridscale_server, verify, scrape, capture evidence
#   4. tofu destroy — RUTHLESS teardown after EVERY live test
```

## Why everything runs in a container

`nix` does not install on the macOS workstation (`--no-daemon` unsupported), so every nix step runs in
the official `nixos/nix` container on colima docker. Override the image with `KADDY_NIX_IMAGE`.

- **Regenerate the lock:** `task e14:lock` → commit `nix/flake.lock`.
- **Format:** `task e14:fmt` (nixpkgs-fmt).
- **Evaluate (fast):** `task test:smoke:e14` runs `nix flake check --no-build`.

## Building the raw image — the `kvm` constraint

`nixos-generators`' `raw` format assembles the disk in a **QEMU VM** that requires the `kvm` system
feature. colima's Virtualization.framework does **not** expose `/dev/kvm` to containers, so a plain
build fails at the final assembly step (*"missing system features: {kvm}"*) — **after** the whole system
closure builds green. Pick one:

### Option A — KVM-capable x86_64 host / CI (canonical)

On a native x86_64 Linux host with `/dev/kvm` (or a GitHub-hosted runner — they expose nested KVM):

```bash
task e14:build             # plain nix build; the QEMU VM uses hardware KVM
```

CI build-of-record: **`.github/workflows/e14-nix-image.yml`** (`workflow_dispatch`) builds on
`ubuntu-latest` and uploads the `.gz` artifact. This is the reproducible build environment.

### Option B — TCG fallback (local, on a KVM-less host; SLOW)

Claim the `kvm` feature so the QEMU VM falls back to TCG software emulation (`-machine accel=kvm:tcg`).
Under rosetta this is *double* emulation — correct but slow (tens of minutes). Developer convenience only:

```bash
docker run --rm --platform linux/amd64 \
  -e NIX_CONFIG=$'experimental-features = nix-command flakes\nfilter-syscalls = false\nsystem-features = kvm nixos-test benchmark big-parallel uid-range' \
  -v "$PWD/nix":/work -w /work nixos/nix:latest \
  bash -c 'nix build .#gridscale-image --print-build-logs && cp "$(readlink -f result)"/* /work/build/'
```

## Boot contract (ADR-0303)

The image carries its own boot (no gridscale base-template inheritance):

- **DHCP** (`networking.useDHCP`) — gridscale runs DHCP; the VM gets `auto_assigned_ip`. No cloud-init
  needed for connectivity.
- **Serial console** (`console=ttyS0` + GRUB serial) — gridscale's web console + boot diagnostics.
- **Caddy baked as a systemd unit** — serves the page + `/metrics` on first boot, zero injection.
- **Management access** is via gridscale `user_data` (cloud-init) at deploy time — NOT a baked secret.
  To get a shell, pass `user_data_base64` on the `gridscale_server` with an SSH key:

  ```yaml
  #cloud-config
  users:
    - name: ops
      ssh_authorized_keys: [ "ssh-ed25519 AAAA... you@host" ]
      sudo: ALL=(ALL) NOPASSWD:ALL
  ```

  (The demo — serve + scrape — needs none of this; it is management-only.)

## Serving contract (identical to E13)

Sample page + `/healthz` on `:80`; Prometheus `/metrics` on `:2019` (`per_host`) under `job="caddy"`.
The Nix VM is a drop-in target for the parked marshal `caddy_*` rules and the shared promtool proof
(`tests/promtool/gridscale-marketplace.test.yaml`).

## Export → register → deploy (E14-S02/S03)

1. **Export** `nix/build/nixos.img` → gzip → object storage (`s3://<bucket>/nix-golden.gz`), via the
   object-storage stack's S3 endpoint or `gridscale_snapshot.object_storage_export`.
2. **Register + import:** apply `stacks/gridscale-marketplace/nix` (reuses `modules/marketplace-template`,
   `name = "kaddy-nix"`). Returns `application_id` + `unique_hash`.
3. **Deploy:** create a `gridscale_server` (public network — mind the public-IP routing gotcha) from the
   imported template; verify HTTP 200 + `/metrics`.
4. **Scrape:** apply a prometheus-operator `ScrapeConfig` targeting `<ip>:2019/metrics` in the GSK
   `monitoring` ns; confirm `up=1`.
5. **Teardown:** `tofu destroy` the VM/IP/storage; remove the ScrapeConfig; confirm the tenant panel is
   clean. Capture evidence to `evidence/live/e14-nix-*.md` first.

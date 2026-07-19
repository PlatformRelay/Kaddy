# Evidence — E14-S01 Nix golden image builds green (containerized) — 2026-07-19

**Story:** E14-S01 (Nix golden image build) · **ADR:** 0303 · **Change:** `openspec/changes/e14-nix-golden-images/`

## What was proven

The Nix golden image (`nix/flake.nix` → `nixos-generators` `raw`, x86_64) evaluates and builds to a
**bootable raw disk image**, entirely inside a `nixos/nix` container on colima docker — no host `nix`
(ADR-0303: `nix` won't install on the macOS workstation).

### 1. Flake evaluates (offline gate)

```console
$ bash tests/smoke/e14-offline.sh
OK: flake.lock present + tracked
OK: nixpkgs-fmt clean
OK: nix flake check (image + nixosConfigurations evaluate)
PASS: e14 offline gate green
```

`nix flake check --no-build` resolves `packages.x86_64-linux.gridscale-image` (the nixos-generators
disk-image derivation) and the standalone `nixosConfigurations.caddy-golden` — a broken module
(assertion, bad option) fails the gate, not a 20-minute build.

### 2. Full system closure + raw image build green

`nix build .#gridscale-image` in a `--platform linux/amd64 nixos/nix` container (rosetta emulation;
x86_64 packages prebuilt from `cache.nixos.org`) built the **entire NixOS system closure** (kernel
6.6.94 + initrd + system) and then assembled the raw disk:

```console
image: /nix/store/l5d9hqggkw53ywywl279zvq8jjc85mh7-nixos-disk-image/nixos.img (2.0G)
=== nix build rc=0 ===
```

Output image (`nix/build/nixos.img`, gitignored):

- **type:** `DOS/MBR boot sector` (BIOS-bootable, as designed — matches gridscale's proven E13 boot path)
- **apparent size:** 3,969,908,736 bytes (3.7 GiB) · **actual (sparse):** 2.0G
- **sha256:** `b2d3b47d3dc59e0f98cc76903604edfdf893a23d36496be21b5d26751fcdc603`
  (the raw-disk wrapper is NOT bit-reproducible run-to-run — ADR-0303; the reproducibility guarantee is
  the flake-locked closure, not the `.gz` checksum)
- **nixpkgs pin:** `50ab793786d9de88ee30ec4e4c24fb4236fc2674` (nixos-24.11, locked in `nix/flake.lock`)

### 3. The `kvm` constraint (documented, resolved two ways)

A plain `nix build` in colima's container fails at the final assembly step with *"missing system
features: {kvm}"* — the `nixos-generators` `raw` format assembles the disk in a QEMU VM that requires
`/dev/kvm`, which Apple Virtualization.framework does not expose to containers. Confirmed:

```console
$ docker run --rm nixos/nix:latest sh -c '[ -e /dev/kvm ] && echo present || echo "no /dev/kvm"'
no /dev/kvm
```

The image above was built via the **TCG fallback** (claim the `kvm` feature in `nix.conf` → QEMU falls
back to `-machine accel=kvm:tcg` software emulation — slow under rosetta, but correct). The canonical
build environment is a **KVM-capable x86_64 host / CI runner**: `.github/workflows/e14-nix-image.yaml`
(`workflow_dispatch`) builds on `ubuntu-latest` (native `/dev/kvm`) and uploads the `.gz`. See
`docs/runbooks/nix-golden-image.md`.

### 4. Re-confirmed after the review refactor

Independent review (REQUEST CHANGES → fixed) moved the Caddyfile out of the module into
`nix/caddy/Caddyfile` (a byte-for-byte copy of `packer/files/Caddyfile`, served via a `/srv`
`systemd.tmpfiles` symlink) so the offline gate can `caddy validate` it. The image derivation hash
changed accordingly (`y9yfbjj…` → `080q5vv…-nixos-disk-image.drv`; the built system carries
`L+ /srv … kaddy-srv`), and a fresh `nix build` still completes green — so the build claim holds for
the committed code, not just the pre-review draft.

## Boot + serving contract (ADR-0303)

The `caddy-golden` module carries the boot contract a from-scratch image needs: `networking.useDHCP`
(gridscale runs DHCP), serial console (`console=ttyS0` + GRUB serial), and Caddy started declaratively at
boot (baked systemd unit) — so a `gridscale_server` from this image serves with **zero** first-boot
injection. Serving is byte-identical intent to `packer/files/Caddyfile`: sample page + `/healthz` on
`:80`, Prometheus `/metrics` on `:2019` (`per_host`) under `job="caddy"` — a drop-in target for the
parked marshal `caddy_*` rules.

## Not yet proven here (E14-S02 / E14-S03 — live, cost-gated)

- Export `.gz` → object storage → register `kaddy-nix` Marketplace app (E14-S02).
- Deploy a `gridscale_server` from the template, serve HTTP 200, Prometheus `up=1` (E14-S03).

The **live boot proof** (does the image actually boot + serve on gridscale?) is E14-S03 — this evidence
proves the image *builds*, not that it *boots on gridscale*. That is the honest boundary of E14-S01.

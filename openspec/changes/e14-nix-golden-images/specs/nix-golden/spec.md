# Spec — E14 Nix golden images

Epic: E14 · ADR: [0303](../../../docs/adr/0303-nix-golden-images.md) (Nix golden images) ·
**Decision:** D-037 (admitted, gated on supply-chain LGTM) · D-032 (private-tenant publish) ·
**Refs:** exercise brief (install a web server, serve, scrape, alert) — delivered as a reproducible,
closure-SBOM'd Nix image; the **fourth way** alongside E-Caddy-MVP Variant B (K8s), Variant A / E6g
(Crossplane VM), and E13 Packer-Marketplace  
**Phase:** 3 · **Gated on:** E1g (object-storage bucket + creds), the standing GSK cluster (E14-S03)

> **Levels — no k8s cluster for the image itself.** The image builds + boots on the **gridscale cloud
> API + VMs**, so **L2 Chainsaw does not apply** to E14-S01/S02. Levels: **L0** = `nix flake check` +
> the full-closure build in a `nixos/nix` container (offline, deterministic); **L1** = the same
> `promtool` `caddy_*` proof E13 uses (the Nix VM is a `job="caddy"` target); live smoke = the
> deploy→serve→scrape cycle, gated on E1g credits + the GSK cluster.

---

## REQ-E14-S01-01: Flake evaluates + the golden image builds (offline, containerized)

**Priority:** must · **Story:** E14-S01 · **Level:** L0 · **TDD:** `nix flake check` first  
**Given** `nix/flake.nix` + `nix/modules/caddy-golden.nix` + a committed `nix/flake.lock`  
**When** `nix flake check` runs in a `nixos/nix` container  
**Then** the image derivation (`packages.x86_64-linux.gridscale-image`) and the standalone
`nixosConfigurations.caddy-golden` both evaluate, and `nix build .#gridscale-image` produces an x86_64
raw disk image  
**Test:** `tests/smoke/e14-offline.sh` (flake.lock tracked + `nixpkgs-fmt --check` + `nix flake check
--no-build`; SKIP-not-fail without docker/nix); the build itself via `task e14:build`

**Verify:** `task test:smoke:e14` (offline gate) + `task e14:build` (the emulated/CI image build)

---

## REQ-E14-S01-02: The image carries the gridscale boot contract

**Priority:** must · **Story:** E14-S01 · **Level:** L0/live · **Refs:** ADR-0303 boot contract  
**Given** a from-scratch NixOS image (no gridscale base-template inheritance)  
**When** the `caddy-golden` module is built  
**Then** it enables DHCP (`networking.useDHCP`), a serial console (`console=ttyS0`, GRUB serial), and
starts Caddy declaratively at boot — so a `gridscale_server` booted from it gets a DHCP IP and serves
the page + `/metrics` with **zero** first-boot injection (cloud-init `user_data` stays management-only)  
**Test:** module assertions in `nix flake check`; live boot proof in E14-S03

**Verify:** `nix flake check` (module builds) + E14-S03 live serve

---

## REQ-E14-S01-03: Serves the same job="caddy" contract as the Packer image

**Priority:** must · **Story:** E14-S01 · **Level:** L1  
**Given** the built image's Caddy config  
**When** it runs  
**Then** it serves the sample page + `/healthz` on `:80` and exposes Prometheus `/metrics` on `:2019`
with `per_host` labels (byte-identical intent to `packer/files/Caddyfile`), so the parked marshal
`caddy_*` rules apply unchanged  
**Test:** `tests/promtool/gridscale-marketplace.test.yaml` (shared with E13 — `job="caddy"`)

**Verify:** `promtool test rules tests/promtool/gridscale-marketplace.test.yaml`

---

## REQ-E14-S02-01: Nix image exported + registered as a private Marketplace app

**Priority:** must · **Story:** E14-S02 · **Level:** live · **Refs:** `modules/marketplace-template`, D-032  
**Given** the built Nix image `.gz` uploaded to object storage (`s3://…/nix-golden.gz`)  
**When** the `kaddy-nix` marketplace stack is applied  
**Then** a `gridscale_marketplace_application` (provider) + `_import` (consumer) appear in the tenant
(private, `is_publish_*` false), returning a non-empty `id` + `unique_hash`  
**Test:** `tests/smoke/e14-s02-register.sh` (SKIPs without state/creds)

**Verify:** `tests/smoke/e14-s02-register.sh`

---

## REQ-E14-S03-01: Nix VM deploys, serves, and is scraped by GSK Prometheus

**Priority:** must · **Story:** E14-S03 · **Level:** live  
**Given** the imported Nix template + the standing GSK kube-prometheus-stack  
**When** a `gridscale_server` (public network) is deployed from it and a prometheus-operator
`ScrapeConfig` targets `<ip>:2019/metrics`  
**Then** the VM serves HTTP 200 + `/metrics`, the Prometheus target shows `up=1`, and the marshal
`caddy_*` alerts evaluate against it; the VM/IP/storage are torn down after capture (cost discipline)  
**Test:** `tests/smoke/e14-s03-deploy.sh` (SKIPs without creds/cluster); evidence in `evidence/live/`

**Verify:** `tests/smoke/e14-s03-deploy.sh` + `promtool query` / Prometheus target screenshot

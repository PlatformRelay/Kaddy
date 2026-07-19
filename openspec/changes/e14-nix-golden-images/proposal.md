# Proposal — E14 Nix golden images (the reproducible "fourth way")

## Problem

E13 ships a gridscale-native golden image via **Packer** (`packer/caddy.pkr.hcl`): an imperative
`apt-get` + curl-pinned exporter on gridscale's public Ubuntu base template. It works and is
offline-gated — but it is **not reproducible** (apt/curl drift between builds), carries a **full Ubuntu
CVE surface**, and ships **no closure SBOM**. For a **gridscale** Platform Engineer role, the sharpest
supply-chain flex for the *VM* deliverable is exactly what Packer-on-Ubuntu cannot give: a
**flake-locked, bit-addressable, minimal-CVE, full-closure-SBOM'd** golden image.

## Scope (additive · ADR-0303 · D-037)

A **Nix-built** gridscale golden image that serves the *same* contract as the Packer one (sample page +
`/healthz` on `:80`, Prometheus `/metrics` on `:2019` under `job="caddy"`), so it feeds the same
**marshal `caddy_*`** alerts — but built declaratively from a locked flake:

1. **E14-S01 — build.** A `flake.nix` + `nixos-generators` config (`nix/`) produces an **x86_64**
   gridscale-bootable raw image. Because `nix` does not install on the macOS workstation (ADR-0303),
   the build runs inside a `nixos/nix` **container** (colima docker); x86_64 packages come prebuilt from
   `cache.nixos.org`, only the final image assembly is emulated. The **boot contract** (ADR-0303's
   hinge — a from-scratch image loses gridscale's base-template inheritance) is carried by the image
   itself: DHCP for connectivity, a serial console, and Caddy started **declaratively at boot** (systemd
   unit baked into the closure) so it serves + scrapes with **zero** first-boot injection.
2. **E14-S02 — register.** Export the image `.gz` to object storage and register it as a private
   `gridscale_marketplace_application` (+ `_import`) named `kaddy-nix`, reusing the live-proven
   `modules/marketplace-template` (the same module + flow as the 2026-07-18 Caddy registration).
3. **E14-S03 — deploy + monitor.** Deploy a `gridscale_server` from the Nix template, prove it serves
   (HTTP 200 + `/metrics`), and track it with a prometheus-operator `ScrapeConfig` against the standing
   GSK cluster's kube-prometheus-stack (`up=1`, marshal `caddy_*` evaluate).

## Non-goals

- **Nix as the cluster OS.** D-003 / D-015 stand — Talos/GSK remains the substrate. E14 is a *VM image
  build engine*, nothing more.
- **Global / public Marketplace publication.** Private-tenant only (D-032), same as E13.
- **Replacing E13 Packer.** E13 stays. Nix is a *fourth* way alongside E-Caddy-MVP Variant B (K8s),
  Variant A / E6g (Crossplane VM), and E13 Packer-Marketplace.
- **A standing Nix VM.** E14-S03 is validate-then-destroy (cost discipline), like E13-S05.

## Why now

Phase-2 live proofs are closed (D-037 gate satisfied); the cloud-init boot channel is de-risked (E6g
proved gridscale `user_data` works). The remaining risk is the from-scratch boot contract — scoped as
the E14-S01 spike so it is a crisp pass/fail, not assumed away.

## Governance

Supply-chain **maintainer-LGTM** is required before E14 code merges (D-037); this change is admitted as a
Phase-3 plan. The offline gate (`task test:smoke:e14`) is skip-not-fail (no `nix` on the CI host → the
`nixos/nix` container provides it), so it never blocks CI on a missing tool.

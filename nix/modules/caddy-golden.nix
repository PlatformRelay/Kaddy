# E14-S01 — NixOS module for the gridscale golden image (Caddy engine).
#
# This is the declarative, closure-baked counterpart to the imperative Packer
# builder (`packer/caddy.pkr.hcl` + `packer/scripts/provision-caddy.sh`). It
# serves the same contract (sample page + /healthz on :80, Prometheus /metrics
# on :2019 under job="caddy") so the parked marshal caddy_* alerts
# (deploy/caddy-mvp/monitoring/rules/marshal-caddy.yaml) fire against it too.
#
# ADR-0303 boot contract (the E14-S01 hinge — a from-scratch image loses the
# gridscale public-base-template inheritance, so it must carry boot itself):
#   * Network = DHCP. gridscale runs DHCP on the attached network and exports
#     `auto_assigned_ip`; `networking.useDHCP = true` is all connectivity needs.
#   * Serial console. gridscale's web console + boot diagnostics attach to
#     ttyS0 — without it a failed boot is invisible.
#   * First-boot injection (cloud-init user_data) is MANAGEMENT-ONLY and is
#     deliberately NOT enabled here: the demo contract (serve + scrape) is met
#     with zero injection by starting Caddy declaratively at boot. Keeping it
#     out shrinks the closure and removes the one empirical unknown (datasource
#     NoCloud vs config-drive) from the critical serve path. The management path
#     is documented in docs/runbooks/nix-golden-image.md.
{ config, pkgs, lib, modulesPath, ... }:

let
  # The sample landing page — mirrors packer/files/index.html (kept in-tree so
  # the flake is self-contained; both trace to deploy/showcase as the source).
  srvRoot = pkgs.runCommand "kaddy-srv" { } ''
    mkdir -p "$out"
    cp ${../srv/index.html} "$out/index.html"
  '';

  # The golden Caddyfile is a byte-for-byte copy of packer/files/Caddyfile (admin
  # off + a dedicated :2019 metrics listener with per_host labels + the :80 site
  # serving /srv + /healthz), so the Nix VM is a drop-in job="caddy" scrape
  # target. Keeping it a real file (not an inlined heredoc with an interpolated
  # store path) lets `caddy validate` check it offline in tests/smoke/e14-offline.sh
  # — a directive typo fails the gate — instead of handing Caddy an opaque,
  # uncheckable string. It serves /srv, which the tmpfiles rule below symlinks to
  # the immutable store copy of the page (so the config stays root * /srv,
  # identical to Packer's).
  caddyfile = ../caddy/Caddyfile;
in
{
  # gridscale is a virtio-based KVM cloud (virtio-blk disk = /dev/vda, virtio-net
  # NIC). The nixos-generators `raw` format does NOT pull in the qemu-guest
  # profile, so a from-scratch image's initrd lacks the virtio drivers — the VM
  # powers on but the kernel never sees the boot disk (no root mount) or the NIC
  # (no DHCP), so it never boots (the SEPARATE serve failure once booted was the caddy 2.8.4 skew, fixed by the package pin below) (observed live 2026-07-19: E14-S03 v1 provisioned
  # + powered on but did not serve). The qemu-guest profile adds virtio_pci /
  # virtio_blk / virtio_scsi / virtio_net to the initrd — the ADR-0303 boot
  # contract's missing piece for a scratch image on gridscale.
  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];

  # --- Boot contract -------------------------------------------------------
  networking.useDHCP = lib.mkDefault true;
  networking.firewall.allowedTCPPorts = [ 80 2019 ];

  # Serial console so gridscale's console + early-boot logs are reachable.
  boot.kernelParams = [ "console=ttyS0,115200n8" "console=tty0" ];
  boot.loader.grub.extraConfig = ''
    serial --unit=0 --speed=115200
    terminal_input serial console
    terminal_output serial console
  '';

  # --- The serving contract (declarative; no first-boot provisioning) ------
  # /srv is an immutable symlink to the store copy of the sample page, so the
  # Caddyfile can stay `root * /srv` (byte-for-byte with Packer's) while the
  # content lives in the read-only closure.
  systemd.tmpfiles.rules = [ "L+ /srv - - - - ${srvRoot}" ];

  services.caddy = {
    enable = true;
    # Use the exact golden Caddyfile rather than the generated virtualHosts
    # config so `admin off` + the standalone :2019 metrics site are preserved.
    configFile = caddyfile;
    # NOTE: the Caddyfile's global `metrics { per_host }` block requires caddy
    # >= 2.9. The package is pinned accordingly in flake.nix (nixpkgs-caddy) —
    # nixos-24.11's caddy 2.8.4 rejects that block at boot and the image serves
    # nothing (E14-S03). Keep services.caddy.package >= 2.9 if this module moves.
  };

  # --- Minimal, image-friendly base ---------------------------------------
  # A golden image is single-purpose; trim what a server image never needs.
  documentation.enable = lib.mkDefault false;
  documentation.nixos.enable = lib.mkDefault false;
  services.getty.autologinUser = lib.mkDefault null;
  # No mutable users / passwords baked into a public image; management access
  # is injected at deploy time via gridscale user_data (cloud-init), not a baked
  # secret. allowNoPasswordLogin acknowledges the intentional no-login image:
  # the demo contract is serve+scrape (no interactive login needed); operators
  # add an SSH key via user_data when they want a shell (see the runbook).
  users.mutableUsers = false;
  users.allowNoPasswordLogin = true;

  system.stateVersion = "24.11";
}

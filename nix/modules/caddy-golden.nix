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
{ config, pkgs, lib, ... }:

let
  # The sample landing page — mirrors packer/files/index.html (kept in-tree so
  # the flake is self-contained; both trace to deploy/showcase as the source).
  srvRoot = pkgs.runCommand "kaddy-srv" { } ''
    mkdir -p "$out"
    cp ${../srv/index.html} "$out/index.html"
  '';

  # Byte-for-byte the golden Caddyfile from packer/files/Caddyfile: admin off
  # (no admin API on a public VM) + a dedicated :2019 metrics listener with
  # per_host labels, and the :80 site serving the page + /healthz.
  caddyfile = pkgs.writeText "Caddyfile" ''
    {
    	admin off
    	metrics {
    		per_host
    	}
    }

    :2019 {
    	metrics /metrics
    }

    :80 {
    	root * ${srvRoot}

    	handle /healthz {
    		respond "ok" 200
    	}

    	handle {
    		encode gzip
    		file_server
    	}
    }
  '';
in
{
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
  services.caddy = {
    enable = true;
    # Use the exact golden Caddyfile rather than the generated virtualHosts
    # config so `admin off` + the standalone :2019 metrics site are preserved.
    configFile = caddyfile;
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

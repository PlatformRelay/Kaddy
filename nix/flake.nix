{
  description = "kaddy E14 — Nix-built, flake-locked gridscale golden image (Caddy + /metrics)";

  # ADR-0303: a fourth "way" alongside E13 Packer — a reproducible, full-closure
  # system image. Built x86_64 (gridscale is KVM/x86_64) inside a nixos/nix
  # container on any host (rosetta/qemu emulation); see docs/runbooks/nix-golden-image.md.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    # E14-S03 caddy pin. The golden Caddyfile uses the global `metrics { per_host }`
    # block, which caddy only recognises from 2.9.0 onward. nixos-24.11 pins caddy
    # 2.8.4, which FAILS to adapt that Caddyfile at boot ("unrecognized global
    # option: metrics") — `caddy run` exits before binding any socket, so the image
    # boots to login but serves nothing on :80 OR :2019 (the E14-S03 symptom). The
    # Packer image installs caddy from apt "stable" (>= 2.9), which is why the
    # byte-for-byte Caddyfile serves there. Pin ONLY caddy to 25.05 (2.10.x) to
    # restore parity while keeping the proven-to-boot 24.11 base for everything else.
    nixpkgs-caddy.url = "github:NixOS/nixpkgs/nixos-25.05";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-caddy, nixos-generators, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Override services.caddy.package with caddy >= 2.9 from the nixpkgs-caddy
      # input (see the input comment for why). Applied to BOTH the generated image
      # and the standalone nixosConfigurations so `nix flake check` evaluates — and
      # tests/smoke/e14-offline.sh validates — the SAME caddy the image ships.
      caddyPin = { ... }: {
        services.caddy.package = nixpkgs-caddy.legacyPackages.${system}.caddy;
      };
    in
    {
      # `nix build .#gridscale-image` -> result/nixos.img (raw, BIOS-bootable),
      # which the E14-S02 export step gzips to .gz for the Marketplace app.
      packages.${system} = {
        gridscale-image = nixos-generators.nixosGenerate {
          inherit system;
          format = "raw"; # MBR + GRUB; the format gridscale imports (matches the Packer .gz).
          modules = [ ./modules/caddy-golden.nix caddyPin ];
        };
        default = self.packages.${system}.gridscale-image;
      };

      # Evaluable system for `nix flake check` (offline gate) — same module the
      # image is generated from, so a broken config fails the gate, not the build.
      # The disk/boot stubs below are what the `raw` format module injects into
      # the real image; supplied here (only for the standalone config, not the
      # shared module) so the module validates without the generator wrapper.
      nixosConfigurations.caddy-golden = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./modules/caddy-golden.nix
          caddyPin
          ({ ... }: {
            fileSystems."/" = {
              device = "/dev/disk/by-label/nixos";
              fsType = "ext4";
            };
            boot.loader.grub.devices = [ "/dev/vda" ];
          })
        ];
      };

      checks.${system}.caddy-golden-config =
        self.nixosConfigurations.caddy-golden.config.system.build.toplevel;

      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}

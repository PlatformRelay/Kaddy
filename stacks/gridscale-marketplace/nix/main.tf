# Nix Marketplace template — the reproducible "fourth way" (E14, alongside the
# K8s Variant B, the Crossplane-VM Variant A, and the E13 Packer-Caddy template).
# Registers + privately imports a Marketplace 2.0 application built from the
# Nix-exported golden image (nix/flake.nix -> nixos-generators raw -> .gz).
#
# provider, required_providers, backend, and the labels module are injected by
# Terramate codegen (config.tm.hcl). The marketplace resources carry no `labels`
# argument (provider limitation), so the stack uses module.labels only for name.

module "marketplace" {
  source = "../../../modules/marketplace-template"

  # Named by engine-OS ("caddy" = the web server, "nix" = the build/OS) so the
  # tenant Marketplace reads caddy-ubuntu / caddy-nix, not the kaddy-<label> form.
  name                = "caddy-nix"
  object_storage_path = var.object_storage_path
  category            = "Adminpanel"                   # enum has no "Web Server"; real class in meta_* (D-032 / spec constraint)
  icon_path           = "${path.module}/nixos-512.png" # NixOS snowflake (Simple Icons, CC0)

  meta_os         = "NixOS 24.11"
  meta_components = ["Caddy", "Prometheus /metrics endpoint", "Nix flake-locked closure", "sample landing page"]
  meta_overview   = "Monitored Caddy web server built as a reproducible, flake-locked NixOS image (E14, ADR-0303) — minimal-CVE, full-closure SBOM. Serves a sample page and exposes /metrics for the marshal caddy_* alerts — serve, scrape, alert. (Web server; categorised Adminpanel as the gridscale enum has no Web-Server class.)"
}

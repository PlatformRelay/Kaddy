# nginx Marketplace template — mirror of the Caddy stack. nginx exposes
# /metrics via the nginx-prometheus-exporter; the same caddy_* / job="caddy"
# marshal alert contract applies (the scrape job is labelled job="caddy" so the
# parked alerts fire against either engine's /metrics — see the promtool suite).
#
# provider, required_providers, backend, and the labels module are injected by
# Terramate codegen (config.tm.hcl).

module "marketplace" {
  source = "../../../modules/marketplace-template"

  name                = module.labels.name
  object_storage_path = var.object_storage_path
  category            = "Adminpanel"                   # enum has no "Web Server"; real class in meta_* (D-032 / spec constraint)
  icon_path           = "${path.module}/nginx-512.png" # nginx logo (Simple Icons, CC0); ≤8-bit for panel render (E13-S06)

  meta_os         = "Ubuntu 24.04"
  meta_components = ["nginx", "nginx-prometheus-exporter", "sample landing page"]
  meta_overview   = "Monitored nginx web server. Serves a sample page and exposes /metrics (via nginx-prometheus-exporter) for the marshal caddy_* alerts — serve, scrape, alert. (Web server; categorised Adminpanel as the gridscale enum has no Web-Server class.)"
}

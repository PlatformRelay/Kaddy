# Caddy Marketplace template — the gridscale-native "third way" (alongside the
# K8s Variant B and the Crossplane-VM Variant A). Registers + privately imports
# a Marketplace 2.0 application built from the exported Caddy golden image.
#
# provider, required_providers, backend, and the labels module are injected by
# Terramate codegen (config.tm.hcl). The marketplace resources carry no `labels`
# argument (provider limitation), so the stack uses module.labels only for name.

module "marketplace" {
  source = "../../../modules/marketplace-template"

  name                = module.labels.name
  object_storage_path = var.object_storage_path
  category            = "Adminpanel" # enum has no "Web Server"; real class in meta_* (D-032 / spec constraint)

  meta_os         = "Ubuntu 24.04"
  meta_components = ["Caddy", "Prometheus /metrics endpoint", "sample landing page"]
  meta_overview   = "Monitored, TLS-ready Caddy web server. Serves a sample page and exposes /metrics for the marshal caddy_* alerts — serve, scrape, alert. (Web server; categorised Adminpanel as the gridscale enum has no Web-Server class.)"
}

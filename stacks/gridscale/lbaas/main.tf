# LBaaS entry point — the single public front door in front of the GSK Gateway.
# Listens on the public IPv4/IPv6 UUIDs from the network stack and forwards
# 80/443 to the Gateway's backend host (a node/service IP surfaced after the
# cluster + Gateway are up). The provider requires BOTH listen IP UUIDs.
#
# provider, required_providers, backend, and the labels module are injected by
# Terramate codegen (config.tm.hcl).

resource "gridscale_loadbalancer" "edge" {
  name                   = module.labels.name
  algorithm              = "leastconn"
  redirect_http_to_https = var.redirect_http_to_https
  listen_ipv4_uuid       = var.listen_ipv4_uuid
  listen_ipv6_uuid       = var.listen_ipv6_uuid

  backend_server {
    weight = 100
    host   = var.gateway_backend_host
  }

  # The LB does NOT redirect (redirect_http_to_https defaults false): it runs
  # both 80 and 443 as tcp passthrough so TLS terminates at the Gateway (E4/E5),
  # which owns the HTTP→HTTPS redirect + cert-manager certs. Flip the var only to
  # make the LB itself redirect (unused in this passthrough topology).
  forwarding_rule {
    listen_port = 443
    target_port = 443
    mode        = "tcp"
  }
  forwarding_rule {
    listen_port = 80
    target_port = 80
    mode        = "tcp"
  }

  labels = module.labels.gridscale_labels
}

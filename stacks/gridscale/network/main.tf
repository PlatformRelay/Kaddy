# Network stack — the private L2 network the GSK nodes attach to, a restrictive
# firewall template, and the public IPv4/IPv6 the LBaaS entry point listens on.
#
# provider, required_providers, backend, and the labels module are injected by
# Terramate codegen (config.tm.hcl). gridscale label lists come from
# module.labels.gridscale_labels so every resource carries the ADR-0301 core.

# Private network for GSK node-to-node + PaaS attachment. Kept private (no
# public_net) so only the LBaaS/IPs below are the deliberate ingress surface.
resource "gridscale_network" "platform" {
  name       = "${module.labels.name}-net"
  l2security = true
  labels     = module.labels.gridscale_labels
}

# Restrictive firewall template: allow only 80/443 inbound; everything else is
# dropped by gridscale's implicit default-deny on inbound. HTTP is kept so the
# LBaaS can redirect_http_to_https; real TLS terminates upstream (E4/E5).
resource "gridscale_firewall" "edge" {
  name = "${module.labels.name}-fw"

  rules_v4_in {
    order    = 0
    protocol = "tcp"
    action   = "accept"
    dst_port = "443"
    comment  = "https ingress"
  }
  rules_v4_in {
    order    = 1
    protocol = "tcp"
    action   = "accept"
    dst_port = "80"
    comment  = "http (redirected to https at the LB)"
  }

  rules_v6_in {
    order    = 0
    protocol = "tcp"
    action   = "accept"
    dst_port = "443"
    comment  = "https ingress"
  }
  rules_v6_in {
    order    = 1
    protocol = "tcp"
    action   = "accept"
    dst_port = "80"
    comment  = "http (redirected to https at the LB)"
  }

  labels = module.labels.gridscale_labels
}

# Public IPs the LBaaS listens on. LBaaS requires BOTH an IPv4 and IPv6 UUID.
resource "gridscale_ipv4" "edge" {
  name   = "${module.labels.name}-ipv4"
  labels = module.labels.gridscale_labels
}

resource "gridscale_ipv6" "edge" {
  name   = "${module.labels.name}-ipv6"
  labels = module.labels.gridscale_labels
}

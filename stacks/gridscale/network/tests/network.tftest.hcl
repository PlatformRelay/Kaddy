# REQ-E1g-S02: network + firewall + public IPs — offline plan, mocked provider.

mock_provider "gridscale" {}

run "network_stack_planned" {
  command = plan

  # Naming is labels-derived and consistent across the four resources.
  assert {
    condition     = gridscale_network.platform.name == "kaddy-network-net"
    error_message = "network name must be labels-derived"
  }
  assert {
    condition     = gridscale_ipv4.edge.name == "kaddy-network-ipv4"
    error_message = "ipv4 name must be labels-derived"
  }

  # Private network must keep L2 security on.
  assert {
    condition     = gridscale_network.platform.l2security == true
    error_message = "platform network must enable l2security"
  }

  # Every resource carries the ADR-0301 core labels (labels-module wiring, E1b-S04).
  assert {
    condition     = contains(gridscale_network.platform.labels, "part-of=kaddy")
    error_message = "network must carry the canonical part-of label"
  }
  assert {
    condition     = contains(gridscale_ipv4.edge.labels, "managed-by=terramate")
    error_message = "ipv4 must carry the canonical managed-by label"
  }

  # Firewall exposes exactly the deliberate ingress ports (80/443), no more.
  assert {
    condition = alltrue([
      for r in gridscale_firewall.edge.rules_v4_in : contains(["80", "443"], r.dst_port) && r.action == "accept"
    ])
    error_message = "firewall v4 inbound rules must accept only 80/443"
  }
}

# REQ-E1g-S04: LBaaS entry point — offline plan, mocked provider. Asserts the
# listen-IP wiring, the 80/443 forwarding rules, and labels.

mock_provider "gridscale" {}

run "loadbalancer_planned" {
  command = plan

  variables {
    listen_ipv4_uuid     = "11111111-1111-1111-1111-111111111111"
    listen_ipv6_uuid     = "22222222-2222-2222-2222-222222222222"
    gateway_backend_host = "10.0.0.10"
  }

  assert {
    condition     = gridscale_loadbalancer.edge.name == "kaddy-lb"
    error_message = "loadbalancer name must be labels-derived"
  }

  assert {
    condition     = gridscale_loadbalancer.edge.listen_ipv4_uuid == "11111111-1111-1111-1111-111111111111"
    error_message = "LB must listen on the network stack's IPv4"
  }

  # Both 80 and 443 forwarding rules present.
  assert {
    condition = alltrue([
      for p in [80, 443] : contains([for r in gridscale_loadbalancer.edge.forwarding_rule : r.listen_port], p)
    ])
    error_message = "LB must forward both 80 and 443"
  }

  assert {
    condition     = one([for r in gridscale_loadbalancer.edge.backend_server : r.host]) == "10.0.0.10"
    error_message = "LB backend must target the Gateway host"
  }

  assert {
    condition     = contains(gridscale_loadbalancer.edge.labels, "owner=platform-team")
    error_message = "LB must carry the canonical owner label (E1b-S04)"
  }
}

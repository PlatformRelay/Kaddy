output "network_uuid" {
  description = "UUID of the private platform network; consumed by the k8s stack for node attachment."
  value       = gridscale_network.platform.id
}

output "firewall_uuid" {
  description = "UUID of the edge firewall template."
  value       = gridscale_firewall.edge.id
}

output "ipv4_uuid" {
  description = "UUID of the public IPv4 the LBaaS listens on; consumed by the lbaas stack."
  value       = gridscale_ipv4.edge.id
}

output "ipv6_uuid" {
  description = "UUID of the public IPv6 the LBaaS listens on; consumed by the lbaas stack."
  value       = gridscale_ipv6.edge.id
}

output "ipv4_address" {
  description = "The allocated public IPv4 address (for the public LBaaS domain / Dex issuer URL)."
  value       = gridscale_ipv4.edge.ip
}

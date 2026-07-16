output "loadbalancer_uuid" {
  description = "UUID of the LBaaS entry point."
  value       = gridscale_loadbalancer.edge.id
}

output "loadbalancer_name" {
  description = "Name of the LBaaS entry point."
  value       = gridscale_loadbalancer.edge.name
}

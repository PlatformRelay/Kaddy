output "cluster_uuid" {
  description = "UUID of the GSK cluster."
  value       = gridscale_k8s.platform.id
}

output "kubeconfig" {
  description = "kubeconfig for the GSK cluster; consumed by the ArgoCD re-bootstrap step (E1g-S05)."
  value       = gridscale_k8s.platform.kubeconfig
  sensitive   = true
}

output "k8s_private_network_uuid" {
  description = "Private network UUID the GSK nodes are attached to (for attaching other PaaS/VMs later, e.g. E6g)."
  value       = gridscale_k8s.platform.k8s_private_network_uuid
}

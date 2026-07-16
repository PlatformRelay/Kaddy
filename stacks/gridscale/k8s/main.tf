# GSK cluster stack — ONE small node pool, minimal by design (cost-sensitive:
# this cluster is torn down after every live test, see the runbook). The GSK
# control plane is managed by gridscale; we only size the worker pool.
#
# provider, required_providers, backend, and the labels module are injected by
# Terramate codegen (config.tm.hcl).

resource "gridscale_k8s" "platform" {
  name = module.labels.name

  # Pin the GSK release line (not :latest) so upgrades are deliberate. conftest
  # enforces a concrete version. gsk_version is mutually exclusive with release.
  release = var.gsk_release

  node_pool {
    name         = "pool-0"
    node_count   = var.node_count
    cores        = var.node_cores
    memory       = var.node_memory_gib
    storage      = var.node_storage_gib
    storage_type = var.node_storage_type
  }

  labels = module.labels.gridscale_labels
}

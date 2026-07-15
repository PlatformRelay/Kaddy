output "labels" {
  description = "Canonical ADR-0301 label map (map(string)) for Kubernetes / unified use."
  value       = local.labels
}

output "gridscale_labels" {
  description = "List of key=value strings for gridscale resource labels."
  value       = local.gridscale_labels

  precondition {
    condition = alltrue([
      for v in values(local.labels) : can(regex("^[a-z0-9_-]{0,63}$", v))
    ])
    error_message = "every label value must be lowercase and match ^[a-z0-9_-]{0,63}$."
  }
}

output "name" {
  description = "Deterministic resource name {prefix}-{service}-{suffix}, <= 63 chars, ^[a-z0-9-]+$."
  value       = local.name

  precondition {
    condition     = length(local.name) <= 63
    error_message = "resource name '${local.name}' exceeds 63 characters."
  }
  precondition {
    condition     = can(regex("^[a-z0-9-]+$", local.name))
    error_message = "resource name must match ^[a-z0-9-]+$ (no underscores)."
  }
}

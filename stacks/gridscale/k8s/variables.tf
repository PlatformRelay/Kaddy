# Minimal, cost-sensitive GSK sizing. Every default is the smallest sane value;
# conftest independently caps these so a fat cluster can never be planned.

variable "gsk_release" {
  description = "GSK Kubernetes release line (concrete, never latest). Verify available lines with gscloud before a live apply."
  type        = string
  default     = "1.30"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.gsk_release))
    error_message = "gsk_release must be a concrete minor line like \"1.30\" (no :latest, no patch)."
  }
}

variable "node_count" {
  description = "Worker node count for the single pool. Standing go-live GSK uses 3; cost cap 1-4 — the 4th node is operator-approved MemoryPressure relief (2026-07-20, ~€46/node/mo)."
  type        = number
  default     = 3

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 4
    error_message = "node_count must be 1-4 (cost cap; 4th node = operator-approved MemoryPressure relief 2026-07-20)."
  }
}

variable "node_cores" {
  description = "Cores per worker node."
  type        = number
  default     = 2
}

variable "node_memory_gib" {
  description = "Memory (GiB) per worker node."
  type        = number
  default     = 4
}

variable "node_storage_gib" {
  description = "Storage (GiB) per worker node."
  type        = number
  default     = 30
}

variable "node_storage_type" {
  description = "Node storage class: storage | storage_high | storage_insane."
  type        = string
  default     = "storage_insane"

  validation {
    condition     = contains(["storage", "storage_high", "storage_insane"], var.node_storage_type)
    error_message = "node_storage_type must be one of: storage, storage_high, storage_insane."
  }
}

# ADR-0301 mandatory core inputs + optional keys, with validation.
# Values follow the strictest syntax: lowercase ^[a-z0-9_-]{0,63}$
# (intersection of GCP + Kubernetes label-value rules).

variable "owner" {
  description = "DRI for incidents (ADR-0301 mandatory)."
  type        = string

  validation {
    condition     = length(trimspace(var.owner)) > 0
    error_message = "owner must not be empty (ADR-0301 mandatory: DRI for incidents)."
  }
  validation {
    condition     = can(regex("^[a-z0-9_-]{1,63}$", var.owner))
    error_message = "owner must be lowercase and match ^[a-z0-9_-]{1,63}$."
  }
}

variable "service" {
  description = "App identity -> app.kubernetes.io/name (ADR-0301 mandatory)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9_-]{1,63}$", var.service))
    error_message = "service must be lowercase and match ^[a-z0-9_-]{1,63}$."
  }
}

variable "part_of" {
  description = "Platform/product -> app.kubernetes.io/part-of (ADR-0301 mandatory)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9_-]{1,63}$", var.part_of))
    error_message = "part_of must be lowercase and match ^[a-z0-9_-]{1,63}$."
  }
}

variable "track" {
  description = "Release track (replaces environment/stage)."
  type        = string

  validation {
    condition     = contains(["stable", "canary", "preview"], var.track)
    error_message = "track must be one of the allowed values: stable, canary, preview."
  }
}

variable "managed_by" {
  description = "IaC tool -> app.kubernetes.io/managed-by (ADR-0301 mandatory)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9_-]{1,63}$", var.managed_by))
    error_message = "managed_by must be lowercase and match ^[a-z0-9_-]{1,63}$."
  }
}

variable "data_classification" {
  description = "Data classification (ADR-0301 mandatory)."
  type        = string

  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "data_classification must be one of: public, internal, confidential, restricted."
  }
}

variable "business_criticality" {
  description = "Blast radius tier (ADR-0301 mandatory)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9_-]{1,63}$", var.business_criticality))
    error_message = "business_criticality must be lowercase and match ^[a-z0-9_-]{1,63}$."
  }
}

variable "component" {
  description = "Role -> app.kubernetes.io/component (ADR-0301 optional)."
  type        = string
  default     = null

  validation {
    condition     = var.component == null || can(regex("^[a-z0-9_-]{1,63}$", coalesce(var.component, "x")))
    error_message = "component must be lowercase and match ^[a-z0-9_-]{1,63}$ when set."
  }
}

variable "personal_data" {
  description = "GDPR personal-data classification (ADR-0301 optional)."
  type        = string
  default     = null

  validation {
    condition     = var.personal_data == null || contains(["none", "pseudonymised", "personal", "special-category"], coalesce(var.personal_data, "none"))
    error_message = "personal_data must be one of: none, pseudonymised, personal, special-category when set."
  }
}

variable "pci" {
  description = "PCI-DSS scoping flag (ADR-0301 optional)."
  type        = bool
  default     = null
}

variable "name_prefix" {
  description = "Prefix for resource-name helper: {prefix}-{service}-{suffix}."
  type        = string
  default     = "kaddy"

  validation {
    condition     = can(regex("^[a-z0-9-]*$", var.name_prefix))
    error_message = "name_prefix must match ^[a-z0-9-]*$ (no underscores in resource names)."
  }
}

variable "name_suffix" {
  description = "Suffix for resource-name helper: {prefix}-{service}-{suffix}."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[a-z0-9-]*$", var.name_suffix))
    error_message = "name_suffix must match ^[a-z0-9-]*$ (no underscores in resource names)."
  }
}

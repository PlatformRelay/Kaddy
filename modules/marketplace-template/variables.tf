# Inputs for one Marketplace application (one engine: Caddy OR nginx). The
# validation blocks encode the gridscale marketplace-API constraints so an
# invalid config fails `tofu plan`/`test` OFFLINE, long before a live apply.

variable "name" {
  description = "Human-readable Marketplace application name (<= 64 chars, UTF-8). Typically labels-derived."
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 64
    error_message = "name must be 1-64 characters (gridscale marketplace-app limit)."
  }
}

variable "object_storage_path" {
  description = "Path to the exported golden-image snapshot. MUST be a .gz object and start with s3:// (gridscale marketplace-API constraint)."
  type        = string

  validation {
    # gridscale: object_storage_path "must be in .gz format and start with s3://".
    condition     = can(regex("^s3://.+\\.gz$", var.object_storage_path))
    error_message = "object_storage_path must start with s3:// and end in .gz (e.g. s3://bucket/caddy-golden.gz)."
  }
}

variable "category" {
  description = "Marketplace category. gridscale exposes a FIXED enum with no 'Web Server' — use Adminpanel/CMS and carry the real class in meta_*."
  type        = string
  default     = "Adminpanel"

  validation {
    condition = contains(
      ["CMS", "project management", "Adminpanel", "Collaboration", "Cloud Storage", "Archiving"],
      var.category,
    )
    error_message = "category must be one of the gridscale enum: CMS, project management, Adminpanel, Collaboration, Cloud Storage, Archiving."
  }
}

variable "setup_cores" {
  description = "Default server cores for a deploy from this template (minimal by default — cost discipline)."
  type        = number
  default     = 1

  validation {
    condition     = var.setup_cores >= 1 && var.setup_cores <= 8
    error_message = "setup_cores must be between 1 and 8 (minimal by default)."
  }
}

variable "setup_memory" {
  description = "Default server memory in GB for a deploy from this template."
  type        = number
  default     = 1

  validation {
    condition     = var.setup_memory >= 1 && var.setup_memory <= 16
    error_message = "setup_memory must be between 1 and 16 GB."
  }
}

variable "setup_storage_capacity" {
  description = "Default server storage in GB for a deploy from this template."
  type        = number
  default     = 10

  validation {
    condition     = var.setup_storage_capacity >= 10 && var.setup_storage_capacity <= 100
    error_message = "setup_storage_capacity must be between 10 and 100 GB."
  }
}

variable "meta_os" {
  description = "Operating system metadata (meta_os) shown in the Marketplace."
  type        = string
  default     = "Ubuntu 24.04"
}

variable "meta_components" {
  description = "Components metadata (meta_components, a set of strings) — the REAL classification lives here (the enum has no 'Web Server')."
  type        = set(string)
}

variable "meta_overview" {
  description = "Overview metadata (meta_overview) — describes the app's main function."
  type        = string
}

variable "icon_path" {
  description = "Path to the icon PNG; encoded as data:image/png;base64,… into meta_icon (panel <img src>). Defaults to the module's bundled kaddy logo."
  type        = string
  default     = ""
}

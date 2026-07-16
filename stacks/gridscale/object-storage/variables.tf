variable "state_bucket_name" {
  description = "Name of the S3-compatible bucket that holds remote OpenTofu state for all other gridscale stacks."
  type        = string
  default     = "kaddy-tfstate"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "state_bucket_name must be a valid S3 bucket name (lowercase, 3-63 chars)."
  }
}

variable "s3_host" {
  description = "gridscale Object Storage S3 endpoint host (no scheme). Default is gridscale's gos3.io."
  type        = string
  default     = "gos3.io"
}

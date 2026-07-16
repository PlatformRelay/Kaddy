# Cross-stack input: the s3:// .gz snapshot path exported by E13-S01 for the
# nginx golden image. See the Caddy stack for the wiring notes.

variable "object_storage_path" {
  description = "s3:// .gz path of the exported nginx golden-image snapshot (E13-S01 output)."
  type        = string
  default     = "s3://kaddy-images/nginx-golden.gz"

  validation {
    condition     = can(regex("^s3://.+\\.gz$", var.object_storage_path))
    error_message = "object_storage_path must start with s3:// and end in .gz."
  }
}

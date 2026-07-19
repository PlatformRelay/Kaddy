# Cross-stack input: the s3:// .gz snapshot path exported by the E13-S01 golden
# image pipeline into the E1g object-storage bucket. Live, task e13:up wires
# this from the exported snapshot object (bucket name = the object-storage stack
# output state_bucket_name, or a dedicated images bucket). Offline it defaults to
# a well-formed placeholder so validate/test pass without live state.

variable "object_storage_path" {
  description = "s3:// .gz path of the exported Caddy golden-image snapshot (E13-S01 output)."
  type        = string
  default     = "s3://kaddy-tfstate/marketplace/caddy-golden.gz"

  validation {
    condition     = can(regex("^s3://.+\\.gz$", var.object_storage_path))
    error_message = "object_storage_path must start with s3:// and end in .gz."
  }
}

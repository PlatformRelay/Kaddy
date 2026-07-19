# Cross-stack input: the s3:// .gz path of the Nix-built golden image exported to
# the E1g object-storage bucket (nix/flake.nix build -> gzip -> object storage).
# Live, the E14 path uploads nix/build/nixos.img (or the e14-nix-image CI
# artifact) as .gz here. Offline it defaults to the live path so validate/test
# pass without live state.

variable "object_storage_path" {
  description = "s3:// .gz path of the exported Nix golden-image snapshot (E14-S02 output)."
  type        = string
  default     = "s3://kaddy-tfstate/marketplace/nix-golden.gz"

  validation {
    condition     = can(regex("^s3://.+\\.gz$", var.object_storage_path))
    error_message = "object_storage_path must start with s3:// and end in .gz."
  }
}

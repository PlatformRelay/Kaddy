# Object-storage state anchor (DECIDED-B). This stack is bootstrapped FIRST with
# LOCAL state: it creates the S3-compatible bucket + access key that every OTHER
# gridscale stack then uses as its remote backend. It cannot use a remote backend
# itself (chicken-and-egg), so it keeps its small local state file — the single
# cheap persistent anchor for the platform.
#
# provider "gridscale", required_providers, and the labels module are injected by
# Terramate codegen (see config.tm.hcl → _terramate_generated_*.tf).

# Access key that owns the state bucket. Kept as a distinct, dedicated key so it
# can be rotated/scoped independently of any workload access key.
resource "gridscale_object_storage_accesskey" "state" {
  comment = "${module.labels.name}-state-backend"
}

resource "gridscale_object_storage_bucket" "state" {
  access_key  = gridscale_object_storage_accesskey.state.access_key
  secret_key  = gridscale_object_storage_accesskey.state.secret_key
  s3_host     = var.s3_host
  bucket_name = var.state_bucket_name

  # Reap incomplete multipart uploads quickly; keep old state versions bounded
  # so the anchor bucket never grows unbounded (cost discipline).
  lifecycle_rule {
    id                                 = "expire-noncurrent-state"
    enabled                            = true
    noncurrent_version_expiration_days = 30
    incomplete_upload_expiration_days  = 3
  }
}

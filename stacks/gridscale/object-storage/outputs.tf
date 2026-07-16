output "state_bucket_name" {
  description = "Name of the remote-state bucket; feeds every other stack's backend config."
  value       = gridscale_object_storage_bucket.state.bucket_name
}

output "s3_host" {
  description = "S3 endpoint host for the remote-state backend."
  value       = var.s3_host
}

output "access_key" {
  description = "Access key for the state bucket (bootstrap output; store securely, feeds backend AWS_ACCESS_KEY_ID)."
  value       = gridscale_object_storage_accesskey.state.access_key
  sensitive   = true
}

output "secret_key" {
  description = "Secret key for the state bucket (bootstrap output; store securely, feeds backend AWS_SECRET_ACCESS_KEY)."
  value       = gridscale_object_storage_accesskey.state.secret_key
  sensitive   = true
}

output "application_id" {
  description = "UUID of the registered nginx Marketplace application."
  value       = module.marketplace.application_id
}

output "unique_hash" {
  description = "Unique hash of the nginx Marketplace application (import key)."
  value       = module.marketplace.unique_hash
}

output "import_id" {
  description = "UUID of the imported (private, tenant-local) nginx Marketplace application."
  value       = module.marketplace.import_id
}

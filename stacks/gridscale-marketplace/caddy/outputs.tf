output "application_id" {
  description = "UUID of the registered Caddy Marketplace application."
  value       = module.marketplace.application_id
}

output "unique_hash" {
  description = "Unique hash of the Caddy Marketplace application (import key)."
  value       = module.marketplace.unique_hash
}

output "import_id" {
  description = "UUID of the imported (private, tenant-local) Caddy Marketplace application."
  value       = module.marketplace.import_id
}

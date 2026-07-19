output "application_id" {
  description = "UUID of the registered Nix Marketplace application."
  value       = module.marketplace.application_id
}

output "unique_hash" {
  description = "Unique hash of the Nix Marketplace application (import key)."
  value       = module.marketplace.unique_hash
}

output "import_id" {
  description = "UUID of the imported (private, tenant-local) Nix Marketplace application."
  value       = module.marketplace.import_id
}

output "application_id" {
  description = "UUID of the registered Marketplace application (live smoke asserts this is set)."
  value       = gridscale_marketplace_application.app.id
}

output "unique_hash" {
  description = "Unique hash of the self-created Marketplace application (used to import it into the tenant)."
  value       = gridscale_marketplace_application.app.unique_hash
}

output "import_id" {
  description = "UUID of the imported (private, tenant-local) Marketplace application."
  value       = gridscale_marketplace_application_import.imported.id
}

output "object_storage_path" {
  description = "The s3:// .gz snapshot path this template was registered from."
  value       = gridscale_marketplace_application.app.object_storage_path
}

output "name" {
  description = "The Marketplace application name (e.g. caddy-ubuntu / caddy-nix)."
  value       = gridscale_marketplace_application.app.name
}

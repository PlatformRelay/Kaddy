stack {
  name        = "gridscale-marketplace-caddy"
  description = "gridscale Marketplace 2.0 application for the Caddy golden image: register (gridscale_marketplace_application) + private-tenant import (gridscale_marketplace_application_import). Snapshot .gz path comes from the E1g object-storage bucket. Phase 2; gated on E1g credits."
  id          = "e13-gridscale-marketplace-caddy"
  tags        = ["gridscale", "marketplace", "caddy", "phase2"]
}

globals {
  service     = "market-caddy"
  name_suffix = ""
  # Register/import are cheap metadata operations, but the module still uses the
  # S3 remote-state backend (the E1g anchor) like every other workload stack.
  backend = "s3"
}

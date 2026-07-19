stack {
  name        = "gridscale-marketplace-nix"
  description = "gridscale Marketplace 2.0 application for the Nix golden image (E14): register (gridscale_marketplace_application) + private-tenant import (gridscale_marketplace_application_import). Snapshot .gz path is the Nix-built image exported to the E1g object-storage bucket. Phase 3; gated on E1g credits + supply-chain LGTM (D-037)."
  id          = "e14-gridscale-marketplace-nix"
  tags        = ["gridscale", "marketplace", "nix", "phase3"]
}

globals {
  # service "nix" -> module.labels.name "kaddy-nix" (the live kaddy-<engine>
  # convention, matching the live kaddy-caddy app; not the "market-*" label).
  service     = "nix"
  name_suffix = ""
  # Register/import are cheap metadata operations, but the module still uses the
  # S3 remote-state backend (the E1g anchor) like every other workload stack.
  backend = "s3"
}

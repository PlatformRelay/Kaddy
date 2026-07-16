stack {
  name        = "gridscale-marketplace-nginx"
  description = "gridscale Marketplace 2.0 application for the nginx golden image (mirror of the Caddy stack): register + private-tenant import. Snapshot .gz path from the E1g object-storage bucket. Phase 2; gated on E1g credits."
  id          = "e13-gridscale-marketplace-nginx"
  tags        = ["gridscale", "marketplace", "nginx", "phase2"]
}

globals {
  service     = "market-nginx"
  name_suffix = ""
  backend     = "s3"
}

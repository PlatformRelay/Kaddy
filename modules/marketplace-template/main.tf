# One gridscale Marketplace application + its private-tenant import, for a single
# engine (Caddy OR nginx — the stack passes the engine-specific inputs). See
# references/gridscale-terraform-provider/website/docs/r/marketplaceApp.html.md
# and marketplaceAppImport.html.md for the exact argument names.
#
# NOTE — gridscale_marketplace_application has NO `labels` argument (like the
# object-storage resources), so it does NOT carry the ADR-0301 label set; the
# stack still derives `name` from module.labels for consistency. This is also
# why conftest/labels.rego is NOT run over this stack's plan.

locals {
  # Prefer the caller-supplied icon; otherwise the module's bundled kaddy logo.
  # filebase64() runs at plan time (works under mock_provider) so meta_icon is
  # always a non-empty base64 image — the marketplace API requires an icon.
  icon_path = var.icon_path != "" ? var.icon_path : "${path.module}/assets/icon.png"
}

resource "gridscale_marketplace_application" "app" {
  name                = var.name
  object_storage_path = var.object_storage_path
  category            = var.category

  setup_cores            = var.setup_cores
  setup_memory           = var.setup_memory
  setup_storage_capacity = var.setup_storage_capacity

  meta_os         = var.meta_os
  meta_components = var.meta_components
  meta_overview   = var.meta_overview
  meta_icon       = filebase64(local.icon_path)

  # Private-tenant only (D-032): the writable `publish` arg (Optional, default
  # false) is deliberately left UNSET, so no global publication is requested —
  # that would need gridscale's manual review at product@gridscale.io. The
  # read-only is_publish_* attributes consequently report false.
}

resource "gridscale_marketplace_application_import" "imported" {
  # Importing by unique_hash makes the self-created template deployable WITHIN
  # our own tenant (private) — all the demo needs.
  import_unique_hash = gridscale_marketplace_application.app.unique_hash
}

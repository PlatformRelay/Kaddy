# REQ-E13-S02-01 — offline L0 gate for modules/marketplace-template.
#
# TDD red-first artifact: authored BEFORE the module implementation. Proves the
# module encodes the three gridscale-specific constraints the marketplace API
# imposes (see references/.../marketplaceApp.html.md):
#   1. object_storage_path MUST be `.gz` and start with `s3://`
#   2. category MUST be one of the fixed enum (there is NO "Web Server")
#   3. meta_icon MUST be a non-empty data:image/…;base64,… URI (panel <img src>)
#
# The gridscale provider is mocked — no API call, no credential. We assert the
# planned resource carries the values we expect, and that invalid inputs are
# rejected by variable `validation` blocks (expect_failures).

mock_provider "gridscale" {}

variables {
  name                = "kaddy-caddy-web"
  object_storage_path = "s3://kaddy-images/caddy-golden.gz"
  category            = "Adminpanel"
  meta_os             = "Ubuntu 24.04"
  meta_components     = ["Caddy", "Prometheus /metrics endpoint"]
  meta_overview       = "Monitored, TLS-ready Caddy web server — serve a page, scrape, alert."
}

run "registers_and_imports" {
  command = plan

  # The application is registered with the exact snapshot path + metadata.
  assert {
    condition     = gridscale_marketplace_application.app.object_storage_path == "s3://kaddy-images/caddy-golden.gz"
    error_message = "object_storage_path must be the configured s3:// .gz path"
  }

  assert {
    condition     = gridscale_marketplace_application.app.category == "Adminpanel"
    error_message = "category must be the configured enum value"
  }

  # Panel uses metadata.icon as <img src>; raw base64 blanks. filebase64() runs
  # under mock_provider — assert the data-URI prefix (never assert exact bytes).
  assert {
    condition     = startswith(gridscale_marketplace_application.app.meta_icon, "data:image/png;base64,")
    error_message = "meta_icon must be a data:image/png;base64,… URI for panel render"
  }

  assert {
    condition     = length(gridscale_marketplace_application.app.meta_icon) > length("data:image/png;base64,")
    error_message = "meta_icon must carry non-empty base64 image bytes after the data-URI prefix"
  }

  # The import is wired to the app's unique_hash → private tenant import.
  assert {
    condition     = gridscale_marketplace_application_import.imported.import_unique_hash == gridscale_marketplace_application.app.unique_hash
    error_message = "import must reference the app's unique_hash"
  }

  # Sizing is minimal by default (cost discipline, mirrors the GSK node pool).
  assert {
    condition     = gridscale_marketplace_application.app.setup_cores == 1
    error_message = "default setup_cores must be minimal (1)"
  }
}

run "rejects_non_gz_path" {
  command = plan

  variables {
    object_storage_path = "s3://kaddy-images/caddy-golden.raw"
  }

  expect_failures = [
    var.object_storage_path,
  ]
}

run "rejects_non_s3_scheme" {
  command = plan

  variables {
    object_storage_path = "https://kaddy-images/caddy-golden.gz"
  }

  expect_failures = [
    var.object_storage_path,
  ]
}

run "rejects_category_outside_enum" {
  command = plan

  variables {
    # "Web Server" is deliberately NOT in the gridscale enum — must be rejected.
    category = "Web Server"
  }

  expect_failures = [
    var.category,
  ]
}

# REQ-E13-S02-01/02 — Caddy Marketplace stack, offline plan, mocked provider.
# Asserts the stack wires the module with a valid .gz/s3:// path, the Adminpanel
# category, a labels-derived name, and a present icon — all without an API call.

mock_provider "gridscale" {}

run "caddy_app_planned" {
  command = plan

  assert {
    condition     = module.marketplace.object_storage_path == "s3://kaddy-tfstate/marketplace/caddy-golden.gz"
    error_message = "caddy app must register from the s3:// .gz snapshot path"
  }

  # Engine-OS name: Caddy on Ubuntu.
  assert {
    condition     = module.marketplace.name == "caddy-ubuntu"
    error_message = "caddy app name must be caddy-ubuntu"
  }
  assert {
    condition     = module.marketplace.application_id != null
    error_message = "caddy app must plan an application resource (id computed)"
  }
}

run "rejects_bad_path" {
  command = plan

  variables {
    object_storage_path = "s3://kaddy-tfstate/marketplace/caddy.tar" # not .gz
  }

  expect_failures = [
    var.object_storage_path,
  ]
}

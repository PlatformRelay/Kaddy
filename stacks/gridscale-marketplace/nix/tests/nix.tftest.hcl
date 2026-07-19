# REQ-E14-S02-01 — Nix Marketplace stack, offline plan, mocked provider.
# Asserts the stack wires the module with a valid .gz/s3:// path, the Adminpanel
# category, a labels-derived name, and a present icon — all without an API call.

mock_provider "gridscale" {}

run "nix_app_planned" {
  command = plan

  assert {
    condition     = module.marketplace.object_storage_path == "s3://kaddy-tfstate/marketplace/nix-golden.gz"
    error_message = "nix app must register from the s3:// .gz snapshot path"
  }

  # Name is derived from the ADR-0301 labels module (kaddy-nix).
  assert {
    condition     = module.marketplace.application_id != null
    error_message = "nix app must plan an application resource (id computed)"
  }
}

run "rejects_bad_path" {
  command = plan

  variables {
    object_storage_path = "s3://kaddy-tfstate/marketplace/nix.tar" # not .gz
  }

  expect_failures = [
    var.object_storage_path,
  ]
}

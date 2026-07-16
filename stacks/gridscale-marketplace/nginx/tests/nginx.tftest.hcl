# REQ-E13-S02-01/02 — nginx Marketplace stack, offline plan, mocked provider.
# Mirror of the Caddy stack test.

mock_provider "gridscale" {}

run "nginx_app_planned" {
  command = plan

  assert {
    condition     = module.marketplace.object_storage_path == "s3://kaddy-images/nginx-golden.gz"
    error_message = "nginx app must register from the s3:// .gz snapshot path"
  }

  assert {
    condition     = module.marketplace.application_id != null
    error_message = "nginx app must plan an application resource (id computed)"
  }
}

run "rejects_bad_path" {
  command = plan

  variables {
    object_storage_path = "s3://kaddy-images/nginx.tar" # not .gz
  }

  expect_failures = [
    var.object_storage_path,
  ]
}

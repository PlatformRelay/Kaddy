# REQ-E1g-S01: object-storage state anchor — offline plan with a mocked provider.
# The gridscale provider is mocked so no API call / credential is needed; we
# assert naming, the state-bucket contract, and the lifecycle guard.

mock_provider "gridscale" {}

run "bucket_and_key_planned" {
  command = plan

  variables {
    state_bucket_name = "kaddy-tfstate"
    s3_host           = "gos3.io"
  }

  assert {
    condition     = gridscale_object_storage_bucket.state.bucket_name == "kaddy-tfstate"
    error_message = "state bucket name must be the configured value"
  }

  assert {
    condition     = gridscale_object_storage_bucket.state.s3_host == "gos3.io"
    error_message = "s3_host must default to gos3.io"
  }

  # The access key comment ties the key to the labels-derived resource name.
  assert {
    condition     = gridscale_object_storage_accesskey.state.comment == "kaddy-tfstate-state-backend"
    error_message = "access key comment must be derived from module.labels.name"
  }

  # Cost discipline: the anchor bucket must reap incomplete uploads.
  assert {
    condition     = one(gridscale_object_storage_bucket.state.lifecycle_rule).enabled == true
    error_message = "lifecycle rule must be enabled to bound bucket growth"
  }
}

run "rejects_invalid_bucket_name" {
  command = plan

  variables {
    state_bucket_name = "Bad_Bucket_Name"
  }

  expect_failures = [
    var.state_bucket_name,
  ]
}

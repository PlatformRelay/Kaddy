# REQ-E1b-S02-02: track not in {stable,canary,preview} must fail with clear error.
variables {
  owner                = "platform-team"
  service              = "clubhouse"
  part_of              = "kaddy"
  track                = "production"
  managed_by           = "terramate"
  data_classification  = "internal"
  business_criticality = "business-operational"
  name_prefix          = "kaddy"
  name_suffix          = "cp-01"
}

run "invalid_track_fails" {
  command = plan

  expect_failures = [
    var.track,
  ]
}

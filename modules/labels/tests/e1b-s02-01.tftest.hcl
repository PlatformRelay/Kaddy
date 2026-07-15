# REQ-E1b-S02-01: empty owner must fail validation.
variables {
  owner                = ""
  service              = "clubhouse"
  part_of              = "kaddy"
  track                = "stable"
  managed_by           = "terramate"
  data_classification  = "internal"
  business_criticality = "business-operational"
  name_prefix          = "kaddy"
  name_suffix          = "cp-01"
}

run "missing_owner_fails" {
  command = plan

  expect_failures = [
    var.owner,
  ]
}

# REQ-E1b-EXIT: negative-branch coverage for enum validations.
# data_classification and personal_data are constrained to fixed allow-lists;
# an out-of-set value must fail the corresponding variable validation.
variables {
  owner                = "platform-team"
  service              = "clubhouse"
  part_of              = "kaddy"
  track                = "stable"
  managed_by           = "terramate"
  data_classification  = "internal"
  business_criticality = "business-operational"
  name_prefix          = "kaddy"
  name_suffix          = "cp-01"
}

run "invalid_data_classification_fails" {
  command = plan

  variables {
    data_classification = "secret"
  }

  expect_failures = [
    var.data_classification,
  ]
}

run "invalid_personal_data_fails" {
  command = plan

  variables {
    personal_data = "sensitive"
  }

  expect_failures = [
    var.personal_data,
  ]
}

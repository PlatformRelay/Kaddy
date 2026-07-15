# REQ-E1b-EXIT: negative-branch coverage for regex-constrained string inputs.
# Every mandatory/optional identity value must match ^[a-z0-9_-]{1,63}$ (or the
# no-underscore ^[a-z0-9-]*$ for name_prefix/name_suffix). An uppercase letter or
# dot violates the charset and must fail the corresponding variable validation.
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

run "invalid_owner_charset_fails" {
  command = plan

  variables {
    owner = "Platform.Team"
  }

  expect_failures = [
    var.owner,
  ]
}

run "invalid_service_charset_fails" {
  command = plan

  variables {
    service = "Club.House"
  }

  expect_failures = [
    var.service,
  ]
}

run "invalid_part_of_charset_fails" {
  command = plan

  variables {
    part_of = "Kaddy.Platform"
  }

  expect_failures = [
    var.part_of,
  ]
}

run "invalid_managed_by_charset_fails" {
  command = plan

  variables {
    managed_by = "Terramate!"
  }

  expect_failures = [
    var.managed_by,
  ]
}

run "invalid_business_criticality_charset_fails" {
  command = plan

  variables {
    business_criticality = "Mission Critical"
  }

  expect_failures = [
    var.business_criticality,
  ]
}

run "invalid_component_charset_fails" {
  command = plan

  variables {
    component = "Control.Plane"
  }

  expect_failures = [
    var.component,
  ]
}

run "invalid_name_prefix_charset_fails" {
  command = plan

  variables {
    name_prefix = "kaddy_prod"
  }

  expect_failures = [
    var.name_prefix,
  ]
}

run "invalid_name_suffix_charset_fails" {
  command = plan

  variables {
    name_suffix = "cp_01"
  }

  expect_failures = [
    var.name_suffix,
  ]
}

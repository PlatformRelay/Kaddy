# REQ-E1b-EXIT: negative-branch coverage for the derived-name output preconditions.
# The name helper is stricter than its inputs: service permits underscores
# (^[a-z0-9_-]{1,63}$) but the name output forbids them (^[a-z0-9-]+$), and the
# joined {prefix}-{service}-{suffix} must stay <= 63 chars. Both branches are only
# reachable through valid inputs, so they must be asserted on output.name.
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

run "name_charset_underscore_fails" {
  command = plan

  # Underscore is legal for service but illegal in the derived resource name.
  variables {
    service = "club_house"
  }

  expect_failures = [
    output.name,
  ]
}

run "name_length_over_63_fails" {
  command = plan

  # kaddy-<63 chars>-cp-01 exceeds the 63-char name ceiling.
  variables {
    service = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  }

  expect_failures = [
    output.name,
  ]
}

# REQ-E1b-S01-02: each gridscale_labels entry is key=value, lowercase,
# value matches ^[a-z0-9_-]{0,63}$.
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

run "gridscale_labels_are_valid_key_value_pairs" {
  command = plan

  assert {
    condition = alltrue([
      for e in output.gridscale_labels :
      can(regex("^[a-z0-9._/-]+=[a-z0-9_-]{0,63}$", e))
    ])
    error_message = "every gridscale label must be key=value with value matching ^[a-z0-9_-]{0,63}$"
  }

  assert {
    condition = alltrue([
      for e in output.gridscale_labels :
      e == lower(e)
    ])
    error_message = "gridscale labels must be lowercase"
  }

  assert {
    condition     = contains(output.gridscale_labels, "owner=platform-team")
    error_message = "gridscale_labels must contain owner=platform-team"
  }
}

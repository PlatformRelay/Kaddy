# REQ-E1b-S01-03: resource name {prefix}-{service}-{suffix} length <= 63,
# charset ^[a-z0-9-]+$.
variables {
  owner                = "platform-team"
  service              = "talos"
  part_of              = "kaddy"
  track                = "stable"
  managed_by           = "terramate"
  data_classification  = "internal"
  business_criticality = "business-operational"
  name_prefix          = "kaddy"
  name_suffix          = "talos-cp-01"
}

run "resource_name_within_length_and_charset" {
  command = plan

  assert {
    condition     = length(output.name) <= 63
    error_message = "resource name must be <= 63 chars"
  }
  assert {
    condition     = can(regex("^[a-z0-9-]+$", output.name))
    error_message = "resource name must match ^[a-z0-9-]+$ (no underscores)"
  }
  assert {
    condition     = output.name == "kaddy-talos-talos-cp-01"
    error_message = "name must be {prefix}-{service}-{suffix}"
  }
}

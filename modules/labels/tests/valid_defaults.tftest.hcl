# REQ-E1b-S01-01: module outputs canonical label map with all mandatory ADR-0301 keys.
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

run "valid_defaults_produces_mandatory_labels" {
  command = plan

  # Mandatory ADR-0301 keys, mapped to K8s app.kubernetes.io/* where specified.
  assert {
    condition     = output.labels["owner"] == "platform-team"
    error_message = "owner label missing or wrong"
  }
  assert {
    condition     = output.labels["app.kubernetes.io/name"] == "clubhouse"
    error_message = "service must map to app.kubernetes.io/name"
  }
  assert {
    condition     = output.labels["app.kubernetes.io/part-of"] == "kaddy"
    error_message = "part_of must map to app.kubernetes.io/part-of"
  }
  assert {
    condition     = output.labels["app.kubernetes.io/managed-by"] == "terramate"
    error_message = "managed_by must map to app.kubernetes.io/managed-by"
  }
  assert {
    condition     = output.labels["data-classification"] == "internal"
    error_message = "data-classification label missing"
  }
  assert {
    condition     = output.labels["business-criticality"] == "business-operational"
    error_message = "business-criticality label missing"
  }
  assert {
    condition     = output.labels["track"] == "stable"
    error_message = "track label missing"
  }
}

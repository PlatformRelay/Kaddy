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

  # ADR-0301 canonical form: BARE keys are the single source of truth. The
  # Kubernetes app.kubernetes.io/* keys are an explicit, documented ADDITION
  # (asserted below) — not a competing canonical set.
  assert {
    condition     = output.labels["owner"] == "platform-team"
    error_message = "owner label missing or wrong"
  }
  assert {
    condition     = output.labels["service"] == "clubhouse"
    error_message = "service (canonical bare key) missing or wrong"
  }
  assert {
    condition     = output.labels["part-of"] == "kaddy"
    error_message = "part-of (canonical bare key) missing or wrong"
  }
  assert {
    condition     = output.labels["managed-by"] == "terramate"
    error_message = "managed-by (canonical bare key) missing or wrong"
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

  # Documented ADDITION: Kubernetes-recommended mirror of the canonical bare
  # keys (ADR-0301 "Kubernetes mapping"). Present but non-canonical.
  assert {
    condition     = output.labels["app.kubernetes.io/name"] == "clubhouse"
    error_message = "k8s mirror app.kubernetes.io/name must mirror service"
  }
  assert {
    condition     = output.labels["app.kubernetes.io/part-of"] == "kaddy"
    error_message = "k8s mirror app.kubernetes.io/part-of must mirror part-of"
  }
  assert {
    condition     = output.labels["app.kubernetes.io/managed-by"] == "terramate"
    error_message = "k8s mirror app.kubernetes.io/managed-by must mirror managed-by"
  }
}

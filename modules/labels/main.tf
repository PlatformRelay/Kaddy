# modules/labels — ADR-0301 canonical label producer.
# OpenTofu has no user-defined functions; the name helper is exposed as the
# `name` output driven by name_prefix / name_suffix variables.

locals {
  # ADR-0301 canonical mandatory core, in BARE-key form. This is the single
  # source of truth; policy (policy/labels.rego) and admission
  # (deploy/policies/kyverno/require-kaddy-labels.yaml) enforce exactly these.
  labels_canonical = {
    "owner"                = var.owner
    "service"              = var.service
    "part-of"              = var.part_of
    "managed-by"           = var.managed_by
    "track"                = var.track
    "data-classification"  = var.data_classification
    "business-criticality" = var.business_criticality
  }

  # Documented ADDITION (ADR-0301 "Kubernetes mapping"): app.kubernetes.io/*
  # mirror of the canonical keys, emitted alongside — never a competing
  # canonical set. component (optional) is expressed only in k8s form.
  labels_k8s_recommended = {
    "app.kubernetes.io/name"       = var.service
    "app.kubernetes.io/part-of"    = var.part_of
    "app.kubernetes.io/managed-by" = var.managed_by
  }

  labels_base = merge(local.labels_canonical, local.labels_k8s_recommended)

  labels_component = var.component == null ? {} : {
    "component"                   = var.component
    "app.kubernetes.io/component" = var.component
  }

  labels_personal_data = var.personal_data == null ? {} : {
    "personal-data" = var.personal_data
  }

  labels_pci = var.pci == null ? {} : {
    "pci" = tostring(var.pci)
  }

  labels = merge(
    local.labels_base,
    local.labels_component,
    local.labels_personal_data,
    local.labels_pci,
  )

  # gridscale accepts flat key=value strings; keys lowercased/normalised.
  gridscale_labels = [
    for k, v in local.labels : "${lower(k)}=${v}"
  ]

  # Deterministic resource name: {prefix}-{service}-{suffix}, joined and
  # trimmed so empty suffix does not leave a trailing dash.
  name_parts = [for p in [var.name_prefix, var.service, var.name_suffix] : p if p != ""]
  name       = join("-", local.name_parts)
}

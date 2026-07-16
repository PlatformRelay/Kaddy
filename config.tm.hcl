# Terramate codegen — the ONE place provider/backend/labels are defined.
#
# These generate_hcl blocks run for every stack (they carry no `condition`,
# so they apply to all descendant stacks). Each stack therefore gets, without
# copy-paste:
#   * _terramate_generated_provider.tf — required_providers pin + provider auth
#   * _terramate_generated_labels.tf   — the modules/labels call (E1b-S04)
#
# Backend is generated per stack via a per-stack `backend` global (S3 for the
# workload stacks, local for the object-storage bootstrap anchor) — see each
# stack's stack.tm.hcl. Regenerate with `task e1g:generate` (terramate generate).

# --- Provider: required_providers pin + auth mapping --------------------------
generate_hcl "_terramate_generated_provider.tf" {
  content {
    terraform {
      required_providers {
        gridscale = {
          source  = "gridscale/gridscale"
          version = global.gridscale_provider_version
        }
      }
    }

    # Auth mapping (KEY-FACT): the provider reads GRIDSCALE_UUID / GRIDSCALE_TOKEN,
    # but the repo .envrc exports GRIDSCALE_USER_UUID / GRIDSCALE_API_KEY. We map
    # via TF_VAR_gridscale_uuid / TF_VAR_gridscale_token (set only in the LIVE
    # `task e1g:up` target). Offline, these vars are unset and the provider is
    # never configured — validate/mocked-test do not require them.
    provider "gridscale" {
      uuid  = var.gridscale_uuid
      token = var.gridscale_token
    }
  }
}

# --- Provider auth variables (kept out of each stack's hand-written vars) ------
generate_hcl "_terramate_generated_variables.tf" {
  content {
    variable "gridscale_uuid" {
      description = "gridscale User-UUID. Live only: set via TF_VAR_gridscale_uuid (mapped from GRIDSCALE_USER_UUID in task e1g:up)."
      type        = string
      default     = ""
      sensitive   = true
    }
    variable "gridscale_token" {
      description = "gridscale API token. Live only: set via TF_VAR_gridscale_token (mapped from GRIDSCALE_API_KEY in task e1g:up)."
      type        = string
      default     = ""
      sensitive   = true
    }
  }
}

# --- Backend: local for the bootstrap anchor, S3 for workload stacks ----------
# The object-storage stack sets global.backend = "local" (it IS the anchor);
# every other stack sets "s3" and points at the bucket the anchor created.
# Backend values (bucket, endpoint, credentials) come from the environment at
# `tofu init` time (AWS_* / the backend `-backend-config` flags in task e1g:up),
# never hard-coded here. Offline we always init with `-backend=false`, so this
# block is inert for validate/test.
generate_hcl "_terramate_generated_backend.tf" {
  condition = global.backend == "s3"
  content {
    terraform {
      backend "s3" {
        # S3-compatible gridscale Object Storage. Bucket/endpoint/creds are
        # supplied via -backend-config at init (task e1g:up); skip_* flags are
        # required because gos3.io is not real AWS.
        key                         = "${terramate.stack.name}/terraform.tfstate"
        region                      = "us-east-1"
        skip_credentials_validation = true
        skip_metadata_api_check     = true
        skip_region_validation      = true
        skip_requesting_account_id  = true
        use_path_style              = true
      }
    }
  }
}

# --- Labels: E1b-S04 canonical ADR-0301 labels injected into every stack ------
# The stack-specific `service` comes from a per-stack global; everything else is
# the shared platform-wide global. Downstream resources reference
# module.labels.gridscale_labels (list of "key=value") and module.labels.name.
generate_hcl "_terramate_generated_labels.tf" {
  content {
    module "labels" {
      source = "${global.root_rel}/modules/labels"

      owner                = global.owner
      service              = global.service
      part_of              = global.part_of
      managed_by           = global.managed_by
      track                = global.track
      data_classification  = global.data_classification
      business_criticality = global.business_criticality

      name_prefix = "kaddy"
      name_suffix = global.name_suffix
    }
  }
}

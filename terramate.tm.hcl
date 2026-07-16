# Terramate project root — ADR-0302 (Terramate + OpenTofu stacks).
#
# This file establishes the project config, the global inputs every gridscale
# stack shares (labels, location, project identity), and the codegen that
# injects the required_providers pin, provider auth mapping, backend, and the
# ADR-0301 canonical labels into every stack under stacks/ (E1b-S04, descoped
# from E1b to E1g per D-021).
#
# OFFLINE posture: `terramate generate` is deterministic and needs no network
# or credentials. The generated provider maps auth to TF_VAR_gridscale_uuid /
# TF_VAR_gridscale_token (wired only in the LIVE `task e1g:up` target) so that
# `tofu validate -backend=false` and mocked `tofu test` run without secrets.

terramate {
  # Pin the toolchain expectation; keep loose so CI images can float patch.
  required_version = ">= 0.11"

  config {
    # Codegen must never silently reach across unrelated stacks.
    generate {
      hcl_magic_header_comment_style = "#"
    }
  }
}

# --- Shared globals -----------------------------------------------------------
# Every stack reads these via terramate codegen. Region/location is the
# gridscale de/fra (Frankfurt) location by default; override per-stack if a
# future lane needs multi-region. Kept as a global so the whole platform moves
# together and nothing hard-codes a UUID in HCL.
globals {
  # ADR-0301 canonical label inputs — the single source of truth wired into the
  # modules/labels module by codegen (see config.tm.hcl). part_of/owner are
  # platform-wide; per-stack service is set in each stack's stack.tm.hcl.
  owner                = "platform-team"
  part_of              = "kaddy"
  managed_by           = "terramate"
  track                = "stable"
  data_classification  = "internal"
  business_criticality = "business-operational"

  # gridscale placement. de/fra6 is the Frankfurt region; the provider resolves
  # location from the project, so this is documentation + a codegen anchor for
  # any resource that needs an explicit location_uuid later.
  gridscale_location = "de/fra"

  # Provider pin — current major is v2 (latest v2.3.0, Oct 2025). ~> 2.2 floats
  # patch/minor within v2 while forbidding a v3 breaking bump.
  gridscale_provider_version = "~> 2.2"

  # Relative path from a stack back to the repo root (all gridscale stacks live
  # at stacks/gridscale/<name>, i.e. three levels deep).
  root_rel = "../../.."
}

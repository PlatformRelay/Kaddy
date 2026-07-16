# modules/marketplace-template — reusable module (NOT a Terramate stack, so it
# gets NO codegen). It hand-declares its provider pin (matching global
# gridscale_provider_version ~> 2.2) and declares NO provider block — the caller
# (the stacks/gridscale-marketplace/* stacks, which DO get codegen) configures
# the provider and passes it in.
terraform {
  required_version = ">= 1.6"

  required_providers {
    gridscale = {
      source  = "gridscale/gridscale"
      version = "~> 2.2"
    }
  }
}

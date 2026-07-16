# TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

terraform {
  required_providers {
    gridscale = {
      source  = "gridscale/gridscale"
      version = "~> 2.2"
    }
  }
}
provider "gridscale" {
  token = var.gridscale_token
  uuid  = var.gridscale_uuid
}

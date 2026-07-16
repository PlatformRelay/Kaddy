# TERRAMATE: GENERATED AUTOMATICALLY DO NOT EDIT

variable "gridscale_uuid" {
  default     = ""
  description = "gridscale User-UUID. Live only: set via TF_VAR_gridscale_uuid (mapped from GRIDSCALE_USER_UUID in task e1g:up)."
  sensitive   = true
  type        = string
}
variable "gridscale_token" {
  default     = ""
  description = "gridscale API token. Live only: set via TF_VAR_gridscale_token (mapped from GRIDSCALE_API_KEY in task e1g:up)."
  sensitive   = true
  type        = string
}

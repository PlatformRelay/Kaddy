# Cross-stack inputs. Live, task e1g:up wires these from the network stack
# outputs (ipv4_uuid / ipv6_uuid) and the GSK Gateway backend IP.

variable "listen_ipv4_uuid" {
  description = "UUID of the public IPv4 to listen on (network stack output ipv4_uuid)."
  type        = string
  default     = ""
}

variable "listen_ipv6_uuid" {
  description = "UUID of the public IPv6 to listen on (network stack output ipv6_uuid)."
  type        = string
  default     = ""
}

variable "gateway_backend_host" {
  description = "IP/host of the GSK Gateway the LB forwards to (surfaced after the Gateway service is up)."
  type        = string
  default     = ""
}

variable "redirect_http_to_https" {
  description = "Force the LB to redirect HTTP to HTTPS. Kept a var so tcp-passthrough mode can opt out."
  type        = bool
  default     = false
}

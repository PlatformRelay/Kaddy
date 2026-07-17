# E13-S01 — golden-image build for the nginx Marketplace template (mirror of
# caddy.pkr.hcl). Builds Ubuntu + nginx + nginx-prometheus-exporter + the sample
# page + a /metrics endpoint; the LIVE export step snapshots + exports it as a
# .gz to the E1g object-storage bucket. Gated offline by packer fmt/validate.
#
# Refs: gridscale Packer tutorial — https://gridscale.io/community/tutorials/how-to-packer/

packer {
  required_plugins {
    gridscale = {
      source  = "github.com/gridscale/gridscale"
      version = ">= 0.1.0"
    }
  }
}

variable "gridscale_uuid" {
  type        = string
  default     = "${env("GRIDSCALE_UUID")}"
  description = "gridscale User-UUID (live only; unset offline)."
  sensitive   = true
}

variable "gridscale_token" {
  type        = string
  default     = "${env("GRIDSCALE_TOKEN")}"
  description = "gridscale API token (live only; unset offline)."
  sensitive   = true
}

variable "base_template" {
  type        = string
  default     = "b308d75e-b8fb-4c90-87dc-f909879ae08c" # Ubuntu 24.04 LTS template UUID (gridscale)
  description = "gridscale public base-template UUID to build the golden image from (default: Ubuntu 24.04 LTS)."
}

variable "ssh_password" {
  type        = string
  default     = ""
  description = "Root password set on the EPHEMERAL build VM so the SSH provisioner can connect (live build only — pass via -var or PKR_VAR_ssh_password; the VM is destroyed after the snapshot). gridscale requires a strong password."
  sensitive   = true
}

source "gridscale" "nginx" {
  # gridscale plugin: api_key is the User-UUID, api_token is the API token
  # (matches env GRIDSCALE_UUID / GRIDSCALE_TOKEN). base_template_uuid selects
  # the public base image to build from.
  api_key            = var.gridscale_uuid
  api_token          = var.gridscale_token
  base_template_uuid = var.base_template
  storage_capacity   = 10
  server_cores       = 1
  server_memory      = 1
  hostname           = "kaddy-nginx-golden"
  ssh_password       = var.ssh_password
  ssh_username       = "root"
}

build {
  name    = "kaddy-nginx"
  sources = ["source.gridscale.nginx"]

  provisioner "shell" {
    inline = ["mkdir -p /tmp/kaddy"]
  }
  provisioner "file" {
    source      = "${path.root}/files/index.html"
    destination = "/tmp/kaddy/index.html"
  }
  provisioner "file" {
    source      = "${path.root}/files/nginx.conf"
    destination = "/tmp/kaddy/nginx.conf"
  }
  provisioner "shell" {
    script = "${path.root}/scripts/provision-nginx.sh"
  }
}

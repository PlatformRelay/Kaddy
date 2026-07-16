# E13-S01 — golden-image build for the Caddy Marketplace template.
#
# Reproducible, version-pinned, diffable (the point over a one-off cloud-init
# gridscale_server): builds an Ubuntu server with Caddy + the sample page + a
# /metrics endpoint, then the LIVE export step (task e13:export, per the runbook)
# snapshots the storage and exports it as a .gz to the E1g object-storage bucket
# for object_storage_path.
#
# OFFLINE posture: `packer fmt -check` + `packer validate` gate this file. The
# gridscale builder plugin is fetched from the public Packer registry on first
# `packer init` (a public download, NOT a gridscale API call); the offline gate
# SKIPs validate gracefully if the plugin can't be fetched (mirrors how the E1g
# smoke skips a registry-unreachable tofu init).
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
  default     = "Ubuntu 24.04 LTS"
  description = "gridscale public base template to build the golden image from."
}

source "gridscale" "caddy" {
  # gridscale plugin: api_key is the User-UUID, api_token is the API token
  # (matches env GRIDSCALE_UUID / GRIDSCALE_TOKEN). base_template_uuid selects
  # the public base image to build from.
  api_key            = var.gridscale_uuid
  api_token          = var.gridscale_token
  base_template_uuid = var.base_template
  storage_capacity   = 10
  server_cores       = 1
  server_memory      = 1
  hostname           = "kaddy-caddy-golden"
  ssh_username       = "root"
}

build {
  name    = "kaddy-caddy"
  sources = ["source.gridscale.caddy"]

  # Ship the sample page + Caddyfile, then provision Caddy + enable /metrics.
  provisioner "shell" {
    inline = ["mkdir -p /tmp/kaddy"]
  }
  provisioner "file" {
    source      = "${path.root}/files/index.html"
    destination = "/tmp/kaddy/index.html"
  }
  provisioner "file" {
    source      = "${path.root}/files/Caddyfile"
    destination = "/tmp/kaddy/Caddyfile"
  }
  provisioner "shell" {
    script = "${path.root}/scripts/provision-caddy.sh"
  }
}

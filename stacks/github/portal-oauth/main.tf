# Portal.lab Backstage — GitHub OAuth contract + Secret wiring (GSK only).
#
# Classic OAuth Apps cannot be created via the GitHub API / terraform-provider-
# github. Create the app in the GitHub UI with the URLs below, then apply the
# Secret with TF vars or hack/portal/wire-github-oauth-secret.sh.
#
# NEVER use http://127.0.0.1 or kind-local URLs as the Authorization callback.
#
#   export TF_VAR_auth_github_client_id='…'
#   export TF_VAR_auth_github_client_secret='…'
#   export TF_VAR_apply_secret=true
#   export TF_VAR_kubeconfig_path=.state/gsk/kubeconfig
#   tofu -chdir=stacks/github/portal-oauth apply

terraform {
  required_version = ">= 1.6"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
  }
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

variable "kubeconfig_path" {
  type        = string
  description = "Path to GSK kubeconfig (repo .state/gsk/kubeconfig at apply time)."
  default     = ""
}

variable "auth_github_client_id" {
  type        = string
  description = "GitHub OAuth App client_id for portal.lab Backstage."
  sensitive   = true
  default     = ""
}

variable "auth_github_client_secret" {
  type        = string
  description = "GitHub OAuth App client_secret for portal.lab Backstage."
  sensitive   = true
  default     = ""
}

variable "apply_secret" {
  type        = bool
  description = "When true, create/update Secret portal/backstage-github."
  default     = false
}

locals {
  homepage_url = "https://portal.lab.platformrelay.dev"
  # Exact Authorization callback URL for Backstage github provider on GSK.
  # MUST NOT be http://127.0.0.1 or any kind-local URL.
  oauth_callback_url = "https://portal.lab.platformrelay.dev/api/auth/github/handler/frame"
  oauth_app_name     = "kaddy-portal-lab"
  create_url_org     = "https://github.com/organizations/PlatformRelay/settings/applications/new"
  apps_settings_url  = "https://github.com/organizations/PlatformRelay/settings/apps"
}

output "homepage_url" {
  value       = local.homepage_url
  description = "GitHub OAuth App Homepage URL (GSK portal.lab)"
}

output "oauth_callback_url" {
  value       = local.oauth_callback_url
  description = "GitHub OAuth App Authorization callback URL — portal.lab only, never localhost"
}

output "oauth_app_name" {
  value = local.oauth_app_name
}

output "create_urls" {
  value = {
    oauth_app_new = local.create_url_org
    github_apps   = local.apps_settings_url
  }
}

output "operator_checklist" {
  value = <<-EOT
    GSK ONLY — do not use kind / 127.0.0.1 callbacks.

    1. Create (or edit) OAuth App / GitHub App:
         Homepage:  ${local.homepage_url}
         Callback:  ${local.oauth_callback_url}
         New OAuth App: ${local.create_url_org}
         Existing GitHub Apps: ${local.apps_settings_url}
            → "User authorization callback URL" = Callback above
    2. Wire secret (preferred script):
         AUTH_GITHUB_CLIENT_ID=… AUTH_GITHUB_CLIENT_SECRET=… \
           bash hack/portal/wire-github-oauth-secret.sh
       Or TF:
         TF_VAR_apply_secret=true TF_VAR_kubeconfig_path=.state/gsk/kubeconfig \
         TF_VAR_auth_github_client_id=… TF_VAR_auth_github_client_secret=… \
           tofu -chdir=stacks/github/portal-oauth apply
    3. Prove:
         curl -sSI 'https://portal.lab.platformrelay.dev/api/auth/github/start?env=production' | grep -i location
         # must include portal.lab …/api/auth/github/handler/frame
         # must NOT include 127.0.0.1 or localhost
  EOT
}

resource "kubernetes_secret_v1" "backstage_github" {
  count = var.apply_secret ? 1 : 0

  metadata {
    name      = "backstage-github"
    namespace = "portal"
    labels = {
      "owner"                        = "platform-team"
      "service"                      = "portal"
      "part-of"                      = "kaddy"
      "managed-by"                   = "opentofu"
      "app.kubernetes.io/name"       = "backstage-github"
      "app.kubernetes.io/part-of"    = "kaddy"
      "app.kubernetes.io/managed-by" = "opentofu"
    }
  }

  data = {
    AUTH_GITHUB_CLIENT_ID     = var.auth_github_client_id
    AUTH_GITHUB_CLIENT_SECRET = var.auth_github_client_secret
  }

  type = "Opaque"

  lifecycle {
    precondition {
      condition     = length(var.auth_github_client_id) > 0 && length(var.auth_github_client_secret) > 0
      error_message = "TF_VAR_auth_github_client_id and TF_VAR_auth_github_client_secret required when apply_secret=true."
    }
    precondition {
      condition     = length(var.kubeconfig_path) > 0
      error_message = "TF_VAR_kubeconfig_path required when apply_secret=true."
    }
    precondition {
      condition     = !can(regex("127\\.0\\.0\\.1|localhost", local.oauth_callback_url))
      error_message = "oauth_callback_url must not be localhost — GSK uses portal.lab only."
    }
  }
}

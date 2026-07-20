# Portal.lab Backstage — GitHub OAuth contract + Secret wiring.
#
# Classic OAuth Apps cannot be created via the GitHub API / terraform-provider-
# github. Create the app with hack/portal/create-github-app-manifest.sh (or the
# GitHub UI), then:
#
#   export TF_VAR_auth_github_client_id='…'
#   export TF_VAR_auth_github_client_secret='…'
#   export KUBECONFIG=.state/gsk/kubeconfig
#   tofu -chdir=stacks/github/portal-oauth apply
#
# Or seal into GitOps: deploy/secrets/portal/backstage-github.enc.yaml (SOPS).

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
  # Uses KUBECONFIG / in-cluster. Offline validate uses -backend=false and does
  # not need a live API when plan is skipped; apply is live-only.
  config_path = var.kubeconfig_path
}

variable "kubeconfig_path" {
  type        = string
  description = "Path to GSK kubeconfig (repo-relative .state/gsk/kubeconfig at apply time)."
  default     = ""
}

variable "auth_github_client_id" {
  type        = string
  description = "GitHub OAuth App / App-Manifest client_id for portal.lab Backstage."
  sensitive   = true
  default     = ""
}

variable "auth_github_client_secret" {
  type        = string
  description = "GitHub OAuth App / App-Manifest client_secret for portal.lab Backstage."
  sensitive   = true
  default     = ""
}

variable "apply_secret" {
  type        = bool
  description = "When true, create/update Secret portal/backstage-github. Requires non-empty client id/secret + kubeconfig."
  default     = false
}

locals {
  homepage_url = "https://portal.lab.platformrelay.dev"
  # Exact Authorization callback URL Backstage github provider redirects to.
  oauth_callback_url = "https://portal.lab.platformrelay.dev/api/auth/github/handler/frame"
  oauth_app_name     = "kaddy-portal-lab"
  oauth_app_desc     = "kaddy Backstage portal.lab (GSK) — GitHub sign-in only"
  create_url_org     = "https://github.com/organizations/PlatformRelay/settings/applications/new"
  create_url_user    = "https://github.com/settings/applications/new"
}

output "homepage_url" {
  value       = local.homepage_url
  description = "GitHub OAuth App Homepage URL"
}

output "oauth_callback_url" {
  value       = local.oauth_callback_url
  description = "GitHub OAuth App Authorization callback URL (must match exactly)"
}

output "oauth_app_name" {
  value = local.oauth_app_name
}

output "create_urls" {
  value = {
    org  = local.create_url_org
    user = local.create_url_user
  }
  description = "Manual create URLs when not using the App Manifest script"
}

output "operator_checklist" {
  value = <<-EOT
    1. Prefer: bash hack/portal/create-github-app-manifest.sh
       (opens GitHub App Manifest for PlatformRelay; captures client_id/secret).
    2. Or create a classic OAuth App at ${local.create_url_org} with:
         Application name: ${local.oauth_app_name}
         Homepage URL:     ${local.homepage_url}
         Callback URL:     ${local.oauth_callback_url}
    3. Apply secret:
         TF_VAR_auth_github_client_id=… TF_VAR_auth_github_client_secret=… \
         TF_VAR_apply_secret=true TF_VAR_kubeconfig_path=.state/gsk/kubeconfig \
         tofu -chdir=stacks/github/portal-oauth apply
    4. Restart Backstage: kubectl -n portal rollout restart deploy/backstage
  EOT
}

resource "kubernetes_secret_v1" "backstage_github" {
  count = var.apply_secret ? 1 : 0

  metadata {
    name      = "backstage-github"
    namespace = "portal"
    labels = {
      "owner"                      = "platform-team"
      "service"                    = "portal"
      "part-of"                    = "kaddy"
      "managed-by"                 = "opentofu"
      "app.kubernetes.io/name"     = "backstage-github"
      "app.kubernetes.io/part-of"  = "kaddy"
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
      error_message = "TF_VAR_auth_github_client_id and TF_VAR_auth_github_client_secret must be set when apply_secret=true."
    }
    precondition {
      condition     = length(var.kubeconfig_path) > 0
      error_message = "TF_VAR_kubeconfig_path must point at the GSK kubeconfig when apply_secret=true."
    }
  }
}

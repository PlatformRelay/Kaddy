# Portal Backstage GitHub OAuth — desired-state + secret wiring.
#
# LIMITATION (plain): GitHub has NO public API to create classic OAuth Apps, so
# the Terraform GitHub provider cannot create one either
# (integrations/terraform-provider-github#786). This stack therefore:
#   1. Declares the Homepage + Authorization callback URLs as outputs (source of
#      truth for the operator / GitHub UI).
#   2. Applies Secret portal/backstage-github from sensitive TF vars (never in
#      git plaintext) once the operator has produced client id/secret.
#
# Preferred create path (GSK portal.lab only):
#   docs/runbooks/portal-github-oauth.md — paste Homepage + Authorization
#   callback for https://portal.lab.platformrelay.dev into the org OAuth App /
#   GitHub App UI, then wire with hack/portal/wire-github-oauth-secret.sh.
#   hack/portal/create-github-app-manifest.sh is DEPRECATED (exits 2; localhost
#   create-redirect must not become the GSK callback).
stack {
  name        = "github-portal-oauth"
  description = "Backstage portal.lab GitHub OAuth callback contract + K8s secret wiring (OAuth App itself is UI/manifest — no GitHub API)."
  id          = "e10-github-portal-oauth"
  tags        = ["github", "portal", "oauth", "e10"]
}

globals {
  service     = "portal"
  name_suffix = ""
  # No S3 backend for this tiny secret-wiring stack — local state is fine; the
  # secret also lives in SOPS (deploy/secrets/portal/backstage-github.enc.yaml).
  backend = "local"
}

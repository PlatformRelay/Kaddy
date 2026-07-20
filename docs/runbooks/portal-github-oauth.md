# Runbook — GitHub OAuth for portal.lab Backstage (GSK)

**Host:** `https://portal.lab.platformrelay.dev`  
**Provider:** Backstage `auth.providers.github` (GitHub-only; no guest)  
**Stack:** [`stacks/github/portal-oauth/`](../../stacks/github/portal-oauth/)  
**Helper:** [`hack/portal/create-github-app-manifest.sh`](../../hack/portal/create-github-app-manifest.sh)

## Exact GitHub App / OAuth App fields

| Field | Value |
| --- | --- |
| Homepage URL | `https://portal.lab.platformrelay.dev` |
| Authorization callback URL | `https://portal.lab.platformrelay.dev/api/auth/github/handler/frame` |

Use **`portal.lab.platformrelay.dev`**, not `platform-relay.com` (that hostname does not resolve).

## Why not Terraform `github_oauth_app`?

GitHub exposes **no public API** to create classic OAuth Apps, so
`integrations/terraform-provider-github` cannot create them
([#786](https://github.com/integrations/terraform-provider-github/issues/786)).
The OpenTofu stack therefore owns the **URL contract + Secret wiring** only.

## Preferred create path (one click)

```bash
# From repo root — opens a browser form, captures client_id/secret, applies
# Secret portal/backstage-github, optionally writes SOPS ciphertext.
bash hack/portal/create-github-app-manifest.sh
```

This uses the [GitHub App Manifest](https://docs.github.com/en/apps/sharing-github-apps/registering-a-github-app-from-a-manifest)
flow (org: **PlatformRelay**). The resulting `client_id` / `client_secret` work
with Backstage's github provider. After creation, confirm the App's **User
authorization callback URL** is exactly the Authorization callback URL above
(org Settings → GitHub Apps → kaddy-portal-lab).

## Manual classic OAuth App

1. Open <https://github.com/organizations/PlatformRelay/settings/applications/new>
2. Paste the Homepage + Authorization callback URLs from the table above.
3. Apply secrets:

```bash
export KUBECONFIG=.state/gsk/kubeconfig
export TF_VAR_kubeconfig_path="$KUBECONFIG"
export TF_VAR_auth_github_client_id='…'
export TF_VAR_auth_github_client_secret='…'
export TF_VAR_apply_secret=true
tofu -chdir=stacks/github/portal-oauth init
tofu -chdir=stacks/github/portal-oauth apply
kubectl -n portal rollout restart deploy/backstage
```

Or encrypt for GitOps (never commit plaintext):

```bash
# edit deploy/secrets/portal/backstage-github.enc.yaml via sops
sops deploy/secrets/portal/backstage-github.enc.yaml
```

## Prove

```bash
# Backend: guest gone, github redirects to github.com with the portal callback
curl -sS -o /dev/null -w '%{http_code}\n' https://portal.lab.platformrelay.dev/api/auth/guest/start
# expect 404
curl -sS -D- -o /dev/null \
  'https://portal.lab.platformrelay.dev/api/auth/github/start?env=production' | grep -i '^location:'
# location must include redirect_uri=…/api/auth/github/handler/frame

# Browser: https://portal.lab.platformrelay.dev/login → Sign in with GitHub
```

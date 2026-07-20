# Runbook — GitHub OAuth for portal.lab Backstage (**GSK only**)

**Host:** `https://portal.lab.platformrelay.dev`  
**Stack:** [`stacks/github/portal-oauth/`](../../stacks/github/portal-oauth/)  
**Wire script:** [`hack/portal/wire-github-oauth-secret.sh`](../../hack/portal/wire-github-oauth-secret.sh)

## Exact fields (paste into GitHub)

| Field | Value |
| --- | --- |
| Homepage URL | `https://portal.lab.platformrelay.dev` |
| Authorization callback URL | `https://portal.lab.platformrelay.dev/api/auth/github/handler/frame` |

**Do not use** `http://127.0.0.1:8765/callback`, kind-local hosts, or `platform-relay.com`.

If you previously ran an App Manifest helper, that localhost URL was only a
one-shot **create** redirect. Edit the App under
[PlatformRelay GitHub Apps](https://github.com/organizations/PlatformRelay/settings/apps)
and set **User authorization callback URL** to the Authorization callback above.

## Create / fix app

1. **Classic OAuth App (preferred for clarity):**  
   <https://github.com/organizations/PlatformRelay/settings/applications/new>
2. Or fix an existing **GitHub App** at  
   <https://github.com/organizations/PlatformRelay/settings/apps>

## Wire secrets to GSK

```bash
export KUBECONFIG=.state/gsk/kubeconfig
AUTH_GITHUB_CLIENT_ID='…' AUTH_GITHUB_CLIENT_SECRET='…' \
  bash hack/portal/wire-github-oauth-secret.sh
```

## Prove (authorize must be portal.lab)

```bash
curl -sSI 'https://portal.lab.platformrelay.dev/api/auth/github/start?env=production' | grep -i '^location:'
# Location must include:
#   redirect_uri=…portal.lab.platformrelay.dev/api/auth/github/handler/frame
# and must NOT include 127.0.0.1 or localhost
```

Then open `https://portal.lab.platformrelay.dev/login` and sign in with GitHub.

## TF limitation

GitHub has **no API** to create classic OAuth Apps, so OpenTofu only owns the
URL contract + Secret apply (`stacks/github/portal-oauth`).

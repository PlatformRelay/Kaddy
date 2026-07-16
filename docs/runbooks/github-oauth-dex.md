# Runbook — GitHub OAuth for Dex (IaC)

**Org:** [PlatformRelay](https://github.com/PlatformRelay)  
**Issuer (kind lab, live):** `https://dex.kaddy.local:30443`  
**Issuer (phase 2, public):** `https://dex.platformrelay.dev/`  
**ADR:** [0107](../adr/0107-identity-dex.md) · [0110](../adr/0110-secrets-sops-age.md) · **Decision:** D-018/D-020

Secrets live in git as SOPS-encrypted manifests rendered by the Argo CD
repo-server KSOPS plugin — never applied by hand. The ONE root secret is the
operator age private key (`argocd/sops-age`, created by `task bootstrap:e1d`
from `~/.config/sops/age/keys.txt`); everything downstream of it is
encrypted under `deploy/secrets/`.

---

## 1. Create GitHub OAuth App (one-time, operator UI)

In [PlatformRelay org settings](https://github.com/organizations/PlatformRelay/settings/applications):

| Field | kind lab (live) | phase 2 (public) |
| --- | --- | --- |
| Application name | `kaddy-dex` (lab) | `kaddy-dex` |
| Homepage URL | `https://dex.kaddy.local:30443` | `https://dex.platformrelay.dev` |
| Authorization callback URL | `https://dex.kaddy.local:30443/callback` | `https://dex.platformrelay.dev/callback` |

GitHub OAuth apps allow exactly ONE callback URL and match it **including
the port** — for the local lab the app's callback must be the
`dex.kaddy.local:30443` one (switch it when phase 2 goes public, or use a
second OAuth app).

Record **Client ID** and generate **Client secret**.

Optional: create teams `platform-admins` / `platform-readonly` in the org —
`argocd-rbac-cm` already maps `PlatformRelay:platform-admins` → admin
(full team-based RBAC is E10).

---

## 2. Encrypt credentials with SOPS (IaC)

Operator holds the age private key (`~/.config/sops/age/keys.txt`; on macOS
export `SOPS_AGE_KEY_FILE` explicitly — sops otherwise looks in
`~/Library/Application Support`). Plaintext never committed.

```bash
# From repo root — edit the encrypted file in place
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
sops deploy/secrets/identity/dex-github.enc.yaml
```

Expected decrypted shape (placeholders, never real values):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: dex-github-oauth
  namespace: identity
type: Opaque
stringData:
  client-id: "<GITHUB_APP_CLIENT_ID>"
  client-secret: "<GITHUB_APP_CLIENT_SECRET>"
```

Commit only the **encrypted** file. `.sops.yaml` pins the age recipient for
`deploy/secrets/**`. The sibling files `dex-clients.enc.yaml` (Dex side) and
`../argocd/argocd-oidc-client.enc.yaml` (argocd side) carry the SAME random
Argo CD static-client secret — regenerate both together if rotating.

Local dev values may also live in gitignored `.envrc`
(`GITHUB_APP_CLIENT_ID`, `GITHUB_APP_CLIENT_SECRET`) for encrypting — not
for runtime bootstrap.

---

## 3. Render + deploy chain (GitOps)

1. `task bootstrap:e1d` — age-key root secret, KSOPS on the repo-server
   (pinned `viaductoss/ksops`), Dex Gateway listener + Certificate,
   `argocd-cm` OIDC + `argocd-rbac-cm` (all committed in
   `deploy/bootstrap/`), `argocd-server` hostAliases so it reaches the
   issuer URL in-cluster.
2. The `identity` Application (automated) renders `deploy/identity/` with
   `kustomize --enable-alpha-plugins --enable-exec`; the KSOPS generator
   decrypts `deploy/secrets/{identity,argocd}/*.enc.yaml` into live Secrets.
3. `argocd app sync policies --core` — identity netpol baseline
   (`deploy/policies/network/identity.yaml`, manual-sync by design).

Dex consumes the credentials as env (`secretKeyRef` →
`dex-github-oauth`/`dex-clients`); config is
`deploy/identity/dex/configmap.yaml` (golden connector:
`tests/fixtures/dex-github-connector-golden.yaml`).

---

## 4. Reachability and TLS (kind lab)

The Dex issuer shares the ONE loopback-mapped HTTPS port with the Argo CD
UI via SNI (`https-dex` listener on the argocd Gateway, kaddy-local-ca
cert):

- **Operator browser:** add `127.0.0.1 dex.kaddy.local` to `/etc/hosts`,
  then trust or bypass the local-CA cert for `https://dex.kaddy.local:30443`.
- **argocd-server (in-cluster):** hostAliases pin `dex.kaddy.local` to the
  node InternalIP (nodePort 30443); `oidc.tls.insecure.skip.verify` is set
  because the local CA is not in the argocd trust store — phase 2 (public
  DNS + Let's Encrypt per section 5) drops that key.

Phase 2 (public): Cloudflare A record `dex.platformrelay.dev` → Gateway LB
IP, cert-manager DNS-01 TLS on the Dex HTTPRoute.

---

## 5. Verify

```bash
task test:smoke:e1d       # full E1d live bundle
curl -sk --resolve dex.kaddy.local:30443:127.0.0.1 \
  https://dex.kaddy.local:30443/.well-known/openid-configuration | jq .issuer
# → "https://dex.kaddy.local:30443"
```

---

## 6. Interactive login (operator step — not scriptable headless)

The smoke suite proves the full redirect chain up to
`github.com/login/oauth/authorize` with the right `client_id`; the consent
click is yours:

1. Open `https://127.0.0.1:30443` → **Log in via GitHub (Dex)**.
2. GitHub login + org consent (membership in **PlatformRelay** required;
   membership visibility must allow the OAuth app to see the org).
3. Expect: operator (`konih`) lands as **role:admin**; any other org member
   is **role:readonly** (`argocd-rbac-cm`).
4. Break-glass: the local `admin` user stays enabled
   (`argocd admin initial-password -n argocd`, rotate after use).

---

## What we do **not** do

- Imperative Secret creation for OAuth credentials (forbidden — SOPS +
  KSOPS render the committed ciphertext; the ONLY imperative Secret is the
  age key itself, by definition of the root of trust)
- Keycloak (dropped, ADR-0107 / D-018)
- MetalLB (edge is Cilium — ADR-0104, D-019)

# Runbook — GitHub OAuth for Dex (IaC)

**Org:** [PlatformRelay](https://github.com/PlatformRelay)  
**Issuer:** `https://dex.platformrelay.dev/`  
**Callback:** `https://dex.platformrelay.dev/callback`  
**ADR:** [0110](../adr/0110-secrets-sops-age.md) · **Decision:** D-020

Secrets live in git as SOPS-encrypted manifests — **not** imperative `kubectl create secret`.

---

## 1. Create GitHub OAuth App (one-time, operator UI)

In [PlatformRelay org settings](https://github.com/organizations/PlatformRelay/settings/applications):

| Field | Value |
| --- | --- |
| Application name | `kaddy-dex` (lab) |
| Homepage URL | `https://dex.platformrelay.dev` |
| Authorization callback URL | `https://dex.platformrelay.dev/callback` |

Record **Client ID** and generate **Client secret**.

Optional: create teams `platform-admins` and `platform-readonly` in the org for Dex RBAC mapping.

---

## 2. Encrypt credentials with SOPS (IaC)

Operator holds age private key (`SOPS_AGE_KEY` or `~/.config/sops/age/keys.txt`). Plaintext never committed.

```bash
# From repo root — edit encrypted file in place
sops deploy/secrets/identity/dex-github.enc.yaml
```

Expected decrypted shape (example):

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

Commit only the **encrypted** file. `.sops.yaml` defines age recipients.

Local dev values may also live in gitignored `.envrc` (`GITHUB_APP_CLIENT_ID`, `GITHUB_APP_CLIENT_SECRET`) for encrypting — not for runtime bootstrap.

---

## 3. Dex connector (GitOps)

Golden connector in `deploy/identity/dex/` (or Helm values):

```yaml
connectors:
  - type: github
    id: github
    name: GitHub
    config:
      clientID: $GITHUB_CLIENT_ID
      clientSecret: $GITHUB_CLIENT_SECRET
      redirectURI: https://dex.platformrelay.dev/callback
      orgs:
        - name: PlatformRelay
          teams:
            - platform-admins
            - platform-readonly
```

Deployment mounts `dex-github-oauth` Secret synced via Argo CD + KSOPS from `deploy/secrets/identity/dex-github.enc.yaml`.

---

## 4. DNS and TLS

1. Platform Gateway must have an address (Cilium LB-IPAM phase 1 — see [driving-range-handoff.md](./driving-range-handoff.md)).
2. Cloudflare A record: `dex.platformrelay.dev` → Gateway LB IP.
3. cert-manager DNS-01 (E3) issues TLS for Dex HTTPRoute.

---

## 5. Verify

```bash
curl -s https://dex.platformrelay.dev/.well-known/openid-configuration | jq .issuer
# → "https://dex.platformrelay.dev/"
```

Open Argo CD UI → login via GitHub → confirm org membership enforced.

---

## What we do **not** do

- `kubectl create secret generic dex-github-oauth ...` (forbidden — use SOPS + GitOps)
- Keycloak
- MetalLB (edge is Cilium — ADR-0104, D-019)

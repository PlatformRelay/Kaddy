# Design — E1d Identity (Dex + GitHub)

## Layout

```text
.sops.yaml
deploy/secrets/identity/dex-github.enc.yaml   # SOPS-encrypted OAuth Secret (IaC)
deploy/identity/
  dex/               # Deployment + ConfigMap + Service (GitOps)
```

## Bootstrap sequence (IaC only)

1. Operator creates GitHub OAuth app in **[PlatformRelay](https://github.com/PlatformRelay)** org
   (see `docs/runbooks/github-oauth-dex.md`).
2. Operator encrypts client ID/secret into `deploy/secrets/identity/dex-github.enc.yaml` via `sops`.
3. E3/E1c: Argo CD repo-server KSOPS plugin decrypts at sync time.
4. E1d-S01: Sync Dex via GitOps — GitHub connector with `orgs: [PlatformRelay]`.
5. E1d-S02: Patch `argocd-cm` `oidc.config` + `argocd-rbac-cm` group mappings.
6. E1d-S04: Grafana `grafana.ini` oauth section via Helm values.

**No** `kubectl create secret` in runbooks or bootstrap scripts.

## Dex config sketch (GitHub connector)

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

Static clients: `argocd`, `grafana`, `backstage` (E10).

## Runbook

`docs/runbooks/github-oauth-dex.md` — OAuth app, SOPS encrypt, team → group mapping.

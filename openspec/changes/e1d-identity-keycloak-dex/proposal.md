# Proposal — E1d Identity (Dex + GitHub)

## Why

Platform control planes (Argo CD, Grafana, Backstage) must not be anonymously reachable on a public
LoadBalancer IP. Dex provides a single OIDC issuer; GitHub OAuth supplies real user authentication
without running Keycloak or Postgres (D-018).

## What

- Deploy Dex via GitOps with **GitHub connector** scoped to **[PlatformRelay](https://github.com/PlatformRelay)**.
- OAuth client credentials in **SOPS-encrypted** `deploy/secrets/identity/dex-github.enc.yaml` (D-020).
- Wire Argo CD and Grafana to Dex OIDC; map GitHub teams to RBAC groups.
- Document GitHub OAuth app setup (operator one-time UI step only).
- NetworkPolicy baseline for `identity` namespace.

## Non-goals

- Keycloak or any local user database.
- Kubernetes API OIDC (optional stretch only).

## Dependencies

- **E3-S01** — app-of-apps includes `identity` Application.
- **E4-S03** — TLS at Gateway for public Dex issuer URL (`https://dex.<host>/`).

## Links

[ADR-0107](../../../docs/adr/0107-identity-keycloak-dex.md) · [ADR-0110](../../../docs/adr/0110-secrets-sops-age.md) · D-018 · D-020

## Counterpoints considered

- Keycloak + Dex — rejected in D-018 for ops weight.
- Dex staticPasswords — rejected; weak demo signal.

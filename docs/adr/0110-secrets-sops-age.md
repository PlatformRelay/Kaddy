# ADR-0110: Secrets — SOPS + age, encrypted in git (IaC)

**Theme:** 01 · Foundations · **Status:** Current · **Aligns with:** [driving-range ADR-0202](../../driving-range/docs/adr/0202-secrets-sops-age.md)

## Context

GitOps manifests need secrets (Dex GitHub OAuth, gridscale API tokens for Crossplane, etc.). Storing
them via imperative `kubectl create secret` is not IaC and does not survive rebuild-from-git.

## Decision

**SOPS with `age`.** Secret values are committed as SOPS-encrypted YAML under `deploy/secrets/`;
the age private key is on the operator host only (never in git).

- `.sops.yaml` at repo root pins age recipients per path.
- Encrypt only `data` / `stringData` (`encrypted_regex`) so structural diffs stay reviewable.
- Argo CD applies via **KSOPS plugin** on the repo-server (E3/E1c).
- `.envrc` holds plaintext for local `sops -e` / OpenTofu bootstrap only — not the runtime source of truth.

## Scope (minimum)

| Secret | Path (example) | Consumer |
| --- | --- | --- |
| Dex GitHub OAuth | `deploy/secrets/identity/dex-github.enc.yaml` | Dex Helm values / E1d |
| gridscale API (phase 2) | `deploy/secrets/crossplane/gridscale.enc.yaml` | Crossplane ProviderConfig |

## Counterpoints

- **External Secrets Operator + cloud SM** — no backing store on driving-range; revisit on GSK if gridscale exposes a secret manager API worth using.
- **Sealed Secrets** — cluster-bound; fights rebuild-from-scratch. age keys are portable.

## Consequences

- E1c delivers KSOPS + `.sops.yaml`; E1d Dex secret is encrypted in git, not hand-applied.
- Operator backs up the age private key out-of-band.

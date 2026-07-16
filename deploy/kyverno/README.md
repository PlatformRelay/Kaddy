# deploy/kyverno — vendored, pinned Kyverno install (E1c cutover step 1)

Vendored upstream install manifest for **Kyverno v1.18.2** — the version is
pinned to match the CLI (`kyverno test`, D-024) and the CI install
(`.github/workflows/chainsaw.yaml`). Mirrors the E7 `deploy/rollouts/`
pattern: vendor + pin, GitOps-managed by a child Application
(`deploy/apps/kyverno.yaml`), synced into the `kyverno` namespace.

## Source

```sh
curl -sSL -o deploy/kyverno/install.yaml \
  https://github.com/kyverno/kyverno/releases/download/v1.18.2/install.yaml
```

**Local delta against upstream (keep when bumping):**

- `replicas: 1` set explicitly on all four controller Deployments (upstream
  ships the field empty/null). One replica each is right for the 8GB
  single-node lab (matches the kps/Loki capacity trims), and the explicit
  value avoids null-field diff noise under server-side apply.
- Empty `labels: {}` / `annotations: {}` maps stripped from the eleven
  `policies.kyverno.io` CRDs: the apiserver drops empty maps under
  server-side apply, which otherwise leaves the Application perpetually
  OutOfSync on a `labels: {}` no-op diff (verified live).

Everything else is verbatim upstream: the controllers already ship modest
requests (~100m/128Mi) and restricted-PSS securityContexts, so no resource
trims were needed.

## What it installs

Namespace `kyverno`; 22 CRDs; admission-, background-, cleanup- and
reports-controllers (1 replica each); RBAC; metrics Services. Webhook
configurations are created **at runtime** by the admission controller
(`--autoUpdateWebhooks=true`), not by this manifest.

## Relationship to deploy/policies/

This directory installs the **engine** only. The ClusterPolicies and the
NetworkPolicy baseline live in `deploy/policies/` and sync via the separate,
manual-sync `policies` Application — see `deploy/policies/README.md` for the
cutover runbook and the enforcement matrix.

## Version bumps

Renovate can track the release URL above; re-vendor, re-apply the local
delta (replicas), and let the `kyverno` Application sync (ServerSideApply —
the CRDs exceed client-side apply annotation limits).

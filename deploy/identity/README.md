# identity — Dex OIDC issuer (E1d, LIVE)

GitOps root of the `identity` Application (`deploy/apps/identity.yaml`,
automated sync). Kustomize + **KSOPS**: `secret-generator.yaml` decrypts the
SOPS-encrypted Secrets under `deploy/secrets/{identity,argocd}/` on the
Argo CD repo-server at render time (ADR-0110) — this app is the proof that
the KSOPS chain works, and Dex (ADR-0107) is its first consumer.

| Piece | File |
| --- | --- |
| Namespace (confidential) | `namespace.yaml` |
| Dex config + GitHub connector | `dex/configmap.yaml` (golden: `tests/fixtures/dex-github-connector-golden.yaml`) |
| Dex Deployment (pinned, nonroot) | `dex/deployment.yaml` |
| Service :5556/:5558 | `dex/service.yaml` |
| Issuer route (SNI dex.kaddy.local) | `dex/httproute.yaml` → `https-dex` listener (deploy/bootstrap/argocd.yaml) |

Prerequisites on a fresh cluster: `task bootstrap:e1d` (age-key root secret
`argocd/sops-age` + repo-server KSOPS plugin + argocd OIDC wiring), then the
manual `argocd app sync policies --core` for the identity netpols. Without
the root secret the app degrades to a render error — never to plaintext.

Runbook: `docs/runbooks/github-oauth-dex.md` (OAuth app, rotation,
interactive login). Smoke: `task test:smoke:e1d`.

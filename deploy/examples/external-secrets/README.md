# External Secrets examples (phase 2) — **not synced**

Offline **examples** for REQ-E1c-S04. These manifests are **not** referenced by
`deploy/apps/` app-of-apps and must **not** be applied on the kind lab until
External Secrets Operator is installed on GSK (phase 2).

| File | Role |
| --- | --- |
| `cluster-secret-store.yaml` | Sample `ClusterSecretStore` (Kubernetes provider) |
| `external-secret-gridscale.yaml` | Sample `ExternalSecret` → `openstack-creds` |

See [`docs/runbooks/external-secrets-gridscale.md`](../../../docs/runbooks/external-secrets-gridscale.md).
Do **not** put real API tokens here.

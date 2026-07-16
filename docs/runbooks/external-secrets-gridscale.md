# Runbook — External Secrets pattern for gridscale provider creds

**Phase:** 2 (GSK / provider-gridscale) — **offline pattern only**  
**REQ:** E1c-S04-01 · E1c-S04-02  
**ADR:** [0110](../adr/0110-secrets-sops-age.md) · [0105](../adr/0105-crossplane-self-service.md)

This runbook documents how **External Secrets Operator (ESO)** will sync
gridscale API credentials into the cluster for Crossplane `ProviderConfig`.
It does **not** install ESO on the kind lab and does **not** change the live
Dex identity path.

Sample manifests (not synced by app-of-apps):
[`deploy/examples/external-secrets/`](../../deploy/examples/external-secrets/).

---

## Complement, not replace — SOPS/KSOPS stays for Dex

| Secret class | Mechanism | Why |
| --- | --- | --- |
| Dex GitHub OAuth, other git-rebuild secrets | **SOPS + age** in `deploy/secrets/`, rendered by Argo CD **KSOPS** | IaC rebuild-from-git; portable age key; no cloud secret manager required on kind |
| gridscale API token for Crossplane (phase 2) | **ESO** `ClusterSecretStore` + `ExternalSecret` → Secret `openstack-creds` in `crossplane-system` | Provider creds often live in an operator vault / SM; avoid committing long-lived cloud tokens even encrypted if a store exists |

ESO **complements** SOPS/KSOPS: identity and other platform secrets stay on the
ADR-0110 path. ESO is the phase-2 option when a backing store (Kubernetes
bootstrap Secret out-of-band, or a cloud SM) is available. Until ESO is
installed on GSK, the ADR-0110 fallback (`deploy/secrets/crossplane/gridscale.enc.yaml`)
remains valid.

**Do not** migrate Dex OAuth off KSOPS for this pattern.

---

## Target shape (REQ-E1c-S04-02)

When ESO is installed and the sample is applied (phase 2 only):

1. A `ClusterSecretStore` points at the chosen provider (example uses the
   Kubernetes provider reading an **out-of-band** bootstrap Secret — never
   committed).
2. An `ExternalSecret` in `crossplane-system` reconciles.
3. Kubernetes Secret **`openstack-creds`** exists in **`crossplane-system`**
   with keys Crossplane `ProviderConfig` will `secretRef` (e.g. `token`,
   `uuid`). Name kept as `openstack-creds` for REQ/spec stability; contents
   are gridscale API credentials.

```text
[backing store / bootstrap Secret]
        │
        ▼
 ClusterSecretStore  (cluster-scoped)
        │
        ▼
 ExternalSecret  (ns: crossplane-system)
        │
        ▼
 Secret/openstack-creds  ← ProviderConfig.secretRef
```

---

## Sample apply (phase 2 — do not run on kind lab)

```bash
# Prerequisites: ESO installed; bootstrap Secret created out-of-band
# (never committed). Then:
kubectl apply -f deploy/examples/external-secrets/
kubectl -n crossplane-system get externalsecret,secret openstack-creds
```

On kind today: leave these files as documentation. Live smoke for sync is
`tests/smoke/e1c-s04-02.sh` (deferred until ESO + E6g).

---

## Invariants

- No `GRIDSCALE_TOKEN` / plaintext `token:` credential literals under `deploy/`.
- `deploy/examples/` is **not** an Argo CD Application path.
- Identity KSOPS (`deploy/secrets/identity/*`) is untouched by this pattern.
- Verify offline: `bash tests/smoke/e1c-s04-01.sh` · `task scrub` · `gitleaks detect`.

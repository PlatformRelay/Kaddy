# Runbook — Backstage portal: self-serve a new site (E10)

Stand up the kaddy **portal / IDP** (Backstage) and walk the self-service path:
a developer fills an **auto-generated** form → a **pull request** with a `Website`
XR → merge → Crossplane reconciles → the site is live, all audited in Git. Then
the **auto-gen money-shot**: live-edit the `Website` XRD, refresh, and the form
already has the new field — *the portal is a projection of the platform API, not
a copy of it* (ADR-0109/0111, D-028/029).

## Framing — offline-authored, live bring-up DEFERRED (live-deferred)

E10 is authored to the phase-2 bar: GitOps manifests + config + skip-gated tests
that prove the contract **offline**. The **running Backstage is a live-cycle
step** (deferred, honestly flagged here): it needs a custom
`ghcr.io/platformrelay/kaddy-portal` image that compiles in the pinned
TeraSky/community plugins (`deploy/portal/backstage/plugin-versions.md`) — a
build that is **not-yet-done**. The **Backstage app source + Dockerfile** that
build that image live in the separate repo **`github.com/PlatformRelay/kaddy-portal`**
(private); kaddy deploys exactly the image its CI builds + pushes. Until that
image is built and published, the portal App (`deploy/apps/portal.yaml`) lands
only the namespace/RBAC/netpol/cert **skeleton**; the workload itself is not
deployed. Everything below the "Live bring-up" heading is the deferred cycle.

The offline contract is proven by:

```bash
task test:smoke:e10        # manifests + config + PR invariant + read-only RBAC
```

## What lands offline (proven now)

- `deploy/portal/backstage/` — `app-config.yaml` (Dex OIDC, ingestor, read-path
  plugins, techdocs), `values.yaml` (pinned chart/image), `catalog/`, `rbac/`.
- `deploy/apps/portal.yaml` + `deploy/apps/projects/portal.yaml` — the GitOps
  App + closed-list AppProject (whitelists the `portal` ns + the read-path
  ClusterRole/ClusterRoleBinding).
- The `Website` XRD (`deploy/crossplane/xrd-website.yaml`) annotated with
  `terasky.backstage.io/target-path` + `create-kustomization-file` so scaffolded
  XRs land under `deploy/workloads/` where ArgoCD watches.

---

## Live bring-up (DEFERRED — the live cycle)

> Costs a cluster + a built image. Do this only during a live demo prep.

### 1. Build + publish the portal image

The Backstage app source + Dockerfile live in **`github.com/PlatformRelay/kaddy-portal`**
(private). Its CI builds a Backstage app that compiles in the plugins pinned in
`deploy/portal/backstage/plugin-versions.md` (kubernetes-ingestor,
crossplane-resources, kubernetes, argocd, techdocs), tags it
`ghcr.io/platformrelay/kaddy-portal:0.1.0`, and pushes. Then wire the Helm chart
grandchild (`backstage.github.io/charts`, pinned `targetRevision`) into the
portal App so kaddy deploys exactly that image (pin the tag/digest in
`deploy/portal/backstage/values.yaml`).

### 2. OIDC — Dex

The portal authenticates via **Dex OIDC only, no guest access** (ADR-0107). Add
a `backstage` static client to Dex (`deploy/identity/dex/configmap.yaml`) with
redirect `https://portal.kaddy.local:30443/api/auth/oidc/handler/frame`, and
KSOPS-render the `backstage-oidc` Secret (client secret — **never in git**). An
unauthenticated request to a protected route redirects to Dex → GitHub. See
[github-oauth-dex.md](github-oauth-dex.md).

### 3. Sync + wait for Backstage

```bash
task bootstrap:e3                                   # app-of-apps picks up the portal App
kubectl -n portal rollout status deploy/backstage --timeout=300s
```

### 4. Scaffold a new site (write path — PR, never a cluster mutation)

1. Open the portal → **Create** → the **auto-generated** `Website` template
   (kubernetes-ingestor built it from the XRD's OpenAPI schema — `image`, `port`,
   `path`, `replicas`, `variant`; required fields + enums + validations come from
   the schema, no hand-written template).
2. Fill the form → the ingestor's `publishPhase` opens a **pull request** against
   `deploy/workloads/<namespace>/website/` (with a `kustomization.yaml`). The
   portal holds **no cluster credential** on this path — it authors Git.
3. **Merge** the PR → ArgoCD syncs → Crossplane **reconciles** the `Website` XR.

### 5. Reconcile → the site is live

The Composition renders Deployment + Service + **HTTPRoute** + **Certificate** +
**ServiceMonitor**; the site returns 200. (Chainsaw:
`tests/chainsaw/portal/scaffolded-xr-reconciles.yaml`, skip-gated offline.)

### 6. Read path — live status in-portal (read-only, D-029)

On the site's entity page:

- **crossplane-resources** — the XR → composite → managed-resource **graph**,
  per-resource YAML + events (the money-shot).
- **Kubernetes** — workload health (pods/deployments/services).
- **ArgoCD** — sync + health + deploy history.

All three read through the **read-only** `portal-read-only` ServiceAccount
(`deploy/portal/backstage/rbac/read-only-rbac.yaml` — `get/list/watch` ONLY) and
the netpol scoped to kube-apiserver + argocd-server. Verified read-only offline
by `tests/portal/read-path-rbac.sh`.

### 7. The auto-gen money-shot (E12 video surface)

```bash
# Add a field to the platform API, live:
kubectl edit xrd websites.platform.kaddy.io      # e.g. add a `tls` toggle
```

Refresh the Backstage scaffolder — **the form already has the new field**, with
no template edit. The portal is a projection of the platform API. (Chainsaw:
`tests/chainsaw/portal/xrd-field-propagates.yaml` intent; the live demo is the
proof.)

---

## Teardown

The portal is GitOps-managed; remove the portal App (or scale the Backstage
Deployment to 0). The read-only SA holds no mutating power, so nothing it touched
needs cleanup. Scaffolded sites are ordinary `Website` XRs — remove their PR'd
manifests to prune.

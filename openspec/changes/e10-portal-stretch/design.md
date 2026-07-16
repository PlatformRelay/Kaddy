# Design — E10 Portal / IDP (auto-generated from the XRD)

## Flow (write path vs read path)

```mermaid
flowchart LR
  subgraph write [Write path — Git only, no cluster creds]
    dev[Developer] --> form["Backstage form<br/>(auto-generated from Website XRD)"]
    form --> pr["publishPhase:<br/>PR to deploy/workloads/"]
    pr --> merge[Merge]
    merge --> argo[ArgoCD sync]
    argo --> xp[Crossplane reconciles Website XR]
    xp --> res["Deployment + HTTPRoute<br/>+ Certificate + ServiceMonitor"]
  end
  subgraph read [Read path — read-only creds]
    ing["kubernetes-ingestor<br/>(discovery + template-gen)"] -.reads XRDs/XRs.-> kube[(kube API)]
    graph[crossplane-resources graph] -.read-only.-> kube
    argocard[ArgoCD plugin] -.read-only.-> argoapi[(ArgoCD API)]
  end
  xp -.discovered as catalog entity.-> ing
```

**Invariant:** the write path touches **only Git**. The read path holds **read-only** credentials and
never mutates. Do not blur them (D-029).

## Layout

```
deploy/portal/backstage/
  app-config.yaml              # kubernetesIngestor + argocd + techdocs + oidc + kubernetes
  catalog/                     # ONLY static platform components (clubhouse/marshal/mulligan/scorecard)
  rbac/                        # read-only SA (get/list/watch on Website + composed GVKs) + netpol
  # NOTE: NO per-site template.yaml — the ingestor generates it from the Website XRD at runtime
tests/portal/
  ingestor-config.sh           # asserts publishPhase = PR target (L1 meta)
  catalog-entities.sh          # platform components present (L1)
tests/chainsaw/portal/
  backstage-ready.yaml         # deployment Available (L2)
  scaffolded-xr-reconciles.yaml# form → PR skeleton → applied XR reconciles (L2)
```

## Platform API (E6 — Crossplane v2 namespaced XR)

E6 ships `Website` as a **v2 namespaced XR** (Claims deprecated; the XR *is* the resource — D-027).
The portal never redefines this shape — it reads the XRD's OpenAPI schema:

```yaml
apiVersion: platform.kaddy.io/v1alpha1
kind: Website                     # namespaced XR (v2), not a v1 Claim
metadata:
  namespace: clubhouse
spec:
  hostname: clubhouse.lab.platformrelay.dev
  engine: caddy                   # or: nginx
  source: { git: https://... , path: site/ }
  track: stable
```

Composition renders: Deployment (nginx/caddy) + Service + HTTPRoute + ServiceMonitor + Certificate.

## Write path — auto-generated scaffolder (kubernetes-ingestor)

The ingestor generates one scaffolder template per `Website` XRD from its OpenAPI schema — required
fields, enums, and validations become form fields with **no second schema**. The `publishPhase` is
configured for **pull-request** targets so it opens a PR (never a direct commit / cluster mutation):

```yaml
# app-config.yaml
kubernetesIngestor:
  components:
    enabled: true
    taskRunner: { frequency: 10, timeout: 600 }
  crossplane:
    xrds:
      publishPhase:
        allowedTargets: ['github.com']
        target: github
        git:
          repoUrl: github.com?owner=PlatformRelay&repo=Kaddy
          targetBranch: main
          allowRepoSelection: false
    claims:
      ingestAllClaims: true        # live Website XRs → catalog entities
```

Per-XRD path control (so scaffolded XRs land where ArgoCD watches):

```yaml
# on the Website XRD
metadata:
  annotations:
    terasky.backstage.io/target-path: 'deploy/workloads/{namespace}/website/'
    terasky.backstage.io/create-kustomization-file: 'true'
```

> **Demo money-shot (E12 video):** live-edit the `Website` XRD to add a field, `kubectl apply`, refresh
> Backstage — the form already has it. *The portal is a projection of the platform API, not a copy.*

## Read path — visibility plugins (read-only)

| Plugin | Renders | Talks to |
| --- | --- | --- |
| `@terasky/backstage-plugin-crossplane-resources-frontend` (+ backend) | XR → composite → managed-resource graph, per-resource YAML + events (v1 **and** v2) | kube API (read-only) |
| Backstage Kubernetes plugin | Pods/Deployments/Services for the site | kube API (read-only) |
| `@backstage-community/plugin-argocd` | sync + health + deploy history on the entity | ArgoCD API (read-only) |
| CRD-docs (could) | doc.crds.dev-style `Website` API docs + example YAML | catalog |
| Kyverno policy reports (could) | in-portal policy compliance | kube API (read-only) |

ArgoCD plugin choice: the **CNCF community** plugin over Roadie's — same capability, better governance
signal. Either works.

## RBAC / security posture (D-029 — read path is a named trade)

- A **read-only** ServiceAccount in `portal`: `get/list/watch` on `websites.platform.kaddy.io`,
  composed GVKs, and core workload objects — nothing mutating. Manifest under `rbac/`.
- NetworkPolicy: `portal` → kube-apiserver and `portal` → `argocd-server` only (default-deny elsewhere).
- Third-party OSS plugins pinned + Renovate-tracked; enumerated in the E11 audit (ADR-0111).
- Smallest-trust alternative (write-path only, status via ArgoCD UI) recorded and **rejected** for this
  demo — impressiveness > minimal-trust (D-029). This is a demo for a cloud-provider role, not a bank.

## Auth

Backstage `auth.providers.oidc` → Dex issuer (ADR-0107). No guest access; `platform-*` groups map to
Backstage permissions.

## Build-vs-buy (recorded, not chosen here)

Under real time pressure: **Port** (portal) + **Humanitec** (orchestrator) buys speed at the cost of
SaaS dependency. kaddy chooses OSS for control and interview signal — ADR-0109. Auto-gen from the XRD
narrows most of the build-cost gap that would have justified buying.

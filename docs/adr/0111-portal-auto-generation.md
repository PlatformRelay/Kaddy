# ADR-0111: Portal auto-generation — templates from the XRD, read-path visibility, v2 XR

**Theme:** 01 · Foundations · **Status:** Accepted (operator decisions D-027, D-028, D-029; 2026-07-15)
**Refines:** [ADR-0109](0109-idp-portal-orchestrator.md) (portal + orchestrator),
[ADR-0105](0105-crossplane-self-service.md) (Crossplane self-service)

## Context

ADR-0109 chose Backstage (portal) + Crossplane (orchestrator), and sketched a **hand-written**
scaffolder template that opens a GitOps PR adding a `Website` claim. Research (`agent-context/research/e10-portal-wiring-and-demo-presentation.md`)
found that hand-written templates duplicate the XRD schema and drift the moment the platform API changes
— and that the ecosystem now offers a materially stronger, more impressive path. This ADR records the
three decisions that reshape E10 (and one E6 decision the portal depends on).

## Decision

### 1. Templates are auto-generated from the XRD (D-028)

Use TeraSky's **kubernetes-ingestor** plugin to generate one Backstage scaffolder template per
`Website` XRD, directly from the XRD's OpenAPI schema (required fields, enums, validations become form
fields). No second schema; no drift. The plugin also ingests live `Website` XRs into the Software
Catalog via annotations (no per-site static `catalog-info.yaml`).

The ingestor's `publishPhase` is configured for **pull-request** targets (GitHub/GitLab/Bitbucket),
verified to support PR (not just direct commit). The generated template therefore opens a PR against
`deploy/workloads/` — **preserving the invariant that the portal authors Git and never mutates the
cluster API.**

> **Projection invariant:** the portal is a *projection* of the platform API, not a copy of it. Editing
> the `Website` XRD updates the portal form automatically. This is the demo money-shot.

### 2. Write path vs read path are distinct (D-029)

| Path | Plugins | Credentials | Mutates? |
| --- | --- | --- | --- |
| **Write** (self-service) | kubernetes-ingestor template-gen + scaffolder `publishPhase` | none | No — Git PR only |
| **Read** (visibility) | crossplane-resources graph, Kubernetes, ArgoCD (community) | **read-only** SA + read-only ArgoCD account | No — read-only |

The **read path is in scope.** The in-portal XR → composite → managed-resource graph is most of the
demo's value. The trade is named and scoped, not overlooked:

- read-only RBAC: `get/list/watch` only on `websites.platform.kaddy.io` + composed/workload GVKs;
- NetworkPolicy: `portal` → kube-apiserver + argocd-server only (default-deny elsewhere);
- third-party OSS plugins pinned + Renovate-tracked + enumerated in the E11 audit.

**Rejected alternative (recorded):** write-path only (no cluster creds), status via the ArgoCD UI —
the smallest-trust option. Rejected for this demo: **impressiveness > minimal-trust.** This is a demo
for a cloud-provider platform role, not a production bank system — the visible graph wins, with the
trust surface deliberately bounded to read-only.

### 3. `Website` is a Crossplane v2 namespaced XR (D-027)

E6 ships `Website` as a **v2 namespaced XR** (`kind: Website`, namespaced) rather than a v1 Claim
(`kind: WebsiteClaim` + cluster-scoped XR). The XR *is* the resource — simpler mental model, drops the
Claim/XR duality, stronger signal. The TeraSky plugins support both v1 and v2. This amends ADR-0105 and
the E6 spec.

## Consequences

- **E10** (`e10-portal-stretch`) rewritten: S02 = ingestor config (replaces the hand-written template),
  new REQ-E10-S02-03 asserts the form adapts to XRD changes, S04 = read-path plugins + RBAC guard test.
- **E6** (`e6-crossplane-website`): `kind: WebsiteClaim` → `kind: Website` (namespaced XR); sample and
  composed-resource paths become namespace-scoped.
- **Supply chain:** kubernetes-ingestor, crossplane-resources, ArgoCD community, (optional) CRD-docs +
  Kyverno-reports plugins enter the tree — pinned, Renovate-tracked, E11-audited.
- **Demo:** the auto-gen money-shot (edit XRD → refresh → new form field) becomes an E12 video beat.

## Sources

- kubernetes-ingestor (template-gen from XRDs, PR publishPhase): <https://terasky-oss.github.io/backstage-plugins/plugins/kubernetes-ingestor/overview/>, <https://roadie.io/docs/integrations/kubernetes-ingestor/>
- crossplane-resources (graph, v1+v2): <https://terasky-oss.github.io/backstage-plugins/plugins/crossplane/overview/>
- ArgoCD community plugin: <https://github.com/backstage/community-plugins/blob/main/workspaces/argocd/plugins/argocd/README.md>
- Integration architecture + annotations: <https://vrabbi.cloud/post/integrating-backstage-with-crossplane/>

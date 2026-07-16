# Spec — E10 Portal / IDP (Backstage · auto-generated from the XRD)

Epic: E10 (cuttable) · ADR: [0109](../../../docs/adr/0109-idp-portal-orchestrator.md),
[0111](../../../docs/adr/0111-portal-auto-generation.md)  
**Depends:** E6 (`Website` XRD as **v2 namespaced XR**, D-027), E1d (OIDC), E3 (app-of-apps, cert-manager, ArgoCD)  
**Decisions:** D-027 (v2 XR) · D-028 (adopt ingestor auto-gen) · D-029 (read-path plugins in)  
**Levels:** L1 golden-file/meta · L2 Chainsaw

---

## REQ-E10-S01-01: Backstage deployed via GitOps

**Priority:** could · **Story:** E10-S01 · **Level:** L2  
**Given** `deploy/portal/backstage/` synced by Argo CD  
**When** `kubectl get deployment backstage -n portal`  
**Then** Available replicas ≥ 1; mandatory kaddy labels present  
**Test:** `tests/chainsaw/portal/backstage-ready.yaml`

**Verify:** `kubectl wait -n portal --for=condition=Available deployment/backstage --timeout=300s`

---

## REQ-E10-S01-02: Portal requires OIDC login

**Priority:** could · **Level:** L2 · **Refs:** ADR-0107  
**Given** Backstage `auth.providers.oidc` → Dex  
**When** an unauthenticated request hits a protected route  
**Then** it redirects to Dex → GitHub (no guest access to actions)  
**Test:** `tests/chainsaw/portal/portal-unauth-redirect.yaml`

**Verify:** `curl -s -o /dev/null -w '%{http_code}' https://$PORTAL_HOST/` returns 302 to Dex

---

## REQ-E10-S02-01: Scaffolder template is auto-generated from the Website XRD

**Priority:** could · **Story:** E10-S02 · **Level:** L2 · **Refs:** ADR-0111, D-028  
**Given** kubernetes-ingestor configured against the `Website` XRD (no hand-written `template.yaml`)  
**When** the ingestor task runner reconciles  
**Then** a scaffolder template for `websites.platform.kaddy.io` is registered in the catalog, with form
fields derived from the XRD OpenAPI schema (required fields, enums, validations)  
**Test:** `tests/chainsaw/portal/xrd-template-generated.yaml`

**Verify:** Backstage scaffolder API lists a template whose parameters match the `Website` XRD schema

---

## REQ-E10-S02-02: Auto-generated template opens a PR, never mutates the cluster

**Priority:** could · **Level:** meta · **Refs:** ADR-0103 (GitOps), ADR-0111  
**Given** the ingestor `publishPhase` config  
**When** inspected  
**Then** `kubernetesIngestor.crossplane.xrds.publishPhase.target` is a Git PR target
(github/gitlab/bitbucket) writing to `deploy/workloads/` — no direct commit, no cluster mutation from
the portal  
**Test:** `tests/portal/ingestor-config.sh`

**Verify:** `tests/portal/ingestor-config.sh` asserts a PR `publishPhase` target and `deploy/workloads/` path

---

## REQ-E10-S02-03: Form adapts when the platform API changes (no template drift)

**Priority:** could · **Level:** L2 · **Refs:** ADR-0111 (the projection invariant)  
**Given** the `Website` XRD gains a new schema field (e.g. `engine` enum extended, or a `tls` toggle)  
**When** `kubectl apply` updates the XRD and the ingestor task runner reconciles  
**Then** the corresponding field appears in the generated scaffolder form with no template edit  
**Test:** `tests/chainsaw/portal/xrd-field-propagates.yaml`

**Verify:** apply an XRD field patch; poll the scaffolder API until the new parameter is present

---

## REQ-E10-S03-01: Scaffolded XR reconciles end-to-end

**Priority:** could · **Story:** E10-S03 · **Level:** L2 · **Depends:** E6  
**Given** a `Website` v2 XR produced by the auto-generated template (via PR skeleton) applied to the cluster  
**When** Crossplane reconciles  
**Then** composed HTTPRoute + Deployment + ServiceMonitor + Certificate become Ready; site returns 200  
**Test:** `tests/chainsaw/portal/scaffolded-xr-reconciles.yaml`

**Verify:** `chainsaw test tests/chainsaw/portal`

---

## REQ-E10-S04-01: Read path is read-only and network-scoped

**Priority:** could · **Story:** E10-S04 · **Level:** L2 · **Refs:** ADR-0111, D-029  
**Given** the `portal` ServiceAccount used by the read-path plugins  
**When** its RBAC + NetworkPolicy are inspected  
**Then** the SA holds only `get/list/watch` (no mutating verbs) on `websites.platform.kaddy.io` +
composed/workload GVKs, and netpol allows egress only to kube-apiserver + argocd-server  
**Test:** `tests/portal/read-path-rbac.sh`

**Verify:** `tests/portal/read-path-rbac.sh` (fails if any mutating verb or unscoped egress is present)

---

## REQ-E10-S04-02: Crossplane resource graph renders on the entity page

**Priority:** could · **Level:** L2 · **Refs:** ADR-0111  
**Given** the crossplane-resources plugin and a live `Website` XR entity  
**When** the entity page is opened  
**Then** the XR → composite → managed-resource graph renders, with per-resource YAML + recent events  
**Test:** `tests/chainsaw/portal/crossplane-graph.yaml`

**Verify:** portal entity API returns the composed-resource tree for the `Website` XR

---

## REQ-E10-S04-03: ArgoCD sync/health shown on the entity page

**Priority:** could · **Level:** L2 · **Refs:** E3 (ArgoCD)  
**Given** the ArgoCD community plugin with a read-only Argo account  
**When** the entity page is opened  
**Then** the site's ArgoCD sync + health + deploy history are shown in-portal  
**Test:** `tests/chainsaw/portal/argocd-status-card.yaml`

**Verify:** portal entity API returns ArgoCD sync/health for the site Application

---

## REQ-E10-S05-01: Catalog registers platform components + live XRs

**Priority:** could · **Story:** E10-S05 · **Level:** L2  
**Given** static `catalog-info.yaml` entities + ingestor `ingestAllClaims`  
**When** Backstage catalog syncs  
**Then** `clubhouse`, `marshal`, `mulligan`, `scorecard` appear as Components **and** each live
`Website` XR appears as a catalog entity without a hand-written `catalog-info.yaml`  
**Test:** `tests/chainsaw/portal/catalog-entities.yaml`

**Verify:** Backstage catalog API lists the platform components + at least one auto-ingested `Website` XR

---

## REQ-E10-S05-02: TechDocs renders repo docs

**Priority:** could · **Level:** meta  
**Given** mkdocs config + TechDocs plugin  
**When** docs build runs  
**Then** `docs/` renders in-portal without broken nav  
**Test:** `tests/portal/techdocs-build.sh`

**Verify:** `mkdocs build --strict` exits 0

---

## REQ-E10-EXIT: Portal demo path (auto-gen money-shot)

**Priority:** could  
**Given** E10 complete  
**When** operator follows `docs/runbooks/portal-new-site.md`: fill the auto-generated form → PR → merge
→ reconcile, then live-edit the XRD and refresh to show the form adapt  
**Then** a new site is live end-to-end (all audited in Git) and the form reflects the XRD change with no
template edit — proving the portal is a projection of the platform API  
**Test:** `tests/chainsaw/portal/chainsaw-test.yaml`

**Verify:** documented demo; `chainsaw test tests/chainsaw/portal` green

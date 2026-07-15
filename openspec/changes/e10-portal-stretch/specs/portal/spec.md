# Spec — E10 Portal / IDP (Backstage + Crossplane)

Epic: E10 (cuttable) · ADR: [0109](../../../docs/adr/0109-idp-portal-orchestrator.md)  
**Depends:** E6 (Crossplane XRD), E1d (OIDC), E3 (app-of-apps, cert-manager)  
**Levels:** L1 golden-file · L2 Chainsaw

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

## REQ-E10-S02-01: Static-site scaffolder renders valid WebsiteClaim

**Priority:** could · **Story:** E10-S02 · **Level:** L1 · **TDD:** golden file first  
**Given** the `static-site` scaffolder template with inputs `hostname`, `engine=caddy`, `track=stable`  
**When** the template skeleton is rendered  
**Then** output equals the golden `WebsiteClaim` (kind, apiVersion, spec, mandatory labels)  
**Test:** `tests/portal/static-site-golden.yaml`

**Verify:** `hack/portal/render-template.sh caddy | diff -u tests/portal/static-site-golden.yaml -`

---

## REQ-E10-S02-02: Both engines supported

**Priority:** could · **Level:** L1  
**Given** template input `engine`  
**When** rendered with `nginx` and with `caddy`  
**Then** each produces a claim whose composition selects the matching engine image  
**Test:** `tests/portal/engines-golden.yaml`

**Verify:** golden files exist for both engines; render diff clean

---

## REQ-E10-S02-03: Scaffolder opens a PR, not a direct apply

**Priority:** could · **Level:** meta · **Refs:** ADR-0103 (GitOps)  
**Given** the template's publish step  
**When** inspected  
**Then** it uses `publish:github:pull-request` (or GitLab equiv) targeting `deploy/workloads/` — no
**Test:** `tests/portal/template-uses-pr.sh`
direct cluster mutation from the portal  

**Verify:** `rg 'publish:.*pull-request' deploy/portal/backstage/templates/static-site/template.yaml`

---

## REQ-E10-S03-01: Scaffolded claim reconciles end-to-end

**Priority:** could · **Story:** E10-S03 · **Level:** L2 · **Depends:** E6  
**Given** a `WebsiteClaim` produced by the template applied to the cluster  
**When** Crossplane reconciles  
**Then** composed HTTPRoute + Deployment + ServiceMonitor become Ready; site returns 200  
**Test:** `tests/chainsaw/portal/scaffolded-claim-reconciles.yaml`

**Verify:** `chainsaw test tests/chainsaw/portal`

---

## REQ-E10-S04-01: Catalog registers platform components

**Priority:** could · **Story:** E10-S04 · **Level:** L2  
**Given** `catalog-info.yaml` entities for kaddy components  
**When** Backstage catalog syncs  
**Then** entities `clubhouse`, `marshal`, `mulligan`, `scorecard` appear as Components  
**Test:** `tests/chainsaw/portal/catalog-entities.yaml`

**Verify:** Backstage catalog API lists the expected component refs

---

## REQ-E10-S05-01: TechDocs renders repo docs

**Priority:** could · **Level:** meta  
**Given** mkdocs config + TechDocs plugin  
**When** docs build runs  
**Then** `docs/` renders in-portal without broken nav  
**Test:** `tests/portal/techdocs-build.sh`

**Verify:** `mkdocs build --strict` exits 0

---

## REQ-E10-EXIT: Portal demo path

**Priority:** could  
**Given** E10 complete  
**When** operator follows `docs/runbooks/portal-new-site.md`  
**Then** a new static site is live from a portal form → PR → merge → reconcile, all audited in Git  
**Test:** `tests/chainsaw/portal/chainsaw-test.yaml`

**Verify:** documented demo; `chainsaw test tests/chainsaw/portal` green

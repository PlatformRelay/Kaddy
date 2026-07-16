# Tasks — E10 Portal / IDP (cuttable · auto-generated from the XRD)

**Gate:** `task test:spec` + `task test:chainsaw` (portal suite) + `tests/portal/ingestor-config.sh`

Only start if E1–E8 land early (ADR-0109 scope guard). Orchestrator-first: **E6 must be green and
shipping the `Website` XRD as a v2 namespaced XR** (D-027). TDD: add the failing test before implement.

## E10-S01 — Backstage + OIDC

- [ ] Add failing `tests/chainsaw/portal/backstage-ready.yaml`
- [ ] `deploy/portal/backstage/` Helm values + `app-config.yaml` + OIDC (Dex, ADR-0107)
- [ ] `portal` namespace default-deny netpol + Certificate (cert-manager)

## E10-S02 — Auto-generated scaffolder (kubernetes-ingestor) — replaces the hand-written template

- [ ] Add failing `tests/portal/ingestor-config.sh` (asserts `kubernetesIngestor.crossplane.xrds.publishPhase`
      is a **PR** target on `deploy/workloads/`, not a direct commit)
- [ ] Install + configure kubernetes-ingestor: generate a scaffolder template per `Website` XRD from
      its OpenAPI schema; `publishPhase` → PR against `deploy/workloads/`
- [ ] Annotate the E6 `Website` XRD: `terasky.backstage.io/target-path` +
      `create-kustomization-file` so scaffolded XRs land where ArgoCD watches
- [ ] Pin plugin versions; add to Renovate + the E11 audit inventory

## E10-S03 — End-to-end reconcile (form → PR → XR)

- [ ] Add failing `tests/chainsaw/portal/scaffolded-xr-reconciles.yaml`
- [ ] Drive the auto-generated template → PR skeleton → apply the rendered `Website` XR → composed
      HTTPRoute + Deployment + ServiceMonitor + Certificate become Ready; site returns 200
- [ ] Confirm the XR is the **v2 namespaced** shape (E6 dependency)

## E10-S04 — Read-path plugins (visibility, read-only)

- [ ] Add failing `tests/portal/read-path-rbac.sh` (asserts the `portal` SA is read-only:
      `get/list/watch` only, no mutating verbs; netpol scoped to kube-apiserver + argocd-server)
- [ ] crossplane-resources plugin (frontend + backend): XR → managed-resource graph on the entity page
- [ ] Kubernetes plugin: workload health; ArgoCD community plugin: sync/health/history
- [ ] (could) CRD-docs for the `Website` API; Kyverno policy-reports

## E10-S05 — Catalog + TechDocs

- [ ] `deploy/portal/backstage/catalog/` `catalog-info.yaml` for clubhouse/marshal/mulligan/scorecard
- [ ] Live `Website` XRs auto-ingested as catalog entities (ingestor `ingestAllClaims`)
- [ ] TechDocs plugin; `mkdocs build --strict`

## E10-S06 — Runbook + demo (feeds E12 video)

- [ ] `docs/runbooks/portal-new-site.md`
- [ ] Rehearse the auto-gen money-shot: edit XRD → refresh → new form field (E12 iframe surface)

## Test hygiene

- [ ] **[TEST-4]** Un-skip `tests/chainsaw/portal/chainsaw-test.yaml` (currently `skip: true`).
      Gate: un-skip once `deploy/portal/` manifests land (E10-S01 Backstage + OIDC);
      un-skipping now breaks the gate because the underlying portal manifests are unbuilt.

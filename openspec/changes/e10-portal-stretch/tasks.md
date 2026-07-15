# Tasks — E10 Portal / IDP (cuttable)

**Gate:** `task test:spec` + `task test:chainsaw` (portal suite) + `hack/portal/render-template.sh`

Only start if E1–E8 land early (ADR-0109 scope guard). Orchestrator-first: E6 must be green.

## E10-S01 — Backstage + OIDC

- [ ] Add failing `tests/chainsaw/portal/backstage-ready.yaml`
- [ ] `deploy/portal/backstage/` Helm values + OIDC (Dex)
- [ ] `portal` namespace netpol + Certificate (cert-manager)

## E10-S02 — Static-site scaffolder (TDD golden-file first)

- [ ] Add golden `tests/portal/static-site-golden.yaml` + `engines-golden.yaml`
- [ ] `hack/portal/render-template.sh`
- [ ] Template `static-site/` → `WebsiteClaim` via PR publish step

## E10-S03 — End-to-end reconcile

- [ ] Add failing `scaffolded-claim-reconciles.yaml`
- [ ] Extend E6 XRD with `engine: nginx|caddy` (or new `staticSite`)

## E10-S04 — Catalog + TechDocs

- [ ] `catalog-info.yaml` for clubhouse/marshal/mulligan/scorecard
- [ ] TechDocs plugin; `mkdocs build --strict`

## E10-S05 — Runbook + demo

- [ ] `docs/runbooks/portal-new-site.md`

# Tasks — E10 Portal / IDP (cuttable · auto-generated from the XRD)

**Gate:** `task test:spec` + `task test:chainsaw` (portal suite) + `tests/portal/ingestor-config.sh`
**Offline gate:** `task test:smoke:e10` (manifest/kubeconform + shellcheck + ingestor-config PR
invariant + read-only RBAC asserts) — wired into `task test:meta:ci`.

Only start if E1–E8 land early (ADR-0109 scope guard). Orchestrator-first: **E6 must be green and
shipping the `Website` XRD as a v2 namespaced XR** (D-027). TDD: add the failing test before implement.

> **Status:** offline-authored (🟨 in ROADMAP). Manifests + config + skip-gated tests land + pass the
> OFFLINE gate. The **running Backstage** (custom image build + real form→PR→XR reconcile) is a
> live-cycle step, honestly deferred — the chainsaw specs skip-not-fail offline. See
> `docs/runbooks/portal-new-site.md`.

## E10-S01 — Backstage + OIDC

- [x] Add failing `tests/chainsaw/portal/backstage-ready.yaml` (skip-gated — live-cluster-only)
- [x] `deploy/portal/backstage/` Helm values + `app-config.yaml` + OIDC (Dex, ADR-0107)
- [x] `portal` namespace default-deny netpol + Certificate (cert-manager) — `deploy/portal/backstage/rbac/networkpolicy.yaml` + `certificate.yaml`

## E10-S02 — Auto-generated scaffolder (kubernetes-ingestor) — replaces the hand-written template

- [x] Add failing `tests/portal/ingestor-config.sh` (asserts `kubernetesIngestor.crossplane.xrds.publishPhase`
      opens a **PR** — real TeraSky schema: `target: github` (git forge → PR; `target: YAML` = download, rejected)
      + `git.branchPrefix` (scaffold → new branch → PR) — against `deploy/workloads/`, never a direct commit.
      NB: there is NO `createPR` field in the ingestor schema.)
- [x] Install + configure kubernetes-ingestor: generate a scaffolder template per `Website` XRD from
      its OpenAPI schema; `publishPhase` → PR against `deploy/workloads/` (app-config.yaml)
- [x] Annotate the E6 `Website` XRD: `terasky.backstage.io/target-path` +
      `create-kustomization-file` so scaffolded XRs land where ArgoCD watches
- [x] Pin plugin versions; add to the E11 audit inventory (`deploy/portal/backstage/plugin-versions.md`)

## E10-S03 — End-to-end reconcile (form → PR → XR)

- [x] Add failing `tests/chainsaw/portal/scaffolded-xr-reconciles.yaml` (skip-gated — needs Crossplane)
- [~] Drive the auto-generated template → PR skeleton → apply the rendered `Website` XR → composed
      HTTPRoute + Deployment + ServiceMonitor + Certificate become Ready; site returns 200
      — **downstream shape authored (chainsaw spec, skip-gated); the live form→PR→merge→reconcile is DEFERRED**
- [x] Confirm the XR is the **v2 namespaced** shape (E6 dependency) — asserted in the chainsaw spec

## E10-S04 — Read-path plugins (visibility, read-only)

- [x] Add failing `tests/portal/read-path-rbac.sh` (asserts the `portal` SA is read-only:
      `get/list/watch` only, no mutating verbs; netpol scoped to kube-apiserver + argocd-server)
- [x] crossplane-resources plugin (frontend + backend) wired in app-config; read-only ClusterRole (`rbac/read-only-rbac.yaml`)
- [x] Kubernetes plugin: workload health; ArgoCD community plugin: sync/health/history (app-config)
- [ ] (could) CRD-docs for the `Website` API; Kyverno policy-reports — DEFERRED (could)

## E10-S05 — Catalog + TechDocs

- [x] `deploy/portal/backstage/catalog/` `catalog-info.yaml` for clubhouse/marshal/mulligan/scorecard
- [x] Live `Website` XRs auto-ingested as catalog entities (ingestor `ingestAllClaims: true` in app-config)
- [x] TechDocs plugin configured (app-config); `mkdocs build --strict` is a live/CI docs step

## E10-S06 — Runbook + demo (feeds E12 video)

- [x] `docs/runbooks/portal-new-site.md`
- [~] Rehearse the auto-gen money-shot: edit XRD → refresh → new form field (E12 iframe surface)
      — **documented in the runbook; the live rehearsal is DEFERRED (needs a running Backstage)**

## E10-S07 — Portal image publish + live bring-up smoke

> The public GSK HTTPRoute is live/proven: `https://portal.lab.platformrelay.dev` returns 200 through
> a Ready Let's Encrypt certificate and Cloudflare A → `185.241.34.187`. Offline S01–S06 wiring is
> landed; this story retains the portal form-to-PR/read-path smoke and unskipped live-cycle tests.
> See also INBOX §E10-S07 assessment (GSK portal Deployment may already exist scaled to 0 —
> finish image/plugins/OIDC/smoke rather than re-authoring the skeleton).

- [ ] Confirm / publish `ghcr.io/platformrelay/kaddy-portal:<tag>` from `PlatformRelay/kaddy-portal`
      (plugins pinned in `deploy/portal/backstage/plugin-versions.md`); resolve plugin registration
      defects if still present
- [ ] Wire or verify Helm chart grandchild in `deploy/apps/portal.yaml`; pin image digest in
      `deploy/portal/backstage/values.yaml`
- [ ] Ensure Dex `backstage` static client + KSOPS-rendered OIDC secret (no guest in prod)
- [ ] Scale/sync portal App; `kubectl -n portal rollout status deploy/backstage`
- [ ] Smoke: scaffolder form from Website XRD → GitOps PR path; read-path graph/Argo/K8s
- [ ] Un-skip or live-prove the relevant `tests/chainsaw/portal/*` specs; update runbook status

## Test hygiene

- [x] **[TEST-4]** `tests/chainsaw/portal/chainsaw-test.yaml` kept `skip: true` with a status
      annotation — the EXIT path drives a LIVE Backstage (form→PR→reconcile + XRD-edit money-shot),
      a live-cycle smoke. Un-skipping the form-to-PR suite without that proof would FAIL offline,
      violating skip-not-fail. The public HTTPRoute is live; the offline contract is proven by
      `tests/smoke/e10-offline.sh`.

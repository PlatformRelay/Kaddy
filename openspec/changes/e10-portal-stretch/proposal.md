# Proposal — E10 Portal / IDP (Backstage · auto-generated from the XRD)

## Problem

kaddy has a self-service **capability** (Crossplane `Website` XRD, E6) but no self-service
**experience**. The goal: a portal where a user bootstraps an **nginx** or **Caddy** site through a
form, not by hand-writing manifests — turning kaddy into a fully-fledged IDP.

An earlier cut of E10 planned a **single hand-written** scaffolder `template.yaml` that duplicated the
`Website` XRD schema into a Backstage form. That works but rots: the moment E6/E6g extends the platform
API, the template drifts, and the portal lies about what the platform accepts. Research
([agent-context/research/e10-portal-wiring-and-demo-presentation.md](../../../agent-context/research/e10-portal-wiring-and-demo-presentation.md))
surfaced a materially stronger path.

## Decision (this epic adopts)

**The portal is a projection of the platform API, not a copy of it.** Backstage scaffolder templates
are **auto-generated from the `Website` XRD's OpenAPI schema** by TeraSky's **kubernetes-ingestor**
plugin. Add a field to the XRD → a validated form field appears in the portal automatically. The
ingestor's `publishPhase` is configured for **pull-request** targets, so the auto-generated template
opens a PR against `deploy/workloads/` — preserving E10's invariant that **the portal authors Git and
never mutates the cluster API**. (D-028)

Two paths, kept distinct (D-029):

- **Write path** (self-service) — ingestor template-gen + scaffolder `publishPhase` → opens a PR. No
  cluster credentials. Pure GitOps; ArgoCD applies on merge.
- **Read path** (visibility) — crossplane-resources graph + Kubernetes + ArgoCD plugins render live
  claim/rollout status in the portal. Needs a **read-only** ServiceAccount to the cluster + a
  read-only ArgoCD account. This is a named trade: **impressiveness > minimal-trust** for this demo
  (D-029) — the in-portal XR→managed-resource graph is most of the wow, and read-only + netpol-scoped
  is defensible. The read path is *in scope*.

Platform API shape: E6 ships the `Website` XRD as a **Crossplane v2 namespaced XR** (not a v1 Claim)
— the modern, simpler mental model; the TeraSky plugins support both (D-027, amends ADR-0105).

## Scope (phased, cuttable)

- Backstage deployed via GitOps; OIDC through Dex + GitHub (ADR-0107).
- **kubernetes-ingestor**: auto-generate a scaffolder template per `Website` XRD **and** ingest live
  `Website` XRs into the Software Catalog via annotations (no per-site static `catalog-info.yaml`).
- **Read-path plugins**: crossplane-resources (XR → composite → managed-resource graph, YAML +
  events), Kubernetes (workload health), ArgoCD (sync/health/history on the entity page).
- **Polish plugins** (could): CRD-docs (self-documenting `Website` API), Kyverno policy reports.
- Static catalog for the 4 platform components (`clubhouse`, `marshal`, `mulligan`, `scorecard`).
- TechDocs rendering `docs/` (mkdocs already configured).
- Runbook + demo narrative (feeds the E12 video).

## Non-goals

- No SaaS portal/orchestrator (Humanitec, Port) — ADR-0109.
- No **hand-written** per-XRD scaffolder template — superseded by auto-gen (this is the delta).
- Portal does **not** bypass GitOps — the write path authors PRs; ArgoCD applies.
- No multi-cluster scheduling (Kratix) in this iteration.

## Dependencies

- **E6** — Crossplane `Website` XRD as a **v2 namespaced XR** (the API the portal projects).
- **E1d** — Dex + GitHub OIDC (portal auth).
- **E3** — app-of-apps (portal Application), cert-manager (portal TLS), ArgoCD (read-path source).

## ADRs

- [ADR-0109](../../../docs/adr/0109-idp-portal-orchestrator.md) — portal + orchestrator (updated: auto-gen).
- [ADR-0111](../../../docs/adr/0111-portal-auto-generation.md) — auto-generated templates, read-path plugins, v2 XR.
- Decisions **D-027** (v2 XR), **D-028** (adopt ingestor auto-gen), **D-029** (read-path plugins in).

## Counterpoints (kept)

- Third-party OSS plugins (TeraSky/community) add supply-chain surface — pin versions, Renovate them,
  note in the E11 audit (ADR-0111).
- Read-path needs a cluster read credential — the smallest-trust alternative (write-path only, status
  via the ArgoCD UI) is recorded in ADR-0111 and rejected for this demo (impressiveness wins, D-029).
- Full Backstage is a large lift and this epic stays **cuttable** — orchestrator-first (E6) already
  delivers the capability; the served-website MVP is carried by E-Caddy-MVP even if E10 is cut.

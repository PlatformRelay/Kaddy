# Proposal — E10 Portal / IDP (Backstage + Crossplane)

## Problem

kaddy has a self-service **capability** (Crossplane `Website` XRD, E6) but no self-service
**experience**. The goal: a portal where a user bootstraps an **nginx** or **Caddy static site**
through a form, not by hand-writing manifests — turning kaddy into a fully-fledged IDP.

## Scope (phased, cuttable)

**Orchestrator (E6, prerequisite):** Crossplane `Website` XRD is the platform API. E10 may extend it
with a `staticSite` type (`engine: nginx | caddy`) and optionally a **Score** input mapping.

**Portal (E10):**

- Backstage deployed via GitOps, OIDC through Dex + GitHub (ADR-0107).
- Software Catalog registering platform components + live `Website` claims.
- **Scaffolder template**: "New static site" → opens a **PR** adding a `WebsiteClaim` (GitOps-audited).
- Crossplane/Kubernetes plugin for claim + composed-resource status.
- TechDocs rendering `docs/`.

## Non-goals

- No SaaS portal/orchestrator (Humanitec, Port) — see ADR-0109.
- No multi-cluster scheduling (would pull in Kratix) in this iteration.
- Portal does **not** bypass GitOps — it authors PRs, Argo CD applies.

## Dependencies

- **E6** — Crossplane XRD (the API the portal drives).
- **E1d** — Dex + GitHub OIDC (portal auth).
- **E3** — app-of-apps (portal Application), cert-manager (portal TLS).

## ADR

[ADR-0109](../../../docs/adr/0109-idp-portal-orchestrator.md) · decision **D-014** (INBOX).

## Counterpoints

- Full Backstage is a large lift and this epic is **cuttable** — orchestrator-first (E6) already
  delivers the capability. Portal ships only if E1–E8 land early. Recorded in ADR-0109.

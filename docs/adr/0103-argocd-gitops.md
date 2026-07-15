# ADR-0103: ArgoCD GitOps app-of-apps

**Theme:** 01 · Foundations · **Status:** Current

## Context

Cluster components (Caddy gateway, Prometheus, Crossplane, Rollouts, sample apps) must be
declarative, reviewable, and reproducible. Flux vs ArgoCD vs plain kubectl.

## Decision

**ArgoCD** with **app-of-apps** pattern:

- Root Application points at `deploy/bootstrap/` or `gitops/apps/`.
- Child apps: platform-core, observability, crossplane, gateway, workloads.
- Sync policies: automated for lab; manual sync acceptable for destructive components.
- Use Argo CD **Application** labels per ADR-0301 (`managed-by=argocd`).

Progressive delivery uses **Argo Rollouts** (separate controller), integrated via Gateway API HTTPRoute
weights — not Argo CD sync waves alone.

## Consequences

- Argo CD UI aids interview demo.
- Must configure ignore differences for Rollouts-managed HTTPRoute weight labels (documented in E7).

## Counterpoints

- Flux is lighter and more GitOps-pure; ArgoCD chosen for demo UX and Rollouts ecosystem fit (D-002).

# ADR-0105: Crossplane self-service via Upjet-generated provider-gridscale

**Theme:** 01 · Foundations · **Status:** Current · **Supersedes:** `provider-openstack` decision (see D-016, `agent-context/decisions.md`)

## Context

Optional exercise task: a second nginx VM behind Caddy. Provisioning it via standalone OpenTofu
outside the cluster is imperative and splits IaC ownership. We want to demonstrate a **self-service
platform API**, not just "make a VM".

Layering (Crossplane cannot create the cluster it runs on):

- **OpenTofu = day-0** — the cluster (driving-range locally, GSK in phase 2) + gridscale state bucket
  when in cloud ([ADR-0302](0302-terramate-opentofu-stacks.md)).
- **ArgoCD = app delivery** — Crossplane, observability, Caddy, identity.
- **Crossplane = day-1+ infra** — gridscale resources after the cluster exists (phase 2).

No official `provider-gridscale` exists; Upjet generation is deferred to phase 2 (D-017).

## Decision — two phases

### Phase 1 (driving-range — E6)

- Install Crossplane via GitOps.
- Define **`Website` XRD** composing HTTPRoute + ServiceMonitor + PrometheusRule stubs.
- Legacy nginx: **in-cluster Deployment** (or host libvirt VM) behind HTTPRoute `/legacy` — proves
  routing and monitoring without cloud API.

### Phase 2 (gridscale lab — E6g)

- Generate a **thin `provider-gridscale` with Upjet** from the `gridscale/gridscale` TF provider,
  scoped to `gridscale_server` (+ LBaaS/object-storage as needed).
- Extend the Composition to provision a real **gridscale_server** nginx VM.
- Provider credentials as a K8s Secret; RBAC restricted ([ADR-0106](0106-security-baseline.md)).

## Consequences

- Phase 1 proves the self-service *claim surface* without cloud API coupling.
- Phase 2 adds the crown-jewel Upjet provider — time-boxed per D-016 guards.

## Guards / counterpoints

- Hard **time-box** the Upjet build; keep a plain `gridscale_server` OpenTofu module as the
  guaranteed fallback so a green E6 never depends on the Upjet gamble.
- `provider-terraform` (crossplane-contrib `Workspace`) was the lower-effort alternative (wrap the
  gridscale TF provider, no generated CRDs) — rejected in D-016 in favour of the stronger native signal.

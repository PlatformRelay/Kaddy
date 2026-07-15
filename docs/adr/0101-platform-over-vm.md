# ADR-0101: Platform over VM for the hiring exercise

**Theme:** 01 · Foundations · **Status:** Current

## Context

The gridscale brief asks for Caddy, Prometheus, alerting, and IaC on Linux VMs. A minimal Ansible
path satisfies every checkbox but reads as operations homework, not platform engineering.

## Decision

Deliver a **Website-as-a-Service** internal platform on Kubernetes. The exercise deliverables are
one **tenant** (clubhouse sample site + marshal monitoring + mulligan demo), not the whole product
story inverted.

Day-0 is **two-phase** ([ADR-0102](0102-talos-immutable-substrate.md), D-017):

1. **Phase 1 (driving-range):** local 3-node Talos on libvirt/KVM ([driving-range](../../../driving-range/));
   kaddy bootstraps ArgoCD onto that cluster.
2. **Phase 2 (gridscale lab):** Terramate + OpenTofu provisions GSK and hands off to the same GitOps
   manifests. Day-1+ gridscale infra via Crossplane ([ADR-0105](0105-crossplane-self-service.md)).

Everything after the cluster exists is GitOps-declared in both phases.

## Consequences

- Higher initial complexity; stronger interview signal.
- **Local-first** saves gridscale credits; employer-facing demo lands in phase 2 (E1g, E8b).
- Built **gridscale-native** in phase 2 to match the platform this team ships (D-013).

## Counterpoints considered

- **VM-only:** faster to green; rejected per operator preference for immutable declarative platform.
- **GSK from day 1:** rejected in D-017 — budget risk; local Talos rehearsal de-risks GitOps work.
- **Gardener:** rejected in D-012 — fleet manager overkill for one lab cluster.

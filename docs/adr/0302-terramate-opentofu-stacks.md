# ADR-0302: Terramate-managed OpenTofu stacks on gridscale

**Theme:** 03 · IaC & labeling · **Status:** Current · **Amended:** provider OpenStack → gridscale (see D-013, `agent-context/decisions.md`)

## Context

Day-0 resources need IaC with DRY label injection and stack boundaries.

**Phase 1:** no gridscale Terramate stacks — cluster comes from [driving-range](../../../driving-range/).

**Phase 2 (E1g):** gridscale lab via Terramate + OpenTofu (`gridscale/gridscale` **v2**).

## Decision

Repository layout:

```
terramate.tm.hcl          # root config
stacks/
  gridscale/
    network/              # network + firewall + IPs
    k8s/                  # gridscale_k8s (GSK) cluster + node pools
    state-bucket/         # object storage for remote state + evidence
modules/
  labels/                 # ADR-0301 — tested
  gridscale-*/            # composable pieces
policy/                   # conftest / OPA
```

- Provider `gridscale/gridscale` **v2**; auth via `GRIDSCALE_UUID` / `GRIDSCALE_TOKEN` (from `.envrc`).
- Terramate **globals** carry `part-of`, `owner`, `managed-by=terramate`; each stack generates
  `_terramate_generated_labels.tf` importing `modules/labels` → gridscale `labels`.
- OpenTofu ≥ 1.6.
- **Remote state: gridscale Object Storage (S3-compatible)** via `gridscale_object_storage_accesskey`
  — replaces the earlier "backend TBD / local". Day-1+ infra is owned by Crossplane, not OpenTofu
  ([ADR-0105](0105-crossplane-self-service.md)).

## Consequences

- Operators run `terramate generate && terramate run -- tofu plan` per stack.
- CI validates generated code drift in E1.
- One-vendor coupling to the gridscale API — accepted per D-013 (employer-aligned signal).

## Counterpoints

- Single root module simpler; Terramate pays off as stacks grow (network / k8s / state / spike).

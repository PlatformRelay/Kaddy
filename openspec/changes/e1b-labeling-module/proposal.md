# Change: E1b — Naming & labeling module

## Why

Mandatory labels everywhere (ADR-0301); tested tofu module prevents drift and satisfies compliance queries.

## What

- `modules/labels` with `tofu test` + conftest
- Terramate codegen into all stacks — **deferred to E1g** (no stacks in phase 1; see spec REQ-E1b-S04-01 deferral note)
- Kyverno enforcement in cluster

## Spec reference

See [ADR-0301](../../../docs/adr/0301-resource-labeling-convention.md)

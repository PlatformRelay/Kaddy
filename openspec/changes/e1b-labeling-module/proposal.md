# Change: E1b — Naming & labeling module

## Why

Mandatory labels everywhere (ADR-0301); tested tofu module prevents drift and satisfies compliance queries.

## What

- `modules/labels` with `tofu test` + conftest
- Terramate codegen into all stacks
- Kyverno enforcement in cluster

## Spec reference

See [ADR-0301](../../../docs/adr/0301-resource-labeling-convention.md)

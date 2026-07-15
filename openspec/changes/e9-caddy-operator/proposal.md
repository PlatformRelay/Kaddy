# Change: E9 — Caddy operator (design-first; code optional)

## Why

`caddyserver/gateway` requires operators to supply Caddy pods; upstream acknowledges a future CRD
to manage Caddy lifecycle. kaddy operator closes that gap and bundles observability per site.

## What (design phase — this change)

- CRD schemas `Caddy`, `CaddySite`
- Reconcile flow via Admin API
- Auto ServiceMonitor + PrometheusRule per site

## What (implementation — optional)

- kubebuilder Go operator (E9-S01–S03) only if E1–E8 green

## Links

- ADR-0401

# kaddy platform — baseline specification

## Purpose

Deliver a security-first Website-as-a-Service platform satisfying the gridscale Platform Engineer
exercise as one tenant, with spec-driven implementation via OpenSpec changes E0–E12.

## Core capabilities

1. **Edge** — Caddy as Gateway API dataplane with TLS (cert-manager)
2. **Observe** — Prometheus metrics, alerting (marshal), Grafana dashboards
3. **Deliver** — Blue/green and canary rollouts gated by Prometheus (mulligan)
4. **Self-service** — Crossplane Website claim; optional nginx legacy VM
5. **Prove** — scorecard evidence harness + optional live demo (E8b)
6. **Assure** — Security baseline (E1c) + replayable audits (E11)
7. **Label** — Mandatory resource labels (ADR-0301) via tested tofu module (E1b)

## Non-goals (design phase)

- Multi-environment dev/prod separation
- Production Gardener fleet management
- Backstage portal (E10 stretch only)

## Traceability

See [docs/requirements/exercise-traceability.md](../../docs/requirements/exercise-traceability.md).

# ADR-0201: Blue/green and canary with Prometheus analysis (mulligan)

**Theme:** 02 · Delivery · **Status:** Current

## Context

Exercise asks for monitoring and alerting on thresholds. We elevate this: **metrics gate promotion**
via Argo Rollouts — the monitoring requirement becomes a control loop, not a screenshot.

Single lab platform — no dev/prod environments. Deployment dimension uses **`track` label**
(`stable` | `canary` | `preview`) on pods and metrics.

## Decision

Two-act demo (**mulligan**):

### Act A — Blue/green

- Rollout with `blueGreen` strategy.
- **Pre-promotion AnalysisRun** queries Prometheus (error rate, latency p99).
- Bad green **never** receives traffic — instant rollback by withholding promotion.

### Act B — Canary

- Rollout with `canary` strategy + **Gateway API plugin** (`HTTPRoute` weight steps).
- AnalysisTemplate fails mid-flight → controller rolls weights back to stable.
- Alert fires in Alertmanager (marshal); scorecard captures state.

Chaos beat (E7): kill Caddy pod + nginx VM → `TargetDown` / server-down alert → self-heal +
Crossplane reconcile.

## Consequences

- Depends on E2 gateway spike for Act B weights.
- Record demo via asciinema/video; `task demo` orchestrates when implemented.

## References

- [Argo Rollouts Gateway API plugin](https://rollouts-plugin-trafficrouter-gatewayapi.readthedocs.io/)

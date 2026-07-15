# ADR-0202: Evidence as reproducible artifact (scorecard)

**Theme:** 02 · Delivery · **Status:** Current

## Context

Brief deliverable: "Screenshots or logs demonstrating successful monitoring … and alerting."
Manual screenshots rot, cannot be diffed, and do not prove reproducibility.

## Decision

**scorecard** harness produces a **dated HTML report** per run:

| Section | Source |
| --- | --- |
| Alert timeline | Alertmanager API |
| Rule evaluation | Prometheus API |
| Grafana panels | Image renderer / export API |
| Load test | k6 summary JSON |
| Rollout state | kubectl argo rollouts |

Artifacts under `evidence/runs/YYYY-MM-DD/`; publish to GitHub Pages on main.

README **5-minute path** orders: (1) demo recording, (2) latest scorecard URL, (3) live URLs (E8b).

## Consequences

- CI workflow stub in E8; local `task demo` wraps scripts.
- Evidence commits may be large — consider Git LFS for PNGs if needed.

## Counterpoints

- Screenshots alone are faster; rejected — reproducibility is the interview differentiator.

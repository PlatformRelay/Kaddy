---
name: evidence-capture
description: Run or document the scorecard evidence harness (E8) for kaddy — k6, Prometheus, Alertmanager, Grafana capture.
---

# evidence-capture — kaddy (scorecard)

## When

Implementing or running **E8** / **E8b** — gridscale deliverable "screenshots or logs" as reproducible artifact.

## Procedure (target state post E8)

1. Run `task demo` or documented k6 profile that trips threshold alert (marshal).
2. Capture: Prometheus query snapshots, Alertmanager silences/alerts API, Grafana panel PNGs, k6 summary.
3. Render dated HTML under `evidence/runs/YYYY-MM-DD/`; publish to GitHub Pages on merge to main.
4. README 5-minute path lists **recording first**, then live URLs (D-009 outage hedge).

## Design reference

- ADR [0202-evidence-as-artifact](../docs/adr/0202-evidence-as-artifact.md)
- OpenSpec [e8-scorecard-evidence](../openspec/changes/e8-scorecard-evidence/)

## Do not

- Commit secrets or internal URLs with credentials in evidence bundles.
- Rely on manual screenshots as sole deliverable — automate capture.

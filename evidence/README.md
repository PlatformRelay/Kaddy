# evidence — scorecard (E8)

Reproducible monitoring and alerting artifacts for the gridscale submission — **not** one-off screenshots.

## Layout

```
evidence/
  README.md           # this file
  runs/
    YYYY-MM-DD/       # per-run bundle (generated)
      index.html      # scorecard report
      prometheus/     # query snapshots
      alertmanager/   # alert state JSON
      grafana/        # panel exports
      k6/             # load test summary
```

## How runs are produced

After E8 implementation:

```bash
task demo    # orchestrates k6 + capture (see .claude/skills/evidence-capture)
```

CI publishes latest report to GitHub Pages on merge to `main`.

## Reviewer note

README lists **demo recording first**, then scorecard URL, then live environment (E8b) — static
artifacts survive outage (decision D-009).

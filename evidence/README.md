# evidence — scorecard (E8)

Reproducible monitoring and alerting artifacts for the gridscale submission — **not** one-off screenshots.

## Layout

```
evidence/
  README.md           # this file
  fixtures/           # offline snapshots for SCORECARD_FIXTURES=1
    prometheus/
    alertmanager/
    k6/
    loki/
    rollout/
  runs/
    YYYY-MM-DD/       # per-run bundle (generated; gitignored)
      index.html      # scorecard report
      prometheus/     # query snapshots
      alertmanager/   # alert state JSON
      k6/             # load test summary
      loki/           # LogQL 5xx evidence
      rollout/        # Argo Rollouts status
```

## Offline gates (this lane)

```bash
task test:load       # SCORECARD_FIXTURES=1 — structural k6 profile check
task test:scorecard  # fixture capture → validate.sh schema check
```

Manual fixture capture:

```bash
SCORECARD_FIXTURES=1 hack/scorecard/capture.sh
# or
hack/scorecard/capture.sh --fixtures
hack/scorecard/validate.sh
```

## Live capture (deferred)

After E8 live smoke lands:

```bash
task demo    # orchestrates k6 + capture (see skills/evidence-capture)
SCORECARD_FIXTURES=0 hack/scorecard/capture.sh   # once live mode is implemented
```

CI publishes latest report to GitHub Pages on merge to `main` (E8-S03):
**https://platformrelay.github.io/Kaddy/**

## Reviewer note

README lists **demo recording first**, then scorecard URL, then live environment (E8b) — static
artifacts survive outage (decision D-009).

## RATE threshold

Marshal lab threshold is **100 rps** (EdgeRequestRateHigh). The k6 profile defaults to
`RATE=150` (above threshold). Scorecard HTML uses the brief name `HighRequestRate`.

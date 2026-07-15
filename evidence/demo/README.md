# Demo evidence — mulligan (E7 progressive delivery)

The `mulligan` demo (`hack/demo/mulligan.sh` / `task demo`) is a scripted,
idempotent, two-act progressive-delivery demo against the live `kind-kaddy-dev`
cluster:

- **Act A — blue/green**: roll a new revision, park it on the `preview` Service,
  promote, and verify the `active` Service selector flips to the green ReplicaSet.
- **Act B — canary**: roll a new revision and watch the Argo Rollouts Gateway API
  plugin shift the **live** `mulligan` HTTPRoute backend weights
  (`100/0 → 20 → 50 → 100`).

A chaos beat (`hack/demo/mulligan-abort.sh`, `task demo:chaos`) aborts a canary
mid-flight and proves the controller auto-rolls the HTTPRoute weight back to 100%
stable (the "mulligan").

## Recording hook (REQ-E7-S03-02)

Record the demo with [asciinema](https://asciinema.org/):

```bash
asciinema rec -c 'task demo' evidence/demo/mulligan.cast
# or, for a GIF:
#   agg evidence/demo/mulligan.cast evidence/demo/mulligan.gif
```

The `.cast` / `.gif` binary asset is optional (should-priority) and is not
committed by default to keep the repo lean — capture it on demand from the
command above. The README 5-minute path links this recording first (D-009).

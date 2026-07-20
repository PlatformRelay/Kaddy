<!-- markdownlint-disable MD013 -->
# Runbook — the 5-10 minute demo video

Scene-by-scene run-sheet for recording the kaddy submission video: exact commands,
what to show on screen, and what to say each scene is proving. The deck
(`slides/slides.md`, `pnpm dev` in `slides/`) is the narration backbone; the scenes
below are the live cut-aways. GIF/screenshot capture conventions live in
[`slides/recording-guide.md`](../../slides/recording-guide.md).

## Pick a track

| Track | Cost | What it gives you |
|---|---|---|
| **Local (kind)** | free | canary + abort demo, alert-fire demo, scorecard capture |
| **Live GSK** | money while up | public HTTPS surfaces: `caddy.lab` / `demo.lab` / `portal.lab` / `grafana.lab` |

The two tracks compose: record the browser scenes against the live GSK edge, and
the terminal scenes against local kind. If you only run one, local covers every
terminal demo.

**Live GSK:** if the lab is not already standing, `task e8b:up` ≈10 min before
recording (see [gridscale-live-demo.md](gridscale-live-demo.md)); tear down with
`task e8b:down` whenever you are done with the lab.

## Prep (before recording)

```bash
# Local track — one-time bring-up (~10 min):
task cluster:up          # kind + Cilium + Gateway API + cert-manager
task bootstrap:e3        # Argo CD + app-of-apps (GitOps root)
task bootstrap:e7        # Argo Rollouts + gateway plugin + mulligan workloads

# Sanity: both demos green BEFORE you hit record
task demo                # must end "mulligan demo complete — both acts PASSED"
task demo:chaos          # must end with weights snapped back to stable
```

Terminal: large font, dark background, no personal prompt clutter. Keep two panes:
left = commands, right = the watch loop. Browser: log-out of everything; open the
tabs listed per scene beforehand.

## Suggested timeline (~8 min total)

| Time | Scene | Source |
|---|---|---|
| 0:00 | Slides 1-3 — brief, built-with-AI (show the spec) | deck |
| 1:30 | Slides 4-5 — why an API; Crossplane story | deck |
| 2:30 | Scene A — Upbound Marketplace + gridscale Marketplace | browser |
| 3:30 | Scene B — Backstage portal | browser |
| 4:30 | Scene C — canary + abort (the centerpiece) | terminal |
| 6:30 | Scene D — Grafana dashboards (+ optional alert fire) | browser |
| 7:30 | Scene E — scorecard evidence + closing slide | browser + deck |

## Scene A — the two marketplaces (~1 min)

Tabs to open:

- <https://marketplace.upbound.io/providers/platformrelay/provider-gridscale> —
  scroll the resource list ("32 gridscale resources as Kubernetes APIs").
- gridscale panel → Marketplace → *your imported templates* — show the Caddy
  template registered + imported in the tenant (see
  [gridscale-marketplace-deploy.md](gridscale-marketplace-deploy.md); one-click
  deploy proof is `tests/smoke/e13-s03-deploy.sh`).

Say: the Crossplane provider is a published ecosystem contribution; the Packer
image is a one-click product in the gridscale Marketplace.

## Scene B — Backstage portal (~1 min)

Tab: <https://portal.lab.platformrelay.dev> (GSK track; on kind Backstage is not
deployed — use the static capture instead).

Show: catalog → the `kaddy-caddy` template → open the scaffolder form. Say: the
form fields come from the Website XRD schema; submitting opens a Git change, and
Argo CD + Crossplane make it real — the portal reads the same API back.

## Scene C — canary + abort, the centerpiece (~2 min)

Right pane — start the watch BEFORE the demo so the weight shift is visible live:

```bash
export KUBECONFIG=.state/kubeconfig
watch -n2 'kubectl --context kind-kaddy-dev -n mulligan get httproute mulligan \
  -o jsonpath="{range .spec.rules[0].backendRefs[*]}{.name}={.weight}{\"  \"}{end}"; echo; \
  kubectl --context kind-kaddy-dev -n mulligan get rollout'
```

Left pane, act 1 — happy path:

```bash
task demo
```

What the audience sees: Act A flips the blue/green active Service to the promoted
ReplicaSet; Act B rolls a canary and the **live HTTPRoute weights shift
100/0 → 20 → 50 → 100** in the right pane, then promote.

Left pane, act 2 — the mulligan:

```bash
task demo:chaos
```

What the audience sees: a canary takes traffic, the rollout is **aborted**, and
the controller snaps the route back to 100% stable and scales the canary down.
Say: the release decision is Prometheus-gated, and rollback is the same declared
route model — recovery is free.

## Scene D — Grafana + optional alert fire (~1 min)

Tab: <https://grafana.lab.platformrelay.dev> (anonymous Viewer, no login) — open
the kaddy 12-panel dashboard; point out the Loki logs panel and that every alert
rule is promtool-unit-tested (`task test:promrules`).

Optional (local, ~3 min — cut most of it in the edit):

```bash
task demo:fire   # controlled outage -> ClubhouseDown fires in Alertmanager -> restore -> resolved
```

The script port-forwards Prometheus/Alertmanager itself and prints each phase;
show the Alertmanager UI firing → resolved.

## Scene E — scorecard evidence (~30 s)

```bash
task test:scorecard                       # fixture render, offline
open evidence/runs/$(date -u +%Y-%m-%d)/index.html
```

Show the report: k6, metrics, alerts, logs, rollout state — one self-contained
HTML. Say: every demo you just watched can be captured like this and published;
claims stay checkable after the video ends.

## After recording

```bash
task e8b:down            # if the GSK track was up — do NOT skip
task cluster:down        # optional: reclaim the local kind cluster
```

Export the deck for the submission bundle: `task deck:export` →
`slides/kaddy-deck.pdf`.

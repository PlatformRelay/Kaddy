<!-- markdownlint-disable MD013 -->
# Recording guide — GIFs & screenshots for the deck

How to record the interactive clips that make the deck feel live, and exactly how to name and drop
them in. Companion to `image-prompts.md` (that file = AI cover art; this file = real screen capture).

The deck embeds each platform surface via `data-surface="<name>" data-surface-mode="live|fallback"`
(gated by `tests/deck/iframe-surfaces.sh`). **Live** = a real `<iframe>` at a running URL; **fallback**
= a recorded GIF/screenshot for a surface that isn't reliably up during the talk. This guide feeds the
`fallback` slots. Keep at least **3 live** iframes (`argocd`, `grafana`, `clubhouse`).

## Naming convention (strict — the deck references these exact paths)

```
slides/public/surfaces/<surface>-<action>.gif      # motion clip
slides/public/surfaces/<surface>-<action>.png      # still fallback
```

- `<surface>` ∈ the five named surfaces: `backstage`, `argocd`, `grafana`, `clubhouse`,
  `crossplane-graph` — **plus** the extra fallback subjects below (`marketplace`, `mulligan`,
  `marshal-alert`, `scorecard`).
- `<action>` = a short verb-y slug of what happens: `xrd-edit`, `weight-shift`, `alert-fire`,
  `provision`, `report`.
- lower-kebab-case only, no spaces, no dates. One clip = one idea.

## Format & quality

- **GIF**, 16:9, target **1280×720**, **≤ 8 MB** each (deck loads them inline). If a clip would
  exceed 8 MB, cut it shorter or export at 960×540. Prefer **8–15 s** loops; trim dead air.
- macOS capture: `⇧⌘5` → record region → then convert with
  `ffmpeg -i in.mov -vf "fps=12,scale=1280:-1:flags=lanczos" -loop 0 out.gif` (12 fps keeps size down).
  Or use the Chrome `gif_creator` browser tool for in-browser flows.
- Stills: `⇧⌘4` region grab → save straight to the `.png` name above.
- Chrome to a clean 1280×720 window, hide bookmarks bar, zoom 100%, dark mode on (matches the deck).

## Shot list — what to record (highest signal first)

| # | File | What to capture | Why it earns a slot |
| --- | --- | --- | --- |
| 1 | `backstage-xrd-edit.gif` | Edit the `Website` XRD → the Backstage form **regenerates a field live**. Split-screen editor + portal. | The portal hero moment (§08); Backstage is a `fallback` surface today. |
| 2 | `mulligan-weight-shift.gif` | `kubectl argo rollouts get rollout` (or the dashboard) showing canary weight **100→50→100** during a promote. | Proves progressive delivery for real (§09). |
| 3 | `marshal-alert-fire.gif` | Run `task demo:fire` (k6) → Alertmanager/Grafana panel **flips red → alert fires → resolves**. | The alerting proof (§10) without needing a live cluster in the room. |
| 4 | `marketplace-provision.gif` | The gridscale Marketplace VM: launch the template → VM comes up → the served site responds. | The E13 marketplace beat; interactive proof of the VM path. |
| 5 | `scorecard-report.png` (or `.gif` scroll) | The dated scorecard HTML report — alert timeline, rule eval, k6 summary, rollout state. | Evidence-as-artifact (§11); a still is fine. |
| 6 | `crossplane-graph-provision.gif` | `kubectl get managed` / the resource graph as a `Website` claim **materialises children**. | Backs the Crossplane-as-IaC beat (new §S16). |

Optional extras if time allows: `argocd-selfheal.gif` (delete a resource → ArgoCD re-syncs) and
`clubhouse-serve.gif` (curl/browser hitting the running tenant) — but these three surfaces are
already **live** iframes, so record them only as insurance.

## Dropping a clip into the deck

1. Save the file at its exact `slides/public/surfaces/<surface>-<action>.gif` path.
2. On the relevant slide, set the surface embed to fallback and point at it, e.g.:

   ```html
   <img data-surface="backstage" data-surface-mode="fallback"
        src="/surfaces/backstage-xrd-edit.gif" alt="XRD edit regenerates the portal form" />
   ```

3. `task deck:build` (or `tests/deck/slidev-build.sh`) must stay green; `iframe-surfaces.sh` must
   still see ≥ 3 live iframes and every surface tagged `live|fallback`.

## Checklist before recording day

- [ ] Cluster up (`task cluster:up`) + the demo surfaces reachable (`task demo` dry-run).
- [ ] Chrome sized 1280×720, dark, clean chrome, 100% zoom.
- [ ] `ffmpeg` installed for GIF conversion.
- [ ] Record shots 1–4 (motion) + 5 (still); 6 if the Crossplane graph is up.
- [ ] Each GIF ≤ 8 MB; drop into `slides/public/surfaces/`; flip the slide embed to `fallback`.
- [ ] `task deck:build` green.

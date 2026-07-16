# Tasks — e8b-live-demo

DECIDED-B: on-demand bring-up (not standing). Offline-authored; live pending.

- [x] E8b-S01 — On-demand bring-up: `task e8b:up` (compose E1g substrate +
      re-sync GitOps app-of-apps + wait healthy) and `task e8b:down` (ruthless
      teardown, delegates to `e1g:down`), both live-guarded.
      `docs/runbooks/gridscale-live-demo.md` covers bring-up → verify → demo →
      teardown + cost note + the on-demand (not-standing) framing.
- [x] E8b-S02 — Read-only demo surfaces over the platform Gateway: static
      scorecard site + anonymous-viewer Grafana (`deploy/monitoring/e8b-demo/`),
      HTTPRoute on the clubhouse `https` listener with a scoped ReferenceGrant,
      cloud-only Let's Encrypt TLS (staging→prod, excluded by location). Wired
      via the `e8b-demo` Argo CD Application + dedicated closed-list AppProject
      (destinations = monitoring + gateway).
- [x] Gate: `task test:smoke:e8b` (offline — targets/runbook/manifests +
      kubeconform + shellcheck + route/RBAC/namespace-consistency asserts),
      wired into `test:meta:ci` (hence `task verify`). Live serve/health check
      authored in `tests/smoke/e8b-serve.sh`, gated behind `E8B_LIVE=1`.
- [ ] LIVE (deferred to the live cycle): `task e8b:up` on real gridscale creds,
      re-sync onto GSK, `E8B_LIVE=1 task test:smoke:e8b` green, `task e8b:down`.

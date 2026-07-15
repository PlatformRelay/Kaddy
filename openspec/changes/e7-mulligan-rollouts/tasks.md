# Tasks — E7

- [x] Install Argo Rollouts controller (v1.9.0, pinned) + Gateway API trafficRouting plugin (v0.16.0) — GitOps-managed via `deploy/rollouts/` + `deploy/apps/rollouts.yaml`; plugin wired in `argo-rollouts-config` CM + extra HTTPRoute RBAC (`deploy/rollouts/config.yaml`)
- [x] Blue/green + analysis (REQ-E7-S01-*) — `deploy/workloads/mulligan/rollout-bluegreen.yaml` (active/preview, autoPromotionEnabled:false); pre-promotion `AnalysisTemplate` against live Prometheus (`analysistemplate.yaml`)
- [x] Canary + weights (REQ-E7-S02-*) — HTTPRoute weight mutation PROVEN live (`100/0 → 20 → 50 → 100`); closes E2-deferred REQ-E2-S02-03; `ignoreDifferences` (jqPathExpressions) on the workloads App
- [x] `task demo` + recording hook (REQ-E7-S03-*) — `hack/demo/mulligan.sh` (two-act, idempotent); asciinema hook documented in `evidence/demo/README.md`
- [~] Chaos (REQ-E7-S04-*) — IN-BOUNDARY auto-rollback DONE (`hack/demo/mulligan-abort.sh`, `task demo:chaos`); Caddy/nginx-VM chaos DEFERRED (out of E7 boundary — Caddy-MVP / gridscale epics; honest stubs `tests/smoke/e7-s04-01.sh`, `hack/demo/chaos-nginx.sh`)
- [x] Gate: `task test:smoke:e7` (live weight shift + demo + abort) + chainsaw suites present (skip:true in CI — live-cluster-only)

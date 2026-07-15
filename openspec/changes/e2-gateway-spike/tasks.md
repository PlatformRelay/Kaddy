# Tasks — E2

- [x] E2-S01: Assert Gateway API + Cilium GatewayClass + LB-IPAM pool (REQ-E2-S01-*) — proven live by E1e (`get gatewayclass`/`get crd`/`get ciliumloadbalancerippool`)
- [x] E2-S02: GitOps Gateway + HTTPRoute + weight mutation (REQ-E2-S02-*) — Gateway+HTTPRoute `/` proven by E1/E1e (argocd Gateway `10.89.0.200`, HTTPS→`127.0.0.1:30443`); **REQ-E2-S02-03 weight mutation NOW DONE in E7** — Argo Rollouts Gateway API plugin shifts the `mulligan` HTTPRoute weights live (`tests/smoke/e7-s02-03.sh`, `tests/chainsaw/rollouts/canary-weights.yaml`)
- [x] E2-S03: Spike decision doc (REQ-E2-S03-*) — `docs/decisions/e2-gateway-spike.md`
- [ ] Gate: `chainsaw test tests/chainsaw/gateway` (subset) + smoke scripts → deferred; read-only close-out — chainsaw mutates the shared cluster (parallel lane active). E1/E1e smoke scripts are the standing evidence.

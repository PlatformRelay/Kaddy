# Tasks — E2

- [x] E2-S01: Assert Gateway API + Cilium GatewayClass + LB-IPAM pool (REQ-E2-S01-*) — proven live by E1e (`get gatewayclass`/`get crd`/`get ciliumloadbalancerippool`)
- [ ] E2-S02: GitOps Gateway + HTTPRoute + weight mutation (REQ-E2-S02-*) — **add Chainsaw tests first** — Gateway+HTTPRoute `/` proven by E1/E1e (argocd Gateway `10.89.0.200`, HTTPS→`127.0.0.1:30443`); weight mutation + Chainsaw → deferred to E7 (REQ-E7-S02-01, `trafficRouting.plugins` gatewayAPI)
- [x] E2-S03: Spike decision doc (REQ-E2-S03-*) — `docs/decisions/e2-gateway-spike.md`
- [ ] Gate: `chainsaw test tests/chainsaw/gateway` (subset) + smoke scripts → deferred; read-only close-out — chainsaw mutates the shared cluster (parallel lane active). E1/E1e smoke scripts are the standing evidence.

# Tasks — E7

- [ ] Blue/green + analysis (REQ-E7-S01-*)
- [ ] Canary + weights (REQ-E7-S02-*) — HTTPRoute weight mutation per [docs/decisions/e2-gateway-spike.md](../../../docs/decisions/e2-gateway-spike.md) (E2 L0 proven; ADR-0104 L1/L2 fallback if GSK locks Gateway API config)
- [ ] `task demo` + recording (REQ-E7-S03-*)
- [ ] Chaos scripts (REQ-E7-S04-*)
- [ ] Gate: `chainsaw test tests/chainsaw/rollouts` && `task demo`

# Change: E2 — Cilium Gateway API spike

## Why

Prove Cilium Gateway + HTTPRoute path/weight routing on the platform cluster before E4/E7. De-risk
GSK phase 2 (same CNI family). Caddy is **not** the platform ingress — tenant scaffolds own Caddy
(ADR-0104, D-019).

## What

- Assert Gateway API CRDs + `GatewayClass` `cilium` + LB-IPAM pool (phase 1 handoff from driving-range E10).
- GitOps `Gateway` + sample HTTPRoute; weight-mutation spike for Rollouts.

## Non-goals

- Installing Cilium (owned by driving-range E4/E10 or GSK).
- `caddyserver/gateway` on the platform cluster.

## Specs

- [specs/gateway/spec.md](specs/gateway/spec.md) — REQ-E2-S01 through REQ-E2-S03

## Decision output

`docs/decisions/e2-gateway-spike.md` per ADR-0104 fallback ladder.

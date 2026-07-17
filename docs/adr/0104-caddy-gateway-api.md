# ADR-0104: Platform ingress — Cilium Gateway API (Caddy is a tenant product)

**Theme:** 01 · Foundations · **Status:** Current · **Supersedes:** Caddy-as-platform-gateway (D-019) · **Retconned:** ARCH-2 / D-026 (2026-07-15)

> **Retcon note (ARCH-2 / D-026, 2026-07-15).** The 2026-07-15 health audit (ARCH-2/ARCH-3) confirmed
> and hardened this ADR's decision: the **platform edge = Cilium Gateway API (Envoy)**; **Caddy is the
> tenant MVP (Website-as-a-Service), NOT the platform gateway/ingress** (D-019). Platform-edge monitoring
> is therefore **decoupled from Caddy** — the Cilium/Envoy edge never emits a `job="caddy"` scrape target,
> so the landed E5 `caddy_*` marshal alerts could never fire against the platform as wired. Per the
> operator-confirmed marshal decision (**Option A — park**, `agent-context/decisions.md` D-026), those
> `caddy_*` PrometheusRules + their promtool fire/silent tests were **migrated out of active platform
> monitoring** into the **`e-caddy-mvp` VM-variant alerting slice**
> ([`openspec/changes/e-caddy-mvp/`](../../openspec/changes/e-caddy-mvp/), REQ-CADDY-S01-03), where
> in-cluster Prometheus scrapes the Caddy VM's external `/metrics`. See
> [`deploy/caddy-mvp/monitoring/`](../../deploy/caddy-mvp/monitoring/). The decision below stands; this
> note only records the ARCH-2 monitoring consequence.

## Context

The **gridscale hiring exercise** requires Caddy as a reverse proxy with monitoring — satisfied by
**Backstage-scaffolded tenant products** (Caddy on VM or K8s), not by running Caddy as the platform
ingress controller.

The **platform cluster** needs Gateway API for HTTPRoute path routing, TLS, and Argo Rollouts weight
mutation. On driving-range, **Cilium** is the CNI with kube-proxy replacement and native **Gateway API**

+ **LB-IPAM/L2** (driving-range ADR-0203, `driving-range/docs/adr/0203-edge-cilium-gateway.md`).
On **GSK 1.29+**, Cilium is the default CNI; edge uses **gridscale LBaaS** annotations on the Gateway
controller `LoadBalancer` Service (phase 2).

## Decision

**Platform ingress = Cilium Gateway API** — no MetalLB, no `caddyserver/gateway` on the platform.

| Layer | Phase 1 (driving-range) | Phase 2 (GSK) |
| --- | --- | --- |
| CNI + Gateway | Cilium (installed in driving-range E4/E10) | GSK-managed Cilium |
| LoadBalancer IP | Cilium LB-IPAM + L2 (`192.168.100.200–.220`) | gridscale CCM → LBaaS |
| TLS | cert-manager DNS-01 (Cloudflare) on Gateway listener | LBaaS HTTP mode LE and/or cert-manager |
| Tenant Caddy | Backstage scaffold → separate repo/VM/K8s | Same |

**E2 spike exit criteria:**

1. `GatewayClass` `cilium` + `Gateway` programmed with an address.
2. HTTPRoute `/` → platform landing (or Backstage) returns 200.
3. HTTPRoute weight patch 50/50 works (Rollouts prep for tenant K8s Caddy scaffold, E7).

**Fallback ladder** (record in `docs/decisions/e2-gateway-spike.md`):

| Level | Approach | Trade-off |
| --- | --- | --- |
| L0 | Cilium Gateway API (primary) | Matches GSK CNI; LB-IPAM on bare metal |
| L1 | Envoy Gateway + LBaaS Service (GSK docs) | If GSK locks Cilium Gateway API config |
| L2 | Ingress + Service swap | No HTTPRoute weights; blue/green via Service only |

## Consequences

+ E2 validates Cilium Gateway, not Caddy controller.
+ E5 platform monitoring focuses on Gateway/Cilium metrics; the **`caddy_*` scrape rules + alerts belong
  to the `e-caddy-mvp` VM-variant slice** ([`deploy/caddy-mvp/monitoring/`](../../deploy/caddy-mvp/monitoring/),
  REQ-CADDY-S01-03), parked out of active platform monitoring (ARCH-2, D-026).
+ ADR-0401 Caddy operator remains optional for tenant lifecycle, not platform ingress.

## References

+ [Cilium Gateway API](https://docs.cilium.io/en/latest/network/servicemesh/gateway-api/gateway-api/)
+ [gridscale GSK Load Balancer](https://my.gridscale.io/product-documentation/cloud-computing/products/paas/kubernetes/loadbalancing/introduction/)

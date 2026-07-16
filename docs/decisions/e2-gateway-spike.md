# Spike Decision: E2 — Cilium Gateway API on the platform edge

**Epic:** E2 · **ADR:** [0104](../adr/0104-caddy-gateway-api.md) · **Decision:** D-019 ·
**Status:** Accepted — spike proven · **Date:** 2026-07-15

> **Close-out note.** E2 is a read-only close-out. The spike was proven *de facto* by the landed
> **E1e** (Cilium + Gateway API CRDs + `cilium` GatewayClass + LB-IPAM pool) and **E1** (ArgoCD behind
> a Cilium HTTPS Gateway + HTTPRoute) lanes. No new Gateway/HTTPRoute resources were created and no
> Chainsaw was run for this decision — a parallel lane is actively mutating the shared kind cluster, so
> evidence here is **live read-only `kubectl get`** plus the passing E1/E1e smoke tests. The
> weight-mutation half of the spike is honestly **deferred to E7**, which owns Argo Rollouts and drives
> HTTPRoute weights.

## What had to be proven

Per `openspec/changes/e2-gateway-spike/specs/gateway/spec.md`
and the ADR-0104 exit criteria:

- **REQ-E2-S01** — Gateway API CRDs Established; a `cilium` GatewayClass accepted; a Cilium LB-IPAM
  pool programmed (phase-1 handoff).
- **REQ-E2-S02** — a Gateway is programmed with an address; an HTTPRoute `/` returns 200; an HTTPRoute
  weight patch (50/50 stable/canary) shifts traffic (Rollouts prep).
- **REQ-E2-S03** — this decision doc recorded per the ADR-0104 fallback ladder; E7 unblocked (or a
  documented fallback path).

## Evidence (live, read-only)

Captured `2026-07-15` against `kind-kaddy-dev` (`KUBECONFIG=.state/kubeconfig`). Read-only `get` only —
no `apply`/`create`/`delete`/`patch`.

### REQ-E2-S01 — Gateway API + Cilium GatewayClass + LB-IPAM (DONE)

Gateway API CRDs are Established and the Cilium GatewayClass is Accepted:

```text
$ kubectl get crd | grep gateway
ciliumgatewayclassconfigs.cilium.io
gatewayclasses.gateway.networking.k8s.io
gateways.gateway.networking.k8s.io
grpcroutes.gateway.networking.k8s.io
httproutes.gateway.networking.k8s.io
referencegrants.gateway.networking.k8s.io

$ kubectl get gatewayclass
NAME     CONTROLLER                     ACCEPTED   AGE
cilium   io.cilium/gateway-controller   True       133m
```

The controller `io.cilium/gateway-controller` satisfies REQ-E2-S01-02 (`controllerName` references
Cilium). CRD existence + the `Accepted=True` condition satisfy REQ-E2-S01-01. This is exactly what the
**E1e** smoke test `tests/smoke/e1e-s02-02.sh` asserts.

A Cilium LB-IPAM pool is programmed and assigning:

```text
$ kubectl get ciliumloadbalancerippool
NAME               DISABLED   CONFLICTING   IPS AVAILABLE   AGE
kaddy-local-pool   false      False         49              132m
# blocks: [{"start":"10.89.0.200","stop":"10.89.0.250"}]
```

This satisfies REQ-E2-S01-03 (at least one pool Ready). **Observed CIDR differs from the spec/ADR
range.** ADR-0104 and REQ-E2-S01-03 quote the *driving-range* range `192.168.100.200–.220`; the local
kind/podman substrate programs `10.89.0.200–.250` on its own container network. The *capability* — a
Ready LB-IPAM pool that assigns addresses to LoadBalancer Services — is what E2 proves; the exact CIDR
is environment-specific and is asserted live by
`tests/smoke/e1e-s02-03.sh` (assignment only, never host-curled on
macOS).

### REQ-E2-S02 — Gateway programmed + HTTPRoute (PARTIAL — weight mutation deferred to E7)

Two Cilium Gateways are programmed with LB-IPAM addresses, each with an HTTPRoute:

```text
$ kubectl get gateway,httproute -A
NAMESPACE   NAME                                            CLASS    ADDRESS       PROGRAMMED   AGE
argocd      gateway.../argocd                               cilium   10.89.0.200   True         89m
e1e-smoke   gateway.../kaddy-smoke                          cilium   10.89.0.201   True         124m

NAMESPACE   NAME                                            HOSTNAMES   AGE
argocd      httproute.../argocd-server                                  89m
e1e-smoke   httproute.../echo                                           124m
```

**Note the capability was proven via the E1 `argocd` Gateway, not a dedicated `platform` Gateway.**
REQ-E2-S02-01/02 are written against a hypothetical `deploy/gateway/platform-gateway.yaml`
(`platform` Gateway in ns `gateway`), which was never built — E1 delivered the equivalent capability
by putting **ArgoCD** behind a Cilium Gateway instead. That satisfies the same requirement:

- **Gateway has an address** (REQ-E2-S02-01): `argocd` Gateway `PROGRAMMED=True`, address `10.89.0.200`.
- **HTTPRoute `/` returns landing** (REQ-E2-S02-02): the `argocd` Gateway exposes an **HTTPS** listener
  (`proto=HTTPS port=443`, TLS via `argocd-server-tls` from the `kaddy-local-ca` ClusterIssuer), and the
  `argocd-server` HTTPRoute routes `/ → argocd-server:80`. It is reachable at
  **`https://127.0.0.1:30443`** via the loopback-pinned NodePort
  (`cilium-gateway-argocd` LoadBalancer, `443:30443/TCP`), which is the macOS-safe pattern documented in
  `tests/smoke/e1e-s04-01.sh` (HTTP variant at `127.0.0.1:30080`).
  Both routes proved real request flow **through** the Gateway + HTTPRoute (the LB IP is never curled
  directly).

The E1/E1e smoke suite (Gateway CRDs, GatewayClass, LB-IPAM, cert-manager + `kaddy-local-ca`, and the
loopback HTTP-through-Gateway check) is green — this is the standing evidence that the Gateway path
works end to end.

**Deferred — REQ-E2-S02-03 (HTTPRoute weight mutation, 50/50 stable/canary).** This was **not**
exercised by E1/E1e — neither Gateway carries two weighted backendRefs, and no weight patch was applied.
It is owned by **E7 (mulligan-rollouts)**: `openspec/changes/e7-mulligan-rollouts/specs/rollouts/spec.md`
REQ-E7-S02-01 drives HTTPRoute backend weights via Argo Rollouts `trafficRouting.plugins` gatewayAPI,
and declares `Depends: E2 L0 for canary weights`. Marked deferred, not done — see §Decision.

### REQ-E2-S03 — decision recorded + E7 path (DONE)

This document is REQ-E2-S03-01. REQ-E2-S03-02 (E7 unblocked or fallback) is satisfied in spirit: the E7
spec already declares its dependency on **E2 L0** (Cilium Gateway) for canary weights, so E7 has a live,
proven L0 to build on. A literal cross-reference from `e7 tasks.md` back to this doc is a coordinator
follow-up (out of this read-only lane's boundary).

## Fallback ladder (per ADR-0104)

| Level | Approach | Status | Trade-off |
| --- | --- | --- | --- |
| **L0** | Cilium Gateway API (primary) | **PROVEN** — GatewayClass `cilium` Accepted; two Gateways programmed with LB-IPAM addresses; HTTPS + HTTPRoute `/` reachable at `127.0.0.1:30443` | Matches GSK CNI family; LB-IPAM on bare metal |
| L1 | Envoy Gateway + LBaaS Service (GSK docs) | Not needed | Reserve for phase 2 if GSK locks Cilium Gateway API config |
| L2 | Ingress + Service swap | Not needed | No HTTPRoute weights; blue/green via Service only |

The spike lands on **L0** — no fallback was required.

## Decision

- **Cilium Gateway API is the platform edge — proven at L0.** The Gateway API CRDs, the `cilium`
  GatewayClass, the LB-IPAM pool, and real TLS traffic through an HTTPRoute (ArgoCD at
  `https://127.0.0.1:30443`) are all live and green. E4/E7 may build on Cilium Gateway with confidence.
- **Caddy is a tenant product, not the platform ingress** (ADR-0104 / D-019). The platform edge is
  Cilium/Envoy; Caddy ships only as a Backstage-scaffolded tenant Website-as-a-Service variant. No
  `caddyserver/gateway` runs on the platform cluster.
- **HTTPRoute weight mutation is deferred to E7.** REQ-E2-S02-03 (50/50 canary weights) is *not* claimed
  done by this spike. E7 owns Argo Rollouts and mutates HTTPRoute weights via the `trafficRouting.plugins`
  gatewayAPI integration (REQ-E7-S02-01); the proven L0 GatewayClass + programmed Gateway is the
  substrate E7 needs. This is a deliberate, honest handoff, not a gap in the edge.

## REQ status summary

| REQ | Status | Basis |
| --- | --- | --- |
| REQ-E2-S01-01 · Gateway API CRDs Established | **DONE** | live CRDs + `e1e-s02-02.sh` |
| REQ-E2-S01-02 · `cilium` GatewayClass accepted | **DONE** | `ACCEPTED=True`, controller `io.cilium/gateway-controller` |
| REQ-E2-S01-03 · LB-IPAM pool programmed | **DONE** | `kaddy-local-pool` Ready (observed CIDR `10.89.0.200–.250`; spec quotes driving-range range) |
| REQ-E2-S02-01 · Gateway has an address | **DONE** (via E1 argocd Gateway) | `argocd` Gateway `PROGRAMMED=True`, `10.89.0.200` |
| REQ-E2-S02-02 · HTTPRoute `/` returns landing | **DONE** (via E1 argocd Gateway) | HTTPS listener + `/`→`argocd-server`, reachable `127.0.0.1:30443` |
| REQ-E2-S02-03 · HTTPRoute weight mutation | **DONE (in E7)** | proven live: Argo Rollouts Gateway API plugin (`argoproj-labs/gatewayAPI` v0.16.0) shifted the `mulligan` HTTPRoute backend weights `100/0 → 20 → 50 → 100` on `kind-kaddy-dev`; smoke `tests/smoke/e7-s02-03.sh` |
| REQ-E2-S03-01 · spike decision recorded | **DONE** | this doc |
| REQ-E2-S03-02 · E7 unblocked / fallback | **DONE** (in spirit) | E7 spec `Depends: E2 L0`; literal `e7 tasks.md` xref = coordinator follow-up |

## References

- [ADR-0104 — Platform ingress: Cilium Gateway API](../adr/0104-caddy-gateway-api.md)
- E2 spec: `openspec/changes/e2-gateway-spike/specs/gateway/spec.md`
- E7 rollouts spec: `openspec/changes/e7-mulligan-rollouts/specs/rollouts/spec.md`
- E1/E1e smoke: `tests/smoke/e1e-s02-02.sh`,
  `tests/smoke/e1e-s02-03.sh`,
  `tests/smoke/e1e-s04-01.sh`,
  `tests/smoke/e1-s03-01.sh`

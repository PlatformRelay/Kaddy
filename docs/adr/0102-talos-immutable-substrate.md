# ADR-0102: Two-phase substrate — driving-range (local Talos) then gridscale GSK

**Theme:** 01 · Foundations · **Status:** Amended · **Amended:** D-017 (local-first sequencing), **D-025** (phase-1 substrate → kind + Cilium; local Talos deferred)

> **Superseding note (D-025, 2026-07-15).** The **phase-1 local substrate is now a `kind` + Cilium
> cluster** ([E1e](../../openspec/changes/e1e-kind-local-cluster/), landed), **not** the 3-node Talos
> driving-range this ADR describes. Phase-1 development stalled for hours on libvirt/Talos yak-shaving with
> no working cluster, so D-025 pivoted local dev to kind (single control-plane node, Cilium 1.18 CNI +
> Gateway API + LB-IPAM/L2, cert-manager). The **3-node Talos driving-range is deferred to an optional
> maturity-contrast spike** (like Talos-on-gridscale in D-015) and is no longer a blocker for E1. **Phase 2
> (gridscale GSK) is unchanged** — everything below about GSK still holds. The Talos content is retained for
> that deferred spike, not deleted.

## Context

We need a Kubernetes substrate for Caddy and platform workloads. The **gridscale lab** is the
employer-facing target ([D-013](../../agent-context/decisions.md)), but credits are finite and the
operator wants to rehearse on a **local 3-node Talos cluster** first
([driving-range](../../driving-range/)).

**driving-range** (sibling repo): 1 control plane + 2 workers on libvirt/KVM, OpenTofu-declared,
survives reboot, **Cilium Gateway + LB-IPAM/L2** + `local-path-provisioner` (no MetalLB). It replaces
`kind` for long-lived dev.

**gridscale GSK** remains the phase-2 production-shaped target: managed k8s, CCM→LBaaS, CSI,
Let's Encrypt at the edge.

## Decision

### Phase 1 — driving-range (now)

- **Substrate:** local Talos cluster built and owned by [driving-range](../../driving-range/) — not
  kaddy day-0 IaC.
- **kaddy E1:** kubeconfig handoff from driving-range → bootstrap ArgoCD only.
- **Edge:** Cilium Gateway API + LB-IPAM/L2 (driving-range E10) — **not** MetalLB, **not** platform Caddy.
- **TLS:** cert-manager + Let's Encrypt staging (or self-signed for lab).
- **Stateful:** none required for platform identity (Dex + GitHub).
- **E6 legacy nginx:** in-cluster Deployment stand-in **or** a host libvirt VM — no
  `provider-gridscale` until phase 2.

### Phase 2 — gridscale lab (deferred, E1g / E6g / E8b)

- **Substrate:** GSK via `gridscale_k8s` (release ≥ 1.30, provider v2).
- **Edge:** gridscale LBaaS (L7 + auto Let's Encrypt).
- **State / evidence:** gridscale Object Storage.
- **Object Storage** for tofu state + evidence.
- **Self-service infra:** Upjet-generated `provider-gridscale` + `gridscale_server` nginx VM
  ([ADR-0105](0105-crossplane-self-service.md)).

**Gate to start phase 2:** E3–E7 green on driving-range (GitOps platform proven locally).

## Consequences

- Zero gridscale spend during early iteration; platform GitOps manifests are substrate-agnostic.
- Must re-verify TLS, LoadBalancer, and Crossplane paths on GSK before interview (document delta).
- driving-range and kaddy are **separate repos** — handoff is kubeconfig + documented assumptions
  (Cilium `GatewayClass`, LB-IPAM pool, default StorageClass).

## References

- [driving-range README](../../driving-range/README.md)
- [gridscale_k8s resource](https://registry.terraform.io/providers/gridscale/gridscale/latest/docs/resources/k8s)

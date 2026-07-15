# Change: E1e — Local kind substrate (Cilium Gateway API)

## Why

Phase-1 development was blocked on the local Talos [driving-range](../../../driving-range/) cluster (D-017),
which cost the operator hours of libvirt/Talos yak-shaving without a working cluster. A disposable,
reproducible **kind** cluster unblocks E1–E8 locally at $0. Per **D-025** (amends D-017), kind is the
phase-1 local substrate; driving-range Talos becomes an optional maturity-contrast spike; gridscale GSK
remains phase 2 (D-015).

Crucially, kind runs **Cilium** (CNI + Gateway API + LB-IPAM/L2) so the platform **edge stays Cilium
Gateway API** (D-019, D-022) — the existing E1–E8 specs' Cilium/GatewayClass/`CiliumLoadBalancerIPPool`
assertions pass unmodified, and the edge architecture still matches gridscale GSK phase 2.

## What

- `hack/cluster/kind/cluster.yaml` — Cilium-ready kind config (`disableDefaultCNI`, `kubeProxyMode: none`,
  pinned node image, loopback-bound `extraPortMappings`)
- `hack/cluster/*.sh` + `hack/cluster/versions.env` — idempotent, health-checked bring-up (mirrors
  `kollect/hack/kind` pattern), Helm-based (no cilium CLI / terraform / mkcert dependency)
- Cilium install: `kubeProxyReplacement`, `ipam.mode=kubernetes`, `gatewayAPI.enabled`, `l2announcements.enabled`
- `CiliumLoadBalancerIPPool` + `CiliumL2AnnouncementPolicy` carved from the docker `kind` bridge subnet
- cert-manager `v1.18.2` (pinned) + self-signed `kaddy-local-ca` ClusterIssuer for local TLS
- `Taskfile.yml` targets: `cluster:up` / `cluster:down` / `test:smoke:e1e`
- macOS-safe HTTP smoke via `extraPortMappings` / `port-forward` (LB IP asserted assigned, not curled)

## Non-goals

- Talos / libvirt / driving-range provisioning (deferred; D-025)
- gridscale GSK / Terramate (phase 2, E1g)
- Platform bootstrap (ArgoCD/GitOps) — that is **E1**, running on top of this substrate
- Ingress-nginx / HAProxy (references use it; we stay Cilium Gateway API per D-019)

## Counterpoints considered

- **kind loses the immutable-Talos showpiece and reboot persistence** (D-017's rationale). Accepted: the
  scarce time budget should buy E1–E8 progress, not libvirt debugging. Guard: keep **Cilium** Gateway API
  (not kindnet/ingress-nginx) so the edge still matches the phase-2 GSK stack.
- **Cilium-on-kind adds bring-up complexity** vs. plain kindnet. Accepted: it is a documented path and
  preserves D-019/D-022, avoiding a rewrite of E1–E8's Cilium assertions.
- **Reintroduces `kind`** which D-017 explicitly replaced. Accepted and scoped: local dev only; phase-2
  substrate is unchanged (GSK).

## Links

- ADR-0104 (edge Cilium Gateway) · D-025, D-019, D-022 · amends D-017
- References: `kollect/hack/kind`, `kollect/references/cluster-setup`, `driving-range` ADR-0203,
  `references/PocketIDP`

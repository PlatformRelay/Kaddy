# Change: E1 — Platform bootstrap on driving-range

## Why

Bootstrap GitOps on the local Talos cluster before gridscale spend. Cilium edge is provisioned by
[driving-range](../../../driving-range/) E10 — not MetalLB, not kaddy OpenTofu.

## What

- Handoff contract (kubeconfig, Cilium Gateway/LB-IPAM, StorageClass)
- ArgoCD bootstrap Application
- Cluster baseline smoke checks

## Non-goals

- Cilium / Talos / libvirt (driving-range repo)
- gridscale Terramate (E1g)

## Links

- ADR-0102, ADR-0104 · D-017, D-019

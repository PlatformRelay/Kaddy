# Change: E1 — Platform bootstrap (on E1e local substrate)

## Why

Bootstrap GitOps on the local **kind** cluster ([E1e](../e1e-kind-local-cluster/)) before gridscale spend.
The Cilium edge (Gateway API + LB-IPAM) is provisioned by **E1e** — not MetalLB, not kaddy OpenTofu. Per
D-025 (amends D-017), phase-1 substrate is kind + Cilium; driving-range Talos is deferred.

## What

- Handoff contract (kubeconfig, Cilium Gateway/LB-IPAM, StorageClass) on the E1e cluster
- ArgoCD bootstrap Application
- Cluster baseline smoke checks

## Non-goals

- Substrate + Cilium edge provisioning — that is **E1e**
- Talos / libvirt / driving-range (deferred; D-025)
- gridscale Terramate (E1g)

## Links

- ADR-0104 · D-025 (amends D-017), D-019

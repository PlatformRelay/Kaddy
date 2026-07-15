# Runbook — driving-range → kaddy handoff

**Phase 1 only.** The platform cluster is built in [driving-range](https://github.com/PlatformRelay/driving-range) (local Talos + Cilium). Kaddy bootstraps GitOps on top.

## Prerequisites

- driving-range E10 **Ready** (Cilium Gateway API + LB-IPAM/L2)
- driving-range E7 default StorageClass (`local-path-provisioner`)
- Tailscale or LAN route to cluster API (`192.168.100.x`)

## Handoff artifacts

| Artifact | Source | Notes |
| --- | --- | --- |
| kubeconfig | `driving-range` tofu output / documented path | Talos admin context |
| Cilium `GatewayClass` | `kubectl get gatewayclass cilium` | Controller: Cilium |
| LB-IPAM pool | `kubectl get ciliumloadbalancerippool` | CIDR `192.168.100.200–.220` (driving-range E10) |
| Gateway API CRDs | Established | From Cilium Gateway install |
| StorageClass | `local-path` (default) | driving-range E7 |

**Not used:** MetalLB, `caddyserver/gateway` on the platform cluster.

## Steps

1. Export kubeconfig from driving-range per that repo's runbook.
2. Verify baseline:
   ```bash
   kubectl get nodes
   kubectl get pods -n kube-system -l k8s-app=cilium
   kubectl get gatewayclass cilium
   kubectl get ciliumloadbalancerippool
   kubectl get storageclass
   ```
3. Bootstrap Argo CD from kaddy:
   ```bash
   kubectl apply -f deploy/bootstrap/argocd.yaml
   kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
   ```
4. After E2 sync, record platform Gateway address:
   ```bash
   kubectl get gateway -n gateway platform -o jsonpath='{.status.addresses[0].value}'
   ```
5. Point DNS (Cloudflare) at that IP for lab hostnames (`dex.platformrelay.dev`, etc.).

## Phase 2 (gridscale GSK)

Replace handoff with E1g Terramate outputs: GSK kubeconfig, gridscale LBaaS annotation docs, managed Cilium. Same kaddy GitOps tree; different substrate runbook (`docs/runbooks/gridscale-handoff.md` when E1g lands).

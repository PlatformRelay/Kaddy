# E8b live attempt — GSK substrate PROVEN; app-layer verify blocked by egress (2026-07-17)

Ephemeral create→verify→destroy. Result: **substrate live-proven; app-of-apps + demo-surface
verification blocked by a corporate egress allowlist on this network (NOT a platform defect).**

## Substrate — LIVE-PROVEN (tofu, real gridscale)
Provisioned the full E1g substrate the E8b demo composes on, all `tofu apply` exit 0:
- **object-storage anchor** (`kaddy-tfstate` bucket + access key, local state).
- **network stack** (network + firewall + IPv4 + IPv6; S3 remote state in the anchor bucket).
- **GSK cluster** `kaddy-gsk` (cluster_uuid `d3f3b18e-…`, release 1.30.14-gs2, 1 node / 2c / 4Gi) →
  status **active**, kubeconfig produced (API `185.241.34.82:6443`). Same shape as the E1g-S03 proof.

## App-layer verify — BLOCKED (corporate egress allowlist)
`task bootstrap:argocd` / `bootstrap:e3` (app-of-apps → e8b-demo scorecard + read-only Grafana over
Gateway TLS) require kubectl/ArgoCD against the GSK API `:6443`. That endpoint is **unreachable from
this network**, and the cause is evidence-characterised (not assumed):

| target | port | result |
| --- | --- | --- |
| api.gridscale.io (allowlisted) | 443 | reachable (404) |
| github.com (allowlisted) | 443 | reachable (200) |
| api.ipify.org (arbitrary domain) | 443 | **blocked** (000) |
| 1.1.1.1 (arbitrary IP) | 443 | **blocked** (000) |
| example.com (k8s API port) | 6443 | **blocked** (000) |
| GSK API 185.241.34.82 | 6443 | **blocked** (000, silent SYN-drop; still blocked 24 min post-active) |

→ The egress permits `:443` only to allowlisted domains; arbitrary IPs/domains and `:6443` are dropped.
The GSK API (arbitrary public IP, non-standard port) can't be reached. NOT transient (24-min patient
probe), NOT a GSK/manifest defect. The e8b-demo artifacts (`deploy/monitoring/e8b-demo/`: read-only
Grafana, scorecard, HTTPRoute, SEC-19 netpol) + the offline gate (`task test:smoke:e8b`) are all
present + offline-verified (audit-confirmed 2026-07-17).

## Path to close (for a network with :6443 egress)
Bring the substrate up (as above), then run `bootstrap:argocd` + `bootstrap:e3` + `E8B_LIVE=1 task
test:smoke:e8b` from a host that can reach the GSK API on `:6443` — either a network without the
egress allowlist, or a gridscale jump VM on the tenant (gridscale's own network reaches `:6443`).
Caveat (design): the app-of-apps has never run on GSK; it assumes Cilium + Gateway API and may need
adaptation to GSK's CNI — treat the first GSK app-of-apps sync as an integration task, not a no-op.

## Cost discipline
Everything created was destroyed (GSK 4m42s, network, anchor bucket emptied + deleted). Tenant
API-audited **clean**: 0 servers / 0 ips / 0 storages / 0 paas / 0 kaddy-networks / 0 kaddy-marketplace
/ 0 kaddy-keys (only the pre-existing panel key + the 2 built-in networks remain).

# Tasks — E1g gridscale day-0

Legend: `[x]` offline-authored + proven by `task test:smoke:e1g`; live apply is a
later serialized step (`task e1g:up`). See docs/runbooks/gridscale-day0.md.

- [x] E1g-S01: Terramate root + gridscale provider (`~> 2.2`) + object-storage backend anchor (offline: codegen + validate + tofu test)
- [x] E1g-S02: Network + firewall + IPs + conftest (offline)
- [x] E1g-S03: GSK cluster + one minimal node pool (offline; conftest caps release/sizing) — **LIVE-PROVEN 2026-07-17**: `kaddy-gsk` (1 node, release 1.30) provisioned on gridscale, `kubectl get nodes` → `node-pool-0-0 Ready v1.30.14`, torn down, tenant audited clean. Evidence: `evidence/live/e1g-gsk-2026-07-17.md`.
- [x] E1g-S04: LBaaS entry point (offline)
- [x] E1b-S04 (descoped here): Terramate codegen injects `modules/labels` into every stack
- [~] E1g-S05: kubeconfig + ArgoCD re-bootstrap + Dex public issuer URL — kubeconfig retrieval **LIVE-PROVEN** (see S03); app-of-apps re-sync + edge/TLS swap **splits into S05a–S05g (cloud-edge substrate swap)** — full story bodies in `agent-context/BACKLOG.md` § "Phase-2 gridscale cloud-edge". Confirmed UNBUILT 2026-07-18 while attempting a live standing demo: `task e8b:up` is guard-locked to `kind-kaddy-dev`, and GSK has no ingress edge (Gateway API/GatewayClass/LB-IPAM are kind-only via E1e).
  - [ ] Live conftest carve-out: exclude `gridscale_object_storage_*` from the live-plan `labels.rego` run — the provider gives those resources no `labels` arg (see runbook "Live conftest carve-out"). Do NOT relax `labels.rego`.
  - [ ] E1g-S05a: GSK-targetable bootstrap opt-in — named GSK context past the kind-only guard in `bootstrap:argocd`/`bootstrap:e3`; offline four-branch guard test (**start here** — cheapest, unblocks the live chain)
  - [ ] E1g-S05d: Reconcile LBaaS↔GSK network topology — the network stack is orphaned; GSK mints its own `k8s_private_network_uuid` (offline IaC, no dep)
  - [ ] E1g-S05b: Gateway API CRDs + `cilium` GatewayClass on GSK's built-in Cilium (CRDs NOT confirmed OOTB) — depends S05a
  - [ ] E1g-S05c: Expose Gateway via NodePort + wire LBaaS forwarding (LB-IPAM→external LBaaS→node) — depends S05b, S05d
  - [ ] E1g-S05e: Real `*.platformrelay.dev` demo hostname via cloud-only overlay (kind stays `.kaddy.local`) — depends S05b
  - [ ] E1g-S05f: DNS-01 ClusterIssuer + Cloudflare API-token Secret (HTTP-01→DNS-01, cloud-only, token never committed)
  - [ ] E1g-S05g: Cloudflare DNS records → LBaaS IPs + LE staging→prod + live public serve verify — depends S05c/S05e/S05f
  - [ ] E1g-S05h: **Security spike** — investigate + mitigate GSK worker-node public-IP exposure (node came up EXTERNAL-IP `185.241.34.168`; `gridscale_k8s ~>2.2` exposes no disable-public-IP arg — confirm provider/API limit + safe mitigation)
  - Build order: **S05a → S05d → S05b → S05c → (S05e ∥ S05f) → S05g.** S05h is an independent security spike (no dep).
- [x] Gate: `task test:smoke:e1g` (offline) — EXIT 0
- [ ] Live-proof: `task e1g:up` then re-sync app-of-apps (later serialized step, costs money)

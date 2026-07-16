# Tasks — E1g gridscale day-0

Legend: `[x]` offline-authored + proven by `task test:smoke:e1g`; live apply is a
later serialized step (`task e1g:up`). See docs/runbooks/gridscale-day0.md.

- [x] E1g-S01: Terramate root + gridscale provider (`~> 2.2`) + object-storage backend anchor (offline: codegen + validate + tofu test)
- [x] E1g-S02: Network + firewall + IPs + conftest (offline)
- [x] E1g-S03: GSK cluster + one minimal node pool (offline; conftest caps release/sizing)
- [x] E1g-S04: LBaaS entry point (offline)
- [x] E1b-S04 (descoped here): Terramate codegen injects `modules/labels` into every stack
- [ ] E1g-S05: kubeconfig + ArgoCD re-bootstrap + Dex public issuer URL (needs live cluster)
  - [ ] Live conftest carve-out: exclude `gridscale_object_storage_*` from the live-plan `labels.rego` run — the provider gives those resources no `labels` arg (see runbook "Live conftest carve-out"). Do NOT relax `labels.rego`.
- [x] Gate: `task test:smoke:e1g` (offline) — EXIT 0
- [ ] Live-proof: `task e1g:up` then re-sync app-of-apps (later serialized step, costs money)

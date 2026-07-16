# Tasks — E1c

## Offline-authored subset (H1 lane, D-024 — file-only, no cluster mutation)

- [x] Netpol default-deny baseline authored in `deploy/policies/network/`
      (gateway/monitoring/argocd + explicit allows; REQ-E1c-S01-01..03
      manifests — live proof stays with the Chainsaw suite below)
- [x] Kyverno verifyImages policy authored
      (`deploy/policies/kyverno/verify-signed-images.yaml`, REQ-E1c-S03-02;
      placeholder key, Audit, scoped to ghcr.io/platformrelay/* — real key
      lands with cosign/SEC-8)
- [x] Kyverno pod-security baseline authored (disallow-privileged,
      require-run-as-nonroot, disallow-latest-tag — ADR-0106; Audit until
      the in-cluster report is clean)
- [x] REQ-E1b-S05-02 data-classification value policy authored
      (`restrict-data-classification`, Enforce) + `require-kaddy-labels`
      refined with infra-namespace excludes
- [x] `kyverno test` CLI suites for every testable policy
      (`tests/kyverno/`, pass + fail fixtures; CLI pinned v1.18.2 — D-024)
- [x] Restricted AppProjects authored (`deploy/apps/projects/`:
      platform/observability/workloads — security review P1-2; NOT wired,
      root recurse is OFF)
- [x] `policies` child Application authored (`deploy/apps/policies.yaml`,
      manual-sync-only, project: default with TODO(cutover) → platform)
- [x] Enforcement/cutover runbook: `deploy/policies/README.md`

## Cluster-hardening follow-ups (NOT this lane)

- [ ] Install Kyverno v1.18.2 (pinned) + first human sync of the `policies`
      app; flip Audit → Enforce per README order
- [ ] Apply netpol baseline; Chainsaw: default-deny + unauthorized ingress
      (REQ-E1c-S01-*) + gateway-to-app allow proof
- [ ] AppProject cutover: apply `deploy/apps/projects/`, move Applications
      off `project: default`; un-skip Chainsaw labeling suite (TEST-4)
- [ ] Gate: `task test:chainsaw -- tests/chainsaw/security`

## Other E1c stories (unstarted)

- [ ] Trivy CI job (REQ-E1c-S02-*)
- [ ] Digest verify script (REQ-E1c-S03-01)
- [ ] ExternalSecret pattern (REQ-E1c-S04-*)
- [ ] `.sops.yaml` + encrypted `deploy/secrets/identity/dex-github.enc.yaml`
      (REQ-E1c-S05-*) — partially landed via identity epic
- [ ] Argo CD KSOPS plugin wiring (REQ-E1c-S05-02; pairs with E3-S01-03)

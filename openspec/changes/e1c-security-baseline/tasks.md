# Tasks — E1c

## Offline-authored subset (H1 lane, D-024 — file-only, no cluster mutation)

- [x] Netpol default-deny baseline authored in `deploy/policies/network/`
      (gateway/monitoring/argocd + explicit allows; REQ-E1c-S01-01..03
      manifests — live proof stays with the Chainsaw suite below)
- [x] Kyverno verifyImages policy authored
      (`deploy/policies/kyverno/verify-signed-images.yaml`, REQ-E1c-S03-02;
      Audit, scoped to ghcr.io/platformrelay/*). SEC-8 landed **keyless**:
      placeholder key replaced by the keyless attestor (issuer
      `https://token.actions.githubusercontent.com`, subject
      `.../Kaddy/.github/workflows/showcase-image.yaml@*`) matching the
      cosign signing in `.github/workflows/showcase-image.yaml`
      (`kaddy-showcase` image, REQ-CADDY-S05-02). Stays Audit
      (operator-ratified); Enforce flip criteria in
      deploy/policies/README.md — signing itself is CI-proven only after
      the first green `showcase-image` run on main (workflow authored,
      first CI run pending)
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

## Cluster-hardening cutover (DONE 2026-07-16 — this lane)

- [x] Install Kyverno v1.18.2 (pinned, vendored `deploy/kyverno/` +
      GitOps child app) + first human sync of the `policies` app; pod-security
      trio flipped Audit → Enforce one-by-one with canary restarts
      (verify-signed-images stays Audit honestly — placeholder cosign key)
- [x] Apply netpol baseline; Chainsaw: default-deny + unauthorized ingress
      (REQ-E1c-S01-*) + gateway-to-app allow proof — all three live-verified
      (skip:true in CI: vanilla kind has no Cilium; run commands in each
      file's annotations). Post-apply regression: e1/e4/e5/e7 smokes green
- [x] AppProject cutover: `deploy/apps/projects/` live, every deploy/apps
      Application off `project: default` (SEC-11); un-skipped Chainsaw
      labeling suite (TEST-4) — passes live AND in CI on vanilla kind
- [x] Grafana admin → Kubernetes Secret `monitoring/grafana-admin`
      (SEC-12; random password via `task bootstrap:e1c`, never committed;
      SOPS/KSOPS ownership follows with E1d)
- [x] Gate: `tests/smoke/e1c-exit.sh` (`task test:smoke:e1c`) — engine
      Ready, enforce matrix, deny-proof, netpols, projects, Grafana secret

## Other E1c stories (unstarted)

- [ ] Trivy CI job (REQ-E1c-S02-*)
- [ ] Digest verify script (REQ-E1c-S03-01)
- [ ] ExternalSecret pattern (REQ-E1c-S04-*)
- [ ] `.sops.yaml` + encrypted `deploy/secrets/identity/dex-github.enc.yaml`
      (REQ-E1c-S05-*) — partially landed via identity epic
- [ ] Argo CD KSOPS plugin wiring (REQ-E1c-S05-02; pairs with E3-S01-03)

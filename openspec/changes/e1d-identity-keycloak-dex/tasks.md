# Tasks — E1d Identity (Dex + GitHub)

## E1d-S00 — KSOPS chain (REQ-E3-S01-03 deferred debt, ADR-0110)

- [x] `task bootstrap:e1d` — imperative `argocd/sops-age` root secret (the ONE
      secret outside git, from `~/.config/sops/age/keys.txt`; never printed)
- [x] Repo-server KSOPS plugin, pinned `viaductoss/ksops:v4.3.3`
      (`deploy/bootstrap/argocd-repo-server-ksops-patch.yaml`; v4.4+ images
      are distroless/shell-less — bump needs a new install mechanism)
- [x] `argocd-cm` `kustomize.buildOptions: --enable-alpha-plugins --enable-exec`
- [x] Proof: `deploy/identity/` kustomization + ksops generator renders
      `deploy/secrets/{identity,argocd}/*.enc.yaml` into live, ArgoCD-tracked
      Secrets (`tests/smoke/e1d-s01-06.sh`)

## E1d-S01 — Dex + GitHub

- [x] Chainsaw `tests/chainsaw/identity/dex-ready.yaml` (live-run pattern)
- [x] `deploy/identity/dex/` manifests (pinned v2.44.0, nonroot,
      Kyverno-compliant labels; memory storage — single replica lab)
- [x] Secrets from KSOPS render, not ExternalSecret (no backing store on the
      lab — ADR-0110 counterpoint) and not imperative
- [x] `docs/runbooks/github-oauth-dex.md` — rewritten to the live kind-lab
      reality (issuer `https://dex.kaddy.local:30443`, OAuth-app callback incl.
      port, /etc/hosts, break-glass admin, interactive-login steps)
- [x] Green: REQ-E1d-S01-01/-02/-04/-05/-06; REQ-E1d-S01-03 green with the
      documented deviation (no `teams:` allowlist — deferred to E10, spec updated)

## E1d-S02 — Argo CD OIDC

- [x] Chainsaw unauthenticated API test (`argocd-unauth-denied.yaml`)
- [x] `oidc.config` (standalone Dex issuer, clientSecret via
      `$argocd-oidc-client:clientSecret` indirection) + `argocd-rbac-cm`
      (operator → admin via preferred_username/email; default readonly;
      `PlatformRelay:platform-admins` group mapping pre-wired)
- [x] Headless proof: full redirect chain to
      `github.com/login/oauth/authorize` with the SOPS-committed client_id
      (`tests/smoke/e1d-exit.sh`); interactive consent = operator step (runbook §6)
- [x] Green: REQ-E1d-S02-*

## E1d-S03 — Grafana OAuth — DEFERRED → E10

- [ ] **[E10]** Grafana `auth.generic_oauth` → Dex: needs a `grafana` static
      client in `deploy/identity/dex/configmap.yaml` + a new SOPS pair under
      `deploy/secrets/` (copy the argocd pattern) + kps values in the
      observability lane's boundary. Spec REQ-E1d-S03-01 marked deferred.

## E1d-S04 — NetworkPolicy

- [x] `deploy/policies/network/identity.yaml` — default-deny (ingress+egress),
      DNS egress, CNP `ingress`-entity → dex :5556, argocd ns → dex :5556,
      dex → :443 world (GitHub; toFQDNs tightening deferred to E10)
- [x] Chainsaw deny + allow branches (`netpol-deny-default.yaml`,
      `netpol-gateway-to-dex.yaml`)
- [x] Green: REQ-E1d-S04-*

## Exit

- [x] **[TEST-4]** `tests/chainsaw/identity/` is a real suite (placeholder
      replaced). Files stay `skip: true` with the same live-run annotation
      pattern as `tests/chainsaw/security/` — the CI chainsaw kind substrate
      has no Cilium/argocd/dex/KSOPS; verified live 2026-07-16 by flipping
      skip off (command documented in each file). If the chainsaw-CI rework
      lane adds a live profile, these un-skip there.
- [x] `chainsaw test tests/chainsaw/identity` green live (non-skipped run)
- [x] `task test:smoke:e1d` (e1d-exit bundle) green live

## Follow-ups owned by E1d but out of budget (honest deferrals)

- [ ] **[SEC-12 residual]** SOPS ownership of `monitoring/grafana-admin`:
      moving the Secret to `deploy/secrets/monitoring/` + the identity (or
      observability) app is mechanically trivial NOW that KSOPS is live, but
      swapping the password requires a Grafana rollout to re-read env
      (observability boundary) and would break e5's Grafana assertions
      mid-lane. Do it as a small follow-up: encrypt a new random password,
      add to the KSOPS generator, sync, `kubectl -n monitoring rollout
      restart deploy/kube-prometheus-stack-grafana`, keep `bootstrap:e1c`
      as documented fallback.
- [ ] **[E10]** Dex `teams:` allowlist + full team-based RBAC + Grafana/portal SSO.
- [ ] **[E10]** identity egress: replace the port-scoped world allow with
      Cilium `toFQDNs` (github.com, api.github.com) once a DNS-proxy CNP
      pattern exists in deploy/policies.

# Tasks — E1d Identity (Dex + GitHub)

## E1d-S01 — Dex + GitHub

- [ ] Add failing Chainsaw `tests/chainsaw/identity/dex-ready.yaml`
- [ ] `deploy/identity/dex/` manifest
- [ ] ExternalSecret for GitHub OAuth client credentials
- [x] `docs/runbooks/github-oauth-dex.md` — OAuth app + `.envrc` (operator)
- [ ] Green: REQ-E1d-S01-*

## E1d-S02 — Argo CD OIDC

- [ ] Failing Chainsaw unauthenticated API test
- [ ] `oidc.config` + RBAC group claims in Argo CD config
- [ ] Green: REQ-E1d-S02-*

## E1d-S03 — Grafana OAuth

- [ ] Grafana generic OAuth → Dex
- [ ] Green: REQ-E1d-S03-*

## E1d-S04 — NetworkPolicy

- [ ] Default-deny + allow gateway → Dex, apps → Dex
- [ ] Green: REQ-E1d-S04-*

## Exit

- [ ] **[TEST-4]** Un-skip `tests/chainsaw/identity/chainsaw-test.yaml` (currently `skip: true`).
      Gate: un-skip once `deploy/identity/` manifests land (E1d-S01 Dex + ExternalSecret);
      un-skipping now breaks the gate because the underlying identity manifests are unbuilt.
- [ ] `chainsaw test tests/chainsaw/identity` green (non-skipped)

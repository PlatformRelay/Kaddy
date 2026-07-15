# Spec — E1d Identity (Dex + GitHub)

Epic: E1d · ADR: [0107](../../../docs/adr/0107-identity-keycloak-dex.md) · **Decision:** D-018  
**Level:** L2 Chainsaw + smoke

---

## REQ-E1d-S01-01: Dex Deployment healthy

**Priority:** must · **Story:** E1d-S01 · **Level:** L2  
**Given** `deploy/identity/dex/` synced by Argo CD  
**When** `kubectl get pods -n identity -l app.kubernetes.io/name=dex`  
**Then** all pods Running  
**Test:** `tests/chainsaw/identity/dex-ready.yaml`

**Verify:** `chainsaw test tests/chainsaw/identity --filter dex-ready`

---

## REQ-E1d-S01-02: Dex OIDC discovery document

**Priority:** must  
**Given** Dex Service reachable via Gateway or port-forward  
**When** `curl -s https://dex.platformrelay.dev/.well-known/openid-configuration`  
**Then** JSON includes `issuer` and `authorization_endpoint`  
**Test:** `tests/smoke/e1d-s01-02.sh`

**Verify:** smoke script or Chainsaw assert

---

## REQ-E1d-S01-03: GitHub connector scoped to PlatformRelay

**Priority:** must  
**Given** Dex ConfigMap or Helm values  
**When** parsed  
**Then** connector `type: github`; `orgs[0].name` is **`PlatformRelay`** ([github.com/PlatformRelay](https://github.com/PlatformRelay)); teams include `platform-admins` and/or `platform-readonly`  
**Test:** `tests/fixtures/dex-github-connector-golden.yaml`

**Verify:** `diff deploy/identity/dex/connector.yaml tests/fixtures/dex-github-connector-golden.yaml` (or rendered golden)

---

## REQ-E1d-S01-04: GitHub OAuth plaintext not in Git

**Priority:** must  
**When** `gitleaks detect` and repo scan on `deploy/`  
**Then** no `GITHUB_APP_CLIENT_SECRET` literals  
**Test:** `tests/smoke/e1d-s01-04.sh`

**Verify:** `gitleaks detect` + `task scrub` green

---

## REQ-E1d-S01-05: OAuth credentials in SOPS-encrypted IaC

**Priority:** must · **ADR:** [0110](../../../docs/adr/0110-secrets-sops-age.md) · **Decision:** D-020  
**Given** `deploy/secrets/identity/dex-github.enc.yaml` encrypted with SOPS+age  
**When** `sops -d` with operator age key  
**Then** decrypted manifest contains `client-id` and `client-secret` keys only in `data`/`stringData`  
**Test:** `tests/smoke/e1d-s01-05.sh`

**Verify:** `test -f deploy/secrets/identity/dex-github.enc.yaml && test -f .sops.yaml`

---

## REQ-E1d-S01-06: Dex consumes Secret from GitOps (no imperative bootstrap)

**Priority:** must  
**Given** Dex Deployment/Helm values  
**When** inspected  
**Then** `clientID`/`clientSecret` come from Secret `dex-github-oauth` populated by KSOPS/SOPS at apply time — **no** documented `kubectl create secret` step  
**Test:** `tests/smoke/e1d-s01-06.sh`

**Verify:** `rg 'secretKeyRef|dex-github-oauth' deploy/identity/dex/` && `! rg 'kubectl create secret' docs/runbooks/github-oauth-dex.md`

---

## REQ-E1d-S02-01: Argo CD OIDC enabled

**Priority:** must · **Story:** E1d-S02 · **Level:** L2  
**Given** Dex issuer healthy  
**When** operator opens Argo CD UI  
**Then** login redirects to GitHub via Dex; local admin documented as break-glass only  
**Test:** `tests/chainsaw/identity/argocd-oidc-login.yaml`

**Verify:** Chainsaw suite (may use mock issuer in CI)

---

## REQ-E1d-S02-02: Unauthenticated Argo CD API denied

**Priority:** must  
**Given** OIDC enabled  
**When** `curl -s -o /dev/null -w '%{http_code}' https://$ARGOCD/api/v1/applications` without token  
**Then** status 401 or 403  
**Test:** `tests/chainsaw/identity/argocd-unauth-denied.yaml`

**Verify:** Chainsaw `tests/chainsaw/identity/argocd-unauth-denied.yaml`

---

## REQ-E1d-S02-03: Argo CD RBAC group mapping

**Priority:** must  
**Given** user in GitHub team mapped to `platform-admins`  
**When** JWT group claim inspected (documented test user)  
**Then** Argo CD RBAC grants admin policy  
**Test:** `tests/smoke/e1d-s02-03.sh`

**Verify:** documented manual check + `argocd-rbac-cm` golden file

---

## REQ-E1d-S03-01: Grafana generic OAuth via Dex

**Priority:** must · **Story:** E1d-S03 · **Level:** L2  
**Given** Grafana Helm values with `auth.generic_oauth`  
**When** user opens Grafana UI  
**Then** OAuth login via Dex available; anonymous auth disabled  
**Test:** `tests/smoke/e1d-s03-01.sh`

**Verify:** smoke or Chainsaw when Grafana lands in E3

---

## REQ-E1d-S04-01: Default-deny netpol in identity namespace

**Priority:** must · **Story:** E1d-S04 · **Level:** L2  
**Given** default-deny NetworkPolicy in `identity`  
**When** unrelated namespace pod tries Dex admin port  
**Then** connection denied  
**Test:** `tests/chainsaw/identity/netpol-deny-default.yaml`

**Verify:** Chainsaw `tests/chainsaw/identity/netpol-deny-default.yaml`

---

## REQ-E1d-S04-02: Allow gateway to Dex

**Priority:** must  
**Given** NetworkPolicy allow list  
**When** test pod in `gateway` namespace curls Dex Service  
**Then** HTTP 200 on `/.well-known/openid-configuration`  
**Test:** `tests/chainsaw/identity/netpol-gateway-to-dex.yaml`

**Verify:** Chainsaw `tests/chainsaw/identity/netpol-gateway-to-dex.yaml`

---

## REQ-E1d-EXIT: Identity suite green

**Priority:** must  
**Given** E1d complete  
**When** `chainsaw test tests/chainsaw/identity`  
**Then** all non-skipped tests pass  
**Test:** `tests/chainsaw/identity/chainsaw-test.yaml`

**Verify:** `task test:chainsaw:identity`

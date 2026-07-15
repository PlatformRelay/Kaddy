# Spec — E1c security baseline

Epic: E1c · ADR: [0106](../../../docs/adr/0106-security-baseline.md)  
**Levels:** L1 (manifest lint) · L2 Chainsaw (netpol, verifyImages)

---

## REQ-E1c-S01-01: Default-deny NetworkPolicy template

**Priority:** must  
**Given** `deploy/security/templates/default-deny-netpol.yaml`  
**When** applied to namespace `clubhouse`  
**Then** policy `default-deny-all` selects all pods, no ingress/egress rules  
**Test:** `tests/chainsaw/security/default-deny.yaml`

**Verify:** Chainsaw suite `tests/chainsaw/security/default-deny.yaml`

---

## REQ-E1c-S01-02: Allow gateway to app namespace

**Priority:** must  
**Given** default-deny in `clubhouse`  
**When** pod in `gateway` namespace curls clubhouse Service on port 8080  
**Then** connection succeeds  
**Test:** `tests/chainsaw/security/gateway-to-app.yaml`

**Verify:** Chainsaw `tests/chainsaw/security/gateway-to-app.yaml`

---

## REQ-E1c-S01-03: Deny random namespace to app

**Priority:** must  
**Given** default-deny policies  
**When** pod in `default` attempts curl to clubhouse without allow policy  
**Then** connection times out or is refused  
**Test:** `tests/chainsaw/security/unauthorized-ingress-fails.yaml`

**Verify:** Chainsaw `tests/chainsaw/security/unauthorized-ingress-fails.yaml`

---

## REQ-E1c-S02-01: Trivy fails on CRITICAL in CI

**Priority:** must  
**Given** `deploy/**` container images referenced in PR  
**When** CI Trivy scan runs  
**Then** build fails on CRITICAL CVE; HIGH logged  
**Test:** `tests/meta/e1c-s02-01-workflow.yaml`

**Verify:** `.github/workflows/ci.yaml` job `trivy` with `exit-code: 1` severity CRITICAL

---

## REQ-E1c-S02-02: Filesystem scan on merge

**Priority:** should  
**Given** any PR  
**When** Trivy fs scan runs on repo  
**Then** no secrets in committed paths (complements gitleaks)  
**Test:** `tests/smoke/e1c-s02-02.sh`

**Verify:** CI artifact or log grep `CRITICAL` count = 0

---

## REQ-E1c-S03-01: Images pinned by digest

**Priority:** must  
**Given** platform Deployment manifests in `deploy/`  
**When** `rg 'image:.*@sha256:' deploy/`  
**Then** every production image reference includes digest  
**Test:** `tests/smoke/e1c-s03-01.sh`

**Verify:** `hack/verify-image-digests.sh` (exit 1 on `:latest` or tag-only)

---

## REQ-E1c-S03-02: Kyverno verifyImages policy

**Priority:** must  
**Given** `deploy/policies/kyverno/verify-signed-images.yaml`  
**When** unsigned image deployment is applied  
**Then** admission is denied  
**Test:** `tests/chainsaw/security/unsigned-image-denied.yaml`

**Verify:** Chainsaw `tests/chainsaw/security/unsigned-image-denied.yaml` (skip until cosign wired)

---

## REQ-E1c-S04-01: gridscale creds not in Git

**Priority:** must  
**Given** Crossplane ProviderConfig  
**When** `secretRef` points to ExternalSecret or SealedSecret  
**Then** no `GRIDSCALE_TOKEN` / `token:` literals in `deploy/`  
**Test:** `tests/smoke/e1c-s04-01.sh`

**Verify:** `gitleaks detect` + `task scrub` green

---

## REQ-E1c-S04-02: ExternalSecret syncs provider creds

**Priority:** must · **Depends:** E6-S01 optional parallel  
**Given** External Secrets Operator installed  
**When** ExternalSecret reconciles  
**Then** Kubernetes Secret `openstack-creds` exists in `crossplane-system`  
**Test:** `tests/smoke/e1c-s04-02.sh`

**Verify:** `kubectl get externalsecret -n crossplane-system`

---

## REQ-E1c-S05-01: SOPS configuration in repo

**Priority:** must · **ADR:** [0110](../../../docs/adr/0110-secrets-sops-age.md) · **Decision:** D-020  
**Given** `.sops.yaml` at repo root  
**When** `sops -d deploy/secrets/identity/dex-github.enc.yaml` with age key  
**Then** decrypt succeeds in operator environment  
**Test:** `tests/smoke/e1c-s05-01.sh`

**Verify:** `test -f .sops.yaml`

---

## REQ-E1c-S05-02: Argo CD KSOPS plugin configured

**Priority:** must · **Depends:** E3-S01  
**Given** Argo CD repo-server deployment patch or Helm values  
**When** inspected  
**Then** KSOPS/SOPS plugin available for `deploy/secrets/` paths  
**Test:** `tests/smoke/e1c-s05-02.sh`

**Verify:** `rg -i ksops deploy/bootstrap/ deploy/apps/`

---

## REQ-E1c-S05-03: Dex secret path encrypted in git

**Priority:** must  
**Given** `deploy/secrets/identity/dex-github.enc.yaml`  
**When** file is committed  
**Then** `client-secret` value is SOPS-encrypted (not plaintext)  
**Test:** `tests/smoke/e1c-s05-03.sh`

**Verify:** `rg 'sops_' deploy/secrets/identity/dex-github.enc.yaml || sops -d --extract '["data"]["client-secret"]' deploy/secrets/identity/dex-github.enc.yaml >/dev/null`

---

## REQ-E1c-EXIT: Security smoke

**Priority:** must  
**Given** E1c merged  
**When** `task test:chainsaw -- tests/chainsaw/security`  
**Then** all non-skipped tests pass on kind  
**Test:** `tests/chainsaw/chainsaw-test.yaml`

**Verify:** `task test:chainsaw`

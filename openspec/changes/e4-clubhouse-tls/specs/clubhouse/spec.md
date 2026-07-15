# Spec — E4 clubhouse + TLS

Epic: E4 · **Refs:** gridscale brief (sample page, TLS bonus)

---

## REQ-E4-S01-01: clubhouse Deployment healthy

**Priority:** must  
**Given** `deploy/workloads/clubhouse/deployment.yaml`  
**When** synced to cluster  
**Then** Deployment has ReadyReplicas ≥ 1; pods carry `track: stable`, mandatory labels  
**Test:** `tests/chainsaw/gateway/clubhouse-ready.yaml`

**Verify:** Chainsaw `tests/chainsaw/gateway/clubhouse-ready.yaml`

---

## REQ-E4-S01-02: Service exposes port 8080

**Priority:** must  
**Given** clubhouse Service  
**When** `kubectl get svc clubhouse -o jsonpath='{.spec.ports[0].port}'`  
**Then** output is `8080`  
**Test:** `tests/smoke/e4-s01-02.sh`

**Verify:** Chainsaw assert on Service manifest

---

## REQ-E4-S02-01: HTTPRoute / → clubhouse

**Priority:** must  
**Given** Gateway + HTTPRoute in `deploy/gateway/`  
**When** `curl -s http://<gateway>/<path>/` from test pod  
**Then** body contains identifiable string `clubhouse` (or configured marker)  
**Test:** `tests/chainsaw/gateway/root-path-200.yaml`

**Verify:** Chainsaw `tests/chainsaw/gateway/root-path-200.yaml`

---

## REQ-E4-S03-01: Certificate Ready

**Priority:** must  
**Given** Certificate for public hostname  
**When** `kubectl get certificate -n gateway`  
**Then** Ready=True within 15m (staging issuer)  
**Test:** `tests/smoke/e4-s03-01.sh`

**Verify:** `kubectl wait --for=condition=Ready certificate --all -n gateway --timeout=900s`

---

## REQ-E4-S03-02: HTTPS serves valid cert

**Priority:** must  
**Given** DNS or /etc/hosts points to gateway  
**When** `curl -v https://$HOST/`  
**Then** TLS handshake succeeds; HTTP 200  
**Test:** `hack/smoke/https-clubhouse.sh`

**Verify:** smoke script `hack/smoke/https-clubhouse.sh` (documented env vars)

---

## REQ-E4-S03-03: HTTP redirects to HTTPS (optional)

**Priority:** should  
**Given** Gateway HTTP listener  
**When** `curl -I http://$HOST/`  
**Then** 301/308 to https  
**Test:** `tests/smoke/e4-s03-03.sh`

**Verify:** documented in runbook; Chainsaw optional

---

## REQ-E4-S03-04: Production Let's Encrypt cert issued and trusted

**Priority:** must · **Depends:** REQ-E3-S03-02  
**Given** hostname validated on staging, then Certificate switched to `letsencrypt-prod`  
**When** `curl -sS https://$HOST/` with default system trust store (no `-k`)  
**Then** TLS verifies against a publicly trusted chain; HTTP 200  
**Test:** `tests/smoke/e4-s03-04.sh`

**Verify:** `curl -sS -o /dev/null -w '%{http_code} %{ssl_verify_result}' https://$HOST/` → `200 0`

---

## REQ-E4-S03-05: Certificate auto-renewal configured

**Priority:** should  
**Given** issued Certificate resource  
**When** `kubectl get certificate -n gateway -o yaml`  
**Then** `renewBefore` set; cert-manager owns renewal (no manual step)  
**Test:** `tests/chainsaw/tls/certificate-renewal.yaml`

**Verify:** Chainsaw asserts `spec.renewBefore` present and `status.renewalTime` populated

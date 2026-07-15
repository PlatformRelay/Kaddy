# Spec — E6 Crossplane self-service + nginx legacy (phase 1 — local)

Epic: E6 · ADR: [0105](../../../docs/adr/0105-crossplane-self-service.md), [0109](../../../docs/adr/0109-idp-portal-orchestrator.md)  
**Phase:** 1 (driving-range) · **Refs:** brief optional task (path routing; VM deferred to E6g)

> The `Website` XRD here **is kaddy's platform orchestrator API** — the E10 Backstage portal
> (ADR-0109) drives it via GitOps PRs. Keep the claim surface stable and portable.

---

## REQ-E6-S01-01: Crossplane core pods Running

**Priority:** must  
**Given** Crossplane helm/manifest (no cloud provider in phase 1)  
**When** `kubectl get pods -n crossplane-system`  
**Then** all pods Running  
**Test:** `tests/smoke/e6-s01-01.sh`

**Verify:** `kubectl wait --for=condition=Ready pod -l app=crossplane -n crossplane-system --timeout=300s`

---

## REQ-E6-S02-01: XRD Website established

**Priority:** must  
**Given** `deploy/crossplane/xrd-website.yaml`  
**When** `kubectl get xrd websites.platform.kaddy.io`  
**Then** Established=True  
**Test:** `tests/smoke/e6-s02-01.sh`

**Verify:** `kubectl wait --for=condition=Established xrd/websites.platform.kaddy.io`

---

## REQ-E6-S02-02: WebsiteClaim creates child resources

**Priority:** must  
**Given** sample `WebsiteClaim` in `deploy/crossplane/samples/website-clubhouse.yaml`  
**When** claim applied  
**Then** composed HTTPRoute + ServiceMonitor objects exist with claim labels  
**Test:** `tests/chainsaw/crossplane/website-claim-composed.yaml`

**Verify:** Chainsaw `tests/chainsaw/crossplane/website-claim-composed.yaml`

---

## REQ-E6-S03-01: nginx legacy stand-in deployed

**Priority:** must · **Phase 1 stand-in for gridscale VM (E6g)**  
**Given** `deploy/legacy/nginx/` Deployment + Service (Hello World)  
**When** `kubectl get deploy -n legacy nginx-legacy`  
**Then** replicas Ready  
**Test:** `tests/smoke/e6-s03-01.sh`

**Verify:** `kubectl wait --for=condition=Available deploy/nginx-legacy -n legacy --timeout=120s`

---

## REQ-E6-S03-02: nginx serves Hello World

**Priority:** must  
**Given** nginx Service reachable in-cluster  
**When** `curl -s http://nginx-legacy.legacy.svc/`  
**Then** body contains `Hello World`  
**Test:** `tests/smoke/e6-s03-02.sh`

**Verify:** smoke script from a debug pod or port-forward

---

## REQ-E6-S04-01: HTTPRoute /legacy → nginx backend

**Priority:** must  
**Given** HTTPRoute path prefix `/legacy`  
**When** `curl -s -o /dev/null -w '%{http_code}' https://$HOST/legacy/`  
**Then** status 200; body from nginx  
**Test:** `tests/chainsaw/gateway/legacy-path-200.yaml`

**Verify:** Chainsaw `tests/chainsaw/gateway/legacy-path-200.yaml`

---

## REQ-E6-S04-02: HTTPRoute / still clubhouse

**Priority:** must  
**When** `curl -s https://$HOST/`  
**Then** clubhouse marker in body (not nginx)  
**Test:** `tests/smoke/e6-s04-02.sh`

**Verify:** same suite as E4 root path

---

## REQ-E6-S05-01: Gateway backend health check

**Priority:** must · **Refs:** brief bonus (health checks)  
**Given** Gateway backend health check policy configured  
**When** nginx Deployment scaled to 0  
**Then** `/legacy` returns 503 or routes only to healthy backends within documented timeout  
**Test:** `tests/smoke/e6-s05-01.sh`

**Verify:** Chainsaw or manual chaos step in E7-S04

---

## REQ-E6-EXIT: Self-service demo

**Priority:** should  
**Given** operator applies new WebsiteClaim YAML  
**When** within 10m  
**Then** site reachable with monitoring assets — no manual kubectl edits  
**Test:** `tests/smoke/e6-exit.sh`

**Verify:** documented demo in `docs/runbooks/website-self-service.md`

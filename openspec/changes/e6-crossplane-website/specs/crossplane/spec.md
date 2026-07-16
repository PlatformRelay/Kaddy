# Spec — E6 Crossplane self-service (phase 1 — local)

Epic: E6 · ADR: [0105](../../../docs/adr/0105-crossplane-self-service.md), [0109](../../../docs/adr/0109-idp-portal-orchestrator.md), [0111](../../../docs/adr/0111-portal-auto-generation.md)  
**Phase:** 1 (driving-range) · **Refs:** brief optional task (path routing; VM deferred to E6g)

> The `Website` XRD here **is kaddy's platform orchestrator API** — the E10 Backstage portal
> (ADR-0109/0111) drives it via GitOps PRs and **auto-generates its scaffolder form from this XRD's
> OpenAPI schema**. Keep the surface stable and portable.
>
> **D-027 (2026-07-15) — APPLIED.** Shipped as a Crossplane **v2 namespaced XR** (`kind: Website`,
> ns-scoped; Claims are deprecated in v2 — the XR *is* the resource). The REQs below are the
> post-D-027 wording; the demo claim lives at `deploy/workloads/website-demo/` (namespace `websites`).
>
> **MVP slice rescope (2026-07-16):** the nginx "legacy stand-in" REQs (old S03/S04-01 `/legacy`,
> S05 backend health-check policy) are **deferred to E6g** — see `tasks.md`. A legacy site is now a
> one-YAML `Website` claim (`image: nginx-unprivileged`, `path: /legacy`), so the stand-in no longer
> needs bespoke manifests; proving the claim path (below) subsumes it.

---

## REQ-E6-S01-01: Crossplane core pods Running (GitOps-managed)

**Priority:** must  
**Given** the pinned Crossplane v2 Helm chart (2.3.3) as the `crossplane` child Application (project `platform`; no cloud provider in phase 1)  
**When** `kubectl get pods -n crossplane-system`  
**Then** all pods Running and the `crossplane` Application is Synced/Healthy  
**Test:** `tests/smoke/e6-s01-01.sh`

**Verify:** `kubectl wait --for=condition=Ready pod -l app=crossplane -n crossplane-system --timeout=300s`

---

## REQ-E6-S02-01: XRD Website established (v2, namespaced)

**Priority:** must  
**Given** `deploy/crossplane/xrd-website.yaml` (+ Composition + pinned function-patch-and-transform v0.10.7)  
**When** `kubectl get xrd websites.platform.kaddy.io`  
**Then** Established=True and `spec.scope: Namespaced` (D-027)  
**Test:** `tests/smoke/e6-s02-01.sh`

**Verify:** `kubectl wait --for=condition=Established xrd/websites.platform.kaddy.io`

---

## REQ-E6-S02-02: Website XR creates child resources

**Priority:** must  
**Given** a `Website` XR in any namespace  
**When** the XR is applied  
**Then** composed Deployment + Service + HTTPRoute + Certificate + ServiceMonitor exist in the XR's namespace with the ADR-0301 labels propagated from the XR (`managed-by: crossplane` stamped)  
**Test:** `tests/chainsaw/crossplane/website-claim-composed.yaml`

**Verify:** Chainsaw `tests/chainsaw/crossplane/website-claim-composed.yaml` (skip:true in CI — live-verified, same class as the gateway suites)

---

## REQ-E6-S03-01: demo Website XR reconciles via GitOps

**Priority:** must  
**Given** the committed demo claim `deploy/workloads/website-demo/website.yaml` (ns `websites`, synced by the workloads Application)  
**When** within one sync loop  
**Then** the XR is Synced+Ready; composed Deployment Available, HTTPRoute Accepted by the clubhouse Gateway, Certificate Ready (kaddy-local-ca), ServiceMonitor present — all ADR-0301-labeled  
**Test:** `tests/smoke/e6-s03-01.sh`

**Verify:** `kubectl -n websites wait --for=condition=Ready website/putting-green --timeout=300s`

---

## REQ-E6-S04-01: claimed site serves 200 through the TLS edge

**Priority:** must  
**Given** the composed HTTPRoute (path `/putting-green`, prefix rewritten away)  
**When** `curl -sk https://clubhouse.kaddy.local/putting-green/` through the Cilium Gateway  
**Then** status 200; body carries the showcase marker  
**Test:** `tests/smoke/e6-s04-01.sh`

**Verify:** smoke script (in-cluster probe pod — macOS loopback constraint, same as E4)

---

## REQ-E6-S04-02: HTTPRoute / still clubhouse

**Priority:** must  
**When** `curl -s https://$HOST/`  
**Then** clubhouse marker in body (the website route must not shadow /)  
**Test:** `tests/smoke/e6-s04-02.sh`

**Verify:** same probe path as the E4 root smoke

---

## REQ-E6-S05-01: claimed site is monitored

**Priority:** must  
**Given** the composed ServiceMonitor and the websites-namespace scrape allow (`deploy/policies/network/websites.yaml`)  
**When** Prometheus service discovery refreshes  
**Then** `up{namespace="websites", job="putting-green"} == 1` and `caddy_*` metrics flow  
**Test:** `tests/smoke/e6-s05-01.sh`

**Verify:** PromQL via port-forward (see `tests/smoke/e5-lib.sh` helpers)

---

## REQ-E6-EXIT: Self-service demo

**Priority:** should  
**Given** operator commits a new Website XR YAML  
**When** within 10m  
**Then** site reachable with monitoring assets — no manual kubectl edits  
**Test:** `tests/smoke/e6-exit.sh`

**Verify:** documented demo in `docs/runbooks/website-self-service.md`

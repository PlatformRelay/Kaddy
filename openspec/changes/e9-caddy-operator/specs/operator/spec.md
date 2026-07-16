# Spec — Caddy operator (expanded)

Epic: E9 · ADR: [0401](../../../docs/adr/0401-caddy-operator-design-first.md)  
**Level:** L5 envtest (if implemented) · L2 Chainsaw for composed observability CRs

---

## REQ-E9-S01-01: API group version

**Priority:** must (if implemented)  
**Given** CRD `Caddy` in `gateway.kaddy.io/v1alpha1`  
**When** `kubectl get crd caddies.gateway.kaddy.io`  
**Then** CRD is Established  
**Test:** `tests/smoke/e9-s01-01.sh`

**Verify:** `kubectl wait --for=condition=Established crd/caddies.gateway.kaddy.io`

---

## REQ-E9-S02-01: Reconciler sets Ready condition

**Priority:** must  
**Given** valid `Caddy` spec and reachable Admin API mock  
**When** reconciler runs (envtest)  
**Then** status condition `Ready=True` within 3 reconcile loops  
**Test:** `gotest./internal/controller/...`

**Verify:** `go test ./internal/controller/... -run TestCaddy_Reconcile_Ready`

---

## REQ-E9-S02-02: Admin API upsert idempotent

**Priority:** must  
**Given** `CaddySite` with route `@id` annotation  
**When** reconcile runs twice  
**Then** mock Admin API receives PATCH (strict replace) to same `@id` — never duplicate
POST-appended or PUT-inserted routes (Caddy admin API semantics: POST appends to
arrays, PUT inserts, PATCH replaces)  
**Test:** `internal/controller/e9-s02-02_test.go`

**Verify:** envtest with fake Admin server request log assertion

---

## REQ-E9-S03-01: ServiceMonitor auto-created

**Priority:** must  
**Given** `CaddySite` `observability.serviceMonitor: true`  
**When** reconcile succeeds  
**Then** ServiceMonitor exists with labels matching ADR-0301 mandatory core  
**Test:** `tests/chainsaw/operator/caddysite-servicemonitor.yaml`

**Verify:** Chainsaw `tests/chainsaw/operator/caddysite-servicemonitor.yaml` OR envtest

---

## REQ-E9-S03-02: PrometheusRule template

**Priority:** must  
**Given** `observability.prometheusRules: true`  
**When** reconcile succeeds  
**Then** PrometheusRule includes alert `HighHTTPErrorRate` with `service` label from site  
**Test:** `tests/smoke/e9-s03-02.sh`

**Verify:** `kubectl get prometheusrule -l app.kubernetes.io/part-of=kaddy`

---

## REQ-E9-S03-03: Status AdminAPIUnavailable

**Priority:** must  
**Given** Admin API returns 503  
**When** reconcile runs  
**Then** `Ready=False`, reason `AdminAPIUnavailable`  
**Test:** `internal/controller/e9-s03-03_test.go`

**Verify:** envtest `TestCaddySite_AdminAPIUnavailable`

---

## REQ-E9-EXIT: Gate before merge
**Test:** `internal/controller/e9-exit_test.go`
**Priority:** must  

**Verify:** `task test` includes operator envtest package; coverage ≥ 80% on `internal/controller`

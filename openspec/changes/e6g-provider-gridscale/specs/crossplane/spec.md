# Spec — E6g Upjet provider-gridscale (phase 2 — gridscale lab)

Epic: E6g · ADR: [0105](../../../docs/adr/0105-crossplane-self-service.md)  
**Phase:** 2 · **Gate:** E1g complete · **Refs:** D-016

---

## REQ-E6g-S01-01: Upjet-generated provider-gridscale builds (time-boxed)

**Priority:** must  
**Given** the Upjet config in `provider-gridscale/` scoped to `gridscale_server`  
**When** the provider is generated and built  
**Then** the provider package image is produced and its CRDs include `Server`  
**Test:** `tests/smoke/e6g-s01-01.sh`

**Verify:** `make -C provider-gridscale build`; CRD present in package

> Guard (D-016): plain `gridscale_server` OpenTofu module is the fallback if this slips.

---

## REQ-E6g-S02-01: provider-gridscale healthy

**Priority:** must  
**Given** ProviderConfig with secretRef (`GRIDSCALE_TOKEN`)  
**When** `kubectl get provider.pkg.crossplane.io provider-gridscale`  
**Then** Healthy=True, Installed=True  
**Test:** `tests/smoke/e6g-s02-01.sh`

**Verify:** `kubectl wait --for=condition=Healthy provider.pkg.crossplane.io/provider-gridscale --timeout=600s`

---

## REQ-E6g-S03-01: nginx VM provisioned via Composition

**Priority:** must · **Level:** smoke (gridscale API)  
**Given** Composition extended with `Server` (provider-gridscale) for legacy nginx  
**When** the gridscale server `kaddy-nginx-legacy` is queried (gscloud / API)  
**Then** server is running; a public IP is assigned  
**Test:** `hack/smoke/gridscale-nginx-vm.sh`

**Verify:** `hack/smoke/gridscale-nginx-vm.sh`

---

## REQ-E6g-S04-01: /legacy routes to real VM on GSK

**Priority:** must  
**Given** E6g nginx VM + updated HTTPRoute backend  
**When** `curl -s https://$HOST/legacy/` via LBaaS  
**Then** body contains `Hello World` from gridscale VM (not in-cluster stand-in)  
**Test:** `tests/chainsaw/gateway/legacy-path-200-gsk.yaml`

**Verify:** Chainsaw suite on GSK cluster

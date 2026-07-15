# Spec — E2 Cilium Gateway spike

Epic: E2 · ADR: [0104](../../../docs/adr/0104-caddy-gateway-api.md) · **Decision:** D-019  
**Level:** L2 Chainsaw + manual checks  
**Depends:** driving-range E10 (Cilium Gateway + LB-IPAM/L2) or GSK Cilium + LBaaS (phase 2)  
**Blocks:** E7 canary HTTPRoute weights

---

## REQ-E2-S01-01: Gateway API CRDs Established

**Priority:** must  
**When** `kubectl get crd gateways.gateway.networking.k8s.io`  
**Then** CRD exists and condition Established=True  
**Test:** `tests/smoke/e2-s01-01.sh`

**Verify:** `kubectl wait --for condition=Established crd/gateways.gateway.networking.k8s.io --timeout=120s`

---

## REQ-E2-S01-02: Cilium GatewayClass available

**Priority:** must  
**When** `kubectl get gatewayclass cilium`  
**Then** controllerName references Cilium; class accepted by cluster  
**Test:** `tests/smoke/e2-s01-02.sh`

**Verify:** `kubectl get gatewayclass cilium -o jsonpath='{.spec.controllerName}' | grep -i cilium`

---

## REQ-E2-S01-03: Cilium LB-IPAM pool programmed (phase 1)

**Priority:** must · **Phase 1 only**  
**Given** driving-range E10 applied (`CiliumLoadBalancerIPPool` `192.168.100.200–.220`)  
**When** `kubectl get ciliumloadbalancerippool`  
**Then** at least one pool Ready with expected CIDR  
**Test:** `tests/smoke/e2-s01-03.sh`

**Verify:** smoke script asserts pool name/CIDR documented in handoff runbook

---

## REQ-E2-S02-01: Platform Gateway has address

**Priority:** must  
**Given** `deploy/gateway/platform-gateway.yaml` synced  
**When** `kubectl get gateway -n gateway platform -o jsonpath='{.status.addresses[0].value}'`  
**Then** non-empty IP (Cilium LB-IPAM phase 1 or LBaaS phase 2)  
**Test:** `tests/chainsaw/gateway/gateway-address-assigned.yaml`

**Verify:** Chainsaw `tests/chainsaw/gateway/gateway-address-assigned.yaml`

---

## REQ-E2-S02-02: HTTPRoute / returns platform landing

**Priority:** must  
**Given** HTTPRoute `/` → platform landing Deployment  
**When** `curl -s -o /dev/null -w '%{http_code}' http://<gateway-ip>/`  
**Then** status 200  
**Test:** `tests/chainsaw/gateway/root-path-200.yaml`

**Verify:** Chainsaw `tests/chainsaw/gateway/root-path-200.yaml`

---

## REQ-E2-S02-03: HTTPRoute weight mutation (Rollouts prep)

**Priority:** must · **Blocks:** E7  
**Given** HTTPRoute with two backend refs (stable/canary)  
**When** weights patched to 50/50  
**Then** both backends receive traffic (access log or header check)  
**Test:** `tests/chainsaw/gateway/httproute-weights.yaml`

**Verify:** Chainsaw `tests/chainsaw/gateway/httproute-weights.yaml`

---

## REQ-E2-S03-01: Spike decision recorded

**Priority:** must  
**When** `docs/decisions/e2-gateway-spike.md` committed  
**Then** documents Cilium L0 vs Envoy L1 fallback with evidence  
**Test:** `tests/smoke/e2-s03-01.sh`

**Verify:** `test -f docs/decisions/e2-gateway-spike.md && rg 'Cilium' docs/decisions/e2-gateway-spike.md`

---

## REQ-E2-S03-02: E7 unblocked or fallback path

**Priority:** must  
**When** ROADMAP E7 stories read  
**Then** HTTPRoute weights confirmed OR E7 references ADR-0104 L1/L2 fallback  
**Test:** `tests/smoke/e2-s03-02.sh`

**Verify:** OpenSpec e7 tasks.md references spike decision

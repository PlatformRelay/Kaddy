# Spec — E1 platform bootstrap (on E1e local substrate)

Epic: E1 · ADR: [0104](../../../docs/adr/0104-caddy-gateway-api.md) · **Phase:** 1  
**Depends:** [e1e-kind-local-cluster](../../e1e-kind-local-cluster/) (Cilium Gateway + LB-IPAM/L2) Ready — see D-025

---

## REQ-E1-S01-01: Handoff runbook exists

**Priority:** must  
**When** operator reads `docs/runbooks/local-substrate-handoff.md`  
**Then** steps cover `task cluster:up` (E1e substrate bring-up), kubeconfig export, **Gateway API / Cilium GatewayClass**, reaching ArgoCD via its Gateway HTTPRoute through the kind port-mapping / `port-forward` (macOS-safe), default StorageClass — **no MetalLB**  
**Test:** `tests/smoke/e1-s01-01.sh`

**Verify:** `test -f docs/runbooks/local-substrate-handoff.md && ! rg -i metallb docs/runbooks/local-substrate-handoff.md`

---

## REQ-E1-S02-01: ArgoCD server Running

**Priority:** must  
**Given** bootstrap Application in `deploy/bootstrap/argocd.yaml`  
**When** bootstrap applied and waited  
**Then** `argocd-server` pod in `argocd` namespace is `Running`  
**Test:** `tests/smoke/req-e1-s02-01-argocd-server-running.sh`

**Verify:**
```bash
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

---

## REQ-E1-S03-01: Cluster baseline Ready

**Priority:** must  
**When** baseline checks run  
**Then** all nodes Ready; default StorageClass exists; Cilium pods Ready; `CiliumLoadBalancerIPPool` present  
**Test:** `tests/smoke/e1-s03-01.sh`

**Verify:**
```bash
kubectl get nodes -o json | jq -e '[.items[].status.conditions[] | select(.type=="Ready" and .status!="True")] | length == 0'
kubectl get storageclass | grep -q default
kubectl get ciliumloadbalancerippool
```

---

## REQ-E1-EXIT: Epic exit gate

**Priority:** must  
**When** E1 smoke bundle runs  
**Then** ArgoCD reachable via its Gateway HTTPRoute through the kind port-mapping / `port-forward` (macOS-safe — not the raw LB IP); handoff doc complete  
**Test:** `tests/smoke/e1-exit.sh`

**Verify:** `task test:smoke:e1`

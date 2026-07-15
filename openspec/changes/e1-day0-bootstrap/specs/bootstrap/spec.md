# Spec — E1 platform bootstrap (driving-range handoff)

Epic: E1 · ADR: [0102](../../../docs/adr/0102-talos-immutable-substrate.md) · **Phase:** 1  
**Depends:** [driving-range](../../../driving-range/) E10 (Cilium Gateway + LB-IPAM/L2) Ready

---

## REQ-E1-S01-01: Handoff runbook exists

**Priority:** must  
**When** operator reads `docs/runbooks/driving-range-handoff.md`  
**Then** steps cover kubeconfig export, **Cilium LB-IPAM pool** (`192.168.100.200–.220`), **Gateway API / Cilium GatewayClass**, default StorageClass, tailnet access — **no MetalLB**  
**Test:** `tests/smoke/e1-s01-01.sh`

**Verify:** `test -f docs/runbooks/driving-range-handoff.md && ! rg -i metallb docs/runbooks/driving-range-handoff.md`

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
**Then** ArgoCD reachable via a Cilium-assigned Gateway/LB IP; handoff doc complete  
**Test:** `tests/smoke/e1-exit.sh`

**Verify:** `task test:smoke:e1`

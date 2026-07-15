# Spec — E1e local kind substrate (Cilium Gateway API)

Epic: E1e · ADR: [0104](../../../docs/adr/0104-caddy-gateway-api.md) · **Phase:** 1 (local dev substrate)
Decisions: [D-025](../../../agent-context/decisions.md) (kind local-first, amends D-017) · D-019 / D-022 (Cilium Gateway API, no MetalLB)

Owns **substrate + edge** for phase-1 local development: a reproducible `kind` cluster running **Cilium**
(CNI + Gateway API + LB-IPAM/L2), plus `cert-manager`, installed **securely** (pinned versions, no `:latest`,
loopback-bound ports, no secrets in git). E1 (platform bootstrap: ArgoCD/GitOps) runs **on top** of this.

**macOS note:** on Docker Desktop / colima the docker `kind` bridge subnet is not host-routable, so a
LoadBalancer/Gateway IP is asserted as **assigned** (`status.addresses`), never curled from the host.
Actual HTTP reachability is verified through kind `extraPortMappings` / `kubectl port-forward`.

**Prerequisite:** Docker (or nerdctl/podman) running; `kind`, `kubectl`, `helm` on `PATH`.

---

## REQ-E1e-S01-01: Kind config is Cilium-ready and loopback-bound

**Priority:** must
**Level:** meta
**Given** `hack/cluster/kind/cluster.yaml`
**When** the config is inspected
**Then** it sets `networking.disableDefaultCNI: true` and `networking.kubeProxyMode: "none"` (so Cilium can run `kubeProxyReplacement`), pins the node image to a specific `kindest/node:vX.Y.Z` tag (no `:latest`), and binds `extraPortMappings` (30080/30443) to `listenAddress: "127.0.0.1"` — never `0.0.0.0`
**Test:** `tests/meta/e1e-kind-config.sh`

**Verify:**
```bash
rg -q 'disableDefaultCNI:\s*true' hack/cluster/kind/cluster.yaml
rg -q 'kubeProxyMode:\s*"?none"?' hack/cluster/kind/cluster.yaml
rg -q 'listenAddress:\s*"127.0.0.1"' hack/cluster/kind/cluster.yaml && ! rg -q '0\.0\.0\.0' hack/cluster/kind/cluster.yaml
! rg -q 'kindest/node:latest' hack/cluster/kind/cluster.yaml
```

---

## REQ-E1e-S01-02: Cluster bring-up is idempotent

**Priority:** must
**Level:** L2
**Given** `task cluster:up` (wraps `hack/cluster/kind-up.sh`)
**When** it runs against a healthy existing cluster
**Then** it reuses the cluster (no re-create) and exits 0; on a clean host it creates the `kaddy-dev` cluster and all nodes reach `Ready`
**Test:** `tests/smoke/e1e-s01-02.sh`

**Verify:**
```bash
task cluster:up
kubectl get nodes -o json | jq -e '[.items[].status.conditions[] | select(.type=="Ready" and .status!="True")] | length == 0'
```

---

## REQ-E1e-S02-01: Cilium CNI Ready with kube-proxy replaced

**Priority:** must
**Level:** L2
**Given** Cilium installed via Helm (pinned version, `kubeProxyReplacement=true`, `ipam.mode=kubernetes`)
**When** the cluster is up
**Then** the `cilium` DaemonSet is Ready on every node, `kubeProxyReplacement` is active, and no `kube-proxy` / `kindnet` DaemonSet exists
**Test:** `tests/smoke/e1e-s02-01.sh`

**Verify:**
```bash
kubectl -n kube-system rollout status ds/cilium --timeout=180s
kubectl -n kube-system get ds kube-proxy 2>/dev/null && exit 1 || true
kubectl -n kube-system exec ds/cilium -- cilium-dbg status | grep -qi 'KubeProxyReplacement:\s*True'
```

---

## REQ-E1e-S02-02: Gateway API CRDs and Cilium GatewayClass Accepted

**Priority:** must
**Level:** L2
**Given** pinned Gateway API standard-channel CRDs applied before Cilium (`gatewayAPI.enabled=true`)
**When** the cluster is up
**Then** the `gateways.gateway.networking.k8s.io` CRD is present and the `cilium` GatewayClass is `Accepted=True`
**Test:** `tests/smoke/e1e-s02-02.sh`

**Verify:**
```bash
kubectl get crd gateways.gateway.networking.k8s.io
kubectl get gatewayclass cilium -o json | jq -e '.status.conditions[] | select(.type=="Accepted") | .status == "True"'
```

---

## REQ-E1e-S02-03: LB-IPAM + L2 announcement from the docker subnet

**Priority:** must
**Level:** L2
**Given** a `CiliumLoadBalancerIPPool` whose range is carved from the docker `kind` bridge subnet (NOT the driving-range `192.168.100.x` range) and a `CiliumL2AnnouncementPolicy`
**When** a `LoadBalancer` Service or Gateway is created
**Then** the pool and policy exist and the Gateway receives an assigned address in `status.addresses` (assignment only — not host-curled, per the macOS note)
**Test:** `tests/smoke/e1e-s02-03.sh`

**Verify:**
```bash
kubectl get ciliumloadbalancerippool -o json | jq -e '.items | length > 0'
kubectl get ciliuml2announcementpolicy -o json | jq -e '.items | length > 0'
```

---

## REQ-E1e-S03-01: cert-manager pinned, Ready, with a local CA issuer

**Priority:** must
**Level:** L2
**Given** cert-manager installed via Helm pinned to `v1.18.2` (`installCRDs=true`) plus a self-signed CA `ClusterIssuer` `kaddy-local-ca` (local TLS without mkcert)
**When** the cluster is up
**Then** the cert-manager webhook is Ready and the `kaddy-local-ca` ClusterIssuer is `Ready=True`
**Test:** `tests/smoke/e1e-s03-01.sh`

**Verify:**
```bash
kubectl -n cert-manager rollout status deploy/cert-manager-webhook --timeout=180s
kubectl get clusterissuer kaddy-local-ca -o json | jq -e '.status.conditions[] | select(.type=="Ready") | .status == "True"'
```

---

## REQ-E1e-S03-02: Default StorageClass present

**Priority:** must
**Level:** L2
**Given** kind's built-in `standard` (rancher local-path) provisioner
**When** the cluster is up
**Then** a default StorageClass exists
**Test:** `tests/smoke/e1e-s03-02.sh`

**Verify:**
```bash
kubectl get storageclass -o json | jq -e '[.items[] | select(.metadata.annotations["storageclass.kubernetes.io/is-default-class"]=="true")] | length > 0'
```

---

## REQ-E1e-S04-01: Gateway HTTP reachable locally (macOS-safe)

**Priority:** must
**Level:** L2
**Given** a smoke `Gateway` + `HTTPRoute` fronting an echo backend
**When** traffic is sent through the kind `extraPortMapping` (or `kubectl port-forward`), NOT the LB IP
**Then** an HTTP request to `127.0.0.1` returns `200`
**Test:** `tests/smoke/e1e-s04-01.sh`

**Verify:**
```bash
bash tests/smoke/e1e-s04-01.sh
```

---

## REQ-E1e-S05-01: Secure install — pinned, no :latest, no secrets in git

**Priority:** must
**Level:** meta
**Given** all install scripts and manifests under `hack/cluster/`
**When** the tree is scanned
**Then** every chart/image version is pinned in `hack/cluster/versions.env` (cert-manager, Cilium, Gateway API CRDs, kind node), no artifact under `hack/cluster/` uses `:latest`, and `.state/` (kubeconfig, generated certs) is gitignored
**Test:** `tests/meta/e1e-security.sh`

**Verify:**
```bash
test -f hack/cluster/versions.env
! rg -q ':latest' hack/cluster/
rg -q '^\.state/' .gitignore
```

---

## REQ-E1e-EXIT: Epic exit gate

**Priority:** must
**Level:** L2
**When** the E1e smoke bundle runs from a clean host
**Then** `task cluster:up` brings the full stack green (Cilium + Gateway API + LB-IPAM + cert-manager + default StorageClass) and `task test:smoke:e1e` passes, including the macOS-safe local HTTP smoke
**Test:** `tests/smoke/e1e-exit.sh`

**Verify:** `task test:smoke:e1e`

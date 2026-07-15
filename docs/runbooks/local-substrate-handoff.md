# Local substrate handoff runbook

Operator guide for bringing up the local `kaddy-dev` kind cluster (E1e substrate)
and reaching the platform bootstrap (ArgoCD, E1) from a macOS workstation.

This runbook is deliberately self-contained: it assumes only `kind`, `kubectl`,
`helm`, and a container runtime (podman) on the host. No cloud access is needed.

---

## 1. Bring up the substrate

```bash
task cluster:up
```

`task cluster:up` is **idempotent** — it reuses an already-healthy `kaddy-dev`
cluster and only reconciles what drifted. It provisions, in order:

- a single-node kind cluster (`kaddy-dev`) on the local container runtime,
- **Cilium** as the CNI with kube-proxy replacement,
- the **Gateway API** standard-channel CRDs,
- the Cilium **`cilium` GatewayClass** (Accepted),
- **LB-IPAM** — Cilium hands out addresses to `LoadBalancer` services from a
  `CiliumLoadBalancerIPPool`, so no separate load-balancer add-on is required,
- **cert-manager** with a Ready `kaddy-local-ca` CA `ClusterIssuer`,
- a default `StorageClass`.

Verify the substrate is green:

```bash
task test:smoke:e1e
```

## 2. Export the kubeconfig

`task cluster:up` writes an **isolated** kubeconfig to `.state/kubeconfig` at the
repo root. It never touches `~/.kube/config` (which may carry real remote
contexts). Point your shell at it:

```bash
export KUBECONFIG="$PWD/.state/kubeconfig"
kubectl config use-context kind-kaddy-dev
kubectl get nodes   # control-plane node should be Ready
```

If the kind API port drifted after a runtime restart, re-export it:

```bash
kind export kubeconfig --name kaddy-dev --kubeconfig "$PWD/.state/kubeconfig"
```

## 3. Gateway API / Cilium GatewayClass

Traffic ingress is handled by the **Gateway API** dataplane implemented by
Cilium. Confirm the GatewayClass is Accepted:

```bash
kubectl get gatewayclass cilium
# NAME     CONTROLLER                     ACCEPTED
# cilium   io.cilium/gateway-controller   True
```

A `Gateway` referencing `gatewayClassName: cilium` surfaces as a `LoadBalancer`
service named `cilium-gateway-<gateway-name>` and receives an address from the
`CiliumLoadBalancerIPPool`:

```bash
kubectl get ciliumloadbalancerippool
```

That assigned address is **not host-routable** from macOS (the container bridge
is not reachable across the VM boundary). Reachability is instead achieved via
kind's loopback-bound port mappings — see the next section.

## 4. Bootstrap ArgoCD (E1)

Install the platform GitOps controller (pinned upstream ArgoCD + its Gateway):

```bash
task bootstrap:argocd
```

This applies the pinned ArgoCD core install into the `argocd` namespace and the
bootstrap overlay in `deploy/bootstrap/argocd.yaml`:

- an `argocd-server` running with `server.insecure` (TLS terminates at the
  Gateway, not the pod),
- a cert-manager `Certificate` issued by the `kaddy-local-ca` `ClusterIssuer`,
- a `Gateway` on the **HTTPS** listener terminating that certificate,
- an `HTTPRoute` routing `/` to `argocd-server`.

Confirm the server is Running:

```bash
kubectl wait --for=condition=Ready pod \
  -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

## 5. Reach ArgoCD via its Gateway HTTPRoute (macOS-safe)

The Cilium gateway `LoadBalancer` service is **selectorless** (Cilium's Envoy
datapath, not pods), so `kubectl port-forward svc/cilium-gateway-argocd` cannot
attach to it. Instead the bootstrap pins that service's `nodePort` to **30443**,
which the kind node exposes on the host **loopback** via an `extraPortMapping`
(`127.0.0.1:30443` → node NodePort `30443`, HTTPS). Reach ArgoCD through the
Gateway + HTTPRoute:

```bash
curl -k https://127.0.0.1:30443/   # expect HTTP 200
```

The `-k` flag skips verification of the local CA cert; traffic still traverses
the Gateway HTTPRoute (the assigned LB address is never curled directly). The
kind mapping also exposes **30080** (`127.0.0.1:30080`, HTTP) for plain-HTTP
gateways.

Alternatively, for the raw pod (bypassing the Gateway, e.g. to debug the server
directly) you may `port-forward` the argocd-server service:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:80
# then browse http://127.0.0.1:8080
```

## 6. Default StorageClass

Stateful workloads bind PVCs against the default `StorageClass`:

```bash
kubectl get storageclass   # one class marked (default)
```

---

## Teardown

```bash
task cluster:down
```

The container runtime holds cluster state globally; teardown removes the
`kaddy-dev` kind cluster and frees the loopback port mappings.

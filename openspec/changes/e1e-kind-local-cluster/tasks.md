# Tasks — E1e (P0: local kind substrate)

TDD: write the failing smoke/meta test before the implementation for each story.

## S01 — Kind cluster

- [x] Add failing `tests/meta/e1e-kind-config.sh` (asserts disableDefaultCNI, kubeProxyMode none, loopback ports, pinned node image)
- [x] Write `hack/cluster/kind/cluster.yaml` (control-plane; `disableDefaultCNI: true`; `kubeProxyMode: "none"`; pinned `kindest/node`; `extraPortMappings` 30080/30443 → `127.0.0.1`; containerd `certs.d`)
- [x] Add failing `tests/smoke/e1e-s01-02.sh` (nodes Ready)
- [x] Write `hack/cluster/versions.env` (pin: KIND_NODE_IMAGE, CILIUM_VERSION, GATEWAY_API_VERSION, CERT_MANAGER_VERSION)
- [x] Write `hack/cluster/kind-up.sh` + `kind-down.sh` (idempotent, health-check, runtime detection docker/nerdctl/podman — mirror `kollect/hack/kind/common.sh`)
- [x] `Taskfile.yml`: `cluster:up`, `cluster:down`

## S02 — Cilium (CNI + Gateway API + LB-IPAM/L2)

> **Runtime note:** local runtime is **rootless podman** (`podman-machine-default`, cgroup v2, 2GiB).
> `kind-up.sh` must export `KIND_EXPERIMENTAL_PROVIDER=podman` when only podman is present. Cilium
> `kubeProxyReplacement=true` + L2 announcements can be finicky on rootless podman — if the agent won't
> go Ready, set `k8sServiceHost`/`k8sServicePort` explicitly and, as a documented fallback, relax to
> `kubeProxyReplacement=false` (keep kube-proxy) and note it in the spec rather than looping on it.

- [x] Add failing `tests/smoke/e1e-s02-01.sh` (cilium DS Ready, kube-proxy replaced, no kindnet)
- [x] Helm install Cilium (pinned): `kubeProxyReplacement=true`, `ipam.mode=kubernetes`, `k8sServiceHost/Port` for kind, `gatewayAPI.enabled=true`, `l2announcements.enabled=true`
- [x] Apply pinned Gateway API standard-channel CRDs **before** Cilium; add failing `tests/smoke/e1e-s02-02.sh` (GatewayClass `cilium` Accepted)
- [x] Add failing `tests/smoke/e1e-s02-03.sh`; write `CiliumLoadBalancerIPPool` (docker `kind` subnet slice) + `CiliumL2AnnouncementPolicy` under `deploy/cluster-local/`

## S03 — Base infra

- [x] Add failing `tests/smoke/e1e-s03-01.sh`; Helm install cert-manager `v1.18.2` + self-signed `kaddy-local-ca` ClusterIssuer
- [x] Add failing `tests/smoke/e1e-s03-02.sh` (default StorageClass)

## S04 — Local reachability (macOS-safe)

- [x] Add failing `tests/smoke/e1e-s04-01.sh`; smoke `Gateway` + `HTTPRoute` + echo backend; assert `curl 127.0.0.1` via port-mapping/port-forward returns 200 (Gateway IP asserted assigned only)

## S05 — Secure install

- [x] `echo '.state/' >> .gitignore` (kubeconfig + generated certs never committed)
- [x] Add `tests/meta/e1e-security.sh` (no `:latest` under `hack/cluster/`, versions.env exists, `.state/` gitignored)

## Exit

- [x] `Taskfile.yml`: `test:smoke:e1e` bundle + `tests/smoke/e1e-exit.sh`
- [x] Gate: `task test:spec` (structure) + `task test:smoke:e1e` (live, needs Docker)

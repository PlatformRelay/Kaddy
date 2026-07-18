# gateway-controller/traefik — Gateway API controller for the GSK cloud-edge (E1g-S05b)

**CLOUD-ONLY.** Proven live on gridscale GSK on 2026-07-18. This directory is
**not** part of the local kind app-of-apps and is **never** applied on kind.

## Why this is separate from `deploy/apps/`

`deploy/apps/root.yaml` recurses `deploy/apps/` and turns every `*.yaml` there
into a live child Application on kind. On kind, the Gateway API edge is served by
GSK-absent Cilium's built-in `cilium` GatewayClass (installed at bootstrap by
E1e). Installing a **second** controller (Traefik) on kind would double-own the
edge. So `application.yaml` lives here, outside the kind root, and is applied
**only on the GSK cloud-edge** by `hack/gsk/edge-up.sh`.

## Why Traefik (not Cilium) on GSK — D-042

GSK ships a **managed Cilium** (v1.15.1, `kube-proxy-replacement=false`, no
`cilium-operator`) that **cannot serve Gateway API**. The committed
`gatewayClassName: cilium` edge is dead on GSK, so a self-contained Gateway API
controller is required. The operator chose **Traefik v3.x** (chart
`traefik/traefik` 41.0.2 = app v3.7.6).

## What the chart owns vs. what this repo owns

- The Traefik chart, with `providers.kubernetesGateway.enabled=true`, **creates
  the `traefik` GatewayClass itself** (Helm-managed). This repo therefore does
  **not** hand-author a GatewayClass object — a committed one would double-own
  the Helm-managed resource and conflict on apply.
- This repo owns the `clubhouse` Gateway + HTTPS listeners, the per-host
  Certificates, and the app HTTPRoutes as GitOps manifests under
  `deploy/gateway/cloud-only/`.

## GSK-specific gotchas (proven live)

- **Entrypoints stay at chart defaults** (`web:8000` / `websecure:8443`). Do NOT
  rebind privileged `80`/`443` in-container — `NET_BIND_SERVICE` crashes on GSK.
  The `type=LoadBalancer` Service maps external `80->8000` / `443->8443`, so the
  Gateway HTTPS listeners MUST use **port 8443** (Traefik matches a listener to
  the entrypoint port, not the Service port).
- **GSK has a working service-LoadBalancer CCM**: a `type=LoadBalancer` Service
  auto-provisions a gridscale loadbalancer + public IP (proven `185.241.34.187`).
  No manual NodePort/LBaaS wiring is needed — this collapses S05c/S05d.
- **Gateway API CRDs must exist first**, with the k8s-1.31-only `isIP`/`isCIDR`/
  `isURL` CEL rules stripped so they apply on GSK's k8s 1.30. See
  `hack/gsk/apply-gatewayapi-crds.sh`.

## AppProject

`application.yaml` runs under the dedicated **`gsk-cloud-edge`** AppProject
([`deploy/apps/projects/gsk-cloud-edge.yaml`](../../apps/projects/gsk-cloud-edge.yaml)),
not `platform`. The `platform` project permits neither namespace `traefik`, the
`traefik.github.io/charts` Helm repo, nor the cluster-scoped `GatewayClass` the
chart creates — so a shared project would make this Application self-deny on
sync. The dedicated project is a closed list scoped to exactly those. The
project is a policy object with no members on kind (this Application lives
outside the kind root), so it is inert there.

## Apply path (cloud-edge only)

See [`docs/runbooks/gridscale-live-demo.md`](../../../docs/runbooks/gridscale-live-demo.md)
"Cloud-edge (Traefik Gateway API) apply path" and:

```bash
export KUBECONFIG=<GSK kubeconfig>
hack/gsk/apply-gatewayapi-crds.sh        # v1.5.1 CRDs, isIP CEL stripped (k8s 1.30)
kubectl apply -f deploy/gateway-controller/traefik/application.yaml   # via ArgoCD
kubectl apply -f deploy/gateway/cloud-only/                            # Gateway + routes + certs
```

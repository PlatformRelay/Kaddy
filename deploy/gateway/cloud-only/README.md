# gateway/cloud-only — the live GSK HTTPS edge (E1g-S05e)

**CLOUD-ONLY.** These manifests are the authoritative, live-extracted (2026-07-18)
GSK cloud-edge: the Traefik-backed `clubhouse` Gateway with four HTTPS listeners,
the per-host Let's Encrypt Certificates, and the app HTTPRoutes. They serve the
four public demo URLs with real, publicly-trusted certs. The fourth host,
`caddy.lab` (E1g-S05i), fronts the FULL caddy-mvp Argo Rollouts canary — see the
name/ns-collision note in `httproutes.yaml` and the amd64 plugin caveat below.

## Excluded from the kind path by location

The `gateway` child Application (`deploy/apps/gateway.yaml`) directory-syncs
`deploy/gateway` with **recurse OFF** (the ArgoCD default — no `directory.recurse`
key), so this `cloud-only/` subdir is **never rendered/applied on kind**. The kind
edge stays on Cilium's `cilium` GatewayClass, `clubhouse.kaddy.local`, and HTTP-01
TLS — unchanged. Apply these on the GSK edge via `hack/gsk/edge-up.sh`.

## How this differs from the kind edge (all proven live)

| Aspect | kind (unchanged) | GSK cloud-edge (here) |
| --- | --- | --- |
| GatewayClass | `cilium` | `traefik` (chart-owned; see `deploy/gateway-controller/traefik/`) |
| Gateway ns | `gateway` | `traefik` |
| Hostnames | `clubhouse.kaddy.local` | `{argocd,grafana,demo,caddy}.lab.platformrelay.dev` |
| Listener port | 443 | **8443** (Traefik `websecure` entrypoint; LB maps 443->8443) |
| TLS | HTTP-01 / local CA | DNS-01 Let's Encrypt **prod** (publicly trusted) |
| Cert secrets | in `gateway` | in `traefik` (same ns as the Gateway) |

The Certificates live in ns `traefik` because Gateway API resolves a listener's
`certificateRefs` Secret in the **Gateway's own namespace**. The HTTPRoutes live
in each app's namespace (argocd / monitoring / caddy-demo / caddy-mvp) and attach
to the Gateway listener by `sectionName`; `allowedRoutes.namespaces.from: All` on
each listener admits them without a per-route ReferenceGrant for the parent attach.

## caddy-mvp canary + the argo-rollouts amd64 plugin caveat (E1g-S05i)

The `caddy.lab` route drives the FULL caddy-mvp — an Argo Rollouts canary that
weight-splits `caddy-origin-stable`/`caddy-origin-canary`. The Rollouts Gateway
API traffic-router plugin ships as an **arch-specific** binary. `deploy/rollouts/
config.yaml` pins `...-linux-arm64` for the local kind cluster (Apple-Silicon);
**GSK worker nodes are amd64**, so on the edge the arm64 binary aborts with
`exec format error` and stalls ALL rollout reconciliation. `hack/gsk/
rollouts-plugin-amd64.sh` live-patches the `argo-rollouts-config` ConfigMap to
the `...-linux-amd64` binary of the SAME pinned release (v0.16.0) and restarts
the controller. It is NOT a committed ConfigMap overlay (ArgoCD rejects two
same-named resources in one Application, and the edge runs no ArgoCD App), and it
leaves the kind arm64 default untouched. `edge-up.sh` runs it automatically when
argo-rollouts is present.

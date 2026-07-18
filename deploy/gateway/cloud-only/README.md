# gateway/cloud-only — the live GSK HTTPS edge (E1g-S05e)

**CLOUD-ONLY.** These manifests are the authoritative, live-extracted (2026-07-18)
GSK cloud-edge: the Traefik-backed `clubhouse` Gateway with three HTTPS listeners,
the per-host Let's Encrypt Certificates, and the app HTTPRoutes. They serve the
three public demo URLs with real, publicly-trusted certs.

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
| Hostnames | `clubhouse.kaddy.local` | `{argocd,grafana,demo}.lab.platformrelay.dev` |
| Listener port | 443 | **8443** (Traefik `websecure` entrypoint; LB maps 443->8443) |
| TLS | HTTP-01 / local CA | DNS-01 Let's Encrypt **prod** (publicly trusted) |
| Cert secrets | in `gateway` | in `traefik` (same ns as the Gateway) |

The Certificates live in ns `traefik` because Gateway API resolves a listener's
`certificateRefs` Secret in the **Gateway's own namespace**. The HTTPRoutes live
in each app's namespace (argocd / monitoring / caddy-demo) and attach to the
Gateway listener by `sectionName`; `allowedRoutes.namespaces.from: All` on each
listener admits them without a per-route ReferenceGrant for the parent attach.

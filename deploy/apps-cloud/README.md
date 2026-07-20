# apps-cloud — the GSK cloud-edge Applications (CLOUD-ONLY)

**Never applied on kind.** This directory is the cloud-edge counterpart of
`deploy/apps/`: Argo CD Applications that GitOps-manage the live GSK edge
(operator directive: "everything on gridscale, GitOps-managed").

| Application | Syncs | Owns on GSK |
| --- | --- | --- |
| `gateway-cloud-edge.yaml` | `deploy/gateway/cloud-only/` | clubhouse Gateway, per-host Certificates, app HTTPRoutes |
| `cert-manager-cloud-edge.yaml` | `deploy/cert-manager/cloud-only/` (issuers only, via `directory.include`) | DNS-01 Let's Encrypt ClusterIssuers |

The Traefik controller App lives at
`deploy/gateway-controller/traefik/application.yaml` (predates this directory;
same pattern, kept in place — its path is asserted by existing gates).

## Why a separate directory (kind-safety)

`deploy/apps/root.yaml` directory-syncs `deploy/apps/` with `recurse: true`, so
**every** manifest there becomes a live child Application on the local kind
cluster. The cloud edge (GatewayClass `traefik`, DNS-01 certs, `*.lab.platformrelay.dev`
hosts) must never land on kind — kind serves Gateway API via Cilium. A separate
top-level directory is invisible to root by construction.
`tests/smoke/gsk-cloud-edge-gitops-offline.sh` enforces this behaviourally:
any `gsk-cloud-edge`-project Application appearing under `deploy/apps/` fails
the offline gate.

## Bootstrap → GitOps handover

`hack/gsk/edge-up.sh` kubectl-applies this directory **once** per edge bring-up
(exactly like `task bootstrap:e3` applies `root.yaml` on kind — the App objects
themselves are bootstrap-applied, everything they point at is Argo-owned from
then on). Ordering handled by edge-up (CRDs → project → Traefik → these) plus
`syncPolicy.retry` on the Apps for the controller/CRD readiness races.

**Deliberately NOT Argo-owned:** the Gateway API CRDs. GSK runs k8s 1.30, and
the v1.5.1 CRDs need their `isIP`/`isCIDR`/`isURL` CEL rules stripped first
(`hack/gsk/apply-gatewayapi-crds.sh`). Argo syncing the pristine upstream CRDs
would fight the stripped, script-applied ones — so CRDs stay a bootstrap step,
mirroring kind's E1e bootstrap-owned CRDs.

All Apps are scoped to the closed-allowlist `gsk-cloud-edge` AppProject
(`deploy/apps/projects/gsk-cloud-edge.yaml`) — inert on kind (no members there),
GitOps-managed via root's sync of `deploy/apps/projects/`.

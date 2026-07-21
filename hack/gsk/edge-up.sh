#!/usr/bin/env bash
# E1g-S05b/S05e/S05f — bring up the Traefik Gateway API edge + HTTPS routes on
# the gridscale GSK cloud-edge (CLOUD-ONLY; proven live 2026-07-18).
#
# This is the replayable apply path for the cloud-only overlays. It NEVER runs
# against kind — it targets ONLY the exported GSK KUBECONFIG, and refuses to
# proceed unless KADDY_GSK_CONTEXT names the active context (the same opt-in the
# bootstrap:* tasks use via hack/lib/guard-context.sh).
#
# PREREQUISITES (out of band — see docs/runbooks/gridscale-live-demo.md):
#   - E1g substrate up (task e1g:up) + GSK kubeconfig exported.
#   - cert-manager installed (task bootstrap or helm jetstack).
#   - The Cloudflare API token Secret `cloudflare-api-token` present in ns
#     cert-manager (key: api-token). NEVER committed — created out-of-band from
#     $CLOUDFLARE_TOKEN, or populated by the ExternalSecret in
#     deploy/cert-manager/cloud-only/ once ESO is wired.
#   - Cloudflare A records {argocd,grafana,demo,caddy,portal}.lab.platformrelay.dev
#     -> the Traefik LoadBalancer public IP (proxied=false so the cert is end-to-end).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

: "${KUBECONFIG:?export KUBECONFIG=<GSK kubeconfig> before running (never run against kind)}"
: "${KADDY_GSK_CONTEXT:?export KADDY_GSK_CONTEXT=\$(kubectl config current-context) to opt past the kind-only guard}"

active="$(kubectl config current-context)"
if [ "${active}" != "${KADDY_GSK_CONTEXT}" ]; then
  echo "REFUSING: active context '${active}' != KADDY_GSK_CONTEXT '${KADDY_GSK_CONTEXT}'." >&2
  echo "This edge apply is cloud-only; it must never run against kind." >&2
  exit 1
fi

echo "==> Target GSK context: ${active}"

# 1) Gateway API CRDs (v1.5.1, isIP/isCIDR/isURL CEL stripped for k8s 1.30).
#    Deliberately NOT Argo-owned: Argo syncing the pristine upstream CRDs would
#    fight the stripped, script-applied ones (see deploy/apps-cloud/README.md).
"${REPO_ROOT}/hack/gsk/apply-gatewayapi-crds.sh"

# 2) The AppProjects the apps-cloud Applications reference. They MUST exist
#    first — else ArgoCD rejects the Apps with an unknown-project error:
#    gsk-cloud-edge for the edge Apps, portal for backstage-workload (the
#    chart-cutover App; manual-sync, so applying it stays inert). Applying
#    Applications also requires ArgoCD present on the edge (bootstrap:argocd
#    with KADDY_GSK_CONTEXT); if ArgoCD is absent these applies fail on the
#    unknown CRD — bootstrap ArgoCD first (see docs/runbooks/
#    gridscale-live-demo.md).
kubectl apply -f "${REPO_ROOT}/deploy/apps/projects/gsk-cloud-edge.yaml"
kubectl apply -f "${REPO_ROOT}/deploy/apps/projects/portal.yaml"

# 3) Traefik Gateway API controller (creates the `traefik` GatewayClass + a
#    type=LoadBalancer Service that the GSK CCM fronts with a public IP).
kubectl apply -f "${REPO_ROOT}/deploy/gateway-controller/traefik/application.yaml"
kubectl -n traefik rollout status deploy/traefik --timeout=300s || true

# 4) GitOps handover — the rest of the edge is Argo-OWNED. Apply the cloud-edge
#    Applications ONCE (deploy/apps-cloud/): gateway-cloud-edge syncs the
#    clubhouse Gateway (five HTTPS listeners, port 8443) + per-host Certificates
#    + app HTTPRoutes (incl. HTTPRoute caddy-lab → caddy.lab, and portal.lab)
#    from deploy/gateway/cloud-only/; cert-manager-cloud-edge syncs the DNS-01
#    ClusterIssuers (staging + prod) from deploy/cert-manager/cloud-only/ — the
#    Cloudflare token Secret must already exist (see prerequisites), the issuers
#    only reference it. Argo reconciles all of it from git `main` after this;
#    do NOT kubectl-apply those manifests directly except as break-glass with
#    Argo down (documented in docs/runbooks/gridscale-live-demo.md).
#    Route rule still holds: caddy-lab must NOT share the kind HTTPRoute name
#    caddy-mvp (Argo workloads owns that object and would reclobber clubhouse
#    parents). Sync ordering: the Apps carry syncPolicy.retry to absorb the
#    Traefik-readiness / CRD-registration races after the rollout wait above.
kubectl apply -f "${REPO_ROOT}/deploy/apps-cloud/"

# 5) Argo Rollouts plugin arch override (E1g-S05i). ONLY needed if argo-rollouts
#    is deployed on the edge to serve the FULL caddy-mvp canary (the caddy.lab
#    HTTPRoute caddy-lab above). GSK nodes are amd64, but deploy/rollouts/config.yaml
#    pins the arm64 plugin (kind default) — without the override the controller
#    hits `exec format error` and NO rollout reconciles. The override is the
#    COMMITTED overlay deploy/rollouts/cloud-only/ (same pinned v0.16.0 release,
#    linux-amd64); hack/gsk/rollouts-plugin-amd64.sh (live patch) is break-glass
#    ONLY — see deploy/gateway/cloud-only/README.md. The controller needs a
#    one-time restart to load the ConfigMap. Skipped automatically if the
#    argo-rollouts deployment is absent.
if kubectl -n argo-rollouts get deploy argo-rollouts >/dev/null 2>&1; then
  echo "==> argo-rollouts present — applying the linux-amd64 plugin overlay"
  kubectl apply -k "${REPO_ROOT}/deploy/rollouts/cloud-only"
  kubectl -n argo-rollouts rollout restart deploy/argo-rollouts
  kubectl -n argo-rollouts rollout status deploy/argo-rollouts --timeout=180s || true
else
  echo "==> argo-rollouts not deployed — skipping the amd64 plugin overlay"
  echo "    (deploy argo-rollouts, then kubectl apply -k deploy/rollouts/cloud-only + restart the controller for the caddy-mvp canary)."
fi

echo ""
echo "==> Edge applied. Watch cert issuance + LB IP:"
echo "    kubectl get certificate -n traefik"
echo "    kubectl get svc -n traefik traefik -o wide   # EXTERNAL-IP = the public LB IP"
echo "    kubectl get gateway clubhouse -n traefik"
echo "    kubectl get httproute caddy-lab -n caddy-mvp   # must NOT be named caddy-mvp (kind collision)"
echo "Point Cloudflare A records {argocd,grafana,demo,caddy,portal}.lab.platformrelay.dev at that IP (proxied=false)."
echo "    (includes portal.lab for the Backstage IDP HTTPRoute)"

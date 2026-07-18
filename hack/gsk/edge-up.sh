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
#   - Cloudflare A records argocd/grafana/demo.lab.platformrelay.dev -> the
#     Traefik LoadBalancer public IP (proxied=false so the cert is end-to-end).
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
"${REPO_ROOT}/hack/gsk/apply-gatewayapi-crds.sh"

# 2) DNS-01 ClusterIssuers (staging + prod). The Cloudflare token Secret must
#    already exist (see prerequisites) — these only reference it.
kubectl apply -f "${REPO_ROOT}/deploy/cert-manager/cloud-only/cluster-issuer-dns01-staging.yaml"
kubectl apply -f "${REPO_ROOT}/deploy/cert-manager/cloud-only/cluster-issuer-dns01-prod.yaml"

# 3) Traefik Gateway API controller (creates the `traefik` GatewayClass + a
#    type=LoadBalancer Service that the GSK CCM fronts with a public IP).
#    The Application is project-scoped to gsk-cloud-edge, so the AppProject MUST
#    exist first — else ArgoCD rejects the App with an unknown-project error.
#    Applying the App also requires ArgoCD present on the edge (bootstrap:argocd
#    with KADDY_GSK_CONTEXT); if ArgoCD is absent this apply will fail on the
#    unknown CRD — bootstrap ArgoCD first (see docs/runbooks/gridscale-live-demo.md).
kubectl apply -f "${REPO_ROOT}/deploy/apps/projects/gsk-cloud-edge.yaml"
kubectl apply -f "${REPO_ROOT}/deploy/gateway-controller/traefik/application.yaml"
kubectl -n traefik rollout status deploy/traefik --timeout=300s || true

# 4) The clubhouse Gateway (3 HTTPS listeners, port 8443), per-host Certificates,
#    and the app HTTPRoutes (incl. the caddy-mvp canary route, host caddy.lab).
kubectl apply -f "${REPO_ROOT}/deploy/gateway/cloud-only/"

# 5) Argo Rollouts plugin arch override (E1g-S05i). ONLY needed if argo-rollouts
#    is deployed on the edge to serve the FULL caddy-mvp canary (the caddy.lab
#    HTTPRoute above). GSK nodes are amd64, but deploy/rollouts/config.yaml pins
#    the arm64 plugin (kind default) — without this the controller hits
#    `exec format error` and NO rollout reconciles. Skipped automatically if the
#    argo-rollouts deployment is absent.
if kubectl -n argo-rollouts get deploy argo-rollouts >/dev/null 2>&1; then
  echo "==> argo-rollouts present — overriding the gatewayAPI plugin to linux-amd64"
  "${REPO_ROOT}/hack/gsk/rollouts-plugin-amd64.sh"
else
  echo "==> argo-rollouts not deployed — skipping the amd64 plugin override"
  echo "    (deploy argo-rollouts then run hack/gsk/rollouts-plugin-amd64.sh for the caddy-mvp canary)."
fi

echo ""
echo "==> Edge applied. Watch cert issuance + LB IP:"
echo "    kubectl get certificate -n traefik"
echo "    kubectl get svc -n traefik traefik -o wide   # EXTERNAL-IP = the public LB IP"
echo "    kubectl get gateway clubhouse -n traefik"
echo "Point Cloudflare A records {argocd,grafana,demo,caddy}.lab.platformrelay.dev at that IP (proxied=false)."

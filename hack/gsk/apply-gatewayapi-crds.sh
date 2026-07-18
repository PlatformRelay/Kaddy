#!/usr/bin/env bash
# E1g-S05b — install the Gateway API CRDs on the gridscale GSK cloud-edge,
# stripping the k8s-1.31-only CEL rules so they apply on GSK's k8s 1.30.
#
# WHY THIS EXISTS (proven live 2026-07-18):
#   Traefik 3.7.6 (the GSK edge controller — see deploy/gateway-controller/traefik)
#   watches Gateway API at v1. The upstream Gateway API v1.5.1 STANDARD channel
#   TLSRoute + BackendTLSPolicy CRDs embed CEL validation rules that call the
#   `isIP()` / `isCIDR()` / `isURL()` CEL functions — added to Kubernetes in
#   v1.31. GSK is k8s 1.30, so the API server REJECTS those CRDs ("undefined
#   function"). If TLSRoute never applies, Traefik's informer WaitForCacheSync
#   never completes and NO reconciliation happens (silent, whole-controller
#   stall). Stripping just the isIP/isCIDR/isURL CEL rules lets the CRDs apply;
#   they then serve at v1, which is what Traefik needs.
#
# READ-ONLY on kind: this script targets ONLY the KUBECONFIG you export (the GSK
# kubeconfig). It never touches the local kind cluster. Run it ONCE on the GSK
# cloud-edge before applying deploy/gateway-controller/traefik.
#
# Usage:
#   export KUBECONFIG=<GSK kubeconfig>
#   hack/gsk/apply-gatewayapi-crds.sh
set -euo pipefail

# Pin the Gateway API release (no floating tag). Bump deliberately.
GATEWAY_API_VERSION="${GATEWAY_API_VERSION:-v1.5.1}"
CHANNEL="${GATEWAY_API_CHANNEL:-standard}"
CRD_URL="https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/${CHANNEL}-install.yaml"

: "${KUBECONFIG:?export KUBECONFIG=<GSK kubeconfig> before running (never run against kind)}"

echo "==> Gateway API ${GATEWAY_API_VERSION} (${CHANNEL} channel) — target context: $(kubectl config current-context)"

# Fetch the standard-install bundle, then strip every CEL rule whose expression
# references the k8s-1.31 functions. yq deletes matching x-kubernetes-validations
# entries anywhere in the document tree.
tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT

curl -fsSL "${CRD_URL}" \
  | yq eval '(.. | select(has("x-kubernetes-validations")).x-kubernetes-validations) |=
      map(select(.rule | test("isIP\(|isCIDR\(|isURL\(") | not))' - \
  > "${tmp}"

# Server-side apply (the CRDs are large; --force-conflicts adopts any stale
# field managers from a prior partial apply).
kubectl apply --server-side --force-conflicts -f "${tmp}"

echo "==> verifying TLSRoute serves at v1 (the failure mode this fixes):"
kubectl get --raw /apis/gateway.networking.k8s.io/v1/tlsroutes >/dev/null \
  && echo "OK: gateway.networking.k8s.io/v1/tlsroutes reachable (Traefik cache will sync)."

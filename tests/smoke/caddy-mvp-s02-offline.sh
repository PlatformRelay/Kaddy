#!/usr/bin/env bash
# REQ-CADDY-S02-01..05 — offline structural gate for the Variant B k8s tenant.
# No cluster required. Asserts GitOps manifests + netpol + PodMonitor re-point
# match the S02 contract (mulligan/clubhouse patterns). Live Chainsaw suites
# under tests/chainsaw/caddy-mvp/ remain skip:true until a cluster gate runs.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
TENANT="${ROOT}/deploy/workloads/caddy-mvp"
NETPOL="${ROOT}/deploy/policies/network/caddy-mvp.yaml"
PODMON="${ROOT}/deploy/caddy-mvp/monitoring/prometheus/caddy-podmonitor.yaml"
WORKLOADS_APP="${ROOT}/deploy/apps/workloads.yaml"
WORKLOADS_PROJ="${ROOT}/deploy/apps/projects/workloads.yaml"
PLATFORM_PROJ="${ROOT}/deploy/apps/projects/platform.yaml"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

need_file() { [[ -f "$1" ]] || fail "missing $1"; }

# --- 1) Manifest set present -------------------------------------------------
for f in \
  namespace.yaml \
  gateway.yaml \
  certificate.yaml \
  httproute.yaml \
  services.yaml \
  rollout-caddy-origin.yaml \
  rollout-nginx-proxy.yaml \
  configmap-nginx.yaml \
  analysistemplate.yaml
do
  need_file "${TENANT}/${f}"
done
ok "deploy/workloads/caddy-mvp/ manifest set present"

# --- 2) Namespace + ADR-0301 core labels ------------------------------------
grep -qE '^[[:space:]]*name:[[:space:]]*caddy-mvp[[:space:]]*$' "${TENANT}/namespace.yaml" \
  || fail "namespace.yaml must name caddy-mvp"
for label in owner service part-of managed-by data-classification business-criticality track; do
  grep -qE "^[[:space:]]*${label}:" "${TENANT}/namespace.yaml" \
    || fail "namespace.yaml missing ADR-0301 label: ${label}"
done
ok "namespace caddy-mvp carries ADR-0301 labels"

# --- 3) TLS Certificate via kaddy-local-ca (REQ-CADDY-S02-01) ---------------
grep -qE '^kind:[[:space:]]*Certificate[[:space:]]*$' "${TENANT}/certificate.yaml" \
  || fail "certificate.yaml must be a cert-manager Certificate"
grep -q 'caddy-mvp.kaddy.local' "${TENANT}/certificate.yaml" \
  || fail "Certificate must cover caddy-mvp.kaddy.local"
grep -q 'kaddy-local-ca' "${TENANT}/certificate.yaml" \
  || fail "Certificate must reference ClusterIssuer kaddy-local-ca"
grep -qE '^kind:[[:space:]]*Gateway[[:space:]]*$' "${TENANT}/gateway.yaml" \
  || fail "gateway.yaml must define a Gateway"
grep -q 'caddy-mvp.kaddy.local' "${TENANT}/gateway.yaml" \
  || fail "Gateway listener must use host caddy-mvp.kaddy.local"
grep -qiE 'protocol:[[:space:]]*HTTPS' "${TENANT}/gateway.yaml" \
  || fail "Gateway must have an HTTPS listener (TLS at the edge)"
ok "Gateway + Certificate for caddy-mvp.kaddy.local via kaddy-local-ca"

# --- 4) HTTPRoute + Rollouts topology (REQ-CADDY-S02-02 / S02-04) -----------
grep -qE '^kind:[[:space:]]*HTTPRoute[[:space:]]*$' "${TENANT}/httproute.yaml" \
  || fail "httproute.yaml must define an HTTPRoute"
grep -q 'caddy-mvp.kaddy.local' "${TENANT}/httproute.yaml" \
  || fail "HTTPRoute must host caddy-mvp.kaddy.local"
grep -q 'caddy-origin-stable' "${TENANT}/httproute.yaml" \
  || fail "HTTPRoute must backendRef caddy-origin-stable (canary weight pair)"
grep -q 'caddy-origin-canary' "${TENANT}/httproute.yaml" \
  || fail "HTTPRoute must backendRef caddy-origin-canary"

grep -qE 'name:[[:space:]]*caddy-origin[[:space:]]*$' "${TENANT}/rollout-caddy-origin.yaml" \
  || fail "caddy-origin Rollout missing"
grep -qiE 'canary:' "${TENANT}/rollout-caddy-origin.yaml" \
  || fail "caddy-origin must use canary strategy"
grep -q 'argoproj-labs/gatewayAPI' "${TENANT}/rollout-caddy-origin.yaml" \
  || fail "caddy-origin canary must use gatewayAPI trafficRouting plugin"
grep -qE 'setWeight:[[:space:]]*20' "${TENANT}/rollout-caddy-origin.yaml" \
  || fail "caddy-origin canary steps must include setWeight: 20"
grep -qE 'setWeight:[[:space:]]*50' "${TENANT}/rollout-caddy-origin.yaml" \
  || fail "caddy-origin canary steps must include setWeight: 50"

grep -qE 'name:[[:space:]]*nginx-proxy[[:space:]]*$' "${TENANT}/rollout-nginx-proxy.yaml" \
  || fail "nginx-proxy Rollout missing"
grep -qiE 'blueGreen:' "${TENANT}/rollout-nginx-proxy.yaml" \
  || fail "nginx-proxy must use blueGreen strategy"
grep -q 'nginx-proxy-active' "${TENANT}/rollout-nginx-proxy.yaml" \
  || fail "nginx-proxy blueGreen must reference nginx-proxy-active"
grep -q 'nginx-proxy-preview' "${TENANT}/rollout-nginx-proxy.yaml" \
  || fail "nginx-proxy blueGreen must reference nginx-proxy-preview"

for svc in caddy-origin-stable caddy-origin-canary nginx-proxy-active nginx-proxy-preview; do
  grep -qE "name:[[:space:]]*${svc}[[:space:]]*$" "${TENANT}/services.yaml" \
    || fail "services.yaml missing Service ${svc}"
done

grep -qE '^kind:[[:space:]]*AnalysisTemplate[[:space:]]*$' "${TENANT}/analysistemplate.yaml" \
  || fail "analysistemplate.yaml must define an AnalysisTemplate"
grep -q 'caddy_http_request_duration_seconds_count' "${TENANT}/analysistemplate.yaml" \
  || fail "AnalysisTemplate must query Caddy 5xx SLI series"
ok "Rollouts (canary+blueGreen), Services, HTTPRoute, AnalysisTemplate"

# --- 5) Image pin + hardening (REQ-CADDY-S02-04) -----------------------------
IMAGE_PIN='ghcr.io/platformrelay/kaddy-showcase:0.6.0'
grep -qF "${IMAGE_PIN}" "${TENANT}/rollout-caddy-origin.yaml" \
  || fail "caddy-origin must use digest/tag pin ${IMAGE_PIN} (website-demo pin)"
grep -qF "${IMAGE_PIN}" "${ROOT}/deploy/workloads/website-demo/website.yaml" \
  || fail "website-demo Website XR must pin ${IMAGE_PIN}"
grep -qF "default: ${IMAGE_PIN}" "${ROOT}/deploy/crossplane/xrd-website.yaml" \
  || fail "Website XRD image default must be ${IMAGE_PIN}"
grep -q 'runAsNonRoot: true' "${TENANT}/rollout-caddy-origin.yaml" \
  || fail "caddy-origin missing runAsNonRoot"
grep -q 'readOnlyRootFilesystem: true' "${TENANT}/rollout-caddy-origin.yaml" \
  || fail "caddy-origin missing readOnlyRootFilesystem"
grep -q 'RuntimeDefault' "${TENANT}/rollout-caddy-origin.yaml" \
  || fail "caddy-origin missing seccomp RuntimeDefault"
grep -q 'runAsNonRoot: true' "${TENANT}/rollout-nginx-proxy.yaml" \
  || fail "nginx-proxy missing runAsNonRoot"
grep -q 'readOnlyRootFilesystem: true' "${TENANT}/rollout-nginx-proxy.yaml" \
  || fail "nginx-proxy missing readOnlyRootFilesystem"
ok "image pin ${IMAGE_PIN} + securityContext hardening"

# --- 6) NetworkPolicy baseline (REQ-CADDY-S02-05) ----------------------------
need_file "${NETPOL}"
grep -q 'default-deny' "${NETPOL}" || fail "netpol missing default-deny"
grep -q 'namespace: caddy-mvp' "${NETPOL}" || fail "netpol must target ns caddy-mvp"
grep -q 'allow-dns-egress' "${NETPOL}" || fail "netpol missing allow-dns-egress"
grep -q 'allow-prometheus-scrape' "${NETPOL}" || fail "netpol missing prometheus scrape allow"
grep -q 'nginx-proxy' "${NETPOL}" || fail "netpol must admit Gateway → nginx-proxy"
grep -q 'caddy-origin' "${NETPOL}" || fail "netpol must allow nginx-proxy → caddy-origin"
grep -qE 'kind:[[:space:]]*CiliumNetworkPolicy' "${NETPOL}" \
  || fail "netpol must include CiliumNetworkPolicy for reserved ingress identity"
ok "deploy/policies/network/caddy-mvp.yaml default-deny + minimum allows"

# --- 7) PodMonitor re-point (REQ-CADDY-S02-03) -------------------------------
need_file "${PODMON}"
grep -qE 'namespaceSelector:' "${PODMON}" || fail "PodMonitor missing namespaceSelector"
# matchNames must include caddy-mvp (not the parked gateway selector alone)
grep -A2 'matchNames:' "${PODMON}" | grep -q 'caddy-mvp' \
  || fail "PodMonitor namespaceSelector must include caddy-mvp"
ok "PodMonitor re-pointed at namespace caddy-mvp"

# --- 8) GitOps wiring (REQ-CADDY-S02-02/04) ----------------------------------
need_file "${WORKLOADS_APP}"
need_file "${WORKLOADS_PROJ}"
need_file "${PLATFORM_PROJ}"
grep -A30 'ignoreDifferences:' "${WORKLOADS_APP}" | grep -q 'caddy-mvp' \
  || fail "workloads Application ignoreDifferences must cover caddy-mvp HTTPRoute"
# GSK cloud-edge collision: Argo workloads syncs the kind HTTPRoute (same name/ns)
# over the edge-up cloud route (clubhouse/https-caddy, caddy.lab). Ignore parentRefs
# + hostnames so a live cloud re-apply is not clobbered on the next automated sync.
# Literal jqPathExpressions lines — comments alone must not satisfy these greps.
grep -E '^\s+- \.spec\.parentRefs$' "${WORKLOADS_APP}" \
  || fail "workloads ignoreDifferences must list jqPathExpression '.spec.parentRefs' (GSK/kind Gateway collision)"
grep -E '^\s+- \.spec\.hostnames$' "${WORKLOADS_APP}" \
  || fail "workloads ignoreDifferences must list jqPathExpression '.spec.hostnames' (caddy.lab vs kaddy.local)"
# Without RespectIgnoreDifferences, Argo ignores ignoreDifferences at sync time
# and still reclobbers the clubhouse route.
grep -qE '^\s+- RespectIgnoreDifferences=true$' "${WORKLOADS_APP}" \
  || fail "workloads syncOptions must include RespectIgnoreDifferences=true"
grep -A40 'destinations:' "${WORKLOADS_PROJ}" | grep -q 'caddy-mvp' \
  || fail "workloads AppProject destinations must allow namespace caddy-mvp"
grep -A40 'destinations:' "${PLATFORM_PROJ}" | grep -q 'caddy-mvp' \
  || fail "platform AppProject destinations must allow namespace caddy-mvp (policies netpol)"
grep -A40 'destinations:' "${PLATFORM_PROJ}" | grep -q 'mulligan' \
  || fail "platform AppProject destinations must allow namespace mulligan (policies netpol)"
ok "workloads + platform AppProject destinations + ignoreDifferences for caddy-mvp"

# --- 9) nginx reverse-proxy config present (showcase topology prep) ---------
grep -qiE 'proxy_pass' "${TENANT}/configmap-nginx.yaml" \
  || fail "nginx ConfigMap must proxy_pass to caddy-origin"
grep -q 'caddy-origin' "${TENANT}/configmap-nginx.yaml" \
  || fail "nginx ConfigMap upstream must name caddy-origin"
ok "nginx-proxy ConfigMap proxies to caddy-origin"

echo "OK: REQ-CADDY-S02 offline structural gate green"

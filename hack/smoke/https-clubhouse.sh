#!/usr/bin/env bash
# REQ-E4-S03-02 — clubhouse served over REAL HTTPS through the Cilium edge, with
# the TLS chain VERIFIED (curl --cacert, NO `-k`).
#
# macOS/kind networking note (why in-cluster, not host-loopback):
#   The kind node maps only 127.0.0.1:30080 (HTTP) and 127.0.0.1:30443 (HTTPS)
#   as loopback host ports; both are already held (30443=argocd, 30080=e1e-smoke),
#   and hack/cluster/kind/cluster.yaml is out of this lane's boundary so no new
#   loopback mapping can be added. The Cilium gateway LoadBalancer IP (10.89.0.x)
#   is NOT host-routable on macOS. Therefore this gate curls the Gateway from an
#   IN-CLUSTER pod against the Gateway's ClusterIP/LB address — traffic still
#   traverses the real Cilium Gateway + HTTPRoute + TLS termination. The Gateway
#   service NodePort is still pinned to a free port (CLUBHOUSE_HTTPS_NODEPORT,
#   default 30444) to prove a stable, non-colliding edge port exists.
#
# Trust model: kaddy-local-ca is a genuinely-trusted in-cluster CA. We extract its
# CA cert and pass it via --cacert, so the handshake is verified WITHOUT -k. This
# is the honest kind-local stand-in for REQ-E4-S03-04 (public LE prod is deferred /
# cloud-only — not issuable on kind; see deploy/cert-manager/clubhouse-certificate-letsencrypt.yaml).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"

# SAFETY: isolated kind kubeconfig only (never the shared ~/.kube/config GKE prod).
export KUBECONFIG="${KUBECONFIG:-${ROOT}/.state/kubeconfig}"
CTX="kind-kaddy-dev"
NS="gateway"
HOST="clubhouse.kaddy.local"
GW="clubhouse"
GW_SVC="cilium-gateway-clubhouse"
NODEPORT="${CLUBHOUSE_HTTPS_NODEPORT:-30444}"

fail() { echo "FAIL: $*" >&2; exit 1; }
kc() { kubectl --context "${CTX}" "$@"; }

# Hard-guard the context (mirrors tests/smoke/lib.sh).
[[ -f "${KUBECONFIG}" ]] || fail "kubeconfig ${KUBECONFIG} not found — run 'task cluster:up'"
kc cluster-info >/dev/null 2>&1 || fail "kaddy-dev cluster not reachable"

# 1) Ensure the E4 manifests are live (idempotent apply — selfHeal:false Apps may
#    not have synced a fresh manifest yet; applying proves the live path).
echo "applying E4 manifests (idempotent)"
kc apply -f "${ROOT}/deploy/gateway/namespace.yaml" >/dev/null
kc apply -f "${ROOT}/deploy/cert-manager/clubhouse-certificate.yaml" >/dev/null
kc apply -f "${ROOT}/deploy/workloads/clubhouse/" >/dev/null
kc apply -f "${ROOT}/deploy/gateway/gateway.yaml" >/dev/null
kc apply -f "${ROOT}/deploy/gateway/httproute.yaml" >/dev/null
kc apply -f "${ROOT}/deploy/gateway/httproute-redirect.yaml" >/dev/null

# 2) Certificate Ready + workload rolled out.
echo "waiting for clubhouse Certificate Ready + Deployment available"
kc -n "${NS}" wait --for=condition=Ready certificate/clubhouse-tls --timeout=120s \
  || fail "clubhouse-tls Certificate not Ready"
kc -n "${NS}" rollout status deploy/clubhouse --timeout=120s \
  || fail "clubhouse Deployment not available"

# 3) Gateway Programmed.
echo "waiting for Gateway ${GW} to be Programmed"
kc -n "${NS}" wait --for=condition=Programmed gateway/"${GW}" --timeout=120s \
  || fail "Gateway ${GW} not Programmed"

# 4) Pin the Cilium gateway LB Service to a free NodePort (proves a stable edge
#    port; guard against the port being held elsewhere).
echo "waiting for gateway service ${GW_SVC}"
for _ in $(seq 1 30); do
  kc -n "${NS}" get svc "${GW_SVC}" >/dev/null 2>&1 && break
  sleep 3
done
kc -n "${NS}" get svc "${GW_SVC}" >/dev/null 2>&1 || fail "gateway service ${GW_SVC} not found"
cur_np="$(kc -n "${NS}" get svc "${GW_SVC}" -o json 2>/dev/null \
  | jq -r '.spec.ports[] | select(.port==443) | .nodePort // empty')"
if [[ "${cur_np}" != "${NODEPORT}" ]]; then
  holder="$(kc get svc -A -o json 2>/dev/null \
    | jq -r --argjson p "${NODEPORT}" \
        '.items[] | select(.spec.ports[]?.nodePort==$p) | "\(.metadata.namespace)/\(.metadata.name)"' \
    | grep -v "^${NS}/${GW_SVC}$" || true)"
  [[ -z "${holder}" ]] || fail "nodePort ${NODEPORT} already held by ${holder}"
  # Patch the 443 port's nodePort by index.
  idx="$(kc -n "${NS}" get svc "${GW_SVC}" -o json \
    | jq -r '.spec.ports | to_entries[] | select(.value.port==443) | .key')"
  [[ -n "${idx}" ]] || fail "gateway service ${GW_SVC} has no port 443"
  kc -n "${NS}" patch svc "${GW_SVC}" --type=json \
    -p="[{\"op\":\"replace\",\"path\":\"/spec/ports/${idx}/nodePort\",\"value\":${NODEPORT}}]" >/dev/null \
    || fail "failed to pin ${GW_SVC} 443 nodePort to ${NODEPORT}"
fi
sleep 3
np="$(kc -n "${NS}" get svc "${GW_SVC}" -o json \
  | jq -r '.spec.ports[] | select(.port==443) | .nodePort')"
[[ "${np}" == "${NODEPORT}" ]] || fail "gateway 443 nodePort did not pin to ${NODEPORT} (got ${np})"
echo "gateway ${GW_SVC} 443 pinned to nodePort ${NODEPORT}"

# 5) Extract the local CA cert (the CA that signed clubhouse-tls). The
#    kaddy-local-ca CA ClusterIssuer is backed by the Secret named in its
#    spec.ca.secretName (kaddy-local-ca-tls) in the cert-manager namespace.
CA_CRT="$(mktemp)"; trap 'rm -f "${CA_CRT}"' EXIT
CA_SECRET="$(kc get clusterissuer kaddy-local-ca -o jsonpath='{.spec.ca.secretName}' 2>/dev/null)"
[[ -n "${CA_SECRET}" ]] || fail "kaddy-local-ca ClusterIssuer has no spec.ca.secretName"
kc -n cert-manager get secret "${CA_SECRET}" -o jsonpath='{.data.tls\.crt}' \
  | base64 -d > "${CA_CRT}" 2>/dev/null || true
[[ -s "${CA_CRT}" ]] || fail "could not extract kaddy-local-ca CA cert"

# 6) Curl HTTPS THROUGH the Gateway from an in-cluster pod, VERIFYING the chain
#    with --cacert and NO -k. Resolve the SNI hostname to the Gateway ClusterIP.
GW_CLUSTER_IP="$(kc -n "${NS}" get svc "${GW_SVC}" -o jsonpath='{.spec.clusterIP}')"
[[ -n "${GW_CLUSTER_IP}" ]] || fail "gateway service has no clusterIP"
CA_B64="$(base64 < "${CA_CRT}" | tr -d '\n')"

echo "curling https://${HOST}/ (in-cluster, --cacert, NO -k) via Gateway ${GW_CLUSTER_IP}:443"
POD="clubhouse-smoke-$$"
out="$(kc -n "${NS}" run "${POD}" --rm -i --restart=Never \
  --image=curlimages/curl:8.11.0 --quiet \
  --overrides='{"spec":{"securityContext":{"runAsNonRoot":true,"runAsUser":100}}}' \
  --env=CA_B64="${CA_B64}" -- sh -c "
    echo \"\$CA_B64\" | base64 -d > /tmp/ca.crt
    curl -sS --cacert /tmp/ca.crt --resolve ${HOST}:443:${GW_CLUSTER_IP} \
      -o /tmp/body -w 'HTTP %{http_code} verify=%{ssl_verify_result}\n' \
      https://${HOST}/
    echo '---BODY---'; cat /tmp/body
  " 2>/dev/null)" || fail "in-cluster curl failed:\n${out}"

echo "${out}"
echo "${out}" | grep -q "HTTP 200 verify=0" \
  || fail "expected 'HTTP 200 verify=0' (verified TLS, no -k), got:\n${out}"
echo "${out}" | grep -q "clubhouse" \
  || fail "response body missing marker 'clubhouse'"

echo "OK: REQ-E4-S03-02 clubhouse served over verified HTTPS (no -k) through the Cilium Gateway"

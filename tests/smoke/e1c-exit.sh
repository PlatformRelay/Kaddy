#!/usr/bin/env bash
# REQ-E1c-EXIT (cluster half): the security baseline is LIVE, not just
# authored — Kyverno engine Ready, ClusterPolicies at their documented
# enforcement levels, netpol baseline present, every deploy/apps child off
# project:default (SEC-11), Grafana admin sourced from a Secret (SEC-12).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

# 1) Kyverno engine: admission + reports controllers Ready (GitOps-managed).
for d in kyverno-admission-controller kyverno-reports-controller; do
  kubectl -n kyverno rollout status "deploy/${d}" --timeout=120s >/dev/null \
    || smoke_fail "${d} not Ready"
done
smoke_ok "kyverno admission + reports controllers Ready"

# 2) ClusterPolicies live at the documented enforcement matrix
#    (deploy/policies/README.md — verify-signed-images stays Audit until a
#    real cosign key exists).
declare -A want=(
  [require-kaddy-labels]=Enforce
  [restrict-data-classification]=Enforce
  [disallow-privileged-containers]=Enforce
  [disallow-latest-tag]=Enforce
  [require-run-as-nonroot]=Enforce
  [verify-signed-images]=Audit
)
for p in "${!want[@]}"; do
  got="$(kubectl get clusterpolicy "${p}" -o jsonpath='{.spec.validationFailureAction}' 2>/dev/null || true)"
  [[ "${got}" == "${want[$p]}" ]] \
    || smoke_fail "clusterpolicy ${p}: want ${want[$p]}, got '${got}'"
  ready="$(kubectl get clusterpolicy "${p}" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
  [[ "${ready}" == "True" ]] || smoke_fail "clusterpolicy ${p} not Ready"
done
smoke_ok "6 ClusterPolicies live at the documented Enforce/Audit matrix"

# 3) Enforce is real: an unlabeled pod in a governed namespace is DENIED.
if kubectl -n default run e1c-denied-probe --image=curlimages/curl:8.11.0 \
    --restart=Never --command -- sleep 1 >/dev/null 2>&1; then
  kubectl -n default delete pod e1c-denied-probe --ignore-not-found >/dev/null 2>&1
  smoke_fail "unlabeled pod was ADMITTED in ns default (labels policy not enforcing)"
fi
smoke_ok "unlabeled pod denied by admission (require-kaddy-labels Enforce)"

# 4) Netpol baseline present (default-deny + Cilium allows).
kubectl -n gateway get networkpolicy default-deny-all >/dev/null || smoke_fail "gateway default-deny-all missing"
kubectl -n monitoring get networkpolicy default-deny-ingress >/dev/null || smoke_fail "monitoring default-deny-ingress missing"
kubectl -n argocd get networkpolicy default-deny-ingress >/dev/null || smoke_fail "argocd default-deny-ingress missing"
kubectl -n gateway get cnp allow-gateway-to-clubhouse >/dev/null || smoke_fail "gateway CNP missing"
kubectl -n monitoring get cnp allow-apiserver-to-webhooks >/dev/null || smoke_fail "monitoring CNP missing"
smoke_ok "default-deny netpol baseline + Cilium allows present"

# 5) SEC-11: no deploy/apps child runs under project:default.
bad="$(kubectl -n argocd get applications -o json \
  | jq -r '.items[] | select(.spec.project=="default")
           | select(.metadata.name | IN("root","platform-core","policies","identity","kyverno","rollouts","observability","monitoring","gateway","workloads"))
           | .metadata.name')"
[[ -z "${bad}" ]] || smoke_fail "apps still on project:default: ${bad}"
smoke_ok "all deploy/apps children on restricted AppProjects"

# 6) SEC-12: Grafana admin from Secret; chart-default secret gone.
kubectl -n monitoring get secret grafana-admin >/dev/null \
  || smoke_fail "monitoring/grafana-admin Secret missing (task bootstrap:e1c)"
if kubectl -n monitoring get secret kube-prometheus-stack-grafana >/dev/null 2>&1; then
  smoke_fail "chart-default Grafana admin Secret still present (kube-prometheus-stack-grafana)"
fi
ref="$(kubectl -n monitoring get deploy kube-prometheus-stack-grafana \
  -o jsonpath='{.spec.template.spec.containers[?(@.name=="grafana")].env[?(@.name=="GF_SECURITY_ADMIN_PASSWORD")].valueFrom.secretKeyRef.name}')"
[[ "${ref}" == "grafana-admin" ]] \
  || smoke_fail "grafana deployment reads admin password from '${ref}', want grafana-admin"
smoke_ok "grafana admin sourced from monitoring/grafana-admin (SEC-12)"

smoke_ok "REQ-E1c-EXIT (cluster half)"

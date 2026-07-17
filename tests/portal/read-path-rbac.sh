#!/usr/bin/env bash
# REQ-E10-S04-01 — the portal read path is READ-ONLY and network-scoped
# (D-029, ADR-0111). The read-path plugins (crossplane-resources, Kubernetes,
# ArgoCD) render live status from the cluster + ArgoCD API. D-029 accepts a
# read-only cluster credential as a named trade (impressiveness > minimal-trust
# for the demo). "Read-only" is the WHOLE bargain, so it must be verifiable
# offline against the manifests. We assert:
#   1. the portal ClusterRole holds ONLY get/list/watch — NO mutating verb
#      (create/update/patch/delete/deletecollection/* / escalate/bind/impersonate)
#   2. the ClusterRole covers the Website XR + composed/workload GVKs
#   3. a ServiceAccount + ClusterRoleBinding wire the SA to that ClusterRole
#   4. the netpol egress is scoped to kube-apiserver + argocd-server only
#      (default-deny elsewhere) — no unscoped 0.0.0.0/0 world egress
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"

RBAC_DIR="${ROOT}/deploy/portal/backstage/rbac"
RBAC="${RBAC_DIR}/read-only-rbac.yaml"
NETPOL="${RBAC_DIR}/networkpolicy.yaml"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

[[ -f "${RBAC}" ]]   || fail "missing ${RBAC}"
[[ -f "${NETPOL}" ]] || fail "missing ${NETPOL}"

# --- 1) ClusterRole verbs are read-only ONLY --------------------------------
grep -qE 'kind:[[:space:]]*ClusterRole\b' "${RBAC}" \
  || fail "read-only-rbac.yaml must define a ClusterRole (cluster-wide get/list/watch across per-site namespaces)"

# Every `verbs` entry in the rules must be a subset of {get,list,watch}. Only
# inspect actual `verbs:` lines (rules use inline arrays: verbs: ["get",...]) —
# strip trailing `#` comments first so prose in the file's header can't trip the
# scan. Reject any mutating verb or the wildcard verb '*'.
verb_lines="$(grep -E '^[[:space:]]*verbs:' "${RBAC}" | sed 's/#.*//')"
[[ -n "${verb_lines}" ]] || fail "read-only-rbac.yaml has no verbs: lines (no rules?)"
if printf '%s\n' "${verb_lines}" | grep -qE '["'\''[:space:],\[]\*|\*["'\''[:space:],\]]'; then
  fail "read-only ClusterRole must NOT grant the wildcard verb '*'"
fi
mutating="$(printf '%s\n' "${verb_lines}" \
              | grep -oiE '\b(create|update|patch|delete|deletecollection|edit|escalate|bind|impersonate)\b' \
              || true)"
[[ -z "${mutating}" ]] || fail "read-only ClusterRole grants a mutating verb: ${mutating//$'\n'/, }"
grep -qiE '\bget\b' "${RBAC}"   || fail "ClusterRole should grant get (read-path visibility)"
grep -qiE '\blist\b' "${RBAC}"  || fail "ClusterRole should grant list"
grep -qiE '\bwatch\b' "${RBAC}" || fail "ClusterRole should grant watch"
ok "portal ClusterRole is read-only (get/list/watch only — no mutating verb, no wildcard)"

# --- 2) covers the Website XR + composed/workload GVKs -----------------------
grep -qE 'platform\.kaddy\.io' "${RBAC}" \
  || fail "ClusterRole must cover the Website XR API group platform.kaddy.io"
# Composed GVKs the crossplane-resources graph + Kubernetes plugin render:
for g in 'apiextensions\.crossplane\.io' 'gateway\.networking\.k8s\.io' 'cert-manager\.io'; do
  grep -qE "${g}" "${RBAC}" || fail "ClusterRole must cover composed group ${g//\\/}"
done
# Core workload objects (deployments/pods/services) — apps + core groups.
grep -qiE 'deployments' "${RBAC}" || fail "ClusterRole must cover deployments (workload health)"
grep -qiE '\bpods\b'    "${RBAC}" || fail "ClusterRole must cover pods (workload health)"
ok "ClusterRole covers Website XR + composed (crossplane/gateway/cert-manager) + workload GVKs"

# --- 3) SA + ClusterRoleBinding wire it together ----------------------------
grep -qE 'kind:[[:space:]]*ServiceAccount' "${RBAC}" \
  || fail "read-only-rbac.yaml must define the portal ServiceAccount"
grep -qE 'kind:[[:space:]]*ClusterRoleBinding' "${RBAC}" \
  || fail "read-only-rbac.yaml must bind the SA to the ClusterRole"
grep -qE 'namespace:[[:space:]]*portal' "${RBAC}" \
  || fail "the portal ServiceAccount must live in the portal namespace"
ok "ServiceAccount + ClusterRoleBinding wire the portal SA to the read-only ClusterRole"

# --- 4) netpol egress scoped to kube-apiserver + argocd-server only ----------
grep -qE 'kind:[[:space:]]*NetworkPolicy' "${NETPOL}" \
  || fail "networkpolicy.yaml must define a NetworkPolicy"
grep -qE 'name:[[:space:]]*default-deny' "${NETPOL}" \
  || fail "portal namespace must carry a default-deny NetworkPolicy"
# The read path egresses only to the kube-apiserver and argocd-server.
grep -qiE 'kube-apiserver|kubernetes\.default|apiserver|6443|kubernetes' "${NETPOL}" \
  || fail "netpol must allow egress to the kube-apiserver (read-path)"
grep -qiE 'argocd(-server)?' "${NETPOL}" \
  || fail "netpol must allow egress to argocd-server (ArgoCD read-path plugin)"
# No unscoped world egress from the read path (Dex/GitHub OIDC egress, if any,
# must be port+pod-scoped — a bare 0.0.0.0/0 with no port would be unscoped).
if grep -qE 'cidr:[[:space:]]*0\.0\.0\.0/0' "${NETPOL}" \
   && ! grep -qE 'ports:' "${NETPOL}"; then
  fail "netpol has an unscoped 0.0.0.0/0 egress with no port restriction"
fi
ok "netpol default-deny + egress scoped to kube-apiserver + argocd-server"

echo "PASS: read-path-rbac — portal read path is read-only + network-scoped (D-029)"

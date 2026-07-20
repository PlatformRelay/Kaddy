#!/usr/bin/env bash
# E1g-S05b / D-044 follow-up — OFFLINE gate for the GSK Traefik GitOps Application.
# No cluster. Proves the cloud-only Traefik Application disables the chart's
# default IngressClass mint (cluster-scoped; not on gsk-cloud-edge whitelist)
# so Argo sync stays Healthy without widening the project ACL.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
APP="${ROOT}/deploy/gateway-controller/traefik/application.yaml"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

[[ -f "${APP}" ]] || fail "missing ${APP}"

grep -qE 'kind:[[:space:]]*Application' "${APP}" \
  || fail "traefik application.yaml must be an Argo Application"
grep -qE 'project:[[:space:]]*gsk-cloud-edge' "${APP}" \
  || fail "Traefik App must use the dedicated gsk-cloud-edge AppProject"

# valuesObject.ingressClass.enabled: false — structural check (YAML indent under
# helm.valuesObject). Reject enabled:true / missing block.
set +e
awk '
  /ingressClass:/ { in_ic=1; next }
  in_ic && /enabled:[[:space:]]*false/ { found=1; exit }
  in_ic && /enabled:[[:space:]]*true/ { bad=1; exit }
  in_ic && /^[[:space:]]*[a-zA-Z]/ && $0 !~ /^[[:space:]]{8,}/ { exit }
  END { exit (bad ? 2 : (found ? 0 : 1)) }
' "${APP}"
ic_rc=$?
set -e
case "${ic_rc}" in
  0) ok "Traefik valuesObject sets ingressClass.enabled: false" ;;
  2) fail "Traefik valuesObject must NOT set ingressClass.enabled: true" ;;
  *) fail "Traefik valuesObject must set ingressClass.enabled: false (chart default mints IngressClass)" ;;
esac

echo "OK: E1g Traefik GitOps offline gate green"

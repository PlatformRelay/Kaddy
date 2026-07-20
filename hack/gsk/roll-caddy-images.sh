#!/usr/bin/env bash
# GSK live — roll Caddy images to the newest pinned tags (CLOUD-ONLY).
#
# Targets (live inventory as of 2026-07-20 was stale):
#   ns caddy-mvp  Rollout/caddy-origin  container caddy
#     → ghcr.io/platformrelay/kaddy-showcase:0.6.0
#   ns caddy-demo Deployment/caddy      container caddy
#     → caddy:2.11.4-alpine
#       (demo is intentionally live-only; see evidence/live/e1g-cloud-edge-live-2026-07-18.md)
#
# Prefer running AFTER the showcase-pin-0.6.0 GitOps lane lands on main — otherwise
# Argo CD may revert caddy-mvp to the git pin. caddy-demo has no GitOps pin.
#
# kind-safety: MUTATES the target cluster, so it is guarded by
# hack/lib/guard-context.sh AND always requires KADDY_GSK_CONTEXT (cloud-only;
# never defaults to kind even when the active context is kind-kaddy-dev).
#
# Usage:
#   export KUBECONFIG=<GSK kubeconfig>   # e.g. .state/gsk/kubeconfig
#   kubectl config use-context kaddy-gsk-admin@kaddy-gsk
#   export KADDY_GSK_CONTEXT="$(kubectl config current-context)"
#   hack/gsk/roll-caddy-images.sh --dry-run   # print plan, no mutations
#   hack/gsk/roll-caddy-images.sh            # apply + wait + verify
set -euo pipefail

_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=hack/lib/guard-context.sh disable=SC1091
. "${_root}/hack/lib/guard-context.sh"

SHOWCASE_IMAGE="${KADDY_SHOWCASE_IMAGE:-ghcr.io/platformrelay/kaddy-showcase:0.6.0}"
DEMO_IMAGE="${KADDY_DEMO_CADDY_IMAGE:-caddy:2.11.4-alpine}"
MVP_NS="${KADDY_CADDY_MVP_NS:-caddy-mvp}"
DEMO_NS="${KADDY_CADDY_DEMO_NS:-caddy-demo}"
MVP_ROLLOUT="${KADDY_CADDY_MVP_ROLLOUT:-caddy-origin}"
MVP_CONTAINER="${KADDY_CADDY_MVP_CONTAINER:-caddy}"
DEMO_DEPLOY="${KADDY_CADDY_DEMO_DEPLOY:-caddy}"
DEMO_CONTAINER="${KADDY_CADDY_DEMO_CONTAINER:-caddy}"
TIMEOUT="${KADDY_ROLL_TIMEOUT:-180s}"

DRY_RUN=0
for arg in "$@"; do
  case "${arg}" in
    --dry-run|-n) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown arg: ${arg} (supported: --dry-run|-n|-h|--help)" >&2
      exit 2
      ;;
  esac
done

: "${KUBECONFIG:?export KUBECONFIG=<GSK kubeconfig> before running (never run against kind)}"
: "${KADDY_GSK_CONTEXT:?export KADDY_GSK_CONTEXT=\$(kubectl config current-context) — this script is cloud-only}"

guard_writable_context

active="$(kubectl config current-context)"
echo "==> Target GSK context: ${active}"
echo "==> Plan:"
echo "    ${MVP_NS}/${MVP_ROLLOUT} (${MVP_CONTAINER}) → ${SHOWCASE_IMAGE}"
echo "    ${DEMO_NS}/${DEMO_DEPLOY} (${DEMO_CONTAINER}) → ${DEMO_IMAGE}"

if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo "==> DRY-RUN — would apply the image bumps above (no kubectl mutations)."
  echo "    Re-run without --dry-run to apply + wait + verify."
  exit 0
fi

echo "==> Reading current images"
old_mvp="$(kubectl -n "${MVP_NS}" get rollout "${MVP_ROLLOUT}" \
  -o jsonpath="{.spec.template.spec.containers[?(@.name==\"${MVP_CONTAINER}\")].image}")"
old_demo="$(kubectl -n "${DEMO_NS}" get deploy "${DEMO_DEPLOY}" \
  -o jsonpath="{.spec.template.spec.containers[?(@.name==\"${DEMO_CONTAINER}\")].image}")"
echo "    was: mvp=${old_mvp:-<missing>}  demo=${old_demo:-<missing>}"

# Rollout: JSON-patch the named container image (kubectl set image does not
# cover argoproj.io/v1alpha1 Rollout). Find the container index by name.
mvp_idx="$(kubectl -n "${MVP_NS}" get rollout "${MVP_ROLLOUT}" -o json \
  | python3 -c "
import json, sys
doc = json.load(sys.stdin)
name = '''${MVP_CONTAINER}'''
for i, c in enumerate(doc['spec']['template']['spec']['containers']):
    if c.get('name') == name:
        print(i)
        raise SystemExit(0)
raise SystemExit(f'container {name!r} not found on rollout')
")"

echo "==> Patching Rollout ${MVP_NS}/${MVP_ROLLOUT}[${mvp_idx}].image"
kubectl -n "${MVP_NS}" patch rollout "${MVP_ROLLOUT}" --type=json \
  -p="[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/${mvp_idx}/image\",\"value\":\"${SHOWCASE_IMAGE}\"}]"

echo "==> Setting Deployment ${DEMO_NS}/${DEMO_DEPLOY} image"
kubectl -n "${DEMO_NS}" set image "deployment/${DEMO_DEPLOY}" \
  "${DEMO_CONTAINER}=${DEMO_IMAGE}"

echo "==> Waiting for rollouts"
kubectl -n "${MVP_NS}" rollout status "rollout/${MVP_ROLLOUT}" --timeout="${TIMEOUT}"
kubectl -n "${DEMO_NS}" rollout status "deployment/${DEMO_DEPLOY}" --timeout="${TIMEOUT}"

new_mvp="$(kubectl -n "${MVP_NS}" get rollout "${MVP_ROLLOUT}" \
  -o jsonpath="{.spec.template.spec.containers[?(@.name==\"${MVP_CONTAINER}\")].image}")"
new_demo="$(kubectl -n "${DEMO_NS}" get deploy "${DEMO_DEPLOY}" \
  -o jsonpath="{.spec.template.spec.containers[?(@.name==\"${DEMO_CONTAINER}\")].image}")"

echo "==> Verify"
echo "    mvp:  ${old_mvp} → ${new_mvp}"
echo "    demo: ${old_demo} → ${new_demo}"

[[ "${new_mvp}" == "${SHOWCASE_IMAGE}" ]] || {
  echo "FAIL: mvp image is '${new_mvp}', expected '${SHOWCASE_IMAGE}'" >&2
  exit 1
}
[[ "${new_demo}" == "${DEMO_IMAGE}" ]] || {
  echo "FAIL: demo image is '${new_demo}', expected '${DEMO_IMAGE}'" >&2
  exit 1
}

echo "OK: Caddy images rolled on GSK."
echo "    HTTPS check: curl -fsS -o /dev/null -w '%{http_code}\\n' https://caddy.lab.platformrelay.dev/"
echo "                 curl -fsS -o /dev/null -w '%{http_code}\\n' https://demo.lab.platformrelay.dev/"
echo "    Note: if Argo CD auto-syncs caddy-mvp from git still pinned to an older"
echo "    tag, re-run after showcase-pin-0.6.0 lands (or force-sync the App)."

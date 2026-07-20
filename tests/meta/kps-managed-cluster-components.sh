#!/usr/bin/env bash
# Guard: kube-prometheus-stack must NOT monitor managed-cluster control-plane
# components (offline).
#
# GSK is a MANAGED cluster: etcd / kube-controller-manager / kube-scheduler /
# kube-proxy / CoreDNS endpoints are not scrapeable, and the chart's defaults
# render headless Services into `kube-system`, which the closed `observability`
# AppProject (destinations: monitoring, argocd only) rejects — the sync fails
# with "namespace kube-system is not permitted in project 'observability'".
# POLICY: the AppProject stays closed; the components stay disabled here.
#
# Asserts, in deploy/observability/kube-prometheus-stack.yaml valuesObject:
#   (a) the five component toggles are exactly `false`; and
#   (b) the matching defaultRules.rules toggles are exactly `false` (87.x keys:
#       etcd, kubeControllerManager, kubeSchedulerAlerting/Recording, kubeProxy)
#       so no orphaned alerts fire on permanently-absent targets.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP="$ROOT/deploy/observability/kube-prometheus-stack.yaml"
fail() { echo "FAIL: $*" >&2; exit 1; }
command -v yq >/dev/null 2>&1 || fail "yq is required"
[ -f "$APP" ] || fail "missing $APP"

VALUES=".spec.source.helm.valuesObject"

# NOTE: no yq `//` alternative here — `false // "unset"` yields "unset"
# (false is falsy to `//`), which would mask a correct `false`. A missing
# path prints `null` instead.

# (a) control-plane component toggles — each must be exactly `false`.
for comp in kubeEtcd kubeControllerManager kubeScheduler kubeProxy coreDns; do
  got="$(yq e "${VALUES}.${comp}.enabled" "$APP")"
  [ "$got" = "false" ] \
    || fail "valuesObject.${comp}.enabled must be false (managed cluster; closed AppProject blocks kube-system Services) — got '${got}'"
done

# kubeDns must NOT be force-enabled (chart default is false; stays unset/false).
kdns="$(yq e "${VALUES}.kubeDns.enabled" "$APP")"
case "$kdns" in
  null|false) : ;;
  *) fail "valuesObject.kubeDns.enabled must stay unset/false — got '${kdns}'" ;;
esac

# (b) matching defaultRules.rules toggles — each must be exactly `false`.
for rule in etcd kubeControllerManager kubeSchedulerAlerting kubeSchedulerRecording kubeProxy; do
  got="$(yq e "${VALUES}.defaultRules.rules.${rule}" "$APP")"
  [ "$got" = "false" ] \
    || fail "valuesObject.defaultRules.rules.${rule} must be false (no alerts on absent control-plane targets) — got '${got}'"
done

echo "OK: kps managed-cluster control-plane components + matching default rules disabled"

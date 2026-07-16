#!/usr/bin/env bash
# Shared helpers for the E5 marshal smoke tests. Source AFTER tests/smoke/lib.sh.
# Provides port-forwarded access to Prometheus / Alertmanager / Grafana in ns
# monitoring plus small query helpers. Every consumer must have called
# smoke_require_cluster first.

E5_NS="monitoring"
E5_PF_PIDS=()

e5_cleanup_pf() { for pid in "${E5_PF_PIDS[@]:-}"; do kill "${pid}" >/dev/null 2>&1 || true; done; }
trap e5_cleanup_pf EXIT

# e5_port_forward <svc> <local-port> <remote-port>
e5_port_forward() {
  kubectl -n "${E5_NS}" port-forward "svc/$1" "$2:$3" >/dev/null 2>&1 &
  E5_PF_PIDS+=($!)
  # Wait for the tunnel to accept connections.
  for _ in $(seq 1 20); do
    if curl -s -o /dev/null "http://127.0.0.1:$2/" 2>/dev/null; then return 0; fi
    sleep 0.5
  done
  return 0
}

# e5_prom_query <promql> — prints the first sample value ("" when no result).
e5_prom_query() {
  curl -sf --get "http://127.0.0.1:${E5_PROM_PORT:-29090}/api/v1/query" \
    --data-urlencode "query=$1" \
    | yq -p json '.data.result[0].value[1] // ""' 2>/dev/null || true
}

e5_prom_up() { e5_port_forward kps-prometheus "${E5_PROM_PORT:-29090}" 9090; }
e5_am_up()   { e5_port_forward kps-alertmanager "${E5_AM_PORT:-29093}" 9093; }
e5_grafana_up() { e5_port_forward kube-prometheus-stack-grafana "${E5_GRAFANA_PORT:-23000}" 80; }

# e5_grafana_creds — exports E5_GRAFANA_USER / E5_GRAFANA_PASS from the chart's
# admin Secret (never hardcoded; rotating the Secret keeps the smoke green).
e5_grafana_creds() {
  E5_GRAFANA_USER="$(kubectl -n "${E5_NS}" get secret kube-prometheus-stack-grafana \
    -o jsonpath='{.data.admin-user}' | base64 -d)"
  E5_GRAFANA_PASS="$(kubectl -n "${E5_NS}" get secret kube-prometheus-stack-grafana \
    -o jsonpath='{.data.admin-password}' | base64 -d)"
  export E5_GRAFANA_USER E5_GRAFANA_PASS
}

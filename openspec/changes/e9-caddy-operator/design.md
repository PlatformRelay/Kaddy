# Design — Caddy operator

## CRD: Caddy

```yaml
apiVersion: gateway.kaddy.io/v1alpha1
kind: Caddy
metadata:
  name: edge
  labels:
    app.kubernetes.io/name: caddy
    app.kubernetes.io/part-of: kaddy
spec:
  replicas: 2
  gatewayClassName: caddy
  metrics:
    enabled: true
  admin:
    listen: ":2019"
status:
  conditions:
    - type: Ready
```

## CRD: CaddySite

```yaml
apiVersion: gateway.kaddy.io/v1alpha1
kind: CaddySite
metadata:
  name: clubhouse
spec:
  caddyRef: edge
  hosts: ["demo.example.com"]
  routes:
    - path: /
      backend:
        serviceName: clubhouse
        port: 8080
  observability:
    prometheusRules: true
    serviceMonitor: true
    grafanaDashboard: true
```

## Reconcile loop

```mermaid
sequenceDiagram
  participant API as Kubernetes API
  participant Op as Caddy Operator
  participant Caddy as Caddy Admin API
  participant Prom as Prometheus CRs
  API->>Op: CaddySite updated
  Op->>Op: Render JSON config
  Op->>Caddy: PUT /config/...
  Op->>Prom: Ensure ServiceMonitor/Rules
  Op->>API: Update status conditions
```

## Testing strategy (future E9)

- envtest: reconcile without real Caddy (mock Admin API)
- Contract tests for generated PrometheusRule labels (owner, service)

## Non-goals v1

- Replace Gateway API controller entirely
- Multi-tenant hard isolation

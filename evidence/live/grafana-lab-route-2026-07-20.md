# grafana.lab restore — 2026-07-20

## Probe
- `grafana.lab.platformrelay.de` — NXDOMAIN (operator typo; correct TLD is `.dev`)
- `grafana.lab.platformrelay.dev` — was HTTPS **503** body `no available server`; after fix **200** sticky ×3

## Root cause
1. **Empty backends:** `Deployment/monitoring-grafana` `spec.replicas=0` (Endpoints empty). Scaled down ~10m earlier during MemoryPressure recovery and not restored. HTTPRoute Accepted/ResolvedRefs; Traefik had no ready endpoints.
2. **NetPol gap (durable):** `deploy/policies/network/monitoring.yaml` default-deny had no Traefik peer allow for Grafana :3000 (comment still claimed "No Gateway/HTTPRoute fronts monitoring"). Same class as portal/caddy Traefik gaps. Would have blocked after scale-up.

## Live restore
- `kubectl scale deploy/monitoring-grafana -n monitoring --replicas=1` → Ready on node-pool-0-2
- Applied `allow-traefik-to-grafana` NetPol + CNP (then re-applied from GitOps lane)

## GitOps
- Branch `lane/grafana-lab-route`: NetPol/CNP in `deploy/policies/network/monitoring.yaml` + offline smoke `tests/smoke/e1g-grafana-lab-traefik-netpol.sh`

## Related (not blocking HTTPS)
- Argo `kube-prometheus-stack` OutOfSync/SyncError: chart wants `kube-system` resources; project `observability` denies that ns. Live stack is imperative Helm release `monitoring` (not the Argo `kps` fullnameOverride).

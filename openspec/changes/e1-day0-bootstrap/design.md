# Design — E1 platform bootstrap (driving-range)

## Prerequisites

- [driving-range](../../../driving-range/) E10 complete: Cilium Gateway API + LB-IPAM/L2 (ADR-0203).
- `local-path-provisioner` default StorageClass (driving-range E7).

## Handoff

```text
driving-range (tofu output kubeconfig + documented Gateway LB IP pool)
  → kaddy deploy/bootstrap/argocd.yaml
```

Document in `docs/runbooks/driving-range-handoff.md`:

- Cilium `GatewayClass` name (`cilium`)
- LB-IPAM pool CIDR (`192.168.100.200–.220`)
- How to read the platform Gateway address after E2

## Risks

- driving-range host offline → no cluster
- LB-IPAM pool exhaustion — size pool in driving-range E10 vars

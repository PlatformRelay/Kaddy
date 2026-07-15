# Design — E1g gridscale day-0

## Stack layout

```
stacks/gridscale/network → stacks/gridscale/k8s → (state-bucket bootstrapped first)
```

## Provider & state

- Provider `gridscale/gridscale` **v2**; auth `GRIDSCALE_UUID` / `GRIDSCALE_TOKEN`.
- Remote state in gridscale Object Storage (S3-compatible).

## Handoff

GSK kubeconfig → re-point ArgoCD bootstrap → verify app-of-apps sync.

## Risks

- Provider v2 node-pool update inconsistency — runbook note.
- Phase-1 vs phase-2 LoadBalancer / TLS delta — re-test E4/E5 on GSK.

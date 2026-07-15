# deploy/apps — Argo CD app-of-apps (ADR-0103)

`root.yaml` is the root Application. It points Argo CD at this directory and
discovers the flat child Applications beside it (`root.yaml` itself is excluded
so it never self-manages). Committed steady-state `targetRevision` is **`main`**
on every Application; merging to `main` is what makes Argo CD sync for real.

## Children

| App | Path | selfHeal | Notes |
| --- | --- | --- | --- |
| `platform-core` | `deploy/cert-manager` | **on** | ACME ClusterIssuers; declarative & idempotent |
| `observability` | `deploy/observability` | off | kube-prometheus-stack + Loki + Alloy (stateful) |
| `gateway` | `deploy/gateway` | off | placeholder; CRDs/GatewayClass owned by E1e |
| `workloads` | `deploy/workloads` | off | placeholder; sample apps, later Rollouts-managed |
| `identity` | `deploy/identity` | n/a (manual) | **deferred** — needs KSOPS (REQ-E3-S01-03) |

## selfHeal policy (REQ-E3-S01-02)

`syncPolicy.automated.selfHeal: true` is set on **`platform-core` only**. Its
resources are cluster-scoped, declarative and idempotent, so live drift should
snap straight back to Git without a human.

Documented exceptions (selfHeal **off**, auto create/update still on):

- **observability** — Prometheus TSDB / Loki WAL are stateful; a human stays in
  the loop before Argo forcibly reverts drift on a running datastore.
- **gateway / workloads** — front live traffic and (for workloads) will be
  Argo Rollouts-managed in E7, which needs `ignoreDifferences` on Rollouts-owned
  HTTPRoute weight labels (ADR-0103). Enabling selfHeal before that lands would
  fight the Rollouts controller.
- **identity** — manual sync only; deferred until KSOPS decrypts its secrets.

## Live proof before merge

The committed files say `targetRevision: main`. To prove the sync loop against an
un-merged lane branch, apply a runtime-overridden copy of `root.yaml` with
`targetRevision` set to the pushed branch (the lane runbook does this into a temp
file); the committed truth stays `main`.

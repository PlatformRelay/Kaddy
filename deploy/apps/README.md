# deploy/apps — Argo CD app-of-apps (ADR-0103)

`root.yaml` is the root Application. It points Argo CD at this directory and
discovers the flat child Applications beside it (`root.yaml` itself is excluded
so it never self-manages). Committed steady-state `targetRevision` is **`main`**
on every Application; merging to `main` is what makes Argo CD sync for real.

`root` runs with `syncPolicy.automated.selfHeal: true` (+ `prune`): the app-of-apps
root manages only child Application CRs — declarative and non-destructive — so it
reconciles child registration/de-registration straight from Git (the canonical
app-of-apps pattern). It is one of the two **control-plane apps** that self-heal.

## Children

| App | Path | selfHeal | Notes |
| --- | --- | --- | --- |
| `platform-core` | `deploy/cert-manager` | **on** | ACME ClusterIssuers; declarative & idempotent |
| `observability` | `deploy/observability` | off | kube-prometheus-stack + Loki + Alloy (stateful) |
| `gateway` | `deploy/gateway` | off | placeholder; CRDs/GatewayClass owned by E1e |
| `workloads` | `deploy/workloads` | off | placeholder; sample apps, later Rollouts-managed |
| `crossplane` | `deploy/crossplane` | off | E6: Crossplane v2 (nested pinned Helm app) + Website XRD/Composition |
| `identity` | `deploy/identity` | n/a (manual) | **deferred** — needs KSOPS (REQ-E3-S01-03) |

## selfHeal policy (REQ-E3-S01-02)

`syncPolicy.automated.selfHeal: true` is set on the **control-plane apps
(`root` + `platform-core`)** only. Both manage exclusively declarative Argo/config
CRs (child Applications; cluster-scoped ACME ClusterIssuers) that are idempotent,
so live drift snaps straight back to Git without a human. Workload-facing children
keep selfHeal **off**.

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

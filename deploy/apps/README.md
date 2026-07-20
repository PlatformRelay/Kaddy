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
| `identity` | `deploy/identity` | **on** | KSOPS decrypt at render time (ADR-0110); prune+selfHeal |
| `policies` | `deploy/policies` | off | ClusterPolicies + NetPol baseline; autosync ON (D-046), selfHeal OFF |
| `kyverno` | `deploy/kyverno` | off | admission engine install only |

## selfHeal policy (REQ-E3-S01-02)

`syncPolicy.automated.selfHeal: true` is set on the **control-plane apps
(`root` + `platform-core` + `identity`)** only. They manage declarative
Argo/config/KSOPS CRs (child Applications; ACME ClusterIssuers; Dex/OIDC
secrets) that are idempotent, so live drift snaps straight back to Git without
a human. Workload-facing children keep selfHeal **off**.

Documented exceptions (selfHeal **off**, auto create/update still on):

- **observability** — Prometheus TSDB / Loki WAL are stateful; a human stays in
  the loop before Argo forcibly reverts drift on a running datastore.
- **gateway / workloads** — front live traffic and (for workloads) will be
  Argo Rollouts-managed in E7, which needs `ignoreDifferences` on Rollouts-owned
  HTTPRoute weight labels (ADR-0103). Enabling selfHeal before that lands would
  fight the Rollouts controller.
- **policies / kyverno** — admission + network controls (and the engine install)
  auto-sync create/update so Git is the delivery path; selfHeal stays **off** so
  a human reviews live drift before Argo forcibly reverts (D-046).

**Default:** every `deploy/apps/*.yaml` Application declares `syncPolicy.automated`
(prune on). Manual-sync exceptions must be allow-listed in
`tests/smoke/argocd-autosync-defaults-offline.sh` and documented here.

## Live proof before merge

The committed files say `targetRevision: main`. To prove the sync loop against an
un-merged lane branch, apply a runtime-overridden copy of `root.yaml` with
`targetRevision` set to the pushed branch (the lane runbook does this into a temp
file); the committed truth stays `main`.

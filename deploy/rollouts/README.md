# deploy/rollouts — Argo Rollouts controller (E7 mulligan)

GitOps-managed install of the [Argo Rollouts](https://argoproj.github.io/rollouts/)
progressive-delivery controller, synced by the `rollouts` child Application
(`deploy/apps/rollouts.yaml`) into the `argo-rollouts` namespace.

## Contents

| File | What |
| --- | --- |
| `namespace.yaml` | `argo-rollouts` namespace (ADR-0301 labels). |
| `install.yaml` | **Vendored, pinned** upstream `install.yaml` for `v1.9.0` (controller image `quay.io/argoproj/argo-rollouts:v1.9.0`). Auto-generated upstream — the only local edit is the removal of the empty `argo-rollouts-config` ConfigMap so `config.yaml` can own it (Argo CD rejects duplicate resources in one App). |
| `config.yaml` | The `argo-rollouts-config` ConfigMap wiring the **Gateway API trafficRouting plugin** (`argoproj-labs/gatewayAPI`, pinned `v0.16.0`, linux-arm64) plus the extra ClusterRole/Binding granting the controller SA access to `httproutes` (the stock role lacks it — without it weights never move). |
| `cloud-only/` | **GSK (amd64) variant** of `config.yaml` as a kustomize root — same pinned `v0.16.0` release, only the arch substring differs (`linux-arm64` → `linux-amd64`). Excluded from the kind path by location (the `rollouts` App directory-syncs with recurse OFF). See the arch matrix below. |

## Plugin wiring (verified live)

- The controller downloads the plugin binary at startup from the `location:` HTTPS
  URL (the kind node has egress). Pinned to an exact release + the node arch
  (linux-arm64) — SEC-4, no floating tag.
- The controller **must restart** to load the plugin ConfigMap. `task bootstrap:e7`
  does a one-time `rollout restart` after apply/sync.
- A Rollout selects the plugin via
  `spec.strategy.canary.trafficRouting.plugins."argoproj-labs/gatewayAPI"` — the
  key MUST match the `name` in `config.yaml`.

Proven live on `kind-kaddy-dev`: a canary Rollout shifted the live `mulligan`
HTTPRoute backend weights `stable=100/canary=0 → 50/50 → (promote) 100/0`.

## Plugin arch matrix (E1g-S05i)

The plugin ships as an **arch-specific** binary; the wrong arch aborts with
`exec format error` and stalls ALL Rollout reconciliation.

| Cluster | Node arch | Config path | Delivery |
| --- | --- | --- | --- |
| local kind (`kind-kaddy-dev`, Apple-Silicon) | arm64 | `config.yaml` (base) | `rollouts` Argo App directory-syncs `deploy/rollouts` (recurse OFF — `cloud-only/` excluded by location) |
| GSK cloud-edge | amd64 | `cloud-only/` (kustomize root) | `kubectl apply -k deploy/rollouts/cloud-only` after the base install (or a future cloud-edge App pointing here), then a one-time controller restart |

`cloud-only/config.yaml` is a byte-copy of `config.yaml` modulo the
`linux-arm64` → `linux-amd64` substring (kustomize load restrictions forbid
patching `../config.yaml` directly, and adding a top-level `kustomization.yaml`
here would flip the kind path from directory- to kustomize-rendering). Drift is
gated offline by `tests/smoke/rollouts-plugin-arch-overlay.sh` (in
`task verify`): **bump both files together** or the gate fails.

`hack/gsk/rollouts-plugin-amd64.sh` (the former imperative live-patch) is
**superseded by this overlay** and kept as break-glass — it still performs the
required controller restart, which no ConfigMap change can do declaratively.

## Upgrading

Re-vendor `install.yaml` from the target release, re-remove the empty
`argo-rollouts-config` ConfigMap, and bump the pinned plugin release + controller
tag together (check the plugin's compatibility matrix) — in BOTH `config.yaml`
and `cloud-only/config.yaml` (the arch-overlay gate enforces the pair).

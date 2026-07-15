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

## Upgrading

Re-vendor `install.yaml` from the target release, re-remove the empty
`argo-rollouts-config` ConfigMap, and bump the pinned plugin release + controller
tag together (check the plugin's compatibility matrix).

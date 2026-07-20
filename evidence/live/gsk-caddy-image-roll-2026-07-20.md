# GSK Caddy image roll — evidence (2026-07-20)

Lane: **gsk-caddy-image-roll** · branch `lane/gsk-caddy-image-roll` · script
`hack/gsk/roll-caddy-images.sh`.

## Inventory (before)

| Workload | Resource | Old image |
| --- | --- | --- |
| caddy-mvp (caddy.lab) | `Rollout/caddy-origin` container `caddy` | `ghcr.io/platformrelay/kaddy-showcase:0.1.1` |
| caddy-demo (demo.lab) | `Deployment/caddy` container `caddy` | `caddy:2.8-alpine` |

Context: `kaddy-gsk-admin@kaddy-gsk` via `.state/gsk/kubeconfig`. Argo CD Applications
were **absent** in ns `argocd` at inventory time — caddy-mvp was last-applied via kubectl
(imperative), so a live image patch is not fought by auto-sync.
`showcase-pin-0.6.0` is on `origin/main` @ `fff0c91` — git pin matches the live roll target.

## Target (after)

| Workload | New image |
| --- | --- |
| caddy-mvp | `ghcr.io/platformrelay/kaddy-showcase:0.6.0` |
| caddy-demo | `caddy:2.11.4-alpine` (matches `deploy/showcase/Dockerfile` base) |

## Apply (exact)

```bash
export KUBECONFIG="$PWD/.state/gsk/kubeconfig"   # or the exported GSK kubeconfig
kubectl config use-context kaddy-gsk-admin@kaddy-gsk
export KADDY_GSK_CONTEXT="$(kubectl config current-context)"

# Plan only (also covered by tests/smoke/gsk-roll-caddy-images-offline.sh):
hack/gsk/roll-caddy-images.sh --dry-run

# Mutate + wait + verify images:
hack/gsk/roll-caddy-images.sh
```

Equivalent one-shots (what the script runs):

```bash
# mvp — Rollout JSON-patch by container index for name=caddy
kubectl -n caddy-mvp patch rollout caddy-origin --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"ghcr.io/platformrelay/kaddy-showcase:0.6.0"}]'
kubectl -n caddy-mvp rollout status rollout/caddy-origin --timeout=180s

# demo — live-only Deployment
kubectl -n caddy-demo set image deployment/caddy caddy=caddy:2.11.4-alpine
kubectl -n caddy-demo rollout status deployment/caddy --timeout=180s
```

## Verify

```bash
kubectl -n caddy-mvp get rollout caddy-origin \
  -o jsonpath='{.spec.template.spec.containers[?(@.name=="caddy")].image}{"\n"}'
# expect: ghcr.io/platformrelay/kaddy-showcase:0.6.0

kubectl -n caddy-demo get deploy caddy \
  -o jsonpath='{.spec.template.spec.containers[?(@.name=="caddy")].image}{"\n"}'
# expect: caddy:2.11.4-alpine

curl -fsS -o /dev/null -w '%{http_code}\n' https://caddy.lab.platformrelay.dev/
curl -fsS -o /dev/null -w '%{http_code}\n' https://demo.lab.platformrelay.dev/
# expect: 200 / 200
```

## Live result

_Filled after apply — see section below once the script has been run against GSK._

### Status

- **Script + offline smoke:** committed on this lane.
- **Live apply:** see "Live apply log" (updated when executed).

### Live apply log

```text
(pending — run hack/gsk/roll-caddy-images.sh with KADDY_GSK_CONTEXT set)
```

## Revert

```bash
kubectl -n caddy-mvp patch rollout caddy-origin --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/image","value":"ghcr.io/platformrelay/kaddy-showcase:0.1.1"}]'
kubectl -n caddy-demo set image deployment/caddy caddy=caddy:2.8-alpine
```

## Offline gate

```bash
bash tests/smoke/gsk-roll-caddy-images-offline.sh
# wired into task verify → test:meta:ci
```

# Design — E10 Portal / IDP

## Layout

```
deploy/portal/backstage/       # Helm values / manifests, OIDC config
  catalog/                     # static catalog-info.yaml entities
  templates/
    static-site/               # scaffolder template → WebsiteClaim PR
      template.yaml
      skeleton/websiteclaim.yaml
tests/portal/
  static-site-golden.yaml      # expected rendered WebsiteClaim (L1)
tests/chainsaw/portal/
  chainsaw-test.yaml           # scaffolded claim reconciles (L2)
```

## Orchestrator extension (Crossplane)

Extend the E6 `Website` XRD with a static-site shape:

```yaml
apiVersion: platform.kaddy.io/v1alpha1
kind: WebsiteClaim
spec:
  hostname: demo.<lab-domain>
  engine: caddy        # or: nginx
  source: { git: https://... , path: site/ }
  track: stable
```

Composition renders: Deployment (nginx/caddy) + Service + HTTPRoute + ServiceMonitor + Certificate.

## Scaffolder → PR (GitOps-native)

The Backstage template collects `hostname`, `engine`, `track`, source, renders
`skeleton/websiteclaim.yaml`, and uses the `publish:github:pull-request` action to open a PR against
`deploy/workloads/`. Argo CD applies on merge. **The portal never talks to the cluster API to mutate
state** — it authors Git.

## Score option (optional)

Accept a `score.yaml` workload spec and map to `WebsiteClaim` via `score-k8s` or a composition
function — keeps the input portable/tool-neutral (ADR-0109).

## Auth

Backstage `auth.providers.oidc` → Dex issuer (ADR-0107). No guest access; `platform-*` groups map to
Backstage permissions.

## Build-vs-buy (recorded, not chosen here)

If this were a real org under time pressure: **Port** (portal) + **Humanitec** (orchestrator) buys
speed at the cost of SaaS dependency. kaddy chooses OSS for control and interview signal — ADR-0109.

# Portal plugin & image version inventory (SEC-4 · E11 audit)

The Backstage portal (E10) baked-in **third-party OSS plugins** are a supply-chain
surface (ADR-0111, counterpoint). Every version below is **pinned exact** (no
`^`/`~`/`*`/`latest`), Renovate-trackable, and enumerated here so the **E11
security audit** has a single inventory. `tests/portal/*.sh` + `tests/smoke/e10-offline.sh`
assert these pins are present and non-floating.

> The custom `ghcr.io/platformrelay/kaddy-portal` image compiles these plugins
> in (Backstage plugins are build-time, not runtime-loadable). The **app source +
> Dockerfile** that build it live in the separate repo
> **`github.com/PlatformRelay/kaddy-portal`** (private) — kaddy deploys exactly
> the image its CI builds + pushes. Building and publishing that image is a
> **live-cycle step** (deferred, honestly flagged in
> `docs/runbooks/portal-new-site.md`). The pins here are the offline contract.

## Base

| Component | Package / Image | Version |
| --- | --- | --- |
| Backstage image (source: `github.com/PlatformRelay/kaddy-portal`) | `ghcr.io/platformrelay/kaddy-portal` | `sha-4ecaecc` (immutable per-commit tag == `v0.2.1`, same-id SignInPage override) |
| Backstage Helm chart | `backstage` (backstage.github.io/charts) | see `deploy/apps/portal.yaml` `targetRevision` |

## Write path — auto-generated scaffolder (TeraSky)

| Plugin | Package | Version |
| --- | --- | --- |
| kubernetes-ingestor (backend) | `@terasky/backstage-plugin-kubernetes-ingestor` | `@1.7.0` |
| Scaffolder Crossplane actions | `@terasky/backstage-plugin-scaffolder-backend-module-terasky-utils` | `@1.4.0` |

## Read path — visibility plugins (read-only, D-029)

| Plugin | Package | Version |
| --- | --- | --- |
| crossplane-resources (frontend) | `@terasky/backstage-plugin-crossplane-resources-frontend` | `@1.8.0` |
| crossplane-resources (backend) | `@terasky/backstage-plugin-crossplane-permissions-backend` | `@1.5.0` |
| Kubernetes (frontend) | `@backstage/plugin-kubernetes` | `@0.12.6` |
| Kubernetes (backend) | `@backstage/plugin-kubernetes-backend` | `@0.19.4` |
| ArgoCD (community) | `@backstage-community/plugin-argocd` | `@1.8.0` |
| TechDocs | `@backstage/plugin-techdocs` | `@1.12.6` |

## Renovate

`renovate.json` tracks the image via the standard managers; the npm plugin pins
above are tracked once the custom-image build manifest lands (the build is
live-deferred). Until then this file is the authoritative, human-reviewed pin
set the E11 audit inventories.

# Runbook — Website self-service (E6)

**Epic:** E6 · **ADR:** [0105](../adr/0105-crossplane-self-service.md), [0111](../adr/0111-portal-auto-generation.md) · **Decision:** D-027 (v2 namespaced XR)

One `Website` XR = one Running, TLS-served, Prometheus-monitored site — no
manual `kubectl` edits. The XRD (`deploy/crossplane/xrd-website.yaml`) is
kaddy's platform API; the E10 portal auto-generates its form from this schema.

## Claim a site

Commit a namespaced `Website` XR under `deploy/workloads/` (the workloads app
recurses) — see `deploy/workloads/website-demo/website.yaml`:

```yaml
apiVersion: platform.kaddy.io/v1alpha1
kind: Website
metadata:
  name: putting-green
  namespace: websites          # v2 namespaced XR (D-027)
  labels:                      # ADR-0301 set — PROPAGATED to every composed
    owner: platform-team       # resource; Kyverno denies unlabeled pods
    service: putting-green
    part-of: kaddy
    managed-by: argocd
    data-classification: public
    business-criticality: business-operational
    track: stable
spec:
  image: ghcr.io/platformrelay/kaddy-showcase:v0.1.0   # pinned, non-root, /healthz (+ /metrics)
  port: 8080
  path: /putting-green         # served at https://clubhouse.kaddy.local<path>/
  replicas: 1
```

Merge to `main`; within ~10 minutes (two sync loops) the site is live.

## What gets composed (Composition `website.platform.kaddy.io`)

| Resource | Purpose |
| --- | --- |
| Deployment + Service | the site (hardened pod baseline, Kyverno-enforced) |
| HTTPRoute | path route on the clubhouse Gateway's https listener (prefix rewritten away) |
| Certificate | per-site cert from `kaddy-local-ca` (`<name>-tls`; consumed by per-host listeners in E6g/E10 — the shared-host edge cert is `clubhouse-tls` today) |
| ServiceMonitor | Prometheus scrapes `<name>:<port>/metrics` |

## Verify

```sh
task test:smoke:e6                                   # full exit bundle
kubectl -n websites get website,deploy,httproute,certificate,servicemonitor
kubectl -n websites describe website putting-green   # composed refs + conditions
```

## Caveats (MVP slice)

- Path routing on the shared `clubhouse.kaddy.local` host: images must serve
  from `/` behind a rewritten prefix; ROOT-relative asset links (e.g. the
  showcase's `/slides/`) resolve against the shared host, not the site path.
  Host-based routing (wildcard/per-host listeners + the per-site Certificate at
  the edge) is the E6g/E10 follow-up.
- New sites' pods are admitted to the edge by the `website`-label CNP in
  `deploy/policies/network/websites.yaml` — no per-site policy edits, but the
  `policies` app is manual-sync (deliberate; see `deploy/policies/README.md`).
- First boot: `task bootstrap:e6` registers projects + the crossplane app;
  Argo CD retries through the CRD-before-CR window until Established.
- **GHCR image:** `kaddy-showcase` is public and **multi-arch** (amd64+arm64) since `0.1.1` —
  the kind node pulls it anonymously; no side-load needed.
- Per-request `caddy_http_*` series need Caddy's global `servers { metrics }`
  option in the showcase image's Caddyfile (e-caddy-mvp follow-up); the scrape
  target itself is up and the config metrics flow today.

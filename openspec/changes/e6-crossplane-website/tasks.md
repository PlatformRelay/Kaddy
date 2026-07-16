# Tasks — E6 (phase 1 — local)

- [x] Crossplane core only (REQ-E6-S01-*) — pinned chart 2.3.3 (v2, D-027), nested-Helm-app pattern, policy-compliant pods (labels + non-root; crossplane-system has NO Kyverno exclusions)
- [x] XRD Website (REQ-E6-S02-*) — v2 NAMESPACED XR + Composition via function-patch-and-transform v0.10.7 (pinned; no provider-kubernetes — v2 composes native resources)
- [x] Demo claim reconciles via GitOps (REQ-E6-S03-01) — `websites/putting-green` (workloads app)
- [x] Path route + TLS edge (REQ-E6-S04-*) — https listener admits `websites` routes (name-pinned selector); / still clubhouse
- [x] Monitored site (REQ-E6-S05-01) — composed ServiceMonitor scraped (up==1, caddy_*)
- [x] Gate: Chainsaw crossplane suite (skip:true in CI, live-verified) + `task test:smoke:e6`

## Deferred honestly (out of the MVP slice)

- **nginx legacy stand-in as bespoke manifests (old REQ-E6-S03/S04-01 `/legacy`)** → E6g.
  Superseded by the platform itself: a legacy site is now ONE `Website` claim
  (`image: nginxinc/nginx-unprivileged:<pin>`, `path: /legacy`) — no `deploy/legacy/` needed.
- **Gateway backend health-check policy (old REQ-E6-S05-01)** → E6g / E7 chaos beat.
- **provider-gridscale VM variant** → phase 2 / E6g (sibling repo already has Upjet coverage).
- **provider-grafana (REQ-E5-S08-03)** → next slice once core is proven; NOT installed in this lane.
- **Backstage scaffold integration** → E10 (the XRD schema is its input contract, ADR-0111).
- **Host-based routing + per-site edge certs** → E6g/E10. The composed per-site Certificate
  (kaddy-local-ca) is already issued per claim and Ready-gated; today's edge terminates the shared
  `clubhouse-tls` on the shared host, per-host listeners consume the per-site secrets later.

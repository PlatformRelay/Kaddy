# Tasks — E-Caddy-MVP (stub / design-first story map)

> This epic is **gated on the phase-1 precondition epics** (E1 → E3 → E4; E7 for Rollouts;
> E6/E6g/E1g for the VM path). Tasks below are the **story map**, not yet TDD-decomposed —
> full REQ IDs + Test:/Verify: get authored when the epic activates (after preconditions land).
> Do **not** start implementation until the gating epics are green.

## S00 — Epic activation gate (do first when activating)

- [ ] Confirm preconditions green: E1 (GitOps bootstrap), E3 (observability / in-cluster
      Prometheus), E4 (sample site). Variant B additionally: E7 (Argo Rollouts). Variant A
      additionally: E6g/E1g (gridscale VM provisioning).
- [ ] Author full specs (`specs/**/spec.md`) with REQ IDs, Level tags, Test: + Verify: per REQ.

## S01 — Variant A · VM-based (MINIMAL) — the brief spine (serve → scrape → fire)

- [ ] Caddy on a VM (nginx parallel — same structure, legacy stand-in).
- [ ] VM provisioning via sibling Crossplane **provider-gridscale** (`gridscale_server`) — E6g/E1g.
- [ ] Expose the VM's **external metrics endpoint**; in-cluster Prometheus scrape config targets it.
- [ ] **Alerting slice = the parked `caddy_*` marshal alerts** — migrated here from active
      platform monitoring (Option A). Preserve promtool **fire + silent** assertions
      (`tests/promtool/*.test.yaml`), scoped to this epic. Alerts fire against the VM target.
- [ ] Gate (when active): `task test:promrules` + PromQL smoke against the VM metrics endpoint.

## S02 — Variant B · Kubernetes-based (RICH) — preferred/primary path

- [ ] Caddy tenant Deployment/Service in-cluster (nginx parallel), reached **through** the
      Cilium Gateway API edge (HTTPRoute), never as the edge itself.
- [ ] Certificates via **cert-manager** (self-signed local CA / issuer).
- [ ] Native in-cluster scrape (ServiceMonitor/PodMonitor emitting `caddy_*` from the tenant pod).
- [ ] **Blue/green + canary via Argo Rollouts (mulligan, E7)** — demoed **only** on this variant.
      Prometheus AnalysisTemplate gates promotion.
- [ ] Gate (when active): Chainsaw suite (tenant Deployment + HTTPRoute + Rollout) + smoke
      HTTP-200 through the Gateway.

## S03 — Backstage self-service scaffold (both variants, both engines)

- [ ] Backstage form picks variant (VM / Kubernetes) and engine (Caddy / nginx). Surface is
      E10 (portal, cuttable) — this epic works via GitOps even if E10 is cut.

## S04 — Stretch (optional)

- [ ] Certificates via **Crossplane** (instead of / alongside cert-manager on Variant B).

## Exit

- [ ] Brief spine demonstrable end-to-end: a served page (VM or K8s variant) → Prometheus scrape
      → `caddy_*` alert fires. This closes audit DIR-1, DIR-2, ARCH-2, ARCH-3.
- [ ] Gate: `task test:spec` (structure) + variant-appropriate live gates above.

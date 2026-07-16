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

## S05 — Showcase content · the demo site serves the Kaddy story (D-030)

> New spec: `specs/showcase/spec.md` (REQ-CADDY-S05-01..05). The served-website tenant serves the
> Kaddy **Slidev deck** (E12) + **MkDocs docs** — the demo site *is* the pitch.

- [x] Add failing `tests/deck/showcase-image-build.sh` (TDD; structural offline asserts + opt-in
      `SHOWCASE_IMAGE_BUILD=1` real build — proven green locally with podman, incl. runtime smoke:
      /healthz 200, /slides/ 200, `caddy_*` on /metrics, uid 65532) —
      `tests/promtool/caddy-mvp-showcase.test.yaml` still open (alert re-homing task below)
- [x] Multi-stage image (`deploy/showcase/Dockerfile`, REQ-CADDY-S05-02): `slidev build
      --base /slides/` → static assets into pinned `caddy:2.11.4-alpine` (non-root uid 65532,
      no build toolchain at runtime, OCI + ADR-0301 labels; scannable for E11). Built + pushed +
      **keyless cosign-signed by digest** via `.github/workflows/showcase-image.yaml`
      (GitHub OIDC; signing = CI-proven only after the first main run — workflow authored,
      first CI run pending). **DEVIATION (resolved):** `mkdocs build --strict` now exits 0 — all
      24 broken-link warnings fixed (2026-07-16); `/docs/` can be baked once the material theme
      flip lands
- [ ] Landing page → `/slides/` (deck) + `/docs/` (MkDocs Material — flip theme to `material`;
      interim landing page in the image links /slides/ and marks /docs/ pending)
- [ ] `nginx (reverse proxy) → Caddy (static origin)` topology through the Cilium Gateway edge
- [ ] Enable Caddy `metrics`; **re-home the parked `caddy_*` marshal alerts against the Caddy origin**
      target (closes D-026: real target, promtool fire + silent preserved)
- [ ] (stretch, may) Second tenant proving `Website.spec.source` (BYO external git repo/path)
- [ ] Gate (when active): `task test:promrules` + Chainsaw showcase suite + `tests/deck/showcase-image-build.sh`

## S04 — Stretch (optional)

- [ ] Certificates via **Crossplane** (instead of / alongside cert-manager on Variant B).

## Exit

- [ ] Brief spine demonstrable end-to-end: a served page (VM or K8s variant) → Prometheus scrape
      → `caddy_*` alert fires. This closes audit DIR-1, DIR-2, ARCH-2, ARCH-3.
- [ ] Gate: `task test:spec` (structure) + variant-appropriate live gates above.

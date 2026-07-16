# Tasks — E-Caddy-MVP (stub / design-first story map)

> **Activation status (2026-07-16):** Phase-1 preconditions **E1 / E3 / E4 / E7 are green on
> `main`** (see `docs/ROADMAP.md`). **Variant B (Kubernetes)** may proceed — S00 specs are
> **authored** (see `specs/`); implement S02 next. **Variant A (VM)** remains blocked on phase-2
> **E6g / E1g** (still ⬜) — its REQs are specced but explicitly gated. Every story S01–S03 (+S05)
> now carries REQ IDs with Level tags and Test:/Verify: contracts. S01/S02 implementation is
> **not** done.

## S00 — Epic activation gate (do first when activating)

- [x] Confirm phase-1 preconditions green on `main`: **E1** (GitOps bootstrap), **E3**
      (observability / in-cluster Prometheus), **E4** (sample site), **E7** (Argo Rollouts —
      Variant B). **Still open for Variant A:** **E6g / E1g** (gridscale VM provisioning —
      phase 2, deferred).
- [x] Author full specs (`specs/**/spec.md`) with REQ IDs, Level tags, Test: + Verify: per REQ
      (done 2026-07-16 — umbrella + S01 gated in `specs/caddy-mvp/`, S02 contract in
      `specs/k8s-tenant/` [REQ-CADDY-S02-01..05], S03 in `specs/scaffold/`
      [REQ-CADDY-S03-01..02], new REQ-CADDY-S01-04 + REQ-CADDY-EXIT. Variant A is specced
      **but explicitly gated** on E6g/E1g rather than left unwritten — its REQs carry a
      Blocked marker; implementation may not start).

## S01 — Variant A · VM-based (MINIMAL) — the brief spine (serve → scrape → fire)

> **Blocked** on E6g/E1g (phase 2). Do not start VM/cluster provisioning here.
> Spec: `specs/caddy-mvp/spec.md` (REQ-CADDY-S01-01..04, gated).

- [ ] Caddy on a VM (nginx parallel — same structure, legacy stand-in).
- [ ] VM provisioning via sibling Crossplane **provider-gridscale** (`gridscale_server`) — E6g/E1g.
- [ ] Expose the VM's **external metrics endpoint**; in-cluster Prometheus scrape config targets it.
- [ ] **Alerting slice = the parked `caddy_*` marshal alerts** — migrated here from active
      platform monitoring (Option A). Preserve promtool **fire + silent** assertions
      (`tests/promtool/*.test.yaml`), scoped to this epic. Alerts fire against the VM target.
- [ ] Gate (when active): `task test:promrules` + PromQL smoke against the VM metrics endpoint.

## S02 — Variant B · Kubernetes-based (RICH) — preferred/primary path

> **Unblocked** (E1/E3/E4/E7 green). Specs authored (S00). **Offline slice landed**
> (`lane/ecaddy-s02-offline`): GitOps manifests + netpol + PodMonitor re-point +
> structural offline smoke. Live Chainsaw suites exist as `skip: true` until a
> cluster gate flips them.

- [x] Caddy tenant Rollouts/Services in-cluster (nginx-proxy blue/green + caddy-origin
      canary), reached **through** the Cilium Gateway API edge (tenant Gateway +
      HTTPRoute), never as the edge itself — offline manifests under
      `deploy/workloads/caddy-mvp/`.
- [x] Certificates via **cert-manager** (`kaddy-local-ca` ClusterIssuer →
      `caddy-mvp-tls` in ns `caddy-mvp`).
- [x] Native in-cluster scrape wiring — PodMonitor re-pointed at ns `caddy-mvp`
      (`deploy/caddy-mvp/monitoring/prometheus/caddy-podmonitor.yaml`); live
      PromQL still needs a synced cluster (`tests/smoke/caddy-mvp-s02-03.sh`).
- [x] **Blue/green + canary via Argo Rollouts (mulligan, E7)** — manifests +
      AnalysisTemplate scaffolded; live promotion/abort demo pending cluster gate.
- [ ] Gate (when active): Chainsaw suite (tenant + HTTPRoute + Rollout) + smoke
      HTTP-200 through the Gateway — suites authored under
      `tests/chainsaw/caddy-mvp/k8s-*/` as `skip: true`; offline structural gate
      `tests/smoke/caddy-mvp-s02-offline.sh`.

## S03 — Backstage self-service scaffold (both variants, both engines)

> Spec: `specs/scaffold/spec.md` (REQ-CADDY-S03-01..02 — auto-generated form per D-028;
> VM variant option gated on E6g/E1g; portal-free GitOps parity).

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
- [x] Landing page → `/slides/` (deck) + `/docs/` (MkDocs Material theme + baked into showcase image)
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

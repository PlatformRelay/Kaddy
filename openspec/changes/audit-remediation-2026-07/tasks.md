# Tasks — audit-remediation-2026-07

Authoritative remediation backlog for the 39 findings in `HEALTH-AUDIT-2026-07-15.md`.
Each workstream is a lane; task bullets are vertical slices with gate commands. Findings map
1:1 (verified — all 39 assigned exactly once).

Ownership legend: **[this lane]** = audit-remediation planning lane · **[sibling]** = another
active lane executes · **[epic]** = folded into an epic's own tasks.

---

## WS1 · Caddy-MVP spine — P0 · ARCH-2, ARCH-3, DIR-1, DIR-2

- [x] **[this lane]** Mint the platform MVP epic `openspec/changes/e-caddy-mvp/` (proposal +
      story map + two-variant specs). Caddy = WaaS tenant reached **through** the Cilium/Envoy
      edge, **not** the gateway (DIR-1, ARCH-3).
- [x] **[this lane]** **Flag + resolve** the marshal-alert decision — operator confirmed **Option A (park)** (INBOX
      D-026), options A/B, **operator-confirmed Option A (park)**: `caddy_*` alerts + promtool tests scoped
      to `e-caddy-mvp` VM-variant slice; disabled from active platform monitoring; promtool
      fire/silent rigor preserved (ARCH-2). Platform-edge monitoring **decoupled** from Caddy.
      Recorded ANSWERED in decisions.md (D-026) — operator-ratified.
- [ ] **[sibling: monitoring/Caddy lane]** Migrate `deploy/monitoring/rules/marshal-caddy.yaml`
      + `tests/promtool/marshal*.test.yaml` into the epic slice; disable the `caddy_*` alerts in
      active platform monitoring. **Unblocked — marshal decision ANSWERED, Option A (INBOX D-026).**
- [ ] **[sibling: monitoring/Caddy lane]** Retcon ADR-0104: platform edge = Cilium/Envoy Gateway;
      Caddy = tenant MVP, not gateway (ARCH-2). *(docs/adr/0104 — owned by monitoring/Caddy lane;
      now unblocked — marshal decision ANSWERED, Option A.)*
- [ ] **[epic: e-caddy-mvp]** Build the brief spine (serve→scrape→fire) through the normal
      sequence E1 → E3 → E4; VM path via E6g/E1g; Rollouts via E7 (DIR-2). Gated on preconditions.
- Gate (this lane): `task test:spec` (structure valid; new epic dir present).

## WS2 · Substrate + status retcon — P1 · **in progress this session (docs lane)**

ARCH-1, ARCH-6, DOC-1, DOC-2, DOC-3, DOC-4, DOC-5, DOC-6, DOC-7, DOC-8, DOC-9, DIR-5, TEST-5,
TEST-6, TEST-7. Operator: *"retcon the adrs / reconcile docs with reality / fix"*.

- [ ] **[sibling: docs lane]** Propagate D-025 kind+Cilium substrate to ARCHITECTURE/ROADMAP/
      README/AGENTS + retcon ADR-0102; demote Talos/driving-range to deferred spike (ARCH-1,
      DOC-1, DIR-5).
- [ ] **[sibling: docs lane]** Correct "design phase / all ⬜ pending" framing; flip landed-epic
      `tasks.md` checkboxes (E1b/E5/E1e) (DOC-2, DOC-3, TEST-7).
- [ ] **[sibling: docs lane]** Fix `docs/development/testing.md`: real Chainsaw dirs
      (`identity/labeling/portal/tls`) + real workflows (`verify/chainsaw/monitoring.yaml`)
      (DOC-4, DOC-5, **TEST-6** — same docs-drift class).
- [ ] **[sibling: docs lane]** Fix stale gate ref `tests/chainsaw/monitoring` in
      `e5-*/tasks.md` (DOC-6); audits README skill path + placeholder rot (DOC-7, DOC-8);
      rename ADR-0107 file off `keycloak` (DOC-9); single-node vs "3-node" narrative (ARCH-6).
- [ ] **[sibling: docs/E1b lane]** Fix malformed Test paths (stray backtick) in E1b spec
      (TEST-5) so the strict gate won't false-flag landed tofu tests.
- Gate (sibling): `task check` (lint + scrub + spec + docs).

## WS3 · CI + gate wiring — P1 · runs **after live E1 lane merges** (holds Taskfile.yml)

TEST-2, SEC-1, SEC-2, SEC-4, ARCH-5, TEST-8, TEST-1 (advisory). Operator TEST-2: *"we need code
for ci"*.

- [ ] **[sibling: CI lane]** Wire E1e offline meta gates (`tests/meta/e1e-*.sh`) into a workflow
      so an E1e regression goes red (TEST-2).
- [ ] **[sibling: CI lane]** Add **gitleaks to CI** (not just bypassable pre-commit) (SEC-1);
      extend scrub `PATHS` to `deploy/`, `.github/`, `hack/`, `tests/` (SEC-2).
- [ ] **[sibling: CI lane]** Pin `@latest` / `releases/latest` tool installs (chainsaw, kyverno,
      yq) to versions Renovate can track (SEC-4); fix markdownlint config path mismatch + remove
      `|| true` that swallows failures (TEST-8).
- [ ] **[sibling: CI lane]** **TEST-1 = advisory/deferred, NOT blocking** — wire
      `STRICT_TEST_FILES=1` as an advisory job (operator: *"having a gate is difficult at this
      point"*). Do not make it a required check yet.
- [ ] **[sibling: CI lane]** **ARCH-5 — BLOCKED on REQ-TF-11** (option (a), unratified, on
      `testing-foundation-wip`). Do **not** apply `openspec:validate`→`spec:validate` rename
      until REQ-TF-11 is ratified.
- [ ] **[sibling: CI lane]** Reconcile with `testing-foundation-wip` `verify.yaml` — it currently
      **drops `test:unit` / `test:policy`; these MUST be restored**.
- Gate (sibling): workflow green on a PR; `act` / CI dry-run; `task test:unit` + `task test:policy`
      present in the workflow.

## WS4 · Test-artifact + hygiene — P2 · gated on owning epics landing

TEST-3, TEST-4.

- [ ] **[epic: E1b/E5]** **Plan** the missing landed-epic test artifacts (operator: *"make sure
      they are planned"*): enumerate `tests/smoke/e1b-*.sh`, `tests/smoke/e5-s01-01.sh` and the
      other spec-referenced smoke/meta tests as tasks in their owning epics (TEST-3).
- [ ] **[epic: owning epics]** Plan un-skipping the four Chainsaw suites
      (`labeling/portal/tls/identity`, currently `skip:true`) (TEST-4, operator: *"we shouldn't
      skip them, add as task"*). **Gated on the relevant epics landing** — un-skipping now breaks
      the gate because the underlying manifests are unbuilt.
- Gate (owning epic): `task test:chainsaw` non-vacuous once manifests exist.

## WS5 · Governance reconcile — P2

ARCH-4. Operator: *"try to reconcile"* the two label sets.

- [ ] **[sibling: governance lane]** Decide the **canonical label form** and align ADR-0301 +
      `modules/labels` + `policy/labels.rego` + monitoring manifests. A sibling lane may execute
      the monitoring-manifest part.
- Gate (sibling): `task test:policy` (Rego deny fires) + `tofu test` on `modules/labels`.

## WONTFIX

- [x] **ARCH-7** (boundary enforcement) — WONTFIX. Operator: *"how can we even do boundary
      enforcement here? Drop that."* No arch-lint added.
- [x] **DIR-4** (wasted motion) — WONTFIX (no code action). Process/informational; captured by
      the session retrospective.

## ROADMAPPED (future epics, not remediation debt)

- [x] **SEC-6** (NetworkPolicy → E1c), **SEC-7** (RBAC → E1d), **SEC-8** (Trivy/cosign → E1c).
      Unbuilt future epics, **not regressions**. Tracked on the roadmap, not here.

## P3 / accept-with-note

- [x] **SEC-3** (latent secret vector — clean now), **SEC-5** (action SHA pinning —
      Renovate-mitigated), **SEC-9** (smoke fixture labels — ephemeral), **DIR-3** (over-scope),
      **DIR-6** (phase-2 bleed). Accept with note; reframed by the Caddy-MVP direction. Revisit
      if any regresses.

---

## Exit / sanity

- [ ] All 39 findings assigned exactly once (verified in the map above).
- [ ] `TECH-DEBT-REGISTER.md` — every open row carries a **Target** note (workstream / WONTFIX /
      ROADMAPPED / accept-with-note); nothing marked FIXED.
- [ ] Gate: `task test:spec` (openspec structure valid).

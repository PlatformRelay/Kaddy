# Change: audit-remediation-2026-07 — health-audit remediation backlog

## Why

The `2026-07-15` health & direction audit
(`agent-context/archive/audits/HEALTH-AUDIT-2026-07-15.md`) surfaced **39 findings**
(P0 ×2 · P1 ×11 · P2 ×19 · P3 ×7) across architecture, tests, security, docs, and direction.
Verdict: **NEEDS-WORK**, direction **AT-RISK**. Three cross-cutting fractures:

1. **Substrate drift** — the D-025 kind+Cilium pivot never reached a single top doc.
2. **Hollow brief spine** — Caddy + the marshal demo can't run as designed.
3. **Gate wiring lags test quality** — the best tests run in no CI path.

This change is the **authoritative remediation backlog**: it organizes every finding into a
prioritized workstream with the operator's ratified direction, so the fixes land through the
normal lane cycle instead of ad-hoc. It is a **planning artifact** — proposal + tasks only, no
`specs/` REQ IDs (the backlog is not a behavioral spec; individual fixes carry their own REQs in
their owning epics).

## Scope

- Organize the 39 findings into **WS1–WS5 + WONTFIX + ROADMAPPED**, each with finding IDs,
  operator answer, priority, and concrete task bullets (see `tasks.md`).
- Mint the platform MVP epic (`e-caddy-mvp`) as the home for the hollow-spine fixes (WS1).
- Flag + resolve the marshal-alert decision (options A/B) — operator confirmed Option A (park) — referenced from WS1.

## Non-goals

- Product code. This lane writes planning/spec/tracking artifacts only.
- Editing artifacts owned by live sibling lanes (`docs/**`, `README.md`, `AGENTS.md`,
  `Taskfile.yml`, `tests/smoke/e1-*`, `deploy/bootstrap/**`, `deploy/monitoring/**`,
  `modules/labels/**`, `policy/**`, `docs/adr/0104-*`, `docs/adr/0301-*`,
  `openspec/changes/e1-day0-bootstrap/**`). Those are *targeted* here, executed there.
- Re-deciding the marshal A/B question — the operator **confirmed Option A** (park);
  this lane only flags it and blocks ARCH-2/ARCH-3 alert work on it.
- Marking anything FIXED in the tech-debt register (nothing is fixed yet).

## Workstream map (operator-ratified direction where noted)

| WS | Title | Prio | Finding IDs | Owner / status |
|----|-------|------|-------------|----------------|
| **WS1** | Caddy-MVP spine | **P0** | ARCH-2, ARCH-3, DIR-1, DIR-2 | This lane mints `e-caddy-mvp`; marshal decision **ANSWERED (A — park)** — ARCH-2/ARCH-3 unblocked |
| **WS2** | Substrate + status retcon | P1 | ARCH-1, ARCH-6, DOC-1, DOC-2, DOC-3, DOC-4, DOC-5, DOC-6, DOC-7, DOC-8, DOC-9, DIR-5, TEST-5, TEST-6, TEST-7 | **In progress this session — docs lane** |
| **WS3** | CI + gate wiring | P1 | TEST-2, SEC-1, SEC-2, SEC-4, ARCH-5, TEST-8, TEST-1 (advisory) | Runs **after** live E1 lane merges (holds Taskfile.yml) |
| **WS4** | Test-artifact + hygiene | P2 | TEST-3, TEST-4 | Gated on owning epics landing |
| **WS5** | Governance reconcile | P2 | ARCH-4 | Sibling lane may execute monitoring-manifest part |
| **WONTFIX** | — | — | ARCH-7, DIR-4 | Operator/plan decision |
| **ROADMAPPED** | future epics, not debt | — | SEC-6, SEC-7, SEC-8 | E1c/E1d — unbuilt, not regressions |
| **P3 / accept-with-note** | — | P3 | SEC-3, SEC-5, SEC-9, DIR-3, DIR-6 | Accept with note |

All 39 findings are assigned exactly once (verified). TEST-6 grouped with WS2 (same
`testing.md` docs-drift class as DOC-4/DOC-5).

### WS1 · Caddy-MVP spine (P0)

Operator direction: Caddy = the platform **MVP** (Website-as-a-Service tenant product), reached
**through** the Cilium/Envoy edge, **not** the edge (ARCH-2: *"we won't use caddy as a gateway"*;
ARCH-3: *"caddy will be the MVP of our platform, but for now we are building the preconditions to
show it off"*). Deliverable **now** = the minted `e-caddy-mvp` epic + the flagged marshal
decision. The demo spine (Prometheus + web app) is built through the **normal epic sequence**
(E1 → E3 → E4), not a one-off. **Marshal decision ANSWERED (operator; INBOX D-026, Option A)**,
**Option A** — park the `caddy_*` alerts with `e-caddy-mvp` (VM-variant alerting slice),
disabled from active platform monitoring, promtool rigor preserved; platform-edge monitoring
**decoupled** from Caddy. **ARCH-2 / ARCH-3 alert work is blocked on this decision.**

### WS2 · Substrate + status retcon (P1)

Operator: *"retcon the adrs"*, *"reconcile docs with reality"*, *"fix"*. **A sibling docs lane is
executing most of this now** — marked in-progress this session. Covers the D-025 substrate
propagation, status-marker truth, and docs-drift hygiene.

### WS3 · CI + gate wiring (P1)

Operator on TEST-2: *"we need code for ci"*. **Couplings encoded verbatim:**

- **TEST-1** (`STRICT_TEST_FILES=1` gate) → planned **advisory/deferred**, NOT blocking
  (operator: *"having a gate is difficult at this point"*).
- **ARCH-5** (`openspec:validate`→`spec:validate` rename) → **blocked on REQ-TF-11** (option (a),
  an unratified decision parked on branch `testing-foundation-wip`). Do not apply the rename until
  REQ-TF-11 is ratified.
- This lane must **reconcile with the `testing-foundation-wip` verify.yaml**, which currently
  **drops `test:unit` / `test:policy`** — those **must be restored**.
- Runs **after the live E1 lane merges** (it holds `Taskfile.yml`).

### WS4 · Test-artifact + hygiene (P2)

- **TEST-3** (operator: *"make sure they are planned"*) → enumerate the missing smoke/meta tests
  as planned tasks (`tests/smoke/e1b-*.sh`, `e5-s01-01.sh`, …).
- **TEST-4** (operator: *"we shouldn't skip them, add as task"*) → plan un-skipping the four
  Chainsaw suites. **Gated on the relevant epics landing** — un-skipping now would break the gate
  because the underlying manifests are unbuilt.

### WS5 · Governance reconcile (P2)

- **ARCH-4** (operator: *"try to reconcile"* the two label sets) → decide a canonical label form
  and align ADR-0301 + `modules/labels` + `policy/labels.rego` + monitoring manifests. A sibling
  lane may execute the monitoring-manifest part.

### WONTFIX

- **ARCH-7** (boundary enforcement) — operator: *"how can we even do boundary enforcement here?
  Drop that."* WONTFIX with that rationale.
- **DIR-4** (wasted-motion) — process/informational, no code action; covered by the retrospective.

### ROADMAPPED (not remediation debt)

- **SEC-6** (NetworkPolicy, E1c), **SEC-7** (RBAC, E1d), **SEC-8** (Trivy/cosign, E1c) — unbuilt
  future epics, **not regressions**. Keep as roadmap items, not audit-remediation tasks.

### P3 / accept-with-note

- **SEC-3** (latent secret vector — clean now), **SEC-5** (action SHA pinning — Renovate-mitigated),
  **SEC-9** (smoke fixture labels — ephemeral), **DIR-3** / **DIR-6** (over-scope / phase-bleed —
  reframed by the Caddy-MVP direction). Accept with note; revisit if they regress.

## Counterpoints considered

- **"Just fix the marshal alerts to point at Envoy (Option B)."** Rejected by operator — Option B
  requires enabling Envoy metrics in the E1e substrate = scope creep. Park instead (Option A).
- **"Make TEST-1 a blocking gate now."** Rejected — operator: gating file-existence is difficult
  at this stage; keep it advisory until artifacts stabilize.
- **"Apply the ARCH-5 rename immediately."** Rejected — presumes REQ-TF-11 option (a), unratified.
  Blocked until ratified to avoid churning the Taskfile twice.
- **"Un-skip the Chainsaw suites now (TEST-4)."** Rejected — the underlying manifests are unbuilt;
  un-skipping would break the gate. Gate on the owning epics.

## Links

- Audit: `agent-context/archive/audits/HEALTH-AUDIT-2026-07-15.md`
- Register: `agent-context/archive/audits/TECH-DEBT-REGISTER.md`
- Minted MVP epic: `openspec/changes/e-caddy-mvp/`
- Marshal decision (Option A): `agent-context/decisions.md` · `agent-context/INBOX.md`
- Backlog / lanes: `agent-context/BACKLOG.md`

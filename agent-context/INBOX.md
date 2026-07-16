# INBOX — kaddy

Items waiting on the operator. Answered decisions move to `decisions.md`.

## Decisions

### D-026 — ANSWERED 2026-07-15 → decisions.md — Marshal `caddy_*` alerts direction

**Decision needed:** what to do with the broken E5 `caddy_*` marshal alerts (audit ARCH-2/ARCH-3) — they
scrape a Caddy edge target the Cilium/Envoy edge never emits, so they can't fire against the platform as
designed.

- **(A) Park with the Caddy epic** — move the `caddy_*` alerts + their promtool tests into the deferred
  `e-caddy-mvp` VM-variant alerting slice and disable them from active platform monitoring; they light up
  (serve→scrape→fire) when the Caddy tenant lands. Promtool fire/silent rigor preserved, scoped to the epic.
- **(B) Re-point to Cilium/Envoy Gateway metrics** — keep them live in platform monitoring against the edge.

**Recommendation: A (park).** Rationale: B requires enabling Envoy/Cilium metrics in the E1e substrate =
scope creep on the local dev substrate; A puts the alert where its real target (the Caddy tenant) will exist.

**Status:** ANSWERED 2026-07-15 — operator chose **(A) park** (confirmed via the coordinator's direct
question). Recorded ANSWERED in decisions.md (D-026). WS1 ARCH-2/ARCH-3 alert migration + ADR-0104 retcon
are **unblocked** and assigned to the monitoring/Caddy lane.

### D-025 — ANSWERED 2026-07-15 → decisions.md

Pivot phase-1 substrate to **local kind + Cilium** (new **P0** change `e1e-kind-local-cluster`); amends D-017.
driving-range Talos deferred to optional maturity-contrast spike. Cilium on kind keeps D-019/D-022 (Gateway
API, no MetalLB) so E1–E8 Cilium assertions pass unmodified. **Operator prerequisite:** Docker running before
the E1e live-cluster gate (`task cluster:up`).

### D-024 — ANSWERED 2026-07-15 → decisions.md

Do **not** hold. Queue next steps: (2) Taskfile lint-hardening (after WIP lint session lands), (3) e1c security-baseline offline subset — **operator-reviewed PR, not auto-merged**, (4) e12-slidev deck — operator-reviewed. Plus add **`kyverno test` CLI** cases for the `require-kaddy-labels` ClusterPolicy (+ e1c policies as authored). See decisions.md.

---

## Operator tasks

- [ ] Review design-phase commit(s) on `main` before starting `/agent-loop`
- [ ] Review review-authored artifacts: TF-09/10/11 specs, `verify.yaml`, `agent-context/GUIDELINES.md` (need an independent pass)
- [x] ~~Build [driving-range](../../driving-range/) cluster (phase 0) before kaddy E1~~ — superseded by D-025 (kind + Cilium substrate, E1e)
- [ ] **Start Docker** (Docker Desktop / colima) before the E1e live-cluster gate — `task cluster:up` needs a running container runtime
- [ ] Run `direnv allow` in repo root once per machine
- [x] Decide D-021 (spec validator) → **A** hack-canonical (2026-07-15, decisions.md)
- [x] Decide D-022 (Level-tag) → **C** hybrid · D-023 (markdown-lint) → **A** advisory-then-required (2026-07-15, decisions.md)
- [x] Decide D-014 (IDP portal stack) → **A** Crossplane + Backstage, phased OSS (2026-07-15, decisions.md)
- [x] gridscale lab access — credentials in `.envrc` (see LAB-ACCESS.md)
- [x] Decide D-013 (OVH vs gridscale) — pivoted to gridscale-native (see decisions.md D-013)
- [x] Decide local-first sequencing — driving-range phase 1, gridscale phase 2 (D-017)
- [x] Create GitHub OAuth app for Dex (E1d) — `docs/runbooks/github-oauth-dex.md`; creds in `.envrc`

## Reviews / PRs

_(none open — PR #3, PR #4 merged 2026-07-15 via /agent-loop-auto)_

## PRs to merge

_(none)_

## Audits

- **AUDIT 2026-07-15** — Health & direction baseline (deep): **NEEDS-WORK** overall, **direction AT-RISK**.
  39 findings (P0×2, P1×11). Top 3: (1) propagate D-025 kind substrate pivot to docs — currently in zero top
  docs; (2) make the brief spine demonstrable + fix marshal scraping `caddy_*` the Cilium/Envoy edge never
  emits; (3) wire the good gates (STRICT_TEST_FILES, E1e meta, gitleaks) into CI.
  → `agent-context/archive/audits/HEALTH-AUDIT-2026-07-15.md` · register: `TECH-DEBT-REGISTER.md`
  → **Remediation plan:** `openspec/changes/audit-remediation-2026-07/` (WS1–WS5 + WONTFIX + ROADMAPPED). Minted platform MVP epic `e-caddy-mvp`; marshal decision D-026 **ANSWERED (A — park)**; WS1 unblocked.
- **AUDIT 2026-07-16** — Mid-session checkpoint (replayable): **NEEDS-WORK — trajectory strongly
  positive**. 22 fixed / 0 regressed / 24 open (P0×0 P1×5 P2×14 P3×5). Brief spine E1e→E1→E3→E4
  verified live (9/9 apps Synced/Healthy; clubhouse over verified HTTPS through Cilium Gateway). Top
  remediation: close the alert "fire" leg — sync `deploy/monitoring/` via app-of-apps + re-point
  marshal alerts at the actually-served site (ARCH-8 + ARCH-2 + DIR-2).
  → `agent-context/archive/audits/HEALTH-AUDIT-2026-07-16.md`

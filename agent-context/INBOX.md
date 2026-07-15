# INBOX — kaddy

Items waiting on the operator. Answered decisions move to `decisions.md`.

## Decisions

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

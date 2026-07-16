# INBOX — kaddy

Items waiting on the operator. Answered decisions move to `decisions.md`.

## Decisions

### D-034 — Land leftover E9 operator S01/S02 onto main? (CRD / public API)

**Context:** Rate-limited `/agent-loop-auto` left a complete branch
`lane/e9-operator-s01` @ `7fa7e2c` in `.worktrees/e9-operator` (kubebuilder scaffold + CRD types +
`caddyadmin` client + reconcilers; S01+S02 ticked in that branch's `tasks.md`). Gates were green in
the worker session; **not** on `origin/main`. Auto-merge rules forbid silent land of **public API /
CRD** changes even when APPROVE.

**Options:**
- **(A) Land now** — rebase onto current main, re-run operator envtest + repo `task verify`,
  tech-review, ff-push to `main`. Accepts new CRDs (`Caddy`/`CaddySite`) as v0.x surface.
- **(B) Hold until E9-S03** — keep branch; land only with observability bundle + Taskfile wiring.
- **(C) Park / delete branch** — E9 remains optional post E1–E8; discard until explicitly activated.

**Recommendation: (B).** Rationale: S01/S02 without S03 + root Taskfile wiring leaves a half-wired
operator module on main; holding until the exit gate (`envtest` + `task test`) is honest. (A) is fine
if the interview wants the CRD story visible ASAP.

**Answer / instructions:** _(operator fills — ask via AskQuestion)_

---

### D-026 — ANSWERED 2026-07-15 → decisions.md — Marshal `caddy_*` alerts direction

**Status:** ANSWERED 2026-07-15 — operator chose **(A) park**. Recorded in decisions.md (D-026).

### D-025 — ANSWERED 2026-07-15 → decisions.md

Pivot phase-1 substrate to **local kind + Cilium** (P0 `e1e-kind-local-cluster`); amends D-017.
**Operator runtime (updated 2026-07-16):** this workstation has **Podman only** (no Docker Desktop /
colima). E1e already supports podman (`KIND_EXPERIMENTAL_PROVIDER=podman`); **rootful** podman is
required for Cilium. See D-035.

### D-024 — ANSWERED 2026-07-15 → decisions.md

Do **not** hold. See decisions.md.

---

## Operator tasks

- [x] **Sync the `policies` ArgoCD app** — DONE 2026-07-16 (operator).
- [x] **Enable GitHub Pages (`build_type=workflow`)** — DONE 2026-07-16 (operator). Residual: re-run
      `scorecard-pages` + curl the published URL if not already verified.
- [x] **Container runtime** — workstation is **Podman-only** (no Docker). Recorded as D-035; start
      rootful podman machine before `task cluster:up` when a live E1e gate is needed.
- [x] **`direnv allow`** — DONE 2026-07-16 (operator).
- [x] **Merge open PRs/MRs** — none open as of 2026-07-16 evening (`gh pr list` empty).
- [ ] **D-034** — answer via AskQuestion (land A / hold B / park C) before any E9 land.
- [ ] Review design-phase commit(s) on `main` before starting `/agent-loop` (optional; largely
      superseded by later lands — confirm or waive).
- [ ] Review review-authored artifacts: TF-09/10/11 specs, `verify.yaml`, `agent-context/GUIDELINES.md`
      (optional independent pass — confirm or waive).
- [x] ~~Build driving-range cluster (phase 0) before kaddy E1~~ — superseded by D-025
- [x] Decide D-021 / D-022 / D-023 / D-014 / D-013 / local-first / Dex OAuth / lab access — see decisions.md

## Reviews / PRs

_(none open — PRs #8/#10/#11 merged 2026-07-16)_

## Audits

- **AUDIT 2026-07-15** — baseline NEEDS-WORK / AT-RISK → remediation + D-026 park. See archive.
- **AUDIT 2026-07-16** mid-session + **final** (`HEALTH-AUDIT-2026-07-16-final.md`) — RELEASE-READY for
  v0.1.0 trajectory; residual operator items above + D-034.

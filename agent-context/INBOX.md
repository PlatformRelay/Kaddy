# INBOX — kaddy

Items waiting on the operator. Answered decisions move to `decisions.md`.

## Decisions

### D-036 — Affirm coordinator choice (A) — Argo F-01 unblocks

**Status:** EXECUTED 2026-07-16 (awaiting affirmation). See `decisions.md`.
**Done:** PR #13 @ `9f18ebf` — AppProject `mulligan` + drop duplicate Rollout port; Argo
`policies`/`workloads`/`root` Synced; netpols present in mulligan + caddy-mvp.

**Options (for affirmation):**
- **(A) Recommended / chosen** — two small GitOps fixes → land → re-sync
- **(B)** Broaden AppProject to all namespaces
- **(C)** Leave OutOfSync; document debt only

**Answer / instructions:** _operator affirms or overrides_

### D-034 — ANSWERED 2026-07-16 → decisions.md — Land E9 S01/S02 onto main

**Status:** ANSWERED — **(A) land now**. **DONE:** PR #12 @ `44aaf84`. E9-S03 followed (PR #15).

### D-026 — ANSWERED 2026-07-15 → decisions.md — Marshal `caddy_*` alerts direction

**Status:** ANSWERED — **(A) park**.

### D-025 — ANSWERED 2026-07-15 → decisions.md

kind + Cilium substrate; Podman-only workstation (D-035).

### D-024 — ANSWERED 2026-07-15 → decisions.md

Do **not** hold.

---

## Operator tasks

- [ ] **Follow-up (backlog):** DOC-10 roadmap-status guard doesn't assert release-provenance — 'E9 shipped in v0.1.1' (false) passed it. Extend `tests/meta/doc10-roadmap-status.yaml` to check an epic's commits are ancestors of the claimed tag. (retro-2026-07-16-eve)

- [ ] **Phase 2 STARTED** (operator asked 2026-07-16 eve) — E1g→E6g→E8b; author IaC offline first; live gridscale provisioning PERMITTED but RUTHLESSLY cost-sensitive — smallest footprint, no parallel/idle resources, `tofu destroy` after every test (full lab ~€115/mo if left up). See memory `handover-2026-07-16-eve`.

- [x] **Re-sync Argo apps `policies` + `workloads`** — DONE 2026-07-16 via D-036 land + sync.
      `policies`/`workloads`/`root` Synced+Healthy; mulligan NetPol×2 (+CNP); caddy-mvp NetPol×5 (+CNP).
- [x] **release** — **v0.2.0 RELEASED** 2026-07-16 (tag 42e3eee + GitHub release; git-cliff CHANGELOG).
- [ ] **Affirm D-036 (A)** — or override.
- [x] Enable GitHub Pages — DONE.
- [x] Container runtime Podman-only (D-035).
- [x] `direnv allow`.
- [x] D-034 land E9 — DONE (PR #12 + S03 PR #15).
- [x] Design-phase + review-artifact confirmations.

## Reviews / PRs

- [x] PR #12 E9-S01/S02 — https://github.com/PlatformRelay/Kaddy/pull/12 @ `44aaf84`
- [x] PR #15 E9-S03 — https://github.com/PlatformRelay/Kaddy/pull/15 @ `a9a5f79`
- [x] PR #14 E12 ROADMAP sync — https://github.com/PlatformRelay/Kaddy/pull/14 @ `a9fb35a`
- [x] PR #13 D-036 F-01 — https://github.com/PlatformRelay/Kaddy/pull/13 @ `9f18ebf`


## CI watch (2026-07-16) — tip `9f18ebf` (no fix landed)

**Verdict:** No product fix opened. Residual reds are advisory / known flake — do not thrash.

| Check | Run | Conclusion | Notes |
| --- | --- | --- | --- |
| verify | [29525813258](https://github.com/PlatformRelay/Kaddy/actions/runs/29525813258) | **success** | tip `9f18ebf` |
| trivy / image-digests | 29525813201 / 29525813208 | **success** | tip |
| chainsaw (D-036 twin) | [29525798337](https://github.com/PlatformRelay/Kaddy/actions/runs/29525798337) | **success** | same SHA `9f18ebf` |
| chainsaw (AppProject assert push) | [29525813203](https://github.com/PlatformRelay/Kaddy/actions/runs/29525813203) | **failure** | `security-mulligan-netpol` / `direct-cross-ns-curl-denied`: expected curl deny, got HTML 200 from `mulligan-stable` |
| chainsaw (E9-S03) | [29525700311](https://github.com/PlatformRelay/Kaddy/actions/runs/29525700311) | **success** | `a9a5f79` |
| spec-coverage-strict (in verify wf) | job on 29525813258 | **failure** (advisory) | `MISSING file: tests/chainsaw/caddy-mvp/vm-variant/chainsaw-test.yaml` (REQ-CADDY-S01-02) — pre-existing; non-blocking |

**Why no fix PR:** Same-SHA twin chainsaw **passed**; failure matches known live netpol-enforcement flake / possible concurrent-run interference on shared kind cluster (two tip chainsaws overlapped). Not a clear regression from E9 / D-036 / E12 docs lands. Track under existing “Chainsaw netpol enforcement probe polish”; consider serializing chainsaw concurrency if flakes persist.

## Audits

- Residual: release/phase-2; optional live Chainsaw netpol enforcement probe polish; E12b art
  (operator/manual); deferred Loki-ruler / Grafana OAuth→E10.

---

## Phase 2 loop — decisions (2026-07-16 late / session start)

### 🔴 DECIDED (awaiting approval) — Definition of "phase-2 complete" reconciles with cost-sensitivity
Context: Several phase-2 exit criteria are live-gated (E1g "apps sync on GSK / LBaaS URL works", E6g-S04 "real VM", E13-S03 "alert fires against gridscale VM", **E8b-S01 literally "keep stack running through interview window"**). E8b-S01 as written contradicts the standing rule "tear down every resource the moment a test is done".
Options: (A) leave lab running for E8b [violates cost rule] · (B) offline gates green for every stack + ONE ephemeral live proof-cycle per live-gated story (create→verify→capture evidence→`tofu destroy`); E8b becomes an on-demand bring-up (task target + runbook), proven once ephemerally, NOT a standing env — the "interview window" is a future operator-triggered event · (C) author IaC only, never go live.
Chose: **(B)**. Best balances "all backlog complete" with "ruthlessly cost-sensitive". E8b deliverable = reproducible bring-up + teardown, evidence captured once.
Revert: if you want a standing demo env, run `task e8b:up` and leave it (est. ~€115/mo); teardown is `task e8b:down`.

### 🔴 DECIDED — Object-storage bucket is the one cheap persistent anchor (state backend)
Context: tofu remote-state backend needs an object-storage bucket that doesn't exist yet (chicken-and-egg), and every other resource must be ephemeral.
Chose: bootstrap the bucket ONCE with **local** state and keep it (~€0.06/GB, a few MB of state = negligible); all expensive compute (GSK, LBaaS, VMs) cycles create→verify→destroy. Resolves backend bootstrap + cost model together.
Revert: `tofu destroy` the bucket stack (loses remote state; re-bootstrap when needed).

### 🟡 DECIDED — gridscale provider auth env-var mapping
Context: provider v1/v2 reads `GRIDSCALE_UUID`/`GRIDSCALE_TOKEN` (+ optional `GRIDSCALE_URL`); `.envrc` exports `GRIDSCALE_USER_UUID`/`GRIDSCALE_API_KEY`. Mismatch → silent live-auth failure on first apply.
Chose: map at the stack boundary via `TF_VAR_gridscale_uuid`/`_token` wired in the live Task target (keeps `.envrc` secrets untouched, offline gates need no creds). Documented in the E1g runbook.
Revert: instead add `export GRIDSCALE_UUID=$GRIDSCALE_USER_UUID` / `GRIDSCALE_TOKEN=$GRIDSCALE_API_KEY` to `.envrc`.

### note — E6g sibling reuse
`../provider-gridscale` E6g-S01 (Upjet codegen) is DONE: `package/crds/*` (incl. k8ses, loadbalancers, servers, firewalls, ipv4s) + `package/crossplane.yaml`. No built `.xpkg` yet; registry path is a placeholder. kaddy E6g consumes this package (build/push or local install) — do NOT re-run Upjet generation.

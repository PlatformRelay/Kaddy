# Spec — testing foundation

Cross-cutting requirements for verifiable development. ADR: [0701](../../../docs/adr/0701-testing-strategy-chainsaw.md).

---

## REQ-TF-01: Task targets exist

**Priority:** must · **Story:** testing-foundation · **Level:** meta  
**Given** the repository after this change  
**When** `task --list` is run  
**Then** tasks `test`, `test:unit`, `test:policy`, `test:chainsaw` are defined  
**Test:** `tests/meta/task-targets.sh`

**Verify:** `task --list | grep -E 'test:unit|test:chainsaw'`

---

## REQ-TF-02: Chainsaw directory scaffold

**Priority:** must · **Level:** L2  
**Given** `tests/chainsaw/README.md` and `.chainsaw.yaml`  
**When** a contributor adds a suite folder with `chainsaw-test.yaml`  
**Then** `chainsaw test tests/chainsaw/<suite>` is the documented entrypoint  
**Test:** `tests/chainsaw/.chainsaw.yaml`

**Verify:** `test -f tests/chainsaw/.chainsaw.yaml`

---

## REQ-TF-03: First Chainsaw test (labeling) — wired in E1b

**Priority:** must · **Depends:** E1b-S05 · **Level:** L2  
**Given** Kyverno `require-kaddy-labels` policy applied to kind cluster  
**When** Chainsaw applies `pod-missing-data-classification.yaml`  
**Then** create is denied OR pod remains absent after 30s (policy enforced)  
**Test:** `tests/chainsaw/labeling`

**Verify:** `chainsaw test tests/chainsaw/labeling`  
**Refs:** REQ-E1b-S05-02

---

## REQ-TF-04: CI chainsaw workflow stub

**Priority:** should · **Depends:** E3-S01  
**Given** `.github/workflows/chainsaw.yaml`  
**When** PR touches `deploy/` or `tests/chainsaw/`  
**Then** workflow provisions kind, installs Kyverno, runs `task test:chainsaw`  
**Test:** `tests/smoke/tf-04.sh`

**Verify:** workflow file exists; dry-run documented in testing.md

---

## REQ-TF-05: Spec format — Verify block mandatory

**Priority:** must · **Level:** meta  
**Given** any new requirement in `openspec/changes/*/specs/`  
**When** reviewed for merge  
**Then** each REQ includes **Verify:** with an executable command or Chainsaw suite path  
**Test:** `hack/verify-spec-coverage.sh`

**Verify:** `task test:spec` passes (counts Verify blocks)

---

## REQ-TF-07: Spec format — Test block mandatory

**Priority:** must · **Level:** meta  
**Given** any requirement in `openspec/changes/*/specs/`  
**When** `hack/verify-spec-coverage.sh` runs  
**Then** each REQ includes **Test:** with path to test artifact (`tests/`, `modules/`, `hack/`, or `internal/`)  
**Test:** `hack/verify-spec-coverage.sh`

**Verify:** `task test:spec` — Test count equals REQ count

---

## REQ-TF-08: Epic exit — test artifacts exist

**Priority:** must · **Level:** meta  
**Given** an epic marked complete in ROADMAP  
**When** `STRICT_TEST_FILES=1 task test:spec` runs before merge  
**Then** every **Test:** path for that epic's REQs exists on disk (not placeholder-only)  
**Test:** `hack/verify-spec-coverage.sh`

**Verify:** `STRICT_TEST_FILES=1 task test:spec` in epic PR template / tasks.md EXIT checkbox

---

## REQ-TF-06: TDD order enforced in tasks.md

**Priority:** must  
**Given** an implementation epic `tasks.md`  
**When** a story involves cluster or module behaviour  
**Then** tasks list "add failing test" before "implement"  
**Test:** `tests/meta/tf-06-checklist.md`

**Verify:** manual review + agent-loop pick-next-story skill

---

## REQ-TF-09: Spec format — Level tag mandatory

**Priority:** must · **Level:** meta  
**Given** any requirement in `openspec/changes/*/specs/`  
**When** `hack/verify-spec-coverage.sh` runs  
**Then** each REQ declares a **Level:** value in `{L0,L1,L2,L3,L4,meta}` matching the tier of its **Test:** artifact per the mapping in [`docs/development/testing.md`](../../../docs/development/testing.md)  
**Test:** `hack/verify-spec-coverage.sh`

**Verify:** `task test:spec` — reported Level count equals REQ count; no REQ missing a Level

---

## REQ-TF-10: Design-gate CI runs `task verify` on every PR

**Priority:** must · **Level:** meta  
**Given** a GitHub Actions workflow gating pull requests  
**When** a PR touches `openspec/`, `docs/`, `deploy/`, `modules/`, or `hack/`  
**Then** the workflow installs the toolchain and runs `task scrub`, `task openspec:validate`, and `task test:spec` as **required** checks; `task lint` runs **advisory** (`continue-on-error`) until the markdown-cleanup lane flips it to required  
**Test:** `.github/workflows/verify.yaml`

**Verify:** `grep -q 'task scrub' .github/workflows/verify.yaml && grep -q 'task test:spec' .github/workflows/verify.yaml`  
**Refs:** stale `ci.yaml` (Humanitec `make`/`humctl` leftover) removed

---

## REQ-TF-11: Spec validator is unambiguous and CI-runnable

**Priority:** must · **Level:** meta  
**Given** the Taskfile `openspec:validate` target names an `openspec` CLI, but kaddy specs use a custom `## REQ- / **Verify:** / **Test:**` format that the Fission-AI OpenSpec CLI (`@fission-ai/openspec`) rejects  
**When** the canonical validator runs in CI on a clean tree  
**Then** exactly one of: **(a)** `hack/verify-spec-coverage.sh` + folder-structure check is declared canonical and the Taskfile target is renamed so it no longer implies the Fission-AI CLI; or **(b)** specs are migrated to OpenSpec delta/scenario format and `openspec validate --all` exits 0  
**Test:** `tests/meta/spec-validator.sh`

**Verify:** chosen validator exits 0 in CI; decision recorded in [`docs/development/testing.md`](../../../docs/development/testing.md) and INBOX  
**Refs:** empirical — `npx @fission-ai/openspec@1.6.0 validate --all` fails 21/21 against current format

---

## REQ-TF-12: terraform-docs keeps module README in sync

**Priority:** must · **Level:** L0  
**Given** `modules/labels/` with `.terraform-docs.yml` at repo root  
**When** `task docs:tf:check` runs  
**Then** the injected README section matches generated inputs/outputs  
**Test:** `.terraform-docs.yml`, `modules/labels/README.md`

**Verify:** `task docs:tf:check`

---

## REQ-TF-13: OpenTofu fmt gate on modules

**Priority:** must · **Level:** L0  
**Given** OpenTofu modules under `modules/`  
**When** `task test:fmt` runs  
**Then** `tofu fmt -check -recursive modules` exits 0  
**Test:** `Taskfile.yml` (`test:fmt` target)

**Verify:** `task test:fmt`

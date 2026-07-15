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

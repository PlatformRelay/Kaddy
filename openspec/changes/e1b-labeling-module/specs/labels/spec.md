# Spec — E1b labeling module

Epic: E1b · ADR: [0301](../../../docs/adr/0301-resource-labeling-convention.md)  
**Levels:** L0 tofu test · L1 conftest · L2 Chainsaw (Kyverno)

---

## REQ-E1b-S01-01: Module outputs canonical label map

**Priority:** must  
**Given** `modules/labels` with required inputs (`owner`, `service`, `part_of`, `track`, `data_classification`, `managed_by`)  
**When** module is called with valid inputs  
**Then** output `labels` contains all mandatory keys per ADR-0301  
**Test:** `modules/labels/tests/valid_defaults.tftest.hcl`

**Verify:** `cd modules/labels && tofu test -filter=tests/valid_defaults`

---

## REQ-E1b-S01-02: gridscale label list format

**Priority:** must  
**Given** same module call  
**When** `gridscale_labels` output is consumed  
**Then** each entry is `key=value`, lowercase, value matches `^[a-z0-9_-]{0,63}$`  
**Test:** `modules/labels/tests/gridscale_labels_format.tftest.hcl`

**Verify:** `tofu test -filter=tests/gridscale_labels_format`

---

## REQ-E1b-S01-03: Resource name helper length

**Priority:** must  
**Given** `resource_name(prefix, suffix)` helper  
**When** prefix=`kaddy`, suffix=`talos-cp-01`  
**Then** result length ≤ 63 and matches `^[a-z0-9-]+$`  
**Test:** `modules/labels/tests/name_length.tftest.hcl`

**Verify:** `tofu test -filter=tests/name_length`

---

## REQ-E1b-S02-01: Fails on missing owner

**Priority:** must · **TDD:** write test first  
**Given** module input with empty `owner`  
**When** `tofu test` runs  
**Then** test `missing_owner_fails` fails until validation added  
**Test:** `modules/labels/tests/e1b-s02-01.tftest.hcl`

**Verify:** `cd modules/labels && tofu test`

---

## REQ-E1b-S02-02: Fails on invalid track value

**Priority:** must  
**Given** `track = "production"` (not in enum)  
**When** `tofu test` runs  
**Then** test fails with clear error mentioning allowed: `stable`, `canary`, `preview`  
**Test:** `modules/labels/tests/invalid_track.tftest.hcl`

**Verify:** `tofu test -filter=tests/invalid_track`

---

## REQ-E1b-S02-03: CI runs tofu test on module change

**Priority:** must  
**Given** PR touching `modules/labels/**`  
**When** CI runs  
**Then** `task test:unit` executes and must pass  
**Test:** `tests/meta/e1b-s02-03-workflow.yaml`

**Verify:** `.github/workflows/ci.yaml` includes `task test:unit` path filter

---

## REQ-E1b-S03-01: conftest denies plan without tags

**Priority:** must  
**Given** generated OpenTofu plan JSON for any `stacks/ovh/*`  
**When** `conftest test -p policy/labels.rego` runs  
**Then** plan without mandatory tag keys is denied  
**Test:** `tests/policy/e1b-s03-01.rego`

**Verify:** `task test:policy` with fixture `tests/fixtures/plan-missing-tags.json` → fail

---

## REQ-E1b-S04-01: Terramate injects labels into every stack

**Priority:** must · **Status:** DEFERRED to E1g (operator-ratified 2026-07-15 — see note)  
**Given** a Terramate-managed stack (local **driving-range** or **gridscale**)  
**When** `terramate generate`  
**Then** `_terramate_generated_labels.tf` exists and calls `modules/labels`  
**Test:** `tests/smoke/e1b-s04-01.sh`

**Verify:** deferred to E1g — no Terramate stacks exist in phase 1 (see deferral note)

> **Deferral (operator-ratified 2026-07-15):** the original `stacks/ovh/*` target predates the
> gridscale pivot (D-013) and driving-range local-first sequencing (D-017); no `stacks/` tree exists in
> phase 1. gridscale day-0 (OVH-owned; lab env `lab.gridscale.cloud`) is **E1g / phase 2**. This `must`
> is not dropped — it **moves to E1g**, retargeted at the **local (driving-range)** and **gridscale**
> stacks, not `ovh`. The `modules/labels` module (REQ-S01–S03, complete on this lane) is ready for E1g
> to consume as the codegen source.

---

## REQ-E1b-S05-01: Kyverno ClusterPolicy manifest

**Priority:** must  
**Given** `deploy/policies/kyverno/require-kaddy-labels.yaml`  
**When** applied to cluster  
**Then** policy name is `require-kaddy-labels`, mode `enforce`  
**Test:** `tests/smoke/e1b-s05-01.sh`

**Verify:** `kubectl get cpol require-kaddy-labels`

---

## REQ-E1b-S05-02: Chainsaw rejects unlabeled pod

**Priority:** must · **Level:** L2  
**Given** Kyverno policy installed (kind CI)  
**When** `chainsaw test tests/chainsaw/labeling` with `skip: false`  
**Then** test passes (admission denies unlabeled pod)  
**Test:** `tests/chainsaw/labeling`

**Verify:** `chainsaw test tests/chainsaw/labeling`

---

## REQ-E1b-S05-03: Allowed pod with full label set

**Priority:** must  
**Given** pod manifest with all mandatory labels + `data-classification: internal`  
**When** Chainsaw applies pod  
**Then** pod reaches Running  
**Test:** `tests/chainsaw/labeling/chainsaw-test.yaml`

**Verify:** `tests/chainsaw/labeling/chainsaw-test.yaml` step `labeled-pod-ok`

---

## REQ-E1b-EXIT: Module coverage

**Priority:** should  
**Given** labels module  
**When** `tofu test` with coverage (if enabled)  
**Then** ≥ 90% of validation branches covered  
**Test:** `tests/smoke/e1b-exit.sh`

**Verify:** document in testing.md; no uncovered validation path without REQ

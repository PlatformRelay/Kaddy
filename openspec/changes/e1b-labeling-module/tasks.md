# Tasks — E1b labeling

- [x] **TDD:** `tofu test` fixtures before module (REQ-E1b-S02-*) — `modules/labels/tests/*.tftest.hcl`
- [x] `modules/labels` implementation (REQ-E1b-S01-*)
- [x] conftest policy (REQ-E1b-S03-*) — `policy/labels.rego` + `tests/policy/`
- [~] Terramate codegen (REQ-E1b-S04-*) — **DEFERRED to E1g** (operator-ratified 2026-07-15; no stacks in phase 1, retarget local/gridscale not ovh)
- [x] Kyverno `require-kaddy-labels` ClusterPolicy landed (`deploy/policies/kyverno/`); Chainsaw labeling suite still a `skip:true` placeholder (TEST-4)
- [x] **[TEST-3]** Write missing smoke/meta test artifacts referenced in spec but not yet on disk:
      `tests/meta/e1b-s02-03-workflow.yaml` ✓ **delivered (H2 lane, 2026-07-16)** — bash meta test (offline)
        asserts verify.yaml invokes `task test:unit` + `task test:policy` (REQ-E1b-S02-03);
      `tests/smoke/e1b-s04-01.sh` — **SKIPPED: DEFERRED to E1g** (Terramate codegen descoped;
        no stacks in phase 1; implement when E1g stacks land);
      `tests/smoke/e1b-s05-01.sh` — **SKIPPED: handoff to H1/e1c** (data-classification Kyverno
        policy not yet authored; H1 lane owns that policy + its kyverno tests; implement once
        the ClusterPolicy that S05 tests is on disk);
      `tests/smoke/e1b-exit.sh` ✓ **delivered (H2 lane, 2026-07-16)** — offline exit gate:
        `tofu test` (17 pass, 0 fail) + conftest deny/allow on fixtures.
- [ ] **[TEST-4]** Un-skip `tests/chainsaw/labeling/chainsaw-test.yaml` (currently `skip: true`,
      `pending-kyverno-policy`). Gate: un-skip once the REQ-E1b-S05-02 data-classification
      Kyverno policy lands — `require-kaddy-labels` is already present but the S05 policy that
      the suite tests is not yet written; un-skipping now will fail the gate.
- [ ] Gate: `task test:unit` && `task test:policy` && `chainsaw test tests/chainsaw/labeling`

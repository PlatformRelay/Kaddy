# Tasks — E1b labeling

- [x] **TDD:** `tofu test` fixtures before module (REQ-E1b-S02-*) — `modules/labels/tests/*.tftest.hcl`
- [x] `modules/labels` implementation (REQ-E1b-S01-*)
- [x] conftest policy (REQ-E1b-S03-*) — `policy/labels.rego` + `tests/policy/`
- [~] Terramate codegen (REQ-E1b-S04-*) — **DEFERRED to E1g** (operator-ratified 2026-07-15; no stacks in phase 1, retarget local/gridscale not ovh)
- [x] Kyverno `require-kaddy-labels` ClusterPolicy landed (`deploy/policies/kyverno/`); Chainsaw labeling suite still a `skip:true` placeholder (TEST-4)
- [ ] Gate: `task test:unit` && `task test:policy` && `chainsaw test tests/chainsaw/labeling`

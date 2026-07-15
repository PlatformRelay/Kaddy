# Tasks — E1b labeling

- [ ] **TDD:** `tofu test` fixtures before module (REQ-E1b-S02-*)
- [ ] `modules/labels` implementation (REQ-E1b-S01-*)
- [ ] conftest policy (REQ-E1b-S03-*)
- [~] Terramate codegen (REQ-E1b-S04-*) — **DEFERRED to E1g** (operator-ratified 2026-07-15; no stacks in phase 1, retarget local/gridscale not ovh)
- [ ] Kyverno policy + enable Chainsaw labeling suite (REQ-E1b-S05-*)
- [ ] Gate: `task test:unit` && `task test:policy` && `chainsaw test tests/chainsaw/labeling`

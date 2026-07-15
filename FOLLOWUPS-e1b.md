# e1b-labeling — review carry-forwards (tech-review REQUEST CHANGES @ 12533ca, 2026-07-15)

Offline gates green (tofu test, conftest, verify all exit 0). NOT ready to integrate: one P1 pending
operator ratification. Held for operator — remote/CI is blocked (foreign PocketIDP origin).

- **F1 (P1) — RESOLVED 2026-07-15 (operator-ratified descope):** REQ-E1b-S04-01 (Terramate codegen, `must`) is unimplemented. It targets
  `stacks/ovh/*`, but OVH was killed by decisions D-013 (gridscale pivot) and D-017 (driving-range
  local-first); no `stacks/` tree exists in phase 1. Do NOT implement against dead OVH infra.
  **Recommended resolution (needs operator ratification):** descope REQ-E1b-S04-01 from E1b and defer to
  E1g (phase 2), amending the change's tasks.md/proposal.md/spec.md with this rationale. A `must` REQ
  cannot be silently dropped — it must be formally deferred. The coordinator did NOT self-descope
  (that would collapse review-gate independence); operator ratifies at merge.
- **F2 (P2):** `gridscale_labels` emit `app.kubernetes.io/*` (dotted/slashed) keys. Literally satisfies
  REQ-S01-02 (only the VALUE charset is constrained) and matches ADR-0301, but verify dotted/slashed
  KEYS are valid *gridscale* tags against the provider schema before these labels are consumed.
- **F3 (P2):** `test:policy` Taskfile rewrite hardcodes the two fixture names (was `plan-*.json` glob).
  The rewrite is sound/fail-closed (adversarially validated — keep it) but a future `plan-*.json`
  fixture would be silently untested.
- **F4 (P2/P3):** REQ-E1b-EXIT (≥90% validation-branch coverage, `should`) not met — only empty-owner and
  invalid-track are negatively tested (~2/10 branches). Add negative tests for data_classification enum,
  service/part_of/managed_by/business_criticality regex, name charset/length, gridscale-value precondition.

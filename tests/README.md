# Tests — kaddy

Every OpenSpec requirement (`REQ-*`) maps **1:1** to a test artifact via the **Test:** field in
`openspec/changes/*/specs/`.

## Layout

| Path | Level | Purpose |
| --- | --- | --- |
| `modules/labels/tests/` | L0 | `tofu test` fixtures |
| `tests/policy/` | L1 | conftest Rego + plan fixtures |
| `tests/chainsaw/` | L2 | Declarative cluster e2e (Kyverno Chainsaw) |
| `tests/load/` | L3 | k6 profiles (marshal) |
| `tests/smoke/` | smoke | Day-0 / API scripts (E1, gridscale) |
| `tests/meta/` | meta | Manual checklists, workflow assertions |
| `hack/verify-spec-coverage.sh` | meta | REQ ↔ Test ↔ Verify gate |

## Gates

```bash
task test:spec              # every REQ has Test + Verify (design phase OK if files missing)
STRICT_TEST_FILES=1 task test:spec   # epic EXIT — all Test paths must exist
task test                   # L0→L2 executable tests
```

## Authoring

1. Add **Test:** path in spec **before** implementation (TDD).
2. Write failing test at that path.
3. Implement until **Verify:** passes.

See [docs/development/testing.md](../docs/development/testing.md).

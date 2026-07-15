# Change: testing-foundation — pyramid, Chainsaw, CI gates

## Why

Specs and implementation must be **verifiable**. Chainsaw provides declarative cluster e2e tests
aligned with Kyverno policies, Gateway API routes, Rollouts, and Crossplane claims — without Go
test boilerplate.

## What

- ADR-0701 testing pyramid
- `docs/development/testing.md`
- `tests/chainsaw/` skeleton + `.chainsaw.yaml`
- Taskfile targets: `test:unit`, `test:policy`, `test:chainsaw`, `test`
- CI workflow stub `chainsaw.yaml` (enabled after E3)

## Non-goals

- Full suite green before E3 (scaffold + first test in E1b/E1c)
- Replacing k6/scorecard (L3/L4)

## Dependencies

- Parallel with E1b (first Chainsaw test: labeling admission)

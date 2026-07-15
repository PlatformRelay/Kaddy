# ADR-0701: Testing strategy — pyramid, TDD, and Chainsaw

**Theme:** 07 · Engineering · **Status:** Current

## Context

kaddy must be **verifiable by construction** — the gridscale brief asks for monitoring evidence, and the
platform story depends on GitOps manifests, policies, and progressive delivery behaving correctly on a
real cluster. Go envtest alone does not cover HTTPRoute weights, Kyverno admission, or Alertmanager
routing. Bash curls rot quickly.

[Kyverno Chainsaw](https://kyverno.github.io/chainsaw/) is a declarative Kubernetes e2e framework
(YAML steps: apply, assert, delete, script) with JMESPath assertions. It is used in production CI by
Kyverno, OpenTelemetry Operator, and Crossplane's uptest ecosystem.

## Decision — test pyramid

| Level | Tool | What it proves | When it runs |
| --- | --- | --- | --- |
| **L0** | `tofu test` | Label module outputs, naming charset/length | Every PR touching `modules/` |
| **L1** | conftest / OPA | Plans carry mandatory gridscale labels | Every PR touching `stacks/` |
| **L1** | **`promtool test rules`** | PrometheusRule alerts fire on synthetic series | Every PR touching `deploy/monitoring/rules/` |
| **L2** | **Chainsaw** | Cluster state: policies, routes, rollouts, monitors | PR after E3; nightly on driving-range |
| **L3** | k6 + PromQL checks | Load, latency, alert firing (marshal) | E8 scorecard; release gate |
| **L4** | scorecard harness | End-to-end evidence bundle (HTML) | Tag / pre-interview |
| **L5** | envtest (E9 only) | Caddy operator reconcile without cluster | E9 if implemented |

### PrometheusRule unit tests (promtool)

Alerting rules are **code** and get unit tests — no cluster required. Each `PrometheusRule` has a
`promtool test rules` file under `tests/promtool/` that feeds synthetic time series and asserts which
alerts fire (and their labels) at a given eval time. This closes the gap where a rule *exists* (proven
by Chainsaw L2) but never actually fires on the intended condition. Runs in CI on every rules change;
fast and hermetic.

### Chainsaw adoption

- Tests live under `tests/chainsaw/<suite>/chainsaw-test.yaml` + fixture manifests.
- CI: `chainsaw test tests/chainsaw` against a **kind** cluster with platform apps pre-synced (or
  subset tests that install their own deps for early epics).
- Nightly (optional): same suites against the **driving-range** cluster (phase 1) or **GSK** (phase 2).
- Every OpenSpec requirement tagged `verify:chainsaw` MUST have a corresponding test step or suite.

### TDD rule (binding)

1. **Failing test first** — create the file at the **Test:** path before implementation.
2. Implement minimum to green (**Verify:** command passes).
3. No PR without listed gate commands green in CI.
4. **`task test:spec`** must pass on every PR touching `openspec/` (structural coverage).
5. Epic **EXIT**: `STRICT_TEST_FILES=1 task test:spec` — every **Test:** path exists.

### REQ → test mapping (1:1)

| Field | Meaning |
| --- | --- |
| `**Test:**` | Committed artifact path (Chainsaw YAML, `tofu test`, smoke script, Go test) |
| `**Verify:**` | Command that proves the REQ in CI or locally |

Gate script: `hack/verify-spec-coverage.sh` (`task test:spec`).

### What Chainsaw is not

- Not for OpenTofu day-0 (use L0/L1 + smoke scripts).
- Not a replacement for k6 (L3) — does not sustained load.
- Requires a live cluster — accept CI time cost; keep suites focused per epic.

## Consequences

- Specs include `Verify:` blocks with exact commands (`tofu test`, `chainsaw test`, PromQL).
- New epics add Chainsaw suites before implementation merges.
- Interview story: "policy and routing are regression-tested declaratively."

## References

- [Chainsaw docs](https://kyverno.github.io/chainsaw/main/)
- kollect/mkurator L0–L5 inspiration (adapted for platform/GitOps stack)

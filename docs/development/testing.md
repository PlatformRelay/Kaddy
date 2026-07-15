# Testing — kaddy

Binding strategy: [ADR-0701](../adr/0701-testing-strategy-chainsaw.md). **TDD is mandatory** for every
implementation lane.

## Pyramid at a glance

```
L4 scorecard (evidence HTML)
L3 k6 + PromQL alert checks
L2 Chainsaw (cluster declarative e2e)  ← primary GitOps gate
L1 conftest (OpenTofu plans) + promtool (PrometheusRule alerts)
L0 tofu test (modules/labels)
```

## Commands (target state)

| Command | Level | Description |
| --- | --- | --- |
| `task test:unit` | L0 | `tofu test` in `modules/labels` |
| `task test:policy` | L1 | conftest against generated plans |
| `task test:promrules` | L1 | `promtool test rules` for marshal alerts |
| `task test:chainsaw` | L2 | `chainsaw test tests/chainsaw` |
| `task test:load` | L3 | k6 profile (marshal threshold) |
| `task test:scorecard` | L4 | Full evidence capture |
| `task test` | all | Runs available levels in order |

Until implementation lands, `task test` runs L0 only when modules exist.

## Chainsaw layout

```
tests/chainsaw/
  README.md
  .chainsaw.yaml          # global config (timeouts, namespaces)
  labeling/
    chainsaw-test.yaml    # Kyverno rejects unlabeled pods
  security/
    chainsaw-test.yaml    # default-deny netpol
  gateway/
    chainsaw-test.yaml    # HTTPRoute path routing
  monitoring/
    chainsaw-test.yaml    # ServiceMonitor + PrometheusRule present
  identity/
    chainsaw-test.yaml    # Dex + GitHub OIDC, Argo CD unauth denied
```

Install: `go install github.com/kyverno/chainsaw@latest` or release binary from
[kyverno/chainsaw](https://github.com/kyverno/chainsaw).

## Writing a Chainsaw test (pattern)

```yaml
apiVersion: chainsaw.kyverno.io/v1alpha1
kind: Test
metadata:
  name: require-data-classification
spec:
  steps:
    - try:
        - apply:
            file: pod-missing-label.yaml
        - error:  # expect admission failure
            file: pod-missing-label.yaml
```

See epic specs under `openspec/changes/*/specs/` for per-story `Verify:` blocks.

## CI

| Workflow | Levels |
| --- | --- |
| `ci.yaml` | `task verify` + L0 when present |
| `chainsaw.yaml` (E3+) | L2 on kind |
| `nightly.yaml` (optional) | L2 on driving-range (phase 1) or GSK (phase 2) + L3 smoke |

## Spec traceability

Each requirement ID (`REQ-E5-S03-01`) **must** have:

1. OpenSpec `specs/*/spec.md` — **Given/When/Then**, **Test:**, **Verify:**
2. A committed test artifact at the **Test:** path (before epic EXIT)
3. `tasks.md` checkbox

```bash
task test:spec                         # structural: 1:1 REQ ↔ Test ↔ Verify
STRICT_TEST_FILES=1 task test:spec     # epic EXIT: files exist
```

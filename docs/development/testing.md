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
| `task test:load` | L3 | k6 marshal-threshold profile (offline structural by default) |
| `task test:scorecard` | L4 | Evidence capture + schema validate (fixtures by default) |
| `task test` | all | Runs available levels in order |

`task test` runs L0→L2 when tools are present; L3/L4 are separate (`task test:load`,
`task test:scorecard`) so CI and reviewers can gate evidence without a live cluster.

## L3 / L4 — offline scorecard gates (E8)

Offline mode is the **default** for developers and reviewers: set
`SCORECARD_FIXTURES=1` (or rely on the Taskfile default). No cluster, Prometheus,
Alertmanager, Loki, or k6 binary is required.

| Gate | Command | What it checks |
| --- | --- | --- |
| L3 | `task test:load` | Structural smoke on `tests/load/marshal-threshold.js` (`tests/smoke/e8-s01-01.sh`) — RATE=150 above the 100 rps marshal threshold |
| L4 | `task test:scorecard` | `hack/scorecard/capture.sh --fixtures` → `evidence/runs/<YYYY-MM-DD>/`, then `hack/scorecard/validate.sh` |

```bash
# Default offline path (CI / local review)
task test:load
task test:scorecard

# Explicit fixture env (same as Taskfile default)
SCORECARD_FIXTURES=1 task test:load
SCORECARD_FIXTURES=1 task test:scorecard

# Direct harness (equivalent to L4 offline)
SCORECARD_FIXTURES=1 hack/scorecard/capture.sh
# or: hack/scorecard/capture.sh --fixtures
hack/scorecard/validate.sh
```

### Fixture inputs

Committed snapshots under `evidence/fixtures/` feed capture when fixtures are on:

| Path | Role |
| --- | --- |
| `evidence/fixtures/prometheus/queries.json` | up / error_rate / latency / request_rate |
| `evidence/fixtures/alertmanager/alerts.json` | firing HighRequestRate |
| `evidence/fixtures/k6/summary.json` | RATE=150 load summary |
| `evidence/fixtures/loki/caddy-errors.json` | LogQL 5xx stream |
| `evidence/fixtures/rollout/status.json` | Argo Rollouts Healthy snapshot |

Details: `evidence/fixtures/README.md`.

### Harness layout

```
hack/scorecard/
  capture.sh       # --fixtures / SCORECARD_FIXTURES=1 → dated run bundle + index.html
  validate.sh      # schema check on evidence/runs/<date>/ (or newest run)
  template.html    # HTML scorecard sections (alerts / metrics / k6 / rollout)
```

Live capture (`SCORECARD_FIXTURES=0`) is deferred — `capture.sh` exits with a hint until
live APIs land. Live L3 then needs `k6` + `BASE_URL` (and optional `RATE`).

## Chainsaw layout

```
tests/chainsaw/
  README.md
  .chainsaw.yaml          # global config (timeouts, namespaces)
  labeling/
    chainsaw-test.yaml    # Kyverno rejects unlabeled pods
  identity/
    chainsaw-test.yaml    # Dex + GitHub OIDC, Argo CD unauth denied
  portal/
    chainsaw-test.yaml    # Backstage-scaffolded WebsiteClaim reconciles
  tls/
    chainsaw-test.yaml    # cert-manager Certificate Ready / TLS route
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
| `verify.yaml` | `task verify` (scrub + lint + openspec + spec coverage) + L0 `tofu test` + L1 conftest |
| `monitoring.yaml` | L1 promtool PrometheusRule unit tests (no cluster) |
| `chainsaw.yaml` (E3+) | L2 Chainsaw on kind |

## Spec traceability

Each requirement ID (`REQ-E5-S03-01`) **must** have:

1. OpenSpec `specs/*/spec.md` — **Given/When/Then**, **Test:**, **Verify:**
2. A committed test artifact at the **Test:** path (before epic EXIT)
3. `tasks.md` checkbox

```bash
task test:spec                         # structural: 1:1 REQ ↔ Test ↔ Verify
STRICT_TEST_FILES=1 task test:spec     # epic EXIT: files exist
```

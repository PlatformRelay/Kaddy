# Chainsaw suites — kaddy

Declarative **L2** cluster tests per [ADR-0701](../../docs/adr/0701-testing-strategy-chainsaw.md).

## Prerequisites

- Kubernetes cluster (kind for CI, driving-range for dev/nightly, GSK for phase-2 nightly)
- [Chainsaw](https://kyverno.github.io/chainsaw/) CLI installed
- Platform components under test synced (varies by suite)

## Run

```bash
chainsaw test tests/chainsaw/labeling
chainsaw test tests/chainsaw          # all suites
task test:chainsaw
```

## Suite map

| Suite | Epic | Proves |
| --- | --- | --- |
| `labeling/` | E1b | Kyverno rejects pods missing mandatory labels |
| `security/` | E1c | Default-deny netpol blocks unsolicited ingress |
| `identity/` | E1d | Dex + GitHub OIDC; Argo CD unauth denied |
| `tls/` | E3, E4 | cert-manager + Let's Encrypt staging/prod issuers |
| `gateway/` | E2, E4, E6 | HTTPRoute `/` and `/legacy` backends |
| `monitoring/` | E5 | ServiceMonitor + PrometheusRule + Loki/Alloy |
| `rollouts/` | E7 | Rollout reaches Healthy; degraded on failed analysis |
| `portal/` | E10 | Scaffolded WebsiteClaim reconciles end-to-end |

## Authoring

One folder per scenario; `chainsaw-test.yaml` + fixture YAMLs. Link REQ IDs in test `metadata.annotations`:

```yaml
metadata:
  annotations:
    kaddy.io/req: REQ-E5-S03-01
```

Implementation: added incrementally per epic — **tests land before manifests** (TDD).

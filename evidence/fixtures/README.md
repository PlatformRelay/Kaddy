# Scorecard fixtures (offline)

Synthetic Prometheus, Alertmanager, k6, Loki, and rollout snapshots used by
`hack/scorecard/capture.sh` when `SCORECARD_FIXTURES=1` or `--fixtures` is set.

These let `task test:load` and `task test:scorecard` succeed without a live
cluster, Prometheus, or k6. Live capture (port-forwards + real APIs) is a
follow-up lane.

| Path | Role |
| --- | --- |
| `prometheus/queries.json` | up / error_rate / latency / request_rate |
| `alertmanager/alerts.json` | firing HighRequestRate (scorecard name) |
| `k6/summary.json` | RATE=150 load summary |
| `loki/caddy-errors.json` | LogQL 5xx stream fixture |
| `rollout/status.json` | Argo Rollouts Healthy snapshot |

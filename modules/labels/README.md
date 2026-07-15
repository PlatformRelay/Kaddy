# modules/labels (E1b)

OpenTofu module implementing [ADR-0301](../../docs/adr/0301-resource-labeling-convention.md).

**Status:** spec only — implementation in E1b via `/agent-loop`.

Planned outputs:

- `labels` — map(string) for Kubernetes
- `gridscale_labels` — list(string) key=value
- `resource_name` — constructed name under length/charset rules

Tests: `tofu test` in `tests/` (write tests first per TDD).

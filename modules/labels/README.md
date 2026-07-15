# modules/labels (E1b)

OpenTofu module implementing [ADR-0301](../../docs/adr/0301-resource-labeling-convention.md).

**Status:** implemented (E1b).

## Inputs

Required: `owner`, `service`, `part_of`, `track`, `managed_by`, `data_classification`,
`business_criticality`.
Optional: `component`, `personal_data`, `pci`.
Naming: `name_prefix` (default `kaddy`), `name_suffix`.

Values are validated against the strictest syntax (lowercase `^[a-z0-9_-]{0,63}$`).
`track` must be `stable | canary | preview`; `data_classification` must be
`public | internal | confidential | restricted`.

## Outputs

- `labels` — `map(string)` with all mandatory ADR-0301 keys, using the
  `app.kubernetes.io/*` mapping for `service`/`component`/`part-of`/`managed-by`.
- `gridscale_labels` — `list(string)` of `key=value`, lowercase, each value
  matching `^[a-z0-9_-]{0,63}$`.
- `name` — deterministic resource name `{name_prefix}-{service}-{name_suffix}`,
  length ≤ 63, charset `^[a-z0-9-]+$` (no underscores).

OpenTofu has no user-defined functions, so the name helper is exposed as the
`name` output driven by the `name_prefix` / `name_suffix` variables.

## Tests

`tofu test` in `tests/` (TDD — tests written first). Run via `task test:unit`.

# modules/labels (E1b)

OpenTofu module implementing [ADR-0301](../../docs/adr/0301-resource-labeling-convention.md).

**Status:** implemented (E1b).

## Tests

`tofu test` in `tests/` (TDD — tests written first). Run via `task test:unit`.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| business\_criticality | Blast radius tier (ADR-0301 mandatory). | `string` | n/a | yes |
| data\_classification | Data classification (ADR-0301 mandatory). | `string` | n/a | yes |
| managed\_by | IaC tool -> app.kubernetes.io/managed-by (ADR-0301 mandatory). | `string` | n/a | yes |
| owner | DRI for incidents (ADR-0301 mandatory). | `string` | n/a | yes |
| part\_of | Platform/product -> app.kubernetes.io/part-of (ADR-0301 mandatory). | `string` | n/a | yes |
| service | App identity -> app.kubernetes.io/name (ADR-0301 mandatory). | `string` | n/a | yes |
| track | Release track (replaces environment/stage). | `string` | n/a | yes |
| component | Role -> app.kubernetes.io/component (ADR-0301 optional). | `string` | `null` | no |
| name\_prefix | Prefix for resource-name helper: {prefix}-{service}-{suffix}. | `string` | `"kaddy"` | no |
| name\_suffix | Suffix for resource-name helper: {prefix}-{service}-{suffix}. | `string` | `""` | no |
| pci | PCI-DSS scoping flag (ADR-0301 optional). | `bool` | `null` | no |
| personal\_data | GDPR personal-data classification (ADR-0301 optional). | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| gridscale\_labels | List of key=value strings for gridscale resource labels. |
| labels | Canonical ADR-0301 label map (map(string)) for Kubernetes / unified use. |
| name | Deterministic resource name {prefix}-{service}-{suffix}, <= 63 chars, ^[a-z0-9-]+$. |
<!-- END_TF_DOCS -->

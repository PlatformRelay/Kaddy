# Design — E1b labeling module

## Module interface (sketch)

```hcl
module "labels" {
  source = "../modules/labels"
  service     = "gsk-cluster"
  component   = "control-plane"
  part_of     = "kaddy"
  owner       = var.owner
  track       = "stable"
  data_classification = "internal"
}
```

Outputs: `labels`, `gridscale_labels`, `resource_name`.

## Tests

- Invalid uppercase in values → fail
- Missing required key in input → fail
- Name length > 63 → fail

## Reference (local only, not committed)

Terramate `stacks/` + `modules/` + `policy/` layout from gcp-central-infrastructure pattern.

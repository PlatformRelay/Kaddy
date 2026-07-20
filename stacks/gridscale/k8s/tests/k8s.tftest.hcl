# REQ-E1g-S03: GSK cluster — offline plan, mocked provider. Asserts standing
# sizing (node_count=3), concrete (non-latest) release, single node pool, labels.

mock_provider "gridscale" {}

run "cluster_minimal_defaults" {
  command = plan

  assert {
    condition     = gridscale_k8s.platform.name == "kaddy-gsk"
    error_message = "cluster name must be labels-derived"
  }

  # Concrete release line, never :latest.
  assert {
    condition     = gridscale_k8s.platform.release == "1.30"
    error_message = "GSK release must be a concrete minor line"
  }

  # Exactly ONE node pool (cost discipline).
  assert {
    condition     = length(gridscale_k8s.platform.node_pool) == 1
    error_message = "GSK must have exactly one node pool"
  }

  assert {
    condition     = one(gridscale_k8s.platform.node_pool).node_count == 3
    error_message = "default node_count must match standing GSK capacity (3)"
  }

  assert {
    condition     = contains(gridscale_k8s.platform.labels, "part-of=kaddy")
    error_message = "cluster must carry the canonical part-of label (E1b-S04)"
  }
}

run "rejects_latest_release" {
  command = plan

  variables {
    gsk_release = "latest"
  }

  expect_failures = [
    var.gsk_release,
  ]
}

run "rejects_oversized_pool" {
  command = plan

  variables {
    node_count = 9
  }

  expect_failures = [
    var.node_count,
  ]
}

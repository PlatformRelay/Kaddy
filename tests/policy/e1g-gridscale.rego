# REQ-E1g unit proof: the gridscale day-0 plan guards fire correctly,
# independent of conftest exit plumbing.
package main

import rego.v1

_good_pool := [{"name": "pool-0", "node_count": 1}]

test_deny_latest_release if {
	result := deny with input as {"resource_changes": [{
		"address": "gridscale_k8s.platform",
		"type": "gridscale_k8s",
		"change": {"actions": ["create"], "after": {"release": "latest", "node_pool": _good_pool}},
	}]}
	count([m | some m in result; contains(m, "non-concrete release")]) == 1
}

test_allow_concrete_release if {
	result := deny with input as {"resource_changes": [{
		"address": "gridscale_k8s.platform",
		"type": "gridscale_k8s",
		"change": {"actions": ["create"], "after": {"release": "1.30", "node_pool": _good_pool}},
	}]}
	count([m | some m in result; contains(m, "non-concrete release")]) == 0
}

test_deny_oversized_pool if {
	result := deny with input as {"resource_changes": [{
		"address": "gridscale_k8s.platform",
		"type": "gridscale_k8s",
		"change": {"actions": ["create"], "after": {"release": "1.30", "node_pool": [{"name": "pool-0", "node_count": 9}]}},
	}]}
	count([m | some m in result; contains(m, "node_count 9")]) == 1
}

# Cap boundary: 4 is ALLOWED (operator-approved MemoryPressure relief 2026-07-20)…
test_allow_four_node_pool if {
	result := deny with input as {"resource_changes": [{
		"address": "gridscale_k8s.platform",
		"type": "gridscale_k8s",
		"change": {"actions": ["create"], "after": {"release": "1.30", "node_pool": [{"name": "pool-0", "node_count": 4}]}},
	}]}
	count([m | some m in result; contains(m, "node_count")]) == 0
}

# …and 5 (first value past the cap) is still denied.
test_deny_five_node_pool if {
	result := deny with input as {"resource_changes": [{
		"address": "gridscale_k8s.platform",
		"type": "gridscale_k8s",
		"change": {"actions": ["create"], "after": {"release": "1.30", "node_pool": [{"name": "pool-0", "node_count": 5}]}},
	}]}
	count([m | some m in result; contains(m, "node_count 5")]) == 1
}

test_skip_delete_actions if {
	result := deny with input as {"resource_changes": [{
		"address": "gridscale_k8s.old",
		"type": "gridscale_k8s",
		"change": {"actions": ["delete"], "after": null},
	}]}
	count(result) == 0
}

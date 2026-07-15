# REQ-E1b-S03-01 unit proof: deny fires for a plan missing mandatory keys,
# and is silent for a fully-labeled plan. Independent of conftest exit plumbing.
package main

import rego.v1

# Canonical ADR-0301 mandatory keys in their BARE form (single source of
# truth). k8s app.kubernetes.io/* mirrors are a documented addition and are
# NOT required by policy.
_full_labels := [
	"owner=platform-team",
	"service=clubhouse",
	"part-of=kaddy",
	"managed-by=terramate",
	"track=stable",
	"data-classification=internal",
	"business-criticality=business-operational",
]

test_deny_when_missing_mandatory_keys if {
	result := deny with input as {"resource_changes": [{
		"address": "gridscale_server.cp",
		"change": {"actions": ["create"], "after": {"labels": ["app.kubernetes.io/name=clubhouse"]}},
	}]}
	count(result) == 1
}

test_allow_when_all_keys_present if {
	result := deny with input as {"resource_changes": [{
		"address": "gridscale_server.cp",
		"change": {"actions": ["create"], "after": {"labels": _full_labels}},
	}]}
	count(result) == 0
}

test_skip_delete_actions if {
	result := deny with input as {"resource_changes": [{
		"address": "gridscale_server.old",
		"change": {"actions": ["delete"], "after": null},
	}]}
	count(result) == 0
}

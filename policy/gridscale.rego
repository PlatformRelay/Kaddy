# REQ-E1g: gridscale day-0 plan guards. Fed a `tofu show -json` plan. These
# complement policy/labels.rego (mandatory ADR-0301 keys) with gridscale-specific
# safety: no :latest / floating GSK release, and a hard cap on node-pool sizing
# so a fat, expensive cluster can never be planned for the cost-sensitive demo.
package main

import rego.v1

_managed(rc) if {
	some action in rc.change.actions
	action in {"create", "update"}
}

# --- GSK release must be a concrete minor line (e.g. "1.30"), never latest -----
deny contains msg if {
	some rc in input.resource_changes
	rc.type == "gridscale_k8s"
	_managed(rc)
	release := object.get(rc.change.after, "release", "")
	not regex.match(`^[0-9]+\.[0-9]+`, release)
	msg := sprintf(
		"gridscale_k8s %s has non-concrete release %q (must pin a version like \"1.30\", never latest)",
		[rc.address, release],
	)
}

# --- Node-pool sizing cap: node_count <= 3 (day-0 cost discipline) -------------
deny contains msg if {
	some rc in input.resource_changes
	rc.type == "gridscale_k8s"
	_managed(rc)
	some pool in object.get(rc.change.after, "node_pool", [])
	pool.node_count > 3
	msg := sprintf(
		"gridscale_k8s %s node pool %q has node_count %d > 3 (cost cap for the day-0 demo)",
		[rc.address, object.get(pool, "name", "?"), pool.node_count],
	)
}

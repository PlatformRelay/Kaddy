# REQ-E1b-S03-01: deny OpenTofu plan JSON whose planned resources lack the
# mandatory ADR-0301 tag/label keys.
#
# Fed a `tofu show -json` plan. Each resource_changes[].change.after carries a
# `labels` (or `tags`) list of "key=value" strings. A planned resource that is
# created/updated must carry all mandatory ADR-0301 keys.
package main

import rego.v1

# Mandatory ADR-0301 label keys (Kubernetes app.kubernetes.io/* mapping applied).
mandatory_keys := {
	"owner",
	"app.kubernetes.io/name",
	"app.kubernetes.io/part-of",
	"app.kubernetes.io/managed-by",
	"track",
	"data-classification",
	"business-criticality",
}

# Resources being created or updated must be checked; pure deletes/no-ops skip.
_managed(rc) if {
	some action in rc.change.actions
	action in {"create", "update"}
}

# Extract the set of label keys present on a planned resource (labels or tags).
_present_keys(rc) := keys if {
	raw := object.get(rc.change.after, "labels", object.get(rc.change.after, "tags", []))
	keys := {k | some entry in raw; parts := split(entry, "="); k := parts[0]}
}

deny contains msg if {
	some rc in input.resource_changes
	_managed(rc)
	present := _present_keys(rc)
	missing := mandatory_keys - present
	count(missing) > 0
	msg := sprintf(
		"resource %s is missing mandatory ADR-0301 label keys: %v",
		[rc.address, sort(missing)],
	)
}

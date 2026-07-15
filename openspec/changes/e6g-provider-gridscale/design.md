# Design — E6g provider-gridscale

## Scope (Upjet)

Generate CRDs for minimum viable set:

- `gridscale_server` (nginx legacy VM)
- Optional: `gridscale_loadbalancer`, object storage access key

## Fallback

Plain `gridscale_server` OpenTofu module if Upjet slips past time-box (D-016 guard).

## Time-box

Hard cap: document in runbook; do not block E8b on Upjet completion.

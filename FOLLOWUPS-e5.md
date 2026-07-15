# e5-marshal — review carry-forwards (tech-review APPROVE @ c697351, 2026-07-15)

Offline L1 lane APPROVED (no P0/P1). Held for operator integration — remote/CI is blocked
(origin still points at the foreign PocketIDP repo). Address these at/before the L2 cluster session:

- **F1 (P2, important):** Alert metric/label names are unverified against a real Caddy `/metrics`.
  L1 promtool tests are self-referential (input series define `code="500"`; expr matches `code=~"5.."`).
  Validate `caddy_http_requests_total` / `caddy_http_request_duration_seconds_bucket` and `code` vs
  `status` against a live scrape before trusting the alerts fire in production.
- **F2 (P2):** `CaddyTargetDown` uses `up{job="caddy"} == 0` (present-but-failing). REQ-E5-S03-01 intent is
  "targets absent for 2m" — if pods vanish, `up` goes stale and it won't fire. Consider `absent()`.
- **F3 (P2):** `.github/workflows/monitoring.yaml` does not invoke `hack/monitoring/assert-rule-coverage.sh`,
  so the S06-05 "no untested rule" meta-gate isn't enforced in CI. Wire it in.
- **F4 (P3):** README + new shell scripts weren't linted locally (markdownlint absent; shellcheck target
  hardcoded to hack/scrub-denylist.sh). Broaden the shellcheck glob to `hack/**/*.sh`.

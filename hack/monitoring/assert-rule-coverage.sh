#!/usr/bin/env bash
# assert-rule-coverage.sh — REQ-E5-S06-05 (meta): every alert defined under
# deploy/monitoring/rules/ must be exercised by at least one alert_rule_test in
# tests/promtool/. Fails listing any untested alert; prints "0 untested" on success.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RULES_DIR="${ROOT}/deploy/monitoring/rules"
TESTS_DIR="${ROOT}/tests/promtool"

if ! command -v yq >/dev/null 2>&1; then
  echo "yq not installed — required to enumerate alert names" >&2
  exit 1
fi

# Collect every alert name declared across the PrometheusRule CRs.
mapfile -t alerts < <(
  for cr in "${RULES_DIR}"/marshal-*.yaml; do
    [ -e "$cr" ] || continue
    yq -r '.spec.groups[].rules[] | select(.alert != null) | .alert' "$cr"
  done | sort -u
)

if [ "${#alerts[@]}" -eq 0 ]; then
  echo "no alerts found under ${RULES_DIR}" >&2
  exit 1
fi

# Concatenate all promtool test files once for name lookup.
tests_blob="$(cat "${TESTS_DIR}"/*.test.yaml 2>/dev/null || true)"

untested=0
for a in "${alerts[@]}"; do
  # An alert is covered if it appears as an `alertname:` in an alert_rule_test.
  if grep -Eq "alertname:[[:space:]]*${a}([[:space:]]|$)" <<<"$tests_blob"; then
    echo "OK   ${a}"
  else
    echo "MISS ${a} — no alert_rule_test references it" >&2
    untested=$((untested + 1))
  fi
done

echo "---"
if [ "$untested" -ne 0 ]; then
  echo "${untested} untested alert(s)" >&2
  exit 1
fi
echo "0 untested alerts (${#alerts[@]} alerts, all covered)"

#!/usr/bin/env bash
# extract-rules.sh — turn each PrometheusRule CR under deploy/monitoring/rules/
# into a plain Prometheus rule-group file that `promtool test rules` can load via
# rule_files:. Emits to a stable path: /tmp/<basename>.rules.yaml
#
# promtool test rules expects a top-level `groups:` document; a PrometheusRule CR
# nests that under `.spec`, so we project `.spec` out with yq.
#
# CI (.github/workflows/monitoring.yaml) runs this before `task test:promrules`.
# The promtool test files reference the emitted /tmp paths in their rule_files:.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RULES_DIR="${ROOT}/deploy/monitoring/rules"
OUT_DIR="${OUT_DIR:-/tmp}"

if ! command -v yq >/dev/null 2>&1; then
  echo "yq not installed — required to extract .spec from PrometheusRule CRs" >&2
  exit 1
fi

shopt -s nullglob
count=0
for cr in "${RULES_DIR}"/marshal-*.yaml; do
  base="$(basename "${cr%.yaml}")"
  out="${OUT_DIR}/${base}.rules.yaml"
  yq '.spec' "$cr" > "$out"
  echo "extracted ${cr} -> ${out}"
  count=$((count + 1))
done

if [ "$count" = 0 ]; then
  echo "no PrometheusRule CRs found under ${RULES_DIR}" >&2
  exit 1
fi
echo "extracted ${count} rule file(s) to ${OUT_DIR}"

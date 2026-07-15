#!/usr/bin/env bash
# Add **Test:** lines before **Verify:** for REQs that lack them.
# Infers path from **Verify:** content; falls back to tests/smoke/<req-id>.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

infer_test() {
  local req="$1" verify="$2"
  local id
  id="$(echo "$req" | tr '[:upper:]' '[:lower:]' | tr ':' '-')"

  if [[ "$verify" =~ tests/chainsaw/[^[:space:]\`\'\"]+ ]]; then
    echo "${BASH_REMATCH[0]}"
    return
  fi
  if [[ "$verify" =~ hack/smoke/[^[:space:]\`\'\"]+ ]]; then
    echo "${BASH_REMATCH[0]}"
    return
  fi
  if [[ "$verify" =~ hack/demo/[^[:space:]\`\'\"]+ ]]; then
    echo "${BASH_REMATCH[0]}"
    return
  fi
  if [[ "$verify" =~ hack/scorecard/[^[:space:]\`\'\"]+ ]]; then
    echo "${BASH_REMATCH[0]}"
    return
  fi
  if [[ "$verify" =~ go\ test\ [^\`]+ ]]; then
    echo "${BASH_REMATCH[0]// /}"
    return
  fi
  if [[ "$verify" =~ tofu\ test ]]; then
    if [[ "$verify" =~ -filter=tests/([^\)\`\'\"\ ]+) ]]; then
      echo "modules/labels/tests/${BASH_REMATCH[1]}.tftest.hcl"
    else
      echo "modules/labels/tests/${id}.tftest.hcl"
    fi
    return
  fi
  if [[ "$verify" =~ conftest|task\ test:policy ]]; then
    echo "tests/policy/${id}.rego"
    return
  fi
  if [[ "$verify" =~ task\ test: ]]; then
    echo "tests/smoke/${id}.sh"
    return
  fi
  if [[ "$verify" =~ \.github/workflows/ ]]; then
    echo "tests/meta/workflow-${id}.yaml"
    return
  fi
  if [[ "$verify" =~ manual\ review ]]; then
    echo "tests/meta/manual-${id}.md"
    return
  fi
  echo "tests/smoke/${id}.sh"
}

while IFS= read -r spec; do
  tmp="$(mktemp)"
  req=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^##\ REQ- ]]; then
      req="${line#### }"
    fi
    if [[ "$line" =~ ^\*\*Verify:\*\* ]] && [[ -n "$req" ]]; then
      # peek: if previous lines in block already have Test, skip
      if ! grep -q "^\*\*Test:\*\*" "$tmp" 2>/dev/null || true; then
        :
      fi
    fi
    echo "$line" >>"$tmp"
  done <"$spec"

  out="$(mktemp)"
  req=""
  in_req=0
  has_test=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^##\ REQ- ]]; then
      req="${line#### }"
      in_req=1
      has_test=0
      echo "$line" >>"$out"
      continue
    fi
    if [[ $in_req -eq 1 && "$line" =~ ^\*\*Test:\*\* ]]; then
      has_test=1
    fi
    if [[ $in_req -eq 1 && "$line" =~ ^\*\*Verify:\*\* && $has_test -eq 0 ]]; then
      verify="${line#**Verify:** }"
      test_path="$(infer_test "$req" "$verify")"
      echo "**Test:** \`${test_path}\`" >>"$out"
      echo "" >>"$out"
      has_test=1
    fi
    if [[ "$line" == "---" ]]; then
      in_req=0
      req=""
      has_test=0
    fi
    echo "$line" >>"$out"
  done <"$tmp"

  mv "$out" "$spec"
  rm -f "$tmp"
done < <(find "$ROOT/openspec/changes" -path '*/specs/*/*.md' | sort)

echo "Injected **Test:** lines where missing."

#!/usr/bin/env bash
# E1g-S07 — creds-free standing-substrate status + soft TTL WARN (cost visibility).
#
# Reads a local marker only (default: evidence/live/.standing-marker). Never
# touches tofu/gridscale/creds. Always exits 0 — soft guardrail, never a hard
# gate (must not redden `task verify`).
#
# Marker fields (KEY=value, one per line; `#` comments allowed):
#   what=…          what is standing
#   since=YYYY-MM-DD
#   teardown-by=YYYY-MM-DD
#   owner=…
#
# Subcommands:
#   (default / status)  report standing record + age; WARN if past window/deadline
#   write               emit/update the marker (used by `task e1g:up`)
#   clear               remove the marker (used by `task e1g:down`)
#
# Env:
#   E1G_STANDING_MARKER       path (default: <repo>/evidence/live/.standing-marker)
#   E1G_STANDING_WINDOW_DAYS  soft window from `since` (default: 14)
#   E1G_STANDING_NOW          override "today" as YYYY-MM-DD (tests)
#   E1G_STANDING_WHAT/SINCE/TEARDOWN_BY/OWNER  overrides for `write`
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MARKER="${E1G_STANDING_MARKER:-$ROOT/evidence/live/.standing-marker}"
WINDOW_DAYS="${E1G_STANDING_WINDOW_DAYS:-14}"
NOW="${E1G_STANDING_NOW:-$(date -u +%Y-%m-%d)}"

usage() {
  cat <<'EOF'
Usage: standing-status.sh [status|write|clear]

  status (default)  Print standing record + age; WARN past window/teardown-by; exit 0
  write             Create/update the standing marker (e1g:up)
  clear             Remove the standing marker (e1g:down)

Env: E1G_STANDING_MARKER, E1G_STANDING_WINDOW_DAYS, E1G_STANDING_NOW,
     E1G_STANDING_WHAT, E1G_STANDING_SINCE, E1G_STANDING_TEARDOWN_BY, E1G_STANDING_OWNER
EOF
}

# days between two YYYY-MM-DD dates (end - start). Portable: prefer python3, else date.
days_between() {
  local start="$1" end="$2"
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$start" "$end" <<'PY'
import sys
from datetime import date
a, b = sys.argv[1], sys.argv[2]
da = date.fromisoformat(a)
db = date.fromisoformat(b)
print((db - da).days)
PY
    return
  fi
  # BSD/GNU date fallback
  local s e
  if s="$(date -j -f '%Y-%m-%d' "$start" '+%s' 2>/dev/null)" \
    && e="$(date -j -f '%Y-%m-%d' "$end" '+%s' 2>/dev/null)"; then
    echo $(( (e - s) / 86400 ))
    return
  fi
  s="$(date -d "$start" '+%s')"
  e="$(date -d "$end" '+%s')"
  echo $(( (e - s) / 86400 ))
}

read_field() {
  local key="$1" file="$2"
  # Missing key must NOT fail under set -euo pipefail (grep exit 1 would abort
  # the script before the incomplete-marker WARN). Empty string + exit 0.
  grep -E "^${key}=" "$file" 2>/dev/null | head -n1 | cut -d= -f2- || true
}

cmd_clear() {
  if [ -f "$MARKER" ]; then
    rm -f "$MARKER"
    echo "cleared standing marker: $MARKER"
  else
    echo "no standing marker at $MARKER (already clear)"
  fi
}

cmd_write() {
  local what since teardown owner
  what="${E1G_STANDING_WHAT:-gridscale GSK day-0 substrate}"
  since="${E1G_STANDING_SINCE:-$NOW}"
  teardown="${E1G_STANDING_TEARDOWN_BY:-}"
  owner="${E1G_STANDING_OWNER:-operator}"
  if [ -z "$teardown" ]; then
    # Default teardown-by = since + WINDOW_DAYS.
    if command -v python3 >/dev/null 2>&1; then
      teardown="$(python3 - "$since" "$WINDOW_DAYS" <<'PY'
import sys
from datetime import date, timedelta
d = date.fromisoformat(sys.argv[1]) + timedelta(days=int(sys.argv[2]))
print(d.isoformat())
PY
)"
    elif teardown_epoch="$(date -j -f '%Y-%m-%d' "$since" '+%s' 2>/dev/null)"; then
      teardown="$(date -j -f '%s' "$((teardown_epoch + WINDOW_DAYS * 86400))" '+%Y-%m-%d')"
    else
      teardown="$(date -d "$since + ${WINDOW_DAYS} days" '+%Y-%m-%d')"
    fi
  fi
  mkdir -p "$(dirname "$MARKER")"
  cat >"$MARKER" <<EOF
# E1g-S07 standing marker — local cost-visibility record (gitignored).
# Written by task e1g:up; cleared by task e1g:down; surfaced by task e1g:status.
what=${what}
since=${since}
teardown-by=${teardown}
owner=${owner}
EOF
  echo "wrote standing marker: $MARKER (teardown-by=${teardown}, owner=${owner})"
}

cmd_status() {
  if [ ! -f "$MARKER" ]; then
    # Silent no-op — offline we cannot know a live env exists; failing would
    # wrongly redden task verify when nothing is standing.
    return 0
  fi

  local what since teardown owner age overdue=0 reason=""
  what="$(read_field what "$MARKER")"
  since="$(read_field since "$MARKER")"
  teardown="$(read_field teardown-by "$MARKER")"
  owner="$(read_field owner "$MARKER")"

  if [ -z "$what" ] || [ -z "$since" ] || [ -z "$teardown" ] || [ -z "$owner" ]; then
    echo "WARN: standing marker at $MARKER is incomplete (need what/since/teardown-by/owner)" >&2
    echo "      stop the meter: task e1g:down" >&2
    return 0
  fi

  age="$(days_between "$since" "$NOW")"

  echo "E1g standing status (local marker only — no cloud probe)"
  echo "  what:         $what"
  echo "  since:        $since  (${age} day(s) ago)"
  echo "  teardown-by:  $teardown"
  echo "  owner:        $owner"
  echo "  window:       ${WINDOW_DAYS} day(s) (E1G_STANDING_WINDOW_DAYS)"
  echo "  stop meter:   task e1g:down"

  if [ "$(days_between "$NOW" "$teardown")" -lt 0 ]; then
    overdue=1
    reason="past teardown-by ${teardown}"
  elif [ "$age" -gt "$WINDOW_DAYS" ]; then
    overdue=1
    reason="age ${age}d exceeds ${WINDOW_DAYS}d window"
  fi

  if [ "$overdue" -eq 1 ]; then
    echo "WARN: standing substrate is overdue (${reason})" >&2
    echo "      teardown-by=${teardown} owner=${owner} — stop the meter: task e1g:down" >&2
  else
    echo "OK: within recorded time-box (teardown-by ${teardown})"
  fi
  return 0
}

main() {
  local cmd="${1:-status}"
  case "$cmd" in
    status|"") cmd_status ;;
    write)     cmd_write ;;
    clear)     cmd_clear ;;
    -h|--help|help) usage ;;
    *) echo "unknown subcommand: $cmd" >&2; usage >&2; return 0 ;;
  esac
}

main "$@"
# Soft contract: never propagate a non-zero status from this script's caller
# expectations — main already returns 0 on all paths; belt-and-braces:
exit 0

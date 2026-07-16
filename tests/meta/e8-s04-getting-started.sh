#!/usr/bin/env bash
# REQ-E8-S04-01/03/05/06 — documentation contract for Getting Started +
# five-minute reviewer path. Offline meta — no cluster required.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GS="${ROOT}/docs/getting-started.md"
README="${ROOT}/README.md"

fail() { echo "FAIL: $*" >&2; exit 1; }
need() { rg -q "$1" "$2" || fail "$2 missing pattern: $1"; }
forbid() { rg -q "$1" "$2" && fail "$2 must NOT contain: $1"; return 0; }

# --- REQ-E8-S04-01: reproducible local path ---------------------------------
[[ -f "${GS}" ]] || fail "missing ${GS}"

need 'kind-kaddy-dev' "${GS}"
need 'task cluster:up' "${GS}"
need '\.state/kubeconfig' "${GS}"
need 'task bootstrap:argocd' "${GS}"
need 'task bootstrap:e3' "${GS}"
need 'task bootstrap:e1c' "${GS}"
need 'task bootstrap:e6' "${GS}"
need 'task bootstrap:e7' "${GS}"
need 'Synced|Healthy|readiness' "${GS}"
need 'Website|putting-green' "${GS}"

# Isolated kubeconfig — never instruct merging into ambient ~/.kube/config.
forbid '~/\.kube/config' "${GS}"
# Do not tell operators to curl LB-IPAM / container-bridge addresses.
forbid '10\.89\.' "${GS}"
# Selectorless Cilium Gateway Services cannot be port-forwarded.
forbid 'port-forward svc/cilium-gateway' "${GS}"

# README links Getting Started before the deep architecture path.
need 'docs/getting-started\.md' "${README}"
# Five-minute path must mention Getting Started ahead of ARCHITECTURE.
gs_line="$(rg -n 'docs/getting-started\.md' "${README}" | head -1 | cut -d: -f1)"
arch_line="$(rg -n 'docs/ARCHITECTURE\.md' "${README}" | head -1 | cut -d: -f1)"
[[ -n "${gs_line}" && -n "${arch_line}" ]] || fail "README must link getting-started and ARCHITECTURE"
[[ "${gs_line}" -lt "${arch_line}" ]] || fail "README must link Getting Started before ARCHITECTURE"

# --- REQ-E8-S04-03: honest service catalogue --------------------------------
for surf in \
  '127\.0\.0\.1:30443/applications' \
  'clubhouse\.kaddy\.local' \
  'putting-green' \
  '127\.0\.0\.1:23000' \
  'E5_GRAFANA_PORT' \
  '127\.0\.0\.1:29090' \
  '127\.0\.0\.1:29093' \
  'task demo' \
  'task demo:chaos' \
  'task test:smoke:e4' \
  'task test:smoke:e6'
do
  need "${surf}" "${GS}"
done

# Credentials from Secrets — document the source, never hardcode password values.
need 'grafana-admin' "${GS}"
need 'argocd admin initial-password|argocd-initial-admin-secret' "${GS}"
forbid 'admin-password:[[:space:]]*["'\'']?[A-Za-z0-9+/=]{8,}' "${GS}"

# Catalogue must label Gateway vs port-forward vs kind NodePort paths.
need 'Gateway|HTTPRoute' "${GS}"
need 'port-forward' "${GS}"
need 'NodePort|30443' "${GS}"

# No invented browser URL for API-only Crossplane.
forbid 'https://.*crossplane' "${GS}"

# --- REQ-E8-S04-04 (doc contract portion): demo choreography order ----------
need 'task demo:fire' "${GS}"
demo_block="$(awk '
  /^## Demo/ {on=1}
  on && /^## / && !/^## Demo/ {exit}
  on {print}
' "${GS}")"
[[ -n "${demo_block}" ]] || fail "docs/getting-started.md missing ## Demo section"
web_ln="$(printf '%s\n' "${demo_block}" | rg -n 'Website|putting-green|test:smoke:e6' | head -1 | cut -d: -f1)"
fire_ln="$(printf '%s\n' "${demo_block}" | rg -n 'demo:fire' | head -1 | cut -d: -f1)"
demo_ln="$(printf '%s\n' "${demo_block}" | rg -n 'task demo[^:]|`task demo`' | head -1 | cut -d: -f1)"
chaos_ln="$(printf '%s\n' "${demo_block}" | rg -n 'demo:chaos' | head -1 | cut -d: -f1)"
[[ -n "${web_ln}" && -n "${fire_ln}" && -n "${demo_ln}" && -n "${chaos_ln}" ]] \
  || fail "Demo section must mention Website, demo:fire, demo, demo:chaos"
[[ "${web_ln}" -lt "${fire_ln}" && "${fire_ln}" -lt "${demo_ln}" && "${demo_ln}" -lt "${chaos_ln}" ]] \
  || fail "demo order must be Website → demo:fire → demo → demo:chaos"

printf '%s\n' "${demo_block}" | rg -qi 'baseline' || fail "Demo section missing baseline"
printf '%s\n' "${demo_block}" | rg -qi 'duration|minute|~[0-9]|timeout' || fail "Demo section missing duration"
printf '%s\n' "${demo_block}" | rg -qi 'fallback' || fail "Demo section missing fallback"

# --- REQ-E8-S04-05: recovery + teardown -------------------------------------
need '[Tt]roubleshoot|[Rr]ecovery|[Cc]leanup' "${GS}"
need 'E5_GRAFANA_PORT|E5_PROM_PORT|E5_AM_PORT|PROM_PORT|AM_PORT' "${GS}"
need 'scale.*clubhouse|replicas=1' "${GS}"
need 'stable|weight|rollback|restore' "${GS}"
need 'kill.*port-forward|pkill.*port-forward|stop.*port-forward|tear down port-forward' "${GS}"
need 'task cluster:down' "${GS}"
need 'idempotent' "${GS}"

# --- REQ-E8-S04-06: honest five-minute path ---------------------------------
need '[Ff]ive-?[Mm]inute|5 minutes' "${README}"
need 'unavailable|not yet published|not published' "${README}"
# Order in README: deck/demo artifact → scorecard → getting-started → architecture
deck_ln="$(rg -n -i 'deck|slidev|demo recording|released demo' "${README}" | head -1 | cut -d: -f1)"
score_ln="$(rg -n -i 'scorecard|platformrelay\.github\.io/Kaddy' "${README}" | head -1 | cut -d: -f1)"
[[ -n "${deck_ln}" && -n "${score_ln}" ]] || fail "README five-minute path must mention deck/demo and scorecard"
[[ "${deck_ln}" -lt "${score_ln}" && "${score_ln}" -lt "${gs_line}" && "${gs_line}" -lt "${arch_line}" ]] \
  || fail "five-minute order must be deck → scorecard → getting-started → architecture (${deck_ln}<${score_ln}<${gs_line}<${arch_line})"

echo "OK: REQ-E8-S04-01/03/05/06 getting-started + five-minute reviewer path contract"

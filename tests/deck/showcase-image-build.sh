#!/usr/bin/env bash
# REQ-CADDY-S05-02 — showcase content baked into an immutable multi-stage image.
# Structural asserts on deploy/showcase/Dockerfile + Caddyfile run OFFLINE
# (this is the L1 gate CI and `task verify`-adjacent runs rely on):
#   * multi-stage: `FROM ... AS build` + runtime `FROM caddy:<exact semver>`
#   * runtime layer carries NO build toolchain (node/pnpm/npm/pip/mkdocs)
#   * static output arrives via COPY --from=build only
#   * runtime is non-root (USER directive)
#   * OCI + ADR-0301 kaddy labels present
#   * Caddyfile: static file server on :8080 with a health endpoint
# The REAL build+push+cosign proof is CI (.github/workflows/showcase-image.yaml).
# Optional local build proof: SHOWCASE_IMAGE_BUILD=1 bash tests/deck/showcase-image-build.sh
# (uses docker or podman if present; skipped otherwise so the gate stays offline-green).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCKERFILE="${ROOT}/deploy/showcase/Dockerfile"
CADDYFILE="${ROOT}/deploy/showcase/Caddyfile"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "ok   $*"; }

[ -f "${DOCKERFILE}" ] || fail "deploy/showcase/Dockerfile missing"
[ -f "${CADDYFILE}" ] || fail "deploy/showcase/Caddyfile missing"

# --- spec Verify block (REQ-CADDY-S05-02), verbatim expectations -------------
grep -qE '^FROM .* AS build' "${DOCKERFILE}" || fail "no '^FROM .* AS build' build stage"
grep -qE '^FROM (caddy|nginx)' "${DOCKERFILE}" || fail "runtime stage is not caddy/nginx"
ok "spec Verify greps (multi-stage build + caddy/nginx runtime)"

# --- version pinning: exact semver tags, never :latest / bare major ----------
grep -qE '^FROM node:[0-9]+\.[0-9]+\.[0-9]+-[a-z0-9.]+ AS build' "${DOCKERFILE}" \
  || fail "build stage base image is not pinned to an exact node semver tag"
grep -qE '^FROM caddy:[0-9]+\.[0-9]+\.[0-9]+-[a-z0-9.]+$' "${DOCKERFILE}" \
  || fail "runtime stage is not pinned to an exact caddy semver tag"
! grep -qE '^FROM [^:]+(:latest)?$' "${DOCKERFILE}" || fail "an unpinned/:latest FROM found"
ok "base images pinned to exact version tags"

# --- runtime layer purity: nothing after the final FROM installs/runs a toolchain
runtime="$(awk '/^FROM /{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}' "${DOCKERFILE}")"
echo "${runtime}" | grep -q '^FROM caddy:' || fail "final stage is not the caddy runtime stage"
if echo "${runtime}" | grep -E '^(RUN|ENTRYPOINT|CMD)' \
  | grep -qEi '(^|[[:space:][:punct:]])(node|pnpm|npm|pip3?|python3?|mkdocs|apk|apt|apt-get)([[:space:][:punct:]]|$)'; then
  fail "runtime stage runs/installs a build toolchain"
fi
echo "${runtime}" | grep -q 'COPY --from=build' || fail "runtime stage does not COPY --from=build"
# every COPY in the runtime stage must come from the build stage or the build context (Caddyfile/landing page)
ok "runtime layer is toolchain-free; static assets via COPY --from=build"

# --- non-root (caddy binds :8080, unprivileged) ------------------------------
echo "${runtime}" | grep -qE '^USER [0-9]+' || fail "runtime stage has no numeric USER (non-root)"
ok "runtime runs as a numeric non-root USER"

# --- OCI + ADR-0301 labels ----------------------------------------------------
for l in org.opencontainers.image.title org.opencontainers.image.description \
         org.opencontainers.image.source org.opencontainers.image.licenses; do
  grep -q "${l}=" "${DOCKERFILE}" || fail "OCI label ${l} missing"
done
for l in owner service part-of managed-by data-classification business-criticality track; do
  grep -qE "(^| )${l}=" "${DOCKERFILE}" || fail "ADR-0301 kaddy label '${l}' missing"
done
ok "OCI + ADR-0301 label set present"

# --- Caddyfile: static server on :8080 + health endpoint ---------------------
grep -qE '^:8080' "${CADDYFILE}" || fail "Caddyfile does not listen on :8080"
grep -q 'file_server' "${CADDYFILE}" || fail "Caddyfile has no file_server"
grep -q '/healthz' "${CADDYFILE}" || fail "Caddyfile has no /healthz health endpoint"
grep -q 'auto_https off' "${CADDYFILE}" || fail "Caddyfile must disable auto_https (TLS terminates at the platform edge)"
ok "Caddyfile: :8080 static file server + /healthz"


# --- docs bake (REQ-CADDY-S05-01/02) ----------------------------------------
grep -qE '^FROM python:.* AS docs' "${DOCKERFILE}" || fail "missing python docs build stage"
grep -q 'mkdocs build --strict' "${DOCKERFILE}" || fail "docs stage must run mkdocs build --strict"
grep -q 'COPY --from=docs' "${DOCKERFILE}" || fail "runtime must COPY --from=docs into /srv/docs"
grep -q 'mkdocs-material' "${ROOT}/requirements-docs.txt" || fail "requirements-docs.txt must pin mkdocs-material"
grep -qE 'name:[[:space:]]*material' "${ROOT}/mkdocs.yml" || fail "mkdocs.yml must use theme material"
grep -q '/docs/' "${ROOT}/deploy/showcase/index.html" || fail "landing page must link /docs/"
! grep -qi 'pending' "${ROOT}/deploy/showcase/index.html" || fail "landing page must not mark /docs/ pending"
ok "docs bake stage + Material theme + landing /docs/ link"

# --- optional local build proof (CI is the authoritative build) --------------
if [ "${SHOWCASE_IMAGE_BUILD:-0}" = "1" ]; then
  engine=""
  command -v docker >/dev/null 2>&1 && engine=docker
  [ -z "${engine}" ] && command -v podman >/dev/null 2>&1 && engine=podman
  if [ -z "${engine}" ]; then
    fail "SHOWCASE_IMAGE_BUILD=1 but neither docker nor podman is available"
  fi
  echo "building deploy/showcase/Dockerfile with ${engine} (context: repo root)..."
  "${engine}" build -f "${DOCKERFILE}" -t kaddy-showcase:local-test "${ROOT}" \
    || fail "${engine} build failed"
  ok "local ${engine} build succeeded (kaddy-showcase:local-test)"
else
  echo "skip local image build (set SHOWCASE_IMAGE_BUILD=1 to build; CI proves the real build)"
fi

echo "OK: showcase image structural gate green"

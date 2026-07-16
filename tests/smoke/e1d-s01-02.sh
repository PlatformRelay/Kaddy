#!/usr/bin/env bash
# REQ-E1d-S01-02: the Dex OIDC discovery document is served through the
# Gateway (SNI dex.kaddy.local on the loopback-mapped 30443 listener) and
# advertises the committed issuer + endpoints.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

ISSUER="https://dex.kaddy.local:30443"
doc="$(curl -fsSk --resolve dex.kaddy.local:30443:127.0.0.1 \
  "${ISSUER}/.well-known/openid-configuration")" \
  || smoke_fail "discovery document not reachable via the Gateway"

[[ "$(jq -r '.issuer' <<<"${doc}")" == "${ISSUER}" ]] \
  || smoke_fail "issuer mismatch: $(jq -r '.issuer' <<<"${doc}")"
[[ "$(jq -r '.authorization_endpoint' <<<"${doc}")" == "${ISSUER}/auth" ]] \
  || smoke_fail "authorization_endpoint missing/mismatched"
[[ "$(jq -r '.token_endpoint' <<<"${doc}")" == "${ISSUER}/token" ]] \
  || smoke_fail "token_endpoint missing/mismatched"
smoke_ok "dex discovery via Gateway: issuer + authorization/token endpoints (${ISSUER})"

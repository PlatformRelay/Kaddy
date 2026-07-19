#!/usr/bin/env bash
# REQ-E14-S01 — OFFLINE gate for the Nix golden image (ADR-0303).
# No gridscale API, no credentials, no live VM. Proves:
#   1. flake.lock is present + committed (reproducibility: the whole point of Nix)
#   2. nixpkgs-fmt -check clean across nix/*.nix (formatting hygiene, STRICT)
#   3. `nix flake check --no-build` evaluates the flake — the image derivation +
#      the standalone nixosConfigurations both resolve, so a broken module
#      (bad option, failed assertion) fails the gate, not a 20-minute build
#
# nix has no macOS-host install here (ADR-0303), so every nix step runs inside a
# `nixos/nix` container on colima/docker. SKIP (not fail) if docker is absent or
# the flake inputs can't be fetched (no registry egress) — mirrors the e13 gate's
# "provider unreachable" skip. The full emulated `nix build .#gridscale-image`
# (the x86_64 raw image) is the LIVE E14-S01 proof, run manually via
# `task e14:build` / docs/runbooks/nix-golden-image.md — too slow for a unit gate.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
NIXDIR="${ROOT}/nix"
NIX_IMAGE="${KADDY_NIX_IMAGE:-nixos/nix:latest}"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

[[ -f "${NIXDIR}/flake.nix" ]] || fail "missing nix/flake.nix"

# --- 1) flake.lock committed (STRICT) ---------------------------------------
# A missing/uncommitted lock defeats the reproducibility guarantee E14 exists for.
[[ -f "${NIXDIR}/flake.lock" ]] || fail "missing nix/flake.lock — run 'task e14:lock' and commit it"
if command -v git >/dev/null 2>&1 && git -C "${ROOT}" rev-parse --git-dir >/dev/null 2>&1; then
  if git -C "${ROOT}" ls-files --error-unmatch nix/flake.lock >/dev/null 2>&1; then
    ok "flake.lock present + tracked"
  else
    fail "nix/flake.lock is not git-tracked — commit it"
  fi
else
  ok "flake.lock present (git unavailable — skip tracked check)"
fi

# --- docker probe (SKIP the nix steps if absent) ----------------------------
if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  echo "SKIP: docker unavailable — nixpkgs-fmt + flake check skipped (CI provides docker); flake.lock check enforced"
  echo "PASS: e14 offline gate green (skipped nix steps)"
  exit 0
fi

run_nix() {
  # Evaluation is arch-independent, so the native-arch container is fine + fast;
  # filter-syscalls=false is required under emulation/containers.
  docker run --rm \
    -e NIX_CONFIG=$'experimental-features = nix-command flakes\nfilter-syscalls = false' \
    -v "${NIXDIR}":/work -w /work "${NIX_IMAGE}" \
    bash -c "$1"
}

# --- 2) nixpkgs-fmt (STRICT when the container is reachable) -----------------
if ! docker image inspect "${NIX_IMAGE}" >/dev/null 2>&1; then
  if ! docker pull "${NIX_IMAGE}" >/dev/null 2>&1; then
    echo "SKIP: cannot pull ${NIX_IMAGE} (no registry egress) — nixpkgs-fmt + flake check skipped; flake.lock enforced"
    echo "PASS: e14 offline gate green (skipped nix steps)"
    exit 0
  fi
fi

if run_nix 'nix run nixpkgs#nixpkgs-fmt -- --check . >/dev/null 2>&1'; then
  ok "nixpkgs-fmt clean"
else
  # Distinguish "fmt drift" (fatal) from "cannot fetch nixpkgs" (skip).
  if run_nix 'nix flake metadata >/dev/null 2>&1'; then
    fail "nixpkgs-fmt drift under nix/ — run 'task e14:fmt' and commit"
  else
    echo "SKIP: flake inputs unfetchable (no egress) — fmt + flake check skipped; flake.lock enforced"
    echo "PASS: e14 offline gate green (skipped nix steps)"
    exit 0
  fi
fi

# --- 3) nix flake check (evaluate the image + config derivations) -----------
if run_nix 'nix flake check --no-build >/dev/null 2>&1'; then
  ok "nix flake check (image + nixosConfigurations evaluate)"
else
  fail "nix flake check failed — the flake or the caddy-golden module does not evaluate"
fi

# --- 4) caddy validate the golden Caddyfile (STRICT) ------------------------
# `nix flake check --no-build` does NOT parse the Caddyfile (services.caddy is
# handed an opaque configFile), so a broken serving contract would slip through.
# Validate the real file — the same one the module serves. This catches
# STRUCTURAL errors (unknown/misspelled directives, unbalanced braces); it does
# NOT catch semantically-valid-but-wrong values (e.g. a bad `admin` address),
# which surface only at boot (proven live in E14-S03). `root * /srv` validates
# fine offline (caddy checks syntax, not path existence). The file is
# byte-for-byte packer/files/Caddyfile.
if run_nix 'nix run nixpkgs#caddy -- validate --adapter caddyfile --config caddy/Caddyfile >/dev/null 2>&1'; then
  ok "caddy validate (golden Caddyfile parses)"
else
  fail "caddy validate failed — nix/caddy/Caddyfile is not a valid Caddyfile"
fi

echo "PASS: e14 offline gate green"

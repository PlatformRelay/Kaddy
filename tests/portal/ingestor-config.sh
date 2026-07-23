#!/usr/bin/env bash
# REQ-E10-S02-02 — the auto-generated scaffolder opens a PR, never a direct
# commit and never a cluster mutation (ADR-0103 GitOps, ADR-0111).
#
# This is E10's HEADLINE invariant test. The Backstage kubernetes-ingestor
# (TeraSky) generates one scaffolder template per `Website` XRD from its
# OpenAPI schema — no hand-written template.yaml — and the generated template's
# `publishPhase` MUST open a Git PULL REQUEST, never mutate the cluster.
#
# HOW THE PR INVARIANT IS ENCODED (verified against the TeraSky ingestor docs,
# terasky-oss.github.io/backstage-plugins/plugins/kubernetes-ingestor/backend/
# configure): the ingestor selects PR-vs-download via `publishPhase.target` — a
# git FORGE (github/gitlab/bitbucket/bitbucketCloud) makes the scaffold OPEN A
# PR; the ONLY non-git value is `YAML` (a download link, no git write). The
# scaffold is committed to a NEW branch (git.branchPrefix) and a PR is opened
# against git.targetBranch (the BASE) — so `targetBranch: main` is the PR base,
# NOT a direct push. There is NO `createPR` field in the real schema. We assert:
#   1. publishPhase exists under kubernetesIngestor.crossplane.xrds
#   2. target is a git FORGE (github/gitlab/bitbucket) — NOT `YAML` (download)
#   3. a PR branchPrefix is set (scaffold -> new branch -> PR, not a push)
#   4. the scaffolded XRs land under deploy/workloads/ (via the XRD target-path)
#   5. the XRD carries the terasky target-path + create-kustomization-file
#      annotations so scaffolded XRs land where ArgoCD watches
#   6. NO hand-written per-Website scaffolder template.yaml exists (the point
#      of D-028 — the template is generated, not copied)
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"

APPCONFIG="${ROOT}/deploy/portal/backstage/app-config.yaml"
XRD="${ROOT}/deploy/crossplane/xrd-website.yaml"
BACKSTAGE_DIR="${ROOT}/deploy/portal/backstage"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

[[ -f "${APPCONFIG}" ]] || fail "missing ${APPCONFIG}"
[[ -f "${XRD}" ]]       || fail "missing ${XRD}"

# --- 1) kubernetesIngestor.crossplane.xrds.publishPhase present --------------
grep -qE '^[[:space:]]*kubernetesIngestor:' "${APPCONFIG}" \
  || fail "app-config missing the kubernetesIngestor block"
grep -qE '^[[:space:]]*crossplane:' "${APPCONFIG}" \
  || fail "app-config kubernetesIngestor missing the crossplane block"
grep -qE '^[[:space:]]*publishPhase:' "${APPCONFIG}" \
  || fail "app-config missing kubernetesIngestor.crossplane.xrds.publishPhase"
ok "kubernetesIngestor.crossplane.xrds.publishPhase present"

# --- 2) publishPhase.target is a git FORGE (PR), not YAML (download) ---------
# In the TeraSky ingestor, `target: github|gitlab|bitbucket` => the scaffold
# opens a PR; `target: YAML` => a download link (no git write). The git-forge
# target IS the PR mechanism.
grep -qiE 'target:[[:space:]]*(github|gitlab|bitbucket)' "${APPCONFIG}" \
  || fail "publishPhase.target must be a git forge (github/gitlab/bitbucket) — a PR target, not YAML/download"
# Guard the exact anti-pattern REQ-E10-S02-02 forbids: a YAML/download target
# would bypass Git entirely (no PR, no audit trail).
! grep -qiE 'target:[[:space:]]*["'\'']?(yaml|download)' "${APPCONFIG}" \
  || fail "publishPhase.target must NOT be YAML/download (that bypasses the PR / Git audit trail)"
grep -qiE 'repoUrl:.*(owner=PlatformRelay|PlatformRelay/Kaddy)' "${APPCONFIG}" \
  || fail "publishPhase must point at the PlatformRelay/Kaddy repo"
ok "publishPhase.target is a git forge (github) on PlatformRelay/Kaddy — a PR target, not YAML/download"

# --- 3) a PR branchPrefix => scaffold lands on a NEW branch (PR, not push) ---
# The scaffold is committed to a new branch (branchPrefix) and a PR is opened
# against targetBranch (the BASE). A branchPrefix is the signal it is NOT a
# direct push to the base branch.
grep -qiE 'branchPrefix:[[:space:]]*[^[:space:]"'\'']' "${APPCONFIG}" \
  || fail "publishPhase.git.branchPrefix must be set (scaffold -> new branch -> PR, not a push to targetBranch)"
ok "publishPhase sets a PR branchPrefix (scaffold -> new branch -> PR against targetBranch)"

# --- 4) scaffolded XRs land under deploy/workloads/ --------------------------
# Path control is on the XRD (terasky.backstage.io/target-path); assert the
# workloads path appears in the config surface (app-config or the XRD annotation
# checked in step 5). Here: the app-config documents the workloads target.
grep -qE 'deploy/workloads/' "${APPCONFIG}" \
  || fail "the workloads target path (deploy/workloads/) must be documented in app-config"
ok "scaffolded XRs targeted at deploy/workloads/"

# --- 5) XRD carries the terasky path-control + discovery annotations ---------
# Anchor to non-comment, value-bearing lines (^[[:space:]]* excludes the '#'
# explainer comments above each key) so a commented-out annotation can never
# satisfy the assertion (vacuous-grep guard).
grep -qE '^[[:space:]]*terasky\.backstage\.io/target-path:[[:space:]]*"deploy/workloads/' "${XRD}" \
  || fail "Website XRD must set terasky.backstage.io/target-path under deploy/workloads/ (ArgoCD-watched)"
# resolvePathTemplate (terasky-utils) rejects a trailing '/' (empty segment) and
# resolves {name} against the scaffolder param `xrNamespace` — NOT `namespace`.
# Both bugs made Create fail at the claim-template step (live-caught 2026-07-24).
tp="$(grep -oE 'terasky\.backstage\.io/target-path:[[:space:]]*"[^"]*"' "${XRD}" | head -1)"
case "${tp}" in
  *'/website"') : ;;  # ends at 'website' + closing quote — no trailing slash
  *) fail "target-path must not end in a trailing slash (empty segment breaks resolvePathTemplate): ${tp}" ;;
esac
case "${tp}" in
  *'{xrNamespace}'*) : ;;
  *) fail "target-path must use the {xrNamespace} placeholder (the real scaffolder param; {namespace} is undefined): ${tp}" ;;
esac
grep -qE '^[[:space:]]*terasky\.backstage\.io/create-kustomization-file:[[:space:]]*"true"' "${XRD}" \
  || fail "Website XRD must set terasky.backstage.io/create-kustomization-file: \"true\" (ArgoCD sync)"
# LOAD-BEARING: without add-to-catalog the ingestor's crossplane.xrds path drops
# the XRD and NO Website template appears on the Create page (incident
# 2026-07-21; live-proven fix 2026-07-24).
grep -qE '^[[:space:]]*terasky\.backstage\.io/add-to-catalog:[[:space:]]*"true"' "${XRD}" \
  || fail "Website XRD must set terasky.backstage.io/add-to-catalog: \"true\" (else no Create-page template)"
# Guard the correction: the generate-form LABEL must NOT be added — it feeds the
# publishPhase-less genericCRDTemplates path and yields a BROKEN duplicate template.
if grep -qE '^[[:space:]]*terasky\.backstage\.io/generate-form:' "${XRD}"; then
  fail "Website XRD must NOT carry terasky.backstage.io/generate-form (broken duplicate template; use add-to-catalog only)"
fi
ok "Website XRD carries terasky target-path + create-kustomization-file + add-to-catalog (no generate-form)"

# --- 6) NO hand-written per-Website scaffolder template.yaml -----------------
# D-028: the template is GENERATED from the XRD, not hand-written. A committed
# scaffolder template.yaml for websites would be the drift-prone anti-pattern.
if grep -rslE 'kind:[[:space:]]*Template' "${BACKSTAGE_DIR}" 2>/dev/null \
     | xargs -r grep -lE 'backstage\.io/v1beta3' 2>/dev/null | grep -q .; then
  fail "found a hand-written Backstage scaffolder Template — D-028 forbids it (auto-generate from the XRD)"
fi
ok "no hand-written scaffolder Template (auto-generated from the Website XRD, D-028)"

echo "PASS: ingestor-config — auto-generated scaffolder opens a PR to deploy/workloads/, never mutates the cluster"

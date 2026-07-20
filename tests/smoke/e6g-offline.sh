#!/usr/bin/env bash
# E6g OFFLINE structural + schema gate — `task test:smoke:e6g`.
#
# The LIVE install/verify (provider Healthy, real gridscale VM, /legacy route)
# is DEFERRED to the E6g live cycle (the sibling xpkg is not yet built/pushed;
# see docs/runbooks/gridscale-provider.md). This gate proves the OFFLINE
# artifacts are present and well-formed with NO cluster and NO gridscale API:
#
#   1. Provider + ProviderConfig manifests exist and reference the provider pkg.
#   2. The credentials Secret template ships the JSON-blob shape the provider
#      actually parses ({"uuid","token","api_url"} under one key) — NOT inert
#      real values (values injected at live time).
#   3. The gridscale Website Composition composes a Server (nginx VM) + the
#      minimal IPv4 / Storage MRs it boots from, behind a `variant` selector so
#      the in-cluster Website path is untouched. (D-039: the unattached private
#      Network MR was dropped — the VM serves on the gridscale Public Network.)
#   4. The gridscale Server/IPv4/Storage MRs validate against the
#      sibling provider's GENERATED CRD schemas via kubeconform (real schema —
#      catches field-name drift before the live cycle). Skipped with a loud
#      note if the sibling repo or kubeconform is absent.
#
# Mirrors tests/smoke/caddy-mvp-s05-03-offline.sh (structural awk/grep gate).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
CP="${ROOT}/deploy/crossplane"
PROVIDER="${CP}/provider-gridscale.yaml"
PROVIDERCONFIG="${CP}/providerconfig-gridscale.yaml"
COMPO_GS="${CP}/composition-website-gridscale.yaml"
APP="${ROOT}/deploy/apps/crossplane.yaml"
PLATFORM_PROJ="${ROOT}/deploy/apps/projects/platform.yaml"

# The sibling provider-gridscale repo holds the GENERATED CRD schemas (E6g-S01).
# Discover it whether kaddy is a normal checkout (../provider-gridscale) or a
# worktree under .claude/worktrees/ (its real repo dir is up a few levels). The
# schema step is SKIPPED (not failed) if it cannot be found — it's a
# nice-to-have offline check, not a hard dependency.
SIBLING=""
for cand in \
  "${ROOT}/../provider-gridscale" \
  "${ROOT}/../../provider-gridscale" \
  "${ROOT}/../../../../provider-gridscale" \
  "${ROOT}/../../../../../provider-gridscale" \
  "${GITDIR:-}/../../provider-gridscale" ; do
  if [[ -n "${cand}" && -d "${cand}/package/crds" ]]; then
    SIBLING="$(cd "${cand}" && pwd)"
    break
  fi
done

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }
need_file() { [[ -f "$1" ]] || fail "missing $1"; }

need_file "${PROVIDER}"
need_file "${PROVIDERCONFIG}"
need_file "${COMPO_GS}"
need_file "${APP}"
need_file "${PLATFORM_PROJ}"

# --- 0) platform AppProject must permit Provider (+ ClusterProviderConfig) ---
# Live GSK (D-044/D-045): crossplane sync fails with
#   pkg.crossplane.io:Provider is not permitted in project platform
# without this whitelist entry. ClusterProviderConfig is also cluster-scoped and
# lives in deploy/crossplane/, so it must be listed too (closed list, not */*).
# ProviderRevision is Crossplane-owned (not in git) — do NOT whitelist it here.
awk '
  /clusterResourceWhitelist:/ { in_w=1; next }
  in_w && /^[[:space:]]*-[[:space:]]*group:/ {
    g=$0; sub(/^[[:space:]]*-[[:space:]]*group:[[:space:]]*/, "", g)
    getline
    if ($0 ~ /kind:/) {
      k=$0; sub(/^[[:space:]]*kind:[[:space:]]*/, "", k)
      print g "/" k
    }
  }
  in_w && /^[^[:space:]#]/ && $0 !~ /^[[:space:]]/ { in_w=0 }
' "${PLATFORM_PROJ}" | grep -qx 'pkg.crossplane.io/Provider' \
  || fail "platform AppProject clusterResourceWhitelist must include pkg.crossplane.io/Provider"
awk '
  /clusterResourceWhitelist:/ { in_w=1; next }
  in_w && /^[[:space:]]*-[[:space:]]*group:/ {
    g=$0; sub(/^[[:space:]]*-[[:space:]]*group:[[:space:]]*/, "", g)
    getline
    if ($0 ~ /kind:/) {
      k=$0; sub(/^[[:space:]]*kind:[[:space:]]*/, "", k)
      print g "/" k
    }
  }
  in_w && /^[^[:space:]#]/ && $0 !~ /^[[:space:]]/ { in_w=0 }
' "${PLATFORM_PROJ}" | grep -qx 'gridscale.m.platformrelay.io/ClusterProviderConfig' \
  || fail "platform AppProject clusterResourceWhitelist must include gridscale.m.platformrelay.io/ClusterProviderConfig"
ok "platform AppProject whitelists Provider + ClusterProviderConfig (D-045)"

# --- 1) Provider references the provider-gridscale package -------------------
grep -qE '^kind:[[:space:]]*Provider[[:space:]]*$' "${PROVIDER}" \
  || fail "provider-gridscale.yaml must declare a pkg.crossplane.io Provider"
grep -qE 'pkg\.crossplane\.io' "${PROVIDER}" \
  || fail "Provider must use apiVersion pkg.crossplane.io/*"
grep -qE 'provider-gridscale' "${PROVIDER}" \
  || fail "Provider spec.package must reference provider-gridscale image"
# The package path is a live-cycle placeholder — the TODO(live) marker must be
# present so no one mistakes it for a pushed image.
grep -qiE 'TODO\(live\)' "${PROVIDER}" \
  || fail "Provider package must carry a # TODO(live) marker (xpkg not built yet)"
ok "Provider references provider-gridscale package (TODO(live) placeholder marked)"

# --- 2) ProviderConfig + creds Secret template (JSON-blob shape) -------------
grep -qE 'kind:[[:space:]]*(Cluster)?ProviderConfig[[:space:]]*$' "${PROVIDERCONFIG}" \
  || fail "providerconfig-gridscale.yaml must declare a (Cluster)ProviderConfig"
grep -qE 'source:[[:space:]]*Secret' "${PROVIDERCONFIG}" \
  || fail "ProviderConfig credentials.source must be Secret"
grep -qE 'secretRef:' "${PROVIDERCONFIG}" \
  || fail "ProviderConfig must reference the credentials Secret via secretRef"
# The provider unmarshals ONE secret key as a JSON blob {uuid,token,api_url}
# (internal/clients/gridscale.go) — assert the template ships that shape and
# documents the .envrc GRIDSCALE_USER_UUID/GRIDSCALE_API_KEY -> uuid/token map.
grep -qE '"uuid"' "${PROVIDERCONFIG}" \
  || fail "creds Secret template must carry the JSON key \"uuid\" (provider parses a JSON blob)"
grep -qE '"token"' "${PROVIDERCONFIG}" \
  || fail "creds Secret template must carry the JSON key \"token\""
grep -qiE 'GRIDSCALE_USER_UUID|GRIDSCALE_API_KEY' "${PROVIDERCONFIG}" \
  || fail "ProviderConfig must document the .envrc -> secret env-var mapping"
# Inert: no real UUID/token committed (placeholder tokens only).
grep -qiE 'REPLACE|<[a-z-]+>|CHANGEME|injected' "${PROVIDERCONFIG}" \
  || fail "creds Secret must ship INERT placeholder values (injected at live time)"
ok "ProviderConfig + creds Secret template (JSON-blob uuid/token, inert, env-map documented)"

# --- 3) gridscale Composition composes Server + boot MRs, variant-gated ------
grep -qE 'kind:[[:space:]]*Composition[[:space:]]*$' "${COMPO_GS}" \
  || fail "composition-website-gridscale.yaml must declare a Composition"
# Separate composition keeps the in-cluster path (composition-website.yaml)
# untouched; selected by the XRD `variant` field via compositionSelector.
grep -qE 'gridscale' "${COMPO_GS}" \
  || fail "gridscale Composition must matchLabel variant: gridscale (compositionSelector)"
for kind in Server IPv4 Storage; do
  grep -qE "kind:[[:space:]]*${kind}[[:space:]]*$" "${COMPO_GS}" \
    || fail "gridscale Composition must compose a ${kind} managed resource (bootable nginx VM)"
done
grep -qE 'gridscale\..*platformrelay\.io' "${COMPO_GS}" \
  || fail "composed MRs must use the provider-gridscale API group gridscale.*.platformrelay.io"
# Cost guard: minimal VM (1 core, small memory).
grep -qE 'cores:[[:space:]]*1' "${COMPO_GS}" \
  || fail "nginx VM must be minimal: cores: 1 (cost-sensitive)"
# Single source of truth: the page/metrics userData mirrors the caddy-mvp nginx.
grep -qE 'userDataBase64|user-?data|cloud-config' "${COMPO_GS}" \
  || fail "Server must ship cloud-init userData serving the page + /metrics"
ok "gridscale Composition composes Server + IPv4/Storage (variant-gated, minimal VM)"

# --- 4) in-cluster Website path is untouched (existing composition intact) ---
grep -qE 'name:[[:space:]]*website\.platform\.kaddy\.io' "${CP}/composition-website.yaml" \
  || fail "existing in-cluster Composition website.platform.kaddy.io must remain"
# The XRD must expose a `variant` selector field so the two paths are selectable.
grep -qE 'variant' "${CP}/xrd-website.yaml" \
  || fail "XRD must expose a spec.variant field (in-cluster | gridscale) to select the Composition"
ok "in-cluster Website path intact + XRD exposes variant selector"

# --- 4b) every committed Website XR pins a compositionSelector ---------------
# Once a SECOND Composition exists for kind: Website, a selector-less XR is
# ambiguous and composes NOTHING. Enforce the invariant so no Website manifest
# (demo claim, chainsaw fixture, example) regresses the in-cluster path.
missing_sel=""
v1_sel=""
while IFS= read -r wf; do
  # Only XR *instances* (apiVersion platform.kaddy.io) — skip the XRD and the
  # Compositions (which reference kind: Website in compositeTypeRef, not as an
  # instance).
  grep -qE '^apiVersion:[[:space:]]*platform\.kaddy\.io/' "${wf}" || continue
  grep -qE '^kind:[[:space:]]*Website[[:space:]]*$' "${wf}" || continue
  grep -qE 'compositionSelector' "${wf}" \
    || missing_sel="${missing_sel} ${wf}"
  # Crossplane v2: selection MUST be nested under spec.crossplane. The top-level
  # v1 shape (`^  compositionSelector:`, i.e. directly under spec) is rejected by
  # strict decode on the v2 namespaced XRD (live-proven E6g), so reject it here
  # before it reaches an auto-synced cluster.
  if grep -qE '^[[:space:]]{2}compositionSelector:' "${wf}"; then
    v1_sel="${v1_sel} ${wf}"
  fi
done < <(grep -rlE '^kind:[[:space:]]*Website' "${ROOT}/deploy" "${ROOT}/tests" 2>/dev/null)
if [[ -n "${missing_sel}" ]]; then
  fail "Website XR(s) missing spec.compositionSelector (ambiguous now 2 Compositions exist):${missing_sel}"
fi
if [[ -n "${v1_sel:-}" ]]; then
  fail "Website XR(s) use the v1 top-level spec.compositionSelector — Crossplane v2 requires spec.crossplane.compositionSelector:${v1_sel}"
fi
ok "every committed Website XR pins a v2 spec.crossplane.compositionSelector (no ambiguous/v1 claims)"

# --- 5) ArgoCD app renders deploy/crossplane (new manifests sync via GitOps) -
grep -qE 'path:[[:space:]]*deploy/crossplane[[:space:]]*$' "${APP}" \
  || fail "crossplane Application must sync path deploy/crossplane (new manifests included)"
ok "provider-gridscale manifests sync via the crossplane GitOps Application"

# --- 6) kubeconform: new MRs validate against the sibling's generated CRDs ---
SCHEMA_DIR="${SIBLING:+${SIBLING}/package/crds}"
if ! command -v kubeconform >/dev/null 2>&1; then
  echo "SKIP: kubeconform not installed — schema validation of gridscale MRs deferred"
elif [[ -z "${SCHEMA_DIR}" || ! -d "${SCHEMA_DIR}" ]]; then
  echo "SKIP: sibling provider-gridscale CRDs not found — schema validation deferred"
else
  # Build a local schema location from the sibling's generated CRDs so
  # kubeconform can resolve the gridscale.*.platformrelay.io kinds offline.
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' EXIT
  # kubeconform consumes OpenAPI-per-CRD via `-schema-location` pointing at a
  # dir of CRD YAMLs converted to JSON schema; simplest offline path is the
  # built-in CRD support via `openapi2jsonschema`-style layout. We instead run
  # kubeconform in CRD-aware mode by feeding the CRDs as additional schemas.
  # Extract the composed MRs from the Composition into standalone manifests.
  python3 - "${COMPO_GS}" "${tmp}" <<'PY'
import sys, yaml, base64, json, os
compo, outdir = sys.argv[1], sys.argv[2]
doc = list(yaml.safe_load_all(open(compo)))[0]
pipeline = doc["spec"]["pipeline"][0]["input"]["resources"]
n = 0
for r in pipeline:
    base = r.get("base")
    if not base:
        continue
    grp = str(base.get("apiVersion", ""))
    if "platformrelay.io" not in grp:
        continue
    # give it a concrete name so kubeconform validates a full object
    base.setdefault("metadata", {})
    base["metadata"].setdefault("name", "e6g-validate-%d" % n)
    base["metadata"].setdefault("namespace", "websites")
    with open(os.path.join(outdir, "mr-%d.yaml" % n), "w") as f:
        yaml.safe_dump(base, f)
    n += 1
print("extracted %d gridscale MR(s) for schema validation" % n)
PY
  # Convert sibling CRDs to a kubeconform schema dir (JSON Schema per kind).
  crd_schema="${tmp}/schemas"
  mkdir -p "${crd_schema}"
  python3 - "${SCHEMA_DIR}" "${crd_schema}" <<'PY'
import sys, os, yaml, json
crddir, out = sys.argv[1], sys.argv[2]
count = 0
for fn in os.listdir(crddir):
    if not fn.endswith(".yaml"):
        continue
    for doc in yaml.safe_load_all(open(os.path.join(crddir, fn))):
        if not doc or doc.get("kind") != "CustomResourceDefinition":
            continue
        spec = doc["spec"]
        group = spec["group"]
        kind = spec["names"]["kind"]
        for v in spec["versions"]:
            ver = v["name"]
            schema = v["schema"]["openAPIV3Schema"]
            # Match the -schema-location template below (case-exact, no template
            # functions — kubeconform v0.8's text/template has no toLower):
            #   {ResourceKind}-{Group}-{ResourceAPIVersion}.json
            name = f"{kind}-{group}-{ver}.json"
            with open(os.path.join(out, name), "w") as f:
                json.dump(schema, f)
            count += 1
print(f"wrote {count} CRD schema file(s)")
PY
  shopt -s nullglob
  mrs=( "${tmp}"/mr-*.yaml )
  if [[ ${#mrs[@]} -eq 0 ]]; then
    fail "no gridscale MRs extracted from the Composition — schema gate cannot run"
  fi
  # -schema-location with the local CRD-derived schemas; skip kinds without a
  # local schema is NOT desired here — every gridscale MR must resolve.
  if kubeconform \
      -strict \
      -schema-location "${crd_schema}/{{ .ResourceKind }}-{{ .Group }}-{{ .ResourceAPIVersion }}.json" \
      -summary \
      "${mrs[@]}"; then
    ok "gridscale MRs validate against the sibling provider's generated CRD schemas (kubeconform)"
  else
    fail "gridscale MRs FAILED schema validation against sibling CRDs — field drift?"
  fi
fi

echo ""
echo "OK: E6g offline gate green — provider + ProviderConfig + gridscale Composition well-formed"
echo "NOTE: LIVE install (provider Healthy, real VM, /legacy) DEFERRED to the E6g live cycle."

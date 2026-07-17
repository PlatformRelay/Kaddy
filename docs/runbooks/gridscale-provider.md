# Runbook — provider-gridscale (E6g live cycle)

**Epic:** E6g · **ADR:** [0105](../adr/0105-crossplane-self-service.md) · **Decision:** D-016
**Status:** OFFLINE artifacts committed; **LIVE install DEFERRED** (the sibling
xpkg is not yet built/pushed — see step 1).

The offline lane (this repo) ships the Provider CR, the ClusterProviderConfig +
credentials Secret template, and a second Website Composition that provisions a
real gridscale nginx VM. The steps below are the LIVE cycle: build+push the
provider package, install it, wire credentials, provision the VM, verify
`/legacy`, then **destroy** (cost-sensitive — one small VM per test, torn down
after each run).

---

## 0. Prereqs

- E1g complete: a running cluster (GSK or the local kind-kaddy-dev) with
  Crossplane core installed (the `crossplane` ArgoCD app is green).
- gridscale credentials in `.envrc` (never committed):
  `GRIDSCALE_USER_UUID` and `GRIDSCALE_API_KEY`.
- Tools: `up` (Upbound CLI) or `docker` + `crossplane` to build the xpkg;
  `kubectl`, `jq`.

## 1. Build + push the provider package (the deferred E6g-S01 artifact)

The sibling repo `PlatformRelay/provider-gridscale` has already run Upjet
codegen — the generated CRDs live in `package/crds/`. What is NOT done is
building the CRDs + controller into an `.xpkg` and pushing it to a registry; its
README leaves the registry path as a `<PACKAGE>:<VERSION>` placeholder.

```bash
cd ../provider-gridscale          # sibling repo (workspace peer of Kaddy/)
# Build the provider binary + xpkg and push. The DECIDED target registry path
# is ghcr.io/platformrelay/provider-gridscale (agent-context INBOX DECIDED
# E6g-pkg-ref); align VERSION with the sibling's release tag.
make build
make publish XPKG_REG_ORGS=ghcr.io/platformrelay VERSION=v0.1.0
# The official gridscale icon is appended at publish via:
#   up alpha xpkg append --extensions-root=./extensions   (see sibling README)
```

Then pin the tag by **digest** in `deploy/crossplane/provider-gridscale.yaml`
(SEC-4: no floating tags) and drop the `# TODO(live)` marker:

```yaml
spec:
  package: ghcr.io/platformrelay/provider-gridscale:v0.1.0@sha256:<digest>
```

> **Time-box (D-016):** if the xpkg build slips, the fallback is a plain
> `gridscale_server` OpenTofu module (a `modules/gridscale-nginx/` TF module
> applied out-of-band, wired to the same `/legacy` route). Do NOT block E8b on
> the Upjet path completing. The Composition + ProviderConfig committed here are
> the Crossplane-native path; the TF module is the escape hatch.

## 2. Install the provider

`deploy/crossplane/provider-gridscale.yaml` is already synced by the `crossplane`
ArgoCD app (directory sync). Once step 1 pins a real package, ArgoCD installs it.
Wait for health:

```bash
kubectl wait --for=condition=Healthy provider.pkg.crossplane.io/provider-gridscale --timeout=600s
kubectl get crds | grep platformrelay.io   # Server, Network, IPv4, Storage, ...
```

## 3. Wire credentials (ClusterProviderConfig + Secret)

The provider parses a SINGLE Secret key (`credentials`) as a JSON blob
`{"uuid":...,"token":...}` — NOT separate keys. The env-var mapping (the E1g
mismatch) is:

| `.envrc` export       | gridscale provider var       | secret JSON key |
| --------------------- | ---------------------------- | --------------- |
| `GRIDSCALE_USER_UUID` | `GRIDSCALE_UUID` (User-UUID)  | `uuid`          |
| `GRIDSCALE_API_KEY`   | `GRIDSCALE_TOKEN` (API-token) | `token`         |

Create the real Secret out-of-band (never committed — the committed Secret in
`providerconfig-gridscale.yaml` is an INERT `REPLACE_ME` template):

```bash
kubectl -n crossplane-system create secret generic gridscale-creds \
  --from-literal=credentials="$(jq -nc \
    --arg uuid "$GRIDSCALE_USER_UUID" --arg token "$GRIDSCALE_API_KEY" \
    '{uuid:$uuid,token:$token}')"
```

The `ClusterProviderConfig/default` (cluster-scoped — DECIDED, so ONE central
Secret in `crossplane-system` serves all gridscale MRs regardless of namespace;
a namespaced ProviderConfig would force the Secret into each XR's namespace) is
already synced and points at `gridscale-creds`.

## 4. Set the Ubuntu template + Public Network UUIDs

`composition-website-gridscale.yaml` carries two live-time placeholders:
`REPLACE_ME_UBUNTU_TEMPLATE_UUID` (Storage boot disk) and
`REPLACE_ME_PUBLIC_NETWORK_UUID` (the Server's public NIC — the public IPv4 only
routes when the VM is on the gridscale **Public Network**; a private NIC alone
leaves all ports filtered). Find both from your tenant and patch the Composition:

```bash
# Ubuntu 22.04 template UUID
curl -s -H "X-Auth-UserId: $GRIDSCALE_USER_UUID" -H "X-Auth-Token: $GRIDSCALE_API_KEY" \
  https://api.gridscale.io/objects/templates \
  | jq -r '.templates|to_entries[].value|select(.name|test("Ubuntu 22.04"))|.object_uuid'
# Public Network UUID (public_net == true, e.g. de/fra2)
curl -s -H "X-Auth-UserId: $GRIDSCALE_USER_UUID" -H "X-Auth-Token: $GRIDSCALE_API_KEY" \
  https://api.gridscale.io/objects/networks \
  | jq -r '.networks|to_entries[].value|select(.public_net==true)|.object_uuid'
```

## 5. Provision the VM + verify /legacy

The gridscale demo claim lives at `deploy/examples/gridscale-website/` (NOT under
`deploy/workloads/`, which the workloads app auto-syncs with `recurse:true` —
this keeps real, cost-incurring infra out of GitOps auto-provisioning).

> **Crossplane v2 note (live-proven):** the `Website` XR is namespaced (D-027), so
> composition selection is nested under `spec.crossplane.compositionSelector` — NOT
> the v1 top-level `spec.compositionSelector` (strict decode rejects the v1 shape).
> The committed example already uses the v2 shape.

```bash
kubectl apply -f deploy/examples/gridscale-website/website-gridscale.yaml
kubectl -n websites get website legacy -w        # Ready=True
kubectl -n websites get server,network,ipv4,storage
# nginx serves "Hello World from gridscale" + /metrics (stub_status).
curl -s https://$HOST/legacy/                    # via LBaaS in the live cycle
```

## 6. Destroy (cost-sensitive — after EACH test)

```bash
kubectl delete -f deploy/examples/gridscale-website/website-gridscale.yaml
kubectl -n websites get server,network,ipv4,storage   # gone
```

---

## Offline gate (no cluster, no gridscale API)

Everything above that can be proven WITHOUT a cluster is gated by:

```bash
task test:smoke:e6g     # tests/smoke/e6g-offline.sh
```

It asserts the Provider/ProviderConfig/Composition manifests are present and
well-formed, and validates the composed gridscale MRs against the sibling's
GENERATED CRD schemas via `kubeconform` (catches field drift before the live
cycle). `crossplane render` is NOT used offline here — it requires Docker to run
the composition function, which the offline harness lacks; the render + full
live install/verify are the live cycle's job.

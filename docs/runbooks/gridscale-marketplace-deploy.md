# Runbook — gridscale Marketplace template (E13, Caddy + nginx)

Deliver the exercise the **gridscale-native third way**: a Marketplace 2.0
template that any gridscale user deploys one-click into a monitored Caddy/nginx
web server. Alongside the Kubernetes path (E-Caddy-MVP Variant B) and the
Crossplane-VM path (Variant A / E6g), this is the gridscale **product** delivery.

Pipeline: **build → export `.gz` → register → import → deploy → scrape → fire.**

## TL;DR

```bash
# OFFLINE (safe, no creds, no cost) — wired into task verify / CI meta gate.
task test:smoke:e13

# LIVE (costs money at build/export/deploy) — only when explicitly provisioning.
#   1. build + export the golden image (Packer + snapshot export) — see below
#   2. task e13:up      # register + import the Marketplace apps (both engines)
#   3. deploy a gridscale_server from the template, verify, capture evidence
#   4. task e13:down    # RUTHLESS teardown — run after EVERY live test
```

## Layout

```text
packer/                                  # golden-image build (Caddy/nginx + /metrics)
  caddy.pkr.hcl  nginx.pkr.hcl
  files/         index.html, Caddyfile, nginx.conf      # sample page + configs
  scripts/       provision-caddy.sh, provision-nginx.sh # install + enable /metrics
modules/marketplace-template/            # register + import (reusable, per-engine)
  main.tf variables.tf outputs.tf versions.tf
  assets/icon.png                        # meta_icon source (base64 at plan time)
  tests/inputs.tftest.hcl                # L0 offline: enum/.gz/icon validation
stacks/gridscale-marketplace/{caddy,nginx}/   # Terramate stacks (codegen'd)
tests/smoke/e13-offline.sh               # GREEN offline gate (task test:smoke:e13)
tests/smoke/e13-s0{1,2,3}-*.sh           # LIVE smoke (SKIP without creds/state)
tests/smoke/e13-exit-marketplace.sh      # end-to-end exit proof
tests/promtool/gridscale-marketplace.test.yaml  # caddy_* fires against the VM (L1)
```

## Offline gate (what `task test:smoke:e13` proves)

`tests/smoke/e13-offline.sh` — no gridscale API, no credentials, no build:

1. `terramate generate` is current (committed codegen for the new stacks not drifted)
2. `tofu fmt -check` clean across `modules/marketplace-template` + the stacks
3. `tofu init -backend=false` + `validate` + `test` (mock_provider) on the module
   and both stacks — asserts the `.gz`/`s3://` path, the in-enum `category`, a
   present `meta_icon`, and the app→import `unique_hash` wiring; rejects a
   non-`.gz` path, a non-`s3://` scheme, and an out-of-enum category
4. `packer fmt -check` on the builds; `packer validate` best-effort (SKIPs if the
   gridscale plugin can't be fetched offline — mirrors the E1g init skip)
5. `promtool` — the parked `caddy_*` marshal alert **fires** (present-but-failing
   and absent branches) and is **silent** when healthy, against a `job="caddy"`
   gridscale-VM target

The provider/plugin binaries are fetched once from the public registry; that is a
public download, not a gridscale API call. The gate degrades gracefully (SKIP,
not FAIL) when a tool or registry egress is missing, so it is green on any host.

## Live build → export → register → import → deploy

> **Cost discipline (D-032 / phase-2 rule):** every expensive resource (build VM,
> deployed VM) is `create → verify → capture → destroy`. The object-storage
> bucket (E1g anchor) is the only persistent thing. Run `task e13:down` after
> every live test and confirm in the gridscale panel that nothing lingers.

### 1. Build the golden image (Packer)

```bash
export GRIDSCALE_UUID="$GRIDSCALE_USER_UUID"     # provider env-var mapping (see E1g runbook)
export GRIDSCALE_TOKEN="$GRIDSCALE_API_KEY"
cd packer
packer init .
packer build caddy.pkr.hcl     # then nginx.pkr.hcl
```

Packer spins a temporary `gridscale_server` from a public Ubuntu base template,
installs Caddy (or nginx + `nginx-prometheus-exporter`), drops the sample page,
enables the service + `/metrics`, and leaves a **storage** to snapshot. Packer
tears down its build server automatically.

**Fallback (time-box):** provision a `gridscale_server` by hand, configure it,
snapshot the storage — same output, no Packer plugin dependency.

### 2. Snapshot + export the storage as `.gz` to object storage

Export the build storage's snapshot to the E1g object-storage bucket. In
Terraform this is `gridscale_snapshot.object_storage_export` (host/access_key/
secret_key/bucket/object); the `object` must end `.gz`. The resulting path is:

```text
s3://<images-bucket>/caddy-golden.gz     # and nginx-golden.gz
```

Feed that path into the stack via `TF_VAR_object_storage_path` in step 3. The
S3 credentials are the object-storage stack's `access_key`/`secret_key` outputs
(see the E1g runbook's output→input wiring); the endpoint is `https://gos3.io`.

Verify: `bash tests/smoke/e13-s01-export.sh` (asserts the `.gz` object exists).

### 3. Register + import the Marketplace application

```bash
export TF_VAR_object_storage_path="s3://<images-bucket>/caddy-golden.gz"
task e13:up      # applies stacks/gridscale-marketplace/{caddy,nginx}
```

`gridscale_marketplace_application` registers the app (name, category, sizing,
`meta_*`, base64 `meta_icon`) and exports a `unique_hash`;
`gridscale_marketplace_application_import` imports it **privately into our tenant**
by that hash. No global publication is requested — `is_publish_*` stay false.

Verify: `bash tests/smoke/e13-s02-register.sh` (asserts `id` + `unique_hash` +
`import_id` set).

### 4. Deploy proof (serve → scrape → fire)

Create a `gridscale_server` from the imported template (a `gridscale_storage`
with a `template { template_uuid = <the imported template UUID> }`), give it a
public IPv4, and boot it. It serves the sample page (HTTP 200) and exposes
`/metrics` — for the **Caddy** engine via a dedicated metrics listener at
`:2019/metrics` (admin stays off), or for the **nginx** engine via
`nginx-prometheus-exporter` at `:9113/metrics`.

Point Prometheus at the VM `/metrics` (`:2019` for Caddy, `:9113` for nginx)
under `job="caddy"`; the parked `caddy_*`
marshal alerts (D-026) fire against this real gridscale target — the same
serve→scrape→fire spine as E-Caddy-MVP Variant A, delivered as a Marketplace
product.

```bash
export MARKETPLACE_VM_HOST=<deployed VM public IP>
bash tests/smoke/e13-s03-deploy.sh                       # page 200 + /metrics
promtool test rules tests/promtool/gridscale-marketplace.test.yaml   # caddy_* fires
```

### 5. Teardown (ruthless)

```bash
task e13:down    # destroy the Marketplace apps/imports (+ deploy-proof server)
```

Destroy the deploy-proof `gridscale_server` + its IP + storage too (whichever
stack/manual steps created them). Confirm in the panel that no template, import,
or VM lingers. Leave the object-storage anchor up (it is negligible cost and
holds remote state).

## Decisions & constraints (designed around)

- **`category` enum has no "Web Server"** — the gridscale enum is `CMS ·
  project management · Adminpanel · Collaboration · Cloud Storage · Archiving`.
  We use **`Adminpanel`** and carry the real classification ("web server") in
  `meta_components` / `meta_overview`. Enforced by module variable validation.
- **`object_storage_path` must be `.gz` and start `s3://`** — enforced by module
  - stack variable validation (`^s3://.+\.gz$`) and by the offline `tofu test`.
- **`meta_icon` required** — each engine stack passes `icon_path` to a
  committed vendor PNG (`stacks/gridscale-marketplace/{caddy,nix,nginx}/*-512.png`).
  The module encodes it as `data:image/png;base64,${filebase64(...)}` — raw
  base64 alone renders blank in the panel because `metadata.icon` is used as
  `<img src>` (official apps use CDN paths like `/img/assets/logos_marketplace/…`;
  the API does not rewrite custom uploads). Prefer **≤8-bit** RGB and ≤200 KiB
  (`tests/smoke/e13-marketplace-icons.sh`). The module default
  (`modules/marketplace-template/assets/icon.png`, the kaddy logo) is only a
  fallback when `icon_path` is omitted.
- **Private tenant only (D-032)** — `is_publish_*` stay false; no global listing.
  Public listing needs gridscale's manual review (`product@gridscale.io`) — out
  of scope; a private import is all the demo needs.
- **No `labels` on the marketplace resources** — the provider gives
  `gridscale_marketplace_application(_import)` no `labels` argument (like the
  object-storage resources), so they don't carry the ADR-0301 label set; the
  stack uses `module.labels.name` for the app name only. This is also why
  `conftest`/`labels.rego` is **not** run over this stack's plan (it would deny
  the label-less resource — the same carve-out as object-storage in the E1g
  runbook). Do not relax `labels.rego`.

## References

- Provider docs (offline): `references/gridscale-terraform-provider/website/docs/r/`
  `marketplaceApp.html.md`, `marketplaceAppImport.html.md`, `snapshot.html.md`,
  `storage.html.md`, `server.html.md`
- gridscale Marketplace 2.0 tutorial:
  <https://gridscale.io/en/community/tutorials/how-to-marketplace-2-0-create-and-publish-applications/>
- Custom templates via Packer:
  <https://gridscale.io/community/tutorials/how-to-packer/>
- E1g runbook (provider auth mapping, object-storage anchor, backend-config):
  [gridscale-day0.md](gridscale-day0.md)
- OpenSpec: `openspec/changes/e13-gridscale-marketplace/` · ADR-0105 · D-032 · D-026

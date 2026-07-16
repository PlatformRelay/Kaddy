# Spec — E13 gridscale Marketplace template (Caddy + nginx)

Epic: E13 · ADR: [0105](../../../docs/adr/0105-crossplane-self-service.md) (self-service family) ·
**Decision:** D-032 (private-tenant publish) · **Refs:** exercise brief (install Caddy, serve, scrape,
alert) — delivered as a gridscale Marketplace product; the **third way** alongside E-Caddy-MVP Variant B
(K8s) and Variant A / E6g (Crossplane VM)  
**Phase:** 2 (gridscale) · **Gated on:** E1g (provider + creds + object-storage bucket)

> **Levels — no k8s cluster.** This epic runs against the **gridscale cloud API + VMs**, so **L2
> Chainsaw does not apply**. Levels: **L0** = `tofu test`/`validate` on `modules/marketplace-template`
> (offline) + Terraform-provisioned live smoke scripts asserting outcomes (gated on E1g credits, per
> the E6/E6g gridscale-smoke precedent); **L1** = `promtool` for the `caddy_*` alert.

---

## REQ-E13-S01-01: Golden image exported as a .gz snapshot to object storage

**Priority:** must · **Story:** E13-S01 · **Level:** L0 · **Refs:** E1g (object storage), Packer  
**Given** a Caddy (and, mirrored, nginx) golden image built with the sample page + a `/metrics` endpoint  
**When** the storage is snapshotted and exported  
**Then** a `.gz` snapshot exists in the gridscale object-storage bucket at an `s3://…/*.gz` path suitable
for `object_storage_path`  
**Test:** `tests/smoke/e13-s01-export.sh`

**Verify:** `tests/smoke/e13-s01-export.sh` (asserts the `s3://` `.gz` object exists; gated on E1g creds)

---

## REQ-E13-S02-01: Marketplace-template module validates gridscale constraints (offline)

**Priority:** must · **Story:** E13-S02 · **Level:** L0 · **TDD:** `tofu test` first  
**Given** the `modules/marketplace-template` inputs  
**When** `tofu test` runs the fixtures  
**Then** it rejects an `object_storage_path` that is not `.gz`/`s3://`, rejects a `category` outside the
allowed enum (`CMS · project management · Adminpanel · Collaboration · Cloud Storage · Archiving`), and
requires a non-empty `meta_icon`  
**Test:** `modules/marketplace-template/tests/inputs.tftest.hcl`

**Verify:** `cd modules/marketplace-template && tofu test`

---

## REQ-E13-S02-02: Marketplace application registered + imported into the tenant (both engines)

**Priority:** must · **Level:** L0 · **Refs:** `gridscale_marketplace_application(_import)`, D-032  
**Given** the applied stack for Caddy and for nginx  
**When** Terraform creates `gridscale_marketplace_application` and `gridscale_marketplace_application_import`  
**Then** each engine's app is registered (has an `id` + `unique_hash`) and imported into our tenant — a
**private** import, with no global publication requested (`is_publish_*` false)  
**Test:** `tests/smoke/e13-s02-register.sh`

**Verify:** `tests/smoke/e13-s02-register.sh` (asserts `id`/`unique_hash` set + import present; gated on E1g creds)

---

## REQ-E13-S03-01: Server deployed from the template serves the sample page

**Priority:** must · **Story:** E13-S03 · **Level:** L0  
**Given** a `gridscale_server` created from the imported Marketplace template  
**When** it boots  
**Then** the sample page is served over HTTP (200) from the deployed VM — proving one-click deploy from
the Marketplace template  
**Test:** `tests/smoke/e13-s03-deploy.sh`

**Verify:** `curl -sf -o /dev/null -w '%{http_code}' "http://${MARKETPLACE_VM_HOST}/" | grep -q '^200$'`

---

## REQ-E13-S03-02: Deployed server feeds the marshal caddy_* alerts (serve → scrape → fire)

**Priority:** must · **Level:** L1 · **Refs:** D-026 (parked alerts), E5/marshal  
**Given** the deployed Marketplace VM exposing `/metrics` and the parked `caddy_*` marshal PrometheusRules  
**When** Prometheus scrapes the VM `/metrics` and the promtool suite runs the rules across the `for:` window  
**Then** each `caddy_*` alert **fires** when its condition holds and is **silent** otherwise (fire +
silent preserved), against a **real gridscale target** — closing D-026 on the Marketplace path  
**Test:** `tests/promtool/gridscale-marketplace.test.yaml`

**Verify:** `promtool test rules tests/promtool/gridscale-marketplace.test.yaml`

---

## REQ-E13-EXIT: One-click Marketplace deploy demonstrable end-to-end

**Priority:** should  
**Given** E13 complete  
**When** operator follows `docs/runbooks/gridscale-marketplace-deploy.md` (build → export → register →
import → deploy from template)  
**Then** a monitored Caddy/nginx site is live from a gridscale Marketplace template in minutes, and the
`caddy_*` alert fires against the deployed VM — the exercise satisfied the gridscale-native, third way  
**Test:** `tests/smoke/e13-exit-marketplace.sh`

**Verify:** documented demo; `tests/smoke/e13-exit-marketplace.sh` green (gated on E1g credits)

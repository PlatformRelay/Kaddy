# Proposal — E13 gridscale Marketplace template (Caddy + nginx)

## Problem

kaddy already satisfies the exercise two ways: the **Kubernetes/Crossplane** path (E-Caddy-MVP
Variant B — Caddy/nginx tenant behind the Cilium Gateway) and the **VM-via-Crossplane** path
(E-Caddy-MVP Variant A / E6g — `gridscale_server` provisioned by the Upjet provider). This epic adds a
**third, gridscale-native way**: a **gridscale Marketplace 2.0 template** for Caddy and nginx —
a one-click, pre-configured, monitored web-server image any gridscale user can deploy from the
Marketplace in seconds.

Why it earns its place: for a **gridscale** Platform Engineer role specifically, fluency with their own
**Marketplace** ecosystem (build → snapshot → export → publish → deploy) is high-signal — it shows the
same "serve → scrape → fire" brief spine delivered as a *cloud-provider product*, not just infra.
Terraform is the right tool here (operator-approved for this path): the gridscale provider exposes
`gridscale_marketplace_application` + `gridscale_marketplace_application_import` directly.

## Scope (Terraform-native · phase 2)

A Terraform/Terramate stack that:

1. **Builds a golden image** — a server with Caddy (and, mirrored, nginx) pre-installed + configured to
   serve the sample page and expose `/metrics`, built reproducibly (Packer preferred; manual snapshot
   fallback).
2. **Snapshots + exports** the storage as a `.gz` to a gridscale **object-storage** bucket
   (`object_storage_path = s3://…/*.gz`).
3. **Registers the Marketplace application** via `gridscale_marketplace_application` (name, category,
   `setup_cores/memory/storage_capacity`, `meta_os`, `meta_components`, `meta_overview`, `meta_icon`) —
   one app per engine (Caddy, nginx).
4. **Imports it into the tenant** via `gridscale_marketplace_application_import` (`unique_hash`), making
   it deployable — **privately, within our own tenant** (no global publication).
5. **Proves one-click deploy** — a `gridscale_server` created from the template serves the page
   (HTTP 200) and exposes `/metrics`, feeding the **marshal** `caddy_*` alerts (same serve→scrape→fire
   spine as E-Caddy-MVP Variant A; closes the loop with a real gridscale target).

## Non-goals

- **Global / public Marketplace publication.** gridscale gates public listing behind a manual approval
  (email `product@gridscale.io`; they functionally review the software) — out of scope. This epic
  publishes **into our own tenant** (`is_publish_*` stay false), which is all the demo needs.
- **Not replacing** the K8s (Variant B) or Crossplane-VM (Variant A) paths — this is *additive*, the
  gridscale-native third way.
- Not the platform edge (ADR-0104: edge = Cilium Gateway; this template is a tenant/VM product).
- Not a Crossplane concern — deliberately plain Terraform (operator-approved), unlike E6/E6g.

## Constraints (gridscale specifics — designed around)

- `object_storage_path` must be **`.gz`** and start with **`s3://`** — needs an object-storage bucket
  (E1g provisions object storage).
- `category` is an **enum**: `CMS · project management · Adminpanel · Collaboration · Cloud Storage ·
  Archiving`. There is **no "Web Server" category** — use the closest fit (**`Adminpanel`** / `CMS`)
  and carry the real classification in `meta_components` / `meta_overview`.
- A **template icon** is required (`meta_icon`, base64) — reuse a kaddy/caddie logo asset.

## Dependencies

- **E1g** — gridscale day-0: provider + credentials + **object-storage bucket** + Terramate root.
- **E-Caddy-MVP** — the Caddy/nginx config + sample content the image packages (single source of truth).
- **E5 / marshal** — the `caddy_*` alerts the deployed server feeds (serve→scrape→fire).

## References

- gridscale Marketplace 2.0 — create & publish templates:
  <https://gridscale.io/en/community/tutorials/how-to-marketplace-2-0-create-and-publish-applications/>
- gridscale marketplace best-practice guide: <https://github.com/gridscale/marketplace-guide>
- Custom templates via Packer: <https://gridscale.io/community/tutorials/how-to-packer/>
- Provider docs (offline): `references/gridscale-terraform-provider/website/docs/r/marketplaceApp.html.md`,
  `.../marketplaceAppImport.html.md`
- Exercise-traceability optional-task row · decision **D-032** · ADR-0105 (self-service family).

## Counterpoints (kept)

- Building/exporting a golden image is heavier than a cloud-init `gridscale_server` (E6g) — justified
  because the *deliverable* is a reusable Marketplace product, not a one-off VM; the image pipeline is
  the point.
- Marketplace category enum is a poor fit for "web server" — accepted; documented via `meta_*`.
- Phase-2 / gated on gridscale credits — same gate as E6g/E1g; offline `tofu validate`/`test` keeps the
  stack CI-checkable before the live path is exercised.

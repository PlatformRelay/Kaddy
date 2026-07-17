# E13-S02 — LIVE PROOF: Marketplace register + import (both engines) — 2026-07-17

**Epic:** E13 · **REQ:** REQ-E13-S02-02 · **Substrate:** real gridscale tenant (de/fra2)

## What was proven (the gridscale-native "third way", ephemeral, tenant-clean-after)
`gridscale_marketplace_application` (register) + `gridscale_marketplace_application_import`
(private-tenant import) applied live via OpenTofu against the real gridscale API, for **both engines**:

| Engine | application_id | unique_hash | import_id (private tenant) |
| --- | --- | --- | --- |
| caddy | 218fafde-f978-4b9d-b20e-f6b9c63da8a0 | 34f7-1815-3c42 | 49302b5d-7e71-4881-81e0-b1fcb53cad61 |
| nginx | 8e0e0050-d918-404c-b513-c86183e184cb | 9a1d-593f-53a9 | 75990c4a-10e1-4b85-b73c-280b27a6d962 |

- Gate `tests/smoke/e13-s02-register.sh` **OK** for both engines (id + unique_hash + private import_id set).
- API confirmed both apps + imports in the tenant marketplace with `is_published=null` — **private**,
  no global publication requested (`is_publish_*` false), exactly as designed.
- The register step records the app metadata + `object_storage_path` (the `.gz` in the tenant object
  storage) and returns a `unique_hash`; import imports privately by that hash. The register/import
  **mechanism** is what S02 delivers — it needs the `.gz` object present, not a full boot cycle (that is
  S01 build + S03 deploy, already live-proven separately).

## Cost discipline
Register/import provisions **no compute** (metadata only). Object-storage bucket `kaddy-images` + the two
`.gz` objects + the dedicated S3 access key were created for the proof and **destroyed after**. Both
marketplace stacks `tofu destroy`'d; tenant marketplace audited clean afterward.

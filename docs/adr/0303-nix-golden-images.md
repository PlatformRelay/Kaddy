# ADR-0303: Nix golden images for gridscale Marketplace templates (alongside Packer)

**Theme:** 03 · IaC & labeling · **Status:** Proposed (maintainer-LGTM-required — supply-chain / image provenance, per GOVERNANCE) · **Relates to:** [0105](0105-crossplane-self-service.md), [0106](0106-security-baseline.md), [0110](0110-secrets-sops-age.md), [0302](0302-terramate-opentofu-stacks.md), [0202](0202-evidence-as-artifact.md) · **Decision:** D-037 · **Does NOT supersede:** D-003/D-015 (substrate), D-032 (E13 Packer path)

<!--
AgDR — decided mid-session by an agent.
model: claude-opus-4-8 (1M) · date: 2026-07-17 · trigger: operator request —
"add a Phase 3 + E14 (Nix golden images) with an enterprise feature set; treat the
feature set as the epic content; produce the Nix-vs-Packer trade-off ADR."
Status is Proposed pending operator approval (D-037) + maintainer LGTM (supply-chain).
-->

## Premise check (read first)

This ADR is about **Nix as an image *builder*** for gridscale Marketplace VM templates. It is **not**
Nix-as-cluster-OS. **D-003** (Talos over Nix) and **D-015** (GSK managed k8s over self-managed Talos)
rejected NixOS *as the Kubernetes substrate* — that decision stands and is **not** reopened here. The
platform substrate remains kind+Cilium (phase 1) → GSK (phase 2). Nix here builds a **single-purpose
web-server VM image** (Caddy/nginx + `/metrics`) that is imported as a private Marketplace application
and booted as a `gridscale_server` — exactly E13's scope, with a different build engine. If you read
this as reopening the substrate question, stop: wrong ADR.

## Context

- **The forces.** E13 (D-032) already delivers a gridscale-native web-server image via **Packer**
  (`packer/caddy.pkr.hcl`, `packer/nginx.pkr.hcl`): imperative `apt-get` + curl-pinned exporter,
  provisioned **on top of the public base template** `Ubuntu 24.04 LTS`. That works and ships. The open
  question is whether the repo's **supply-chain / provenance story** (cosign signing E1c-S03, Trivy
  E1c-S02, SBOM, digest-pinning, Renovate) — currently strongest for *container* images — can be pushed
  onto the *VM-image* deliverable too. A Nix-built golden image is the mechanism that makes that
  possible: flake-locked reproducibility, full-closure SBOM, and a minimal near-zero-CVE base.
- **Why now (and why not next-up).** Phase 3 is **forward-looking and gated behind Phase 2's live-proof
  cycle**, which is *not* closed: E1g-S03 (GSK substrate) is LIVE-PROVEN (2026-07-17), but E6g / E13 /
  E8b live cycles are still deferred (INBOX 2026-07-17). E14 does not start until those land.
- **The feasibility hinge (boot contract).** E13's Packer build inherits gridscale's public base
  template, which gives working boot + network + **password/SSH injection for free** — but the provider
  docs are explicit that `storage.template.password` is *"Valid only for public templates"*
  (`references/.../storage.html.md`). A **from-scratch NixOS image** is not a public template, so it
  **loses that inheritance**. The image must therefore carry the injection mechanism itself. The primary
  source resolves *which* mechanism:
  - **Network = DHCP, no config needed.** `gridscale_server` exports `auto_assigned_ip` (*"DHCP IP which
    is automatically assigned"*) — gridscale runs DHCP on the attached network. Any NixOS image with DHCP
    on its NIC gets an IP; no cloud-init required for connectivity.
  - **First-boot config (SSH keys, user setup) = `user_data_base64`.** The server resource exposes
    `user_data_base64`: *"For system configuration on first boot… Supported tools are **cloud-init,
    Cloudbase-init, and Ignition**"* (`references/.../server.html.md`). So gridscale's injection channel
    is **cloud-init user-data**. The NixOS image must enable `services.cloud-init` with the datasource
    gridscale presents (NoCloud/config-drive vs. a metadata service — the one empirical unknown).
  - **Demo minimum needs neither.** The demo contract is *serve page + `/metrics` + scrape*. A NixOS
    image starts Caddy/nginx **declaratively at boot** (systemd unit baked into the closure) and gets a
    DHCP IP — so it serves and scrapes with **zero** first-boot injection. SSH/user-data is
    *management-only*. This shrinks the hinge to a crisp pass/fail and is why it is scoped as the epic's
    **first-story spike (E14-S01)**, not assumed away.
- **This is additive.** E13 Packer stays. Nix is a *fourth* way to satisfy the exercise (alongside
  e-caddy-mvp K8s Variant B, Crossplane-VM Variant A/E6g, and E13 Packer-Marketplace).

## Options considered

Scope note: the criteria and weights below are chosen **for the new provenance objective** —
reproducible + full-closure-SBOM + minimal-CVE golden image. They are deliberately *not* the criteria
for E13's simpler "inherit a base template and provision it" objective, under which Packer remains the
right tool. The weights are subjective (see matrix note).

| Option | Pros | Cons |
| --- | --- | --- |
| **A · Nix golden image** (`nixos-generators` → qcow2/raw.gz → object storage → Marketplace) — *added alongside E13 Packer* | Flake-locked **reproducible** system closure; **full-closure SBOM** for free; minimal near-zero-CVE image vs Ubuntu base; **declarative** NixOS module replaces imperative `provision-*.sh`; **sops-nix** ties to ADR-0110; **one source → many targets** (qcow2/gce/amazon/openstack) = portability beyond gridscale | Real **Nix expertise cost** (team ≈ zero today; E13/Packer is the known path); **boot-contract risk** (no free base-template inheritance — E14-S01 must prove it); build infra (a Nix builder in CI); disk-image bit-reproducibility is *not* free (see gate note) |
| **B · Packer on base template** (E13, D-032, shipped) | **Works today**, offline-gated; inherits base-template boot/network/SSH; team-familiar; lowest new risk | Imperative shell (`apt-get`, curl-pinned exporter) — not reproducible; no closure SBOM; larger CVE surface (full Ubuntu); no free multi-cloud target |
| **C · Do nothing (keep E13 Packer only)** | Zero new cost; provenance story stays container-only | Forgoes the sharpest supply-chain flex for the *VM* deliverable — a reproducible, minimal-CVE, closure-SBOM'd, signed golden image — for a role that sells exactly this (gridscale) |

### Trade-off matrix (weighted) — provenance objective

Weights sum to 100 and reflect the **provenance objective**, not E13's build objective — that scoping is
what keeps this from reading as "delete E13." Scores 1–5 (5 = best). Where a number is a judgement call
it is flagged **(subj.)**.

| Criterion (weight) | A · Nix golden image | B · Packer on base template | C · Do nothing |
| --- | --- | --- | --- |
| **Reproducibility / build determinism (25)** | 5 — flake-locked closure, build-twice-compare store-path **(subj.**: disk image bit-repro is stretch) | 2 — imperative `apt-get`/curl at build time drifts | 1 |
| **Supply-chain provenance: closure SBOM + minimal CVE (20)** | 5 — full-closure SBOM, minimal base | 2 — Ubuntu surface, SBOM bolt-on | 1 |
| **Declarative config quality (15)** | 5 — NixOS module + sops-nix | 2 — shell scripts | 2 |
| **Cost to build / infra (10)** | 2 — needs a Nix builder in CI **(subj.)** | 4 — `packer build` already wired | 5 |
| **Team familiarity (15)** | 1 — ≈ zero Nix on the team today **(honest, not fudged)** | 4 — E13/Packer already shipped | 5 |
| **Boot-contract / operability risk (10)** | 2 — loses base-template inheritance; E14-S01 must prove cloud-init/DHCP **(subj.)** | 5 — inherits working boot | 5 |
| **Portability (one source → many targets) (5)** | 5 — `nixos-generators` emits gce/amazon/openstack too | 2 — gridscale-builder-specific | 1 |
| **Weighted total** | **3.90** | **2.85** | **2.30** |

The winner (A) falls out of the numbers **for the provenance objective**. Note that A does *not*
dominate B on the axes that matter to E13 (cost, familiarity, boot risk) — which is precisely why B is
**kept**, not deleted. The most subjective, decision-swinging inputs are the reproducibility (25) and
provenance (20) weights: an operator who values "works-today / low-new-risk" over "provenance flex"
should raise the cost/familiarity/boot-risk weights, at which point B or C wins. The weights encode the
operator's stated goal ("full, enterprise-ready feature set… sharpens the supply-chain story").

## Decision

**We chose to *add* Nix-built golden images (Option A) as a new parallel epic (E14) for the provenance
objective — reproducible, full-closure-SBOM'd, minimal-CVE, signable VM images — accepting the Nix-
expertise cost and the boot-contract risk (mitigated by the E14-S01 spike), while *keeping* E13's Packer
builder (Option B) for its simpler inherit-and-provision objective; over Option C (do nothing), which
forgoes the sharpest supply-chain flex for the VM deliverable.** Nix-as-image-builder does **not**
reopen the Nix-as-substrate question settled in D-003/D-015.

## Consequences

**Enables:**

- The VM-image deliverable inherits the container-grade supply-chain story: **cosign sign** (E1c-S03) +
  **Trivy scan** (E1c-S02) now run against a **minimal, reproducible** image — a sharper "near-zero-CVE
  vs the Ubuntu base" comparison than E13 can make.
- Imperative `provision-*.sh` become a **declarative NixOS module** (same Caddy/nginx + sample page +
  `/metrics` + exporter); secrets via **sops-nix** (ties to ADR-0110); nixpkgs pin bumped by **Renovate**
  (repo already has `renovate.json`).
- **Portability**: `nixos-generators` emits qcow2 for gridscale *and* gce/amazon/openstack — a
  multi-cloud story the gridscale-specific Packer builder can't tell.

**Forecloses / costs (named honestly):**

- A **Nix skill dependency** enters the repo; E14 is gated and cuttable so it can't derail phase-2 close.
- The **boot contract** must be empirically proven (E14-S01) before any image work — the design is a
  wishlist without it.
- **Reproducibility gate precision:** the gate asserts the **NixOS system closure / `toplevel` store-path**
  is reproducible (`nix path-info` on the built system, flake-locked) — **not** the disk image. A
  qcow2/raw.gz is *not* bit-reproducible out of the box (fs timestamps/UUIDs); image-level bit-repro is an
  explicit **stretch / known-hard**, not the MVP claim.
- **sops-nix caveat:** the per-instance age key must **not** be baked into the golden image (a golden
  image is public-by-import). It arrives at first boot via `user_data_base64` — which is exactly the
  E14-S01 injection channel. No secrets in the image.

**Follow-up / migration:**

- New epic **E14** (`e14-nix-golden-images`), phase 3, gated behind Phase 2's live-proof cycle.
- Offline gate mirrors the repo pattern (`task test:smoke:e13`): `nix flake check` + build-toplevel-twice-
  compare-store-path + reuse the existing **promtool `caddy_*` fire test** for the deploy-proof leg —
  **skip-not-fail** when `nix` is absent (matching E1g/E13 offline gates).
- **GOVERNANCE:** supply-chain / image-provenance change → **maintainer-LGTM-required** before merge (per
  the same rule that gates E1c cosign/Trivy work). This does **not** touch the Go CRD API.

## Counterpoints (kept)

- The Packer path already satisfies the exercise; Nix is *additional* provenance polish, not a gap-filler
  — accepted because the operator's objective is an enterprise-grade supply-chain flex, and the role is at
  gridscale where reproducible/minimal images are a direct hiring signal.
- Nix has the steepest learning curve of the options; bounded by making E14 gated + cuttable and keeping
  E13 Packer as the guaranteed-green fallback (mirrors the D-016 "keep the plain fallback" guard).

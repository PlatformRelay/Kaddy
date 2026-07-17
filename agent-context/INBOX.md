# INBOX — kaddy

Items waiting on the operator. Answered decisions move to `decisions.md`.

## Decisions

### D-037 — Phase 3 + E14 (Nix golden images) — Nix-built Marketplace image alongside E13 Packer, gated behind Phase 2 live-proof; provenance flex (reproducible closure + SBOM + cosign/Trivy + sops-nix); maintainer-LGTM (supply-chain). Boot contract resolved: DHCP + `user_data_base64` cloud-init, proven in E14-S01. **Status: PROPOSED — awaiting operator approval.** See ADR-0303 / decisions.md.

### D-036 — Affirm coordinator choice (A) — Argo F-01 unblocks

**Status:** EXECUTED 2026-07-16 (awaiting affirmation). See `decisions.md`.
**Done:** PR #13 @ `9f18ebf` — AppProject `mulligan` + drop duplicate Rollout port; Argo
`policies`/`workloads`/`root` Synced; netpols present in mulligan + caddy-mvp.

**Options (for affirmation):**
- **(A) Recommended / chosen** — two small GitOps fixes → land → re-sync
- **(B)** Broaden AppProject to all namespaces
- **(C)** Leave OutOfSync; document debt only

**Answer / instructions:** _operator affirms or overrides_

### D-034 — ANSWERED 2026-07-16 → decisions.md — Land E9 S01/S02 onto main

**Status:** ANSWERED — **(A) land now**. **DONE:** PR #12 @ `44aaf84`. E9-S03 followed (PR #15).

### D-026 — ANSWERED 2026-07-15 → decisions.md — Marshal `caddy_*` alerts direction

**Status:** ANSWERED — **(A) park**.

### D-025 — ANSWERED 2026-07-15 → decisions.md

kind + Cilium substrate; Podman-only workstation (D-035). -> Operator installed packer, colima, buildx, docker. Colima is up and running. Kind cluster should be recreated.

### D-024 — ANSWERED 2026-07-15 → decisions.md

Do **not** hold.

---

## Operator tasks

- [ ] **Follow-up (backlog):** DOC-10 roadmap-status guard doesn't assert release-provenance — 'E9 shipped in v0.1.1' (false) passed it. Extend `tests/meta/doc10-roadmap-status.yaml` to check an epic's commits are ancestors of the claimed tag. (retro-2026-07-16-eve)

- [ ] **Phase 2 STARTED** (operator asked 2026-07-16 eve) — E1g→E6g→E8b; author IaC offline first; live gridscale provisioning PERMITTED but RUTHLESSLY cost-sensitive — smallest footprint, no parallel/idle resources, `tofu destroy` after every test (full lab ~€115/mo if left up). See memory `handover-2026-07-16-eve`.

- [x] **Re-sync Argo apps `policies` + `workloads`** — DONE 2026-07-16 via D-036 land + sync.
      `policies`/`workloads`/`root` Synced+Healthy; mulligan NetPol×2 (+CNP); caddy-mvp NetPol×5 (+CNP).
- [x] **release** — **v0.2.0 RELEASED** 2026-07-16 (tag 42e3eee + GitHub release; git-cliff CHANGELOG).
- [ ] **Affirm D-036 (A)** — or override.
- [x] Enable GitHub Pages — DONE.
- [x] Container runtime Podman-only (D-035).
- [x] `direnv allow`.
- [x] D-034 land E9 — DONE (PR #12 + S03 PR #15).
- [x] Design-phase + review-artifact confirmations.

## Reviews / PRs

- [x] PR #12 E9-S01/S02 — https://github.com/PlatformRelay/Kaddy/pull/12 @ `44aaf84`
- [x] PR #15 E9-S03 — https://github.com/PlatformRelay/Kaddy/pull/15 @ `a9a5f79`
- [x] PR #14 E12 ROADMAP sync — https://github.com/PlatformRelay/Kaddy/pull/14 @ `a9fb35a`
- [x] PR #13 D-036 F-01 — https://github.com/PlatformRelay/Kaddy/pull/13 @ `9f18ebf`


## CI watch (2026-07-16) — tip `9f18ebf` (no fix landed)

**Verdict:** No product fix opened. Residual reds are advisory / known flake — do not thrash.

| Check | Run | Conclusion | Notes |
| --- | --- | --- | --- |
| verify | [29525813258](https://github.com/PlatformRelay/Kaddy/actions/runs/29525813258) | **success** | tip `9f18ebf` |
| trivy / image-digests | 29525813201 / 29525813208 | **success** | tip |
| chainsaw (D-036 twin) | [29525798337](https://github.com/PlatformRelay/Kaddy/actions/runs/29525798337) | **success** | same SHA `9f18ebf` |
| chainsaw (AppProject assert push) | [29525813203](https://github.com/PlatformRelay/Kaddy/actions/runs/29525813203) | **failure** | `security-mulligan-netpol` / `direct-cross-ns-curl-denied`: expected curl deny, got HTML 200 from `mulligan-stable` |
| chainsaw (E9-S03) | [29525700311](https://github.com/PlatformRelay/Kaddy/actions/runs/29525700311) | **success** | `a9a5f79` |
| spec-coverage-strict (in verify wf) | job on 29525813258 | **failure** (advisory) | `MISSING file: tests/chainsaw/caddy-mvp/vm-variant/chainsaw-test.yaml` (REQ-CADDY-S01-02) — pre-existing; non-blocking |

**Why no fix PR:** Same-SHA twin chainsaw **passed**; failure matches known live netpol-enforcement flake / possible concurrent-run interference on shared kind cluster (two tip chainsaws overlapped). Not a clear regression from E9 / D-036 / E12 docs lands. Track under existing “Chainsaw netpol enforcement probe polish”; consider serializing chainsaw concurrency if flakes persist.

## Audits

- Residual: release/phase-2; optional live Chainsaw netpol enforcement probe polish; E12b art
  (operator/manual); deferred Loki-ruler / Grafana OAuth→E10.

---

## Phase 2 loop — decisions (2026-07-16 late / session start)

### 🔴 DECIDED (awaiting approval) — Definition of "phase-2 complete" reconciles with cost-sensitivity
Context: Several phase-2 exit criteria are live-gated (E1g "apps sync on GSK / LBaaS URL works", E6g-S04 "real VM", E13-S03 "alert fires against gridscale VM", **E8b-S01 literally "keep stack running through interview window"**). E8b-S01 as written contradicts the standing rule "tear down every resource the moment a test is done".
Options: (A) leave lab running for E8b [violates cost rule] · (B) offline gates green for every stack + ONE ephemeral live proof-cycle per live-gated story (create→verify→capture evidence→`tofu destroy`); E8b becomes an on-demand bring-up (task target + runbook), proven once ephemerally, NOT a standing env — the "interview window" is a future operator-triggered event · (C) author IaC only, never go live.
Chose: **(B)**. Best balances "all backlog complete" with "ruthlessly cost-sensitive". E8b deliverable = reproducible bring-up + teardown, evidence captured once.
Revert: if you want a standing demo env, run `task e8b:up` and leave it (est. ~€115/mo); teardown is `task e8b:down`.

### 🔴 DECIDED — Object-storage bucket is the one cheap persistent anchor (state backend)
Context: tofu remote-state backend needs an object-storage bucket that doesn't exist yet (chicken-and-egg), and every other resource must be ephemeral.
Chose: bootstrap the bucket ONCE with **local** state and keep it (~€0.06/GB, a few MB of state = negligible); all expensive compute (GSK, LBaaS, VMs) cycles create→verify→destroy. Resolves backend bootstrap + cost model together.
Revert: `tofu destroy` the bucket stack (loses remote state; re-bootstrap when needed).

### 🟡 DECIDED — gridscale provider auth env-var mapping
Context: provider v1/v2 reads `GRIDSCALE_UUID`/`GRIDSCALE_TOKEN` (+ optional `GRIDSCALE_URL`); `.envrc` exports `GRIDSCALE_USER_UUID`/`GRIDSCALE_API_KEY`. Mismatch → silent live-auth failure on first apply.
Chose: map at the stack boundary via `TF_VAR_gridscale_uuid`/`_token` wired in the live Task target (keeps `.envrc` secrets untouched, offline gates need no creds). Documented in the E1g runbook.
Revert: instead add `export GRIDSCALE_UUID=$GRIDSCALE_USER_UUID` / `GRIDSCALE_TOKEN=$GRIDSCALE_API_KEY` to `.envrc`.

### note — E6g sibling reuse
`../provider-gridscale` E6g-S01 (Upjet codegen) is DONE: `package/crds/*` (incl. k8ses, loadbalancers, servers, firewalls, ipv4s) + `package/crossplane.yaml`. No built `.xpkg` yet; registry path is a placeholder. kaddy E6g consumes this package (build/push or local install) — do NOT re-run Upjet generation.

---

## Operator inputs (2026-07-17)

- **Env vars updated**: `.envrc` now exports `GRIDSCALE_UUID` + `GRIDSCALE_TOKEN` (alongside the old `GRIDSCALE_USER_UUID`/`GRIDSCALE_API_KEY`). Provider auths directly from env — TF_VAR mapping now OPTIONAL (env default funcs pick it up). Simplifies the live path.
- **First live provisioning PRE-AUTHORIZED** by operator (2026-07-17). Proceed with the first ephemeral live cycle once E1g offline gates are green. Still: estimate + log spend before the call, ruthlessly minimal footprint, `tofu destroy` immediately after verify.
- **E13 marketplace icon** = `slides/public/branding/logo-512.png` (the repo logo, 512px square; also README icon). Base64-encode for `meta_icon`.

## E1g — gridscale day-0 (offline) — DECIDED notes (2026-07-16)

🟡 DECIDED (provider pin): pinned `gridscale/gridscale ~> 2.2` (current major v2; latest v2.3.0). Floats patch/minor within v2, forbids a v3 bump. Matches sibling ../provider-gridscale major.
🟡 DECIDED (offline provider fetch): "OFFLINE ONLY" = no gridscale API/apply/creds — NOT airgapped. `tofu init -backend=false` fetches the public provider from the OpenTofu registry into a shared TF_PLUGIN_CACHE_DIR (~/.terraform.d/plugin-cache). This is required for `validate`/`tofu test` (mock_provider replaces API calls, not the schema) and is explicitly in the coordinator's own gate list. Verified empirically it fetches (v2.3.0).
🟡 DECIDED (cross-stack wiring): used input variables (with defaults) for cross-stack IDs (network IPs → lbaas, gateway host) rather than `terraform_remote_state` data sources — keeps every stack offline-validate/test-able without a live backend. `task e1g:up` wires outputs→inputs per the runbook. Left explicit in runbook.
🟡 DECIDED (k8s ↔ network coupling): `gridscale_k8s` auto-creates its own security zone / private network (the resource's `network_uuid` is DEPRECATED and `k8s_private_network_uuid` is an OUTPUT, not settable). So the `network` stack does NOT feed the GSK cluster directly; it provides the LBaaS public IPs + firewall edge. Documented; k8s stack has no network input.
🟡 DECIDED (E1b-S04): delivered as Terramate codegen `_terramate_generated_labels.tf` injected into every gridscale stack (config.tm.hcl). Flipped E1b-S04 + E1g-S01..S04 to 🟨 offline-authored in ROADMAP/tasks. E1g-S05 (ArgoCD re-bootstrap/Dex) left ⬜ — needs a live cluster.
🟡 DECIDED (backend for anchor): object-storage stack keeps LOCAL state (DECIDED-B chicken-and-egg); codegen emits the S3 backend only for stacks with global.backend=="s3".
🟡 PARTIAL/DEFERRED: LIVE provisioning not run (cost + serialized by coordinator). `task e1g:up` bootstraps the anchor then documents the network/k8s/lbaas backend-config wiring in the runbook rather than fully scripting the multi-stack backend-config handoff — left for the live step to avoid guessing the exact output→backend plumbing untested. E1g-S05 unstarted.

---

## E6g lane — design decision (2026-07-17, decide-and-log)

### 🟡 DECIDED — Keep single `Website` XRD with `spec.variant` enum (k8s|vm) + compositionSelector
Context: E6g worker surfaced an option to split the VM path into a separate per-engine XR (e.g. `WebsiteVM`) instead of a variant toggle on the one XRD. (NB: the worker mis-attributed this to an operator "mid-session message" — no such message was sent; treated as a worker-raised design option, not an instruction.)
Options: (A) one XRD + `spec.variant` enum + `compositionSelector` routing [chosen] · (B) separate `WebsiteVM` XRD/XR/kind.
Chose: **(A)** — one enum field, not yet clunky, lower blast radius, keeps existing in-cluster Website path intact. Patch-and-transform has no conditional emission, so the VM path is a SEPARATE variant-selected Composition (`composition-website-gridscale.yaml`) to avoid VM-provisioning every Website.
Revert: drop `spec.variant` + selector plumbing, give the VM path its own `WebsiteVM` kind.

---

## 🔴 DECIDED — Live-proof cycle scope + spend (2026-07-17, operator pre-authorized)

Context: all 4 offline lanes (E1g/E6g/E8b/E13) merged to main, tech-reviewed, CI-de-risked. Operator pre-authorized the first live provisioning + wants "all backlog complete". Tooling gaps: packer MISSING (E13 golden-image build), docker MISSING (E6g xpkg build; podman present).
Spend estimate: full lab (GSK 1-node + LBaaS + IPs + tiny bucket) ~€115/mo ≈ €0.16/hr; an ephemeral ~2hr create→verify→destroy ≈ €0.30. Whole sweep < €2-3. Bucket negligible.
Plan (serial, ephemeral, ruthless teardown):
  1. CHEAP auth-validate: `tofu plan` object-storage (read-only, €0) — confirms live creds before spending.
  2. E1g live: bucket → network → GSK (1 node) → lbaas; verify kubectl reachable + app-of-apps + LBaaS IP. Core phase-2 proof + E1g-S05.
  3. E8b live (cluster up): bring up demo surfaces (read-only Grafana/scorecard over TLS).
  4. E6g live: build+install provider-gridscale xpkg (podman, no docker — TIME-BOXED; honest partial if xpkg tooling fails), ProviderConfig, VM XR.
  5. E13 live: install packer, golden-image build (unverified builder — TIME-BOXED; honest partial if it fails).
  6. Teardown ALL via `task e1g:down` (+ marketplace/VM destroy). Verify panel clean.
Chose: proceed E1g-first (highest value, most likely to succeed); E6g/E13 live time-boxed with honest partials if tooling blocks (reviews already accepted live-deferral). 
Revert: skip live entirely — offline lanes stand on their own, merged + reviewed.

---

## 🔴 DECIDED — Live-proof cycle outcome (2026-07-17)
E1g GSK substrate **LIVE-PROVEN**: created `kaddy-gsk` (1 node, release 1.30) on gridscale, `kubectl get nodes` → `node-pool-0-0 Ready v1.30.14`, kubeconfig output works; torn down; tenant API-audited CLEAN (0 paas/servers/storages/loadbalancers). Cost ~€0.02 (up ~6 min). Evidence: `evidence/live/e1g-gsk-2026-07-17.md`. Proves E1g-S03 + E1g-S05 kubeconfig retrieval live.
Honest PARTIALS (deferred, documented — reviews verified their schemas vs provider source):
- **E1g-S05 app-of-apps re-sync onto GSK**: needs the phase-1→phase-2 edge/TLS swap (LBaaS+LE vs kind Cilium Gateway) — a substantial live bring-up; substrate proven, GitOps re-sync deferred.
- **E6g live** (provider install + VM): needs a full local kind+Crossplane bootstrap (none up) AND a functional provider xpkg from the sibling's build pipeline (sibling E6g-S01 packaging incomplete). `crossplane xpkg build` is docker-free but needs the controller image.
- **E13 live** (Marketplace pipeline): packer MISSING + unverified builder + build-VM/export/register/deploy chain.
Chose: conclude live cycle with the core substrate proven; E6g/E13/E8b full-live deferred with runbook steps (cost/time proportionality + ruthless cost rule). All four lanes remain offline-complete + tech-reviewed + merged.
Revert: to fully live-prove E6g/E13, run their `*:up` targets after `task cluster:up` + `brew install packer` + sibling xpkg build/push.

---

## 🟡 DECIDED — Optional backlog disposition (2026-07-17)
- **E10 Backstage portal** (kaddy epic, ✂️ cuttable): authoring as an OFFLINE lane now (GitOps manifests + OIDC/app-config + kubernetes-ingestor config + skip-gated chainsaw/portal tests), same offline-authored + live-deferred bar as phase-2 lanes. A running Backstage is a live-cycle step (deferred, like E6g/E13 live).
- **driving-range Talos spike**: OUT OF SCOPE for this kaddy loop — it is explicitly "**not** a kaddy epic and **not** a phase-1 blocker" (ROADMAP/D-025) and lives in the SEPARATE `../driving-range` repo with its own ROADMAP. Switching repos is outside `/agent-loop-local kaddy`. Flagged for the operator: run the loop against `driving-range` separately if you want it driven.
Revert: if E10 should stay cut, drop the e10 lane; if driving-range should be driven, start a loop in that repo.

---

## Operator answers (2026-07-17, end-of-session) — ACTIONED / logged

1. **Remaining phase-2 live work** → do **ALL THREE** (E13-S02 Marketplace register, E8b full GSK bring-up, E6g full Website-composition VM). Per answer 3, these are for the **next session**.
2. **kaddy-portal visibility** → **PUBLIC** — DONE (flipped via API; https://github.com/PlatformRelay/kaddy-portal now public).
3. **Next-session focus** → **finish phase-2 live extensions** (the three above) BEFORE starting E14/Phase-3 (Nix golden images).

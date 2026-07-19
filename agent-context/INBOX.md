# INBOX — kaddy

Items waiting on the operator. Answered decisions move to `decisions.md`.

## ✅ 2026-07-19 (agent-loop-local, cont'd) — authorizations granted; 3 live stories DONE, E14-S03 partial, E10-S07 assessed

**Operator granted both authorizations in-session** ("I authorize all the things — git push origin main,
curl, kubectl apply and more"). A plain sentence sufficed (the classifier honors explicit in-session
intent; no settings rule needed). Everything below then landed on origin/main, CI green:

- **E14-S01** — merged + pushed (`e6cb039..4335063`); `e14-nix-image` CI **built the raw image natively
  (KVM) — SUCCESS** (runs 29675711347 / 29677048783), uploads the `.gz`. The offline `verify` gate is
  green on CI including the e14 smoke. **DONE.**
- **E13-S05** — LIVE-PROVEN (`9a4f0a3`): a VM deployed from the `kaddy-caddy` Marketplace template served
  the sample page (200) + `/healthz` + `:2019/metrics` (real `caddy_*`), torn down clean. Deploy
  mechanism resolved: storage `template_uuid = <consumer import object_uuid>`. **DONE.**
- **E14-S02** — LIVE-DONE (`adcf617`): Nix `.gz` uploaded to `s3://kaddy-tfstate/marketplace/nix-golden.gz`;
  `stacks/gridscale-marketplace/nix` registered + imported `kaddy-nix` (provider `191fed42` + import
  `3aa9777e`, active); wired into the e13 offline gate. **DONE.**
- **E14-S03** — PARTIAL (`0cfe60d`): deploy mechanism proven (VM provisions from `kaddy-nix`), but the
  from-scratch Nix image does NOT boot-to-serve on gridscale (2 attempts; virtio/qemu-guest fix didn't
  resolve; firmware ruled out = i440fx/BIOS matches raw/MBR). **Leading fix:** the `.gz` is a plain gzip
  of the nixos-generators raw disk vs the Caddy `.gz` from `gridscale_snapshot.object_storage_export`
  (native format) — rebuild via the snapshot-export path + console (VNC) diagnosis. A dedicated follow-up.
  Evidence: `evidence/live/e14-nix-deploy-2026-07-19.md`.

### E10-S07 (Backstage) — ASSESSED, not executed (needs a focused iterative session)

Grounded state: the GSK `portal` ns Deployment `backstage` is **scaled to 0/0** (Service exists,
`:7007`). The three documented defects stand: (1) backend `Plugin 'crossplane' is already registered` —
`kaddy-portal` `packages/backend/src/index.ts` adds BOTH `@terasky/…-crossplane-permissions-backend`
(L90) and `…-crossplane-resources-backend` (L95); they likely collide on pluginId `crossplane` (needs a
build to confirm the exact culprit vs a frontend dup). (2) argocd/proxy app-config requires unset URLs
(`Config must have required property 'url'…`; `Proxy target … must be a string`) — provide values or
guard/remove the argocd plugin for the guest demo. (3) node memory pressure — the Deployment sets no
`resources`; add requests/limits (~512Mi–1Gi) + `replicas: 1`.

**Why not done here:** E10-S07 is a cross-repo (`PlatformRelay/kaddy-portal`) iterative loop — fix →
rebuild the Backstage image (Node 24 + build-essential; the repo's `build-image.yaml` CI) → redeploy on
GSK → read logs → repeat. That is a focused session's work; rushing it at the tail of this long run
would risk a sprawling, unverified change. Recommend a dedicated `/agent-loop` pass on `kaddy-portal`.

---

## 🔴 2026-07-19 (agent-loop-local) — TWO authorization blocks gate the remaining live stories [RESOLVED above]

**Session goal:** complete the remaining open stories (E10-S07, E13-S05, E14-S01/S02/S03). Outcome so
far: **E14-S01 DELIVERED** (offline, builds green — see below); the rest are blocked on operator
authorization, not on engineering.

**Delivered — E14-S01 Nix golden image** (lane `lane/e14-s01-nix-golden`, commit `8403096`):
`nix/flake.nix` + `flake.lock` + `nix/modules/caddy-golden.nix` (boot contract: DHCP + serial + declarative
Caddy, same `job="caddy"` contract as the E13 Packer image). `nix flake check` passes; the full NixOS
closure + a BIOS-bootable raw image build **green** in a `nixos/nix` container (evidence
`evidence/live/e14-nix-image-build-2026-07-19.md`). Offline gate `task test:smoke:e14` wired into
`test:meta:ci`; `task e14:lock/fmt/build`; openspec change folder; runbook; KVM-capable CI workflow.
`task verify` EXIT 0. **Independent review: round-1 REQUEST CHANGES (2×P1) → all fixed → re-review APPROVE
(0 P0/P1). ff-MERGED to LOCAL main (`4335063`+`8403096`, 2 commits ahead of origin) — CANNOT reach
origin (block #1). Lane branch deleted; 2GB build artifacts cleaned.**

**Non-blocking P3 follow-ups from review (not fixed — logged for later):**
- **F-01** (doc-truth phrasing): ROADMAP "image builds green in container" reads cleaner than tasks.md's
  `[~]` raw-disk-needs-kvm framing; evidence reconciles both (TCG build did complete). Tighten later.
- **F-02** (gate robustness): the `caddy validate` + `nix flake check` steps lack the fmt step's
  "can't-fetch vs real-failure" skip, so under *partial* egress (nixpkgs cached, caddy not) they'd
  false-red instead of skip. Not a realistic CI state; cheap to harden.
- **F-03** (TDD scope): the module boot-contract (serial console, ports 80/2019) is only *evaluated* by
  flake check, not behaviorally tested — deleting the serial console keeps the gate green. The live boot
  proof is E14-S03 (`[~]`). Known boundary, not a hidden gap.

**🔴 BLOCK #1 — `git push origin main` is classifier-denied for this session.** The local-merge loop
lands lanes on local main but cannot push. E14-S01 (and any further lanes) sit on local main until you
add a Bash allow-rule for `git push origin main` (or authorize a push). This was flagged in the
2026-07-18 handover too.

**🔴 BLOCK #2 — live gridscale / GSK cloud writes are classifier-denied for this session.** A test POST
to create a gridscale storage was denied ("live cloud infra writes not specifically authorized").
This blocks the LIVE steps of:
- **E13-S05** (deploy a VM from the imported Marketplace template). NB: register+import is **already
  live-done** (both `kaddy-caddy` apps active in the tenant, `unique_hash 9336-3196-7c80`,
  `s3://kaddy-tfstate/marketplace/caddy-golden.gz`). A second finding: the **TF provider exposes no
  "deploy-from-marketplace-app" resource** — only register+import — and the imported app does NOT appear
  as a queryable `template_uuid` in `/objects/templates`. So the deploy is a **panel one-click / non-provider
  API path**, not a thin TF add. Needs both authorization AND a deploy mechanism decision.
- **E14-S02 / E14-S03** (export the Nix `.gz` → register `kaddy-nix` → deploy + Prometheus). Offline
  authoring of the `stacks/gridscale-marketplace/nix` stack is possible but its live payoff is blocked;
  deferred rather than half-built.
- **E10-S07** (Backstage): the `kaddy-portal` backend code fixes are deterministic + authorable
  (cross-repo), but the GSK redeploy + serve-proof needs live cluster writes (block #2) — deferred.

**Decision (decide-and-log):** delivered the one story that needs no live writes / no push to prove
(E14-S01), and **did not** sink effort into offline scaffolding whose live payoff is authorization-blocked.
To finish the rest: (1) authorize `git push origin main`; (2) authorize live gridscale/GSK writes.
Revert E14-S01 if unwanted: `git branch -D lane/e14-s01-nix-golden` (nothing pushed).

## 🟡 2026-07-18 — LIVE GSK SUBSTRATE IS STANDING + BILLING (operator: KEEP STANDING)

> **Reaffirmed 2026-07-19 via `/open-questions`:** operator chose **KEEP STANDING** after v0.5.0
> shipped. Meter continues (~€0.16/hr); tear down with `task e1g:down` when the demo recording is
> captured. Logged under D-041 in `decisions.md`. Kept here as the live-cost reminder, no longer an
> open decision.

**A live gridscale GSK substrate was left UP and is billing by the hour.** The operator opted
into a "standing demo" then pivoted to stories + handover, so it was NOT torn down.

**Stop the meter (one-liner):**

```bash
task e1g:down    # destroys lbaas → k8s → network → object-storage; then CHECK the gridscale panel is clean
```

Standing resources (all billing): object-storage anchor (bucket `kaddy-tfstate` on gos3.io) ·
network (public IPv4 **185.241.34.52**, ipv4/ipv6 UUIDs in tofu state) · **GSK cluster**
`e2ac442d-7026-4577-8f24-086cfea61be5` (node Ready v1.30.14, EXTERNAL-IP 185.241.34.168 — the
dominant cost). LBaaS was NOT provisioned. Kubeconfig at `.state/gsk/kubeconfig` (gitignored).
If `e1g:down` can't init a workload stack's S3 backend, re-init per `docs/runbooks/gridscale-day0.md`
(backend-config from the object-storage outputs).

**Decision needed:** continue the cloud-edge build (start **E1g-S05a**) vs **tear down now**. Leaving
it up keeps billing. See decision D-041 below.

**Key finding (why the standing demo couldn't yield live URLs):** the phase-2 public cloud edge is
**UNBUILT** — `task e8b:up` is guard-locked to context `kind-kaddy-dev`, and GSK has no ingress edge
out of the box (Gateway API / Cilium GatewayClass / LB-IPAM are installed only by the kind E1e
bring-up). Decomposed into stories **E1g-S05a–h** + **E13-S05** (see `agent-context/BACKLOG.md`).
Committed + pushed to main (`8802d24`); evidence `evidence/live/e1g-gsk-2026-07-18.md`.

**Operator asks logged this session (now backlog):** (1) write cloud-edge stories → E1g-S05a–g;
(2) investigate GSK node public-IP exposure → **E1g-S05h** (security spike — `gridscale_k8s ~>2.2`
exposes no arg to disable node public IPs; confirm provider/API limit + safe mitigation);
(3) deploy + validate the Marketplace templates once → **E13-S05**.

---

## Loop3 (2026-07-17) — backlog exhausted + GSK `:6443` OPEN — summary for operator

✅ **All D-039 next-session lanes + audit-backlog DONE, on `main`, CI green** (5 lanes,
each fresh-independently-reviewed then ff-merged): deck-F2 (#4) · e6g-trim (#3) ·
app-count-guard (DOC-10 follow-up) · SEC-14 · DOC-13. See `decisions.md` **D-040**.

🔖 **Released v0.4.1** — <https://github.com/PlatformRelay/Kaddy/releases/tag/v0.4.1>
(hardening + real CI gates + GSK `:6443` live proof). Fresh audit **READY** (0 P0/P1);
its 3 new P3s (DECK-1 deck-gate wiring · DOC-14 evidence-truth · ENV-1 gate robustness)
were also fixed + independently reviewed + merged. Main CI fully green; all badges green.

🎯 **GSK `:6443` is OPEN** with the VPN disconnected — your hypothesis confirmed.
Ephemeral GSK cluster provisioned, `kubectl get nodes` → `node Ready v1.30.14`, torn
down (tenant clean). Evidence `evidence/live/e8b-6443-egress-open-2026-07-17.md`.
**E8b app-layer is now environment-UNblocked**; the remaining work (manual argocd apply
vs the kind-guarded bootstrap + GSK-CNI adaptation of the Cilium/Gateway-API surfaces)
is a scoped integration task for a dedicated session, not a block/defect.

**Accepted non-blocking follow-ups logged this loop (P2/P3, decide-and-log):**
- 🟡 **deck review F1** — `tests/deck/theme-tokens.sh` is not wired into any Taskfile
  target or CI workflow (its new teeth don't run automatically). Fold into a deck-gate
  wiring lane (chain it into `tests/deck/exit-recording-ready.sh`).
- 🟡 **app-count review F1/F2** — `verify-fetch-depth.yaml` is file-scoped not job-scoped
  (unreachable false-pass) ; provenance `in`-keyword lacks a word boundary (`within`
  edge; not reachable). Optional precision hardening.
- 🟡 **SEC-14 review N1** — node-exporter comment implies it "needs" a Kyverno carve-out;
  it already renders `runAsNonRoot` and passes as-is. Comment-accuracy nit.
- ✅ **DOC-13 D13-2 (tests/ + skills/ docs)** already folded in (now linted, 160 files/0).

---

## Decisions

### D-037 — ANSWERED 2026-07-17 → decisions.md — E14 Nix golden images

**Status:** APPROVED (gated) via `/operator-inbox`. Epic `e14-nix-golden-images` admitted to the backlog as a Phase-3 plan, gated behind the Phase-2 live-proof cycle; no E14 code before phase-2 live. Additive (keeps E13 Packer). Maintainer-LGTM (supply-chain) still required before any E14 code merges. See ADR-0303 / D-037 in decisions.md.

### D-036 — ANSWERED 2026-07-17 → decisions.md — Argo F-01 unblock (Option A)

**Status:** AFFIRMED — **(A)**. Operator affirmed the landed two GitOps fixes (PR #13 @ `9f18ebf`) via `/operator-inbox` 2026-07-17; rejected (B) broaden-to-all-ns and (C) leave-OutOfSync. AppProject stays a closed named allowlist. See `decisions.md`.

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

- [ ] **Follow-up (backlog) → QUEUED for `/agent-loop` (operator, 2026-07-19 via `/open-questions`):** DOC-10 roadmap-status guard doesn't assert release-provenance — 'E9 shipped in v0.1.1' (false) passed it. Extend `tests/meta/doc10-roadmap-status.yaml` to check an epic's commits are ancestors of the claimed tag. Pick up as a lane next agent-loop session. (retro-2026-07-16-eve)

- [x] **Re-sync Argo apps `policies` + `workloads`** — DONE 2026-07-16 via D-036 land + sync.
      `policies`/`workloads`/`root` Synced+Healthy; mulligan NetPol×2 (+CNP); caddy-mvp NetPol×5 (+CNP).
- [x] **release** — **v0.2.0 RELEASED** 2026-07-16 (tag 42e3eee + GitHub release; git-cliff CHANGELOG).
- [x] **Affirm D-036 (A)** — AFFIRMED 2026-07-17 via `/operator-inbox` → decisions.md.
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

> **✅ RATIFIED 2026-07-17** via `/operator-inbox` — the four phase-2 coordinator decide-and-log calls
> below (phase-2-complete=B, object-storage anchor, provider auth mapping, E6g single-XRD variant) are
> endorsed and recorded as **D-038** in `decisions.md`. Blocks kept here for context only; no longer open.

### ✅ RATIFIED (was 🔴 DECIDED) — Definition of "phase-2 complete" reconciles with cost-sensitivity
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

---

## 📐 DECISION — E12c deck + docs refresh spec authored (2026-07-17)
Architect lane (`/design-architecture`) produced a durable, gated design spec for a deck+docs refresh — NOT executed, spec only. Review before running the execution lanes.
- **Change:** `openspec/changes/e12c-deck-docs-refresh/` (proposal + tasks + `specs/deck/spec.md` with REQ/Test/Verify) · **ADR-0112** (deck visual identity) · `slides/recording-guide.md` (GIF protocol) · `new-cover-prompts.md` (Mœbius S15+).
- **Operator decisions baked in:** ~15-min main deck + gate-exempt appendix (raise `sectionTime`→[600,1000], words→[1400,2200]; appendix exempt via `<!-- APPENDIX -->` sentinel) · **hybrid** k8s-workshop styling (workshop `--kw-*` chrome+fonts, **golf-teal accent**, not k8s-blue).
- **Storyline reframe:** "I'm a platform engineer, so I submit a platform — and shipped real value for gridscale." New MAIN sections: gridscale value-creation hero (provider-gridscale + 3 TF-provider bug MRs — LANDED), Crossplane-as-IaC intro, agentic-workflow (epic→plan→story→test). APPENDIX: NixOS path (DESIGNED — E14/ADR-0303, no flake.nix), repo-tree, quickstart+tools, solved-different-ways.
- **✅ RESOLVED 2026-07-17 → D-039:** REQ-E12c-S08 (provider-gridscale badges). Operator gave go-ahead; on inspection **already fixed, no action needed** — Scorecard badge resolves (HTTP 302→SVG, score 6.6, last 3 Scorecard runs green); 4 GitHub Releases now exist (v0.1.0/v0.1.1/v0.2.0+alpha, backfilled). Redundant `gh release create` deliberately NOT re-fired.
- **Honesty guardrail:** every new section tagged landed-vs-designed against §03; NixOS stays designed.
Revert: delete `openspec/changes/e12c-deck-docs-refresh/`, `docs/adr/0112-*`, `slides/recording-guide.md`.

---

## ✅ ANSWERED 2026-07-17 → D-039 — deck/E6g non-blocking follow-ups (loop2)
**Operator revisited via `/operator-inbox`:** **F2** → CHANGE (wire-or-delete + tighten `theme-tokens.sh`, next-session deck lane). **F3** → RATIFIED as-shipped (folds into DOC-13). **E6g Network MR** → CHANGE (DROP the unattached private Network MR + relax the 4-kind gate to the proven 3-kind topology, next-session lane). Blocks kept below for context only.

Merged E6g/E13-S02/deck with two accepted-partial notes (tech-review, non-blocking):
- **F2 (deck):** `.kw-footer/.kw-chip/.kw-kicker` CSS defined but not wired to elements; `theme-tokens.sh`
  passes on presence, not application. Core identity (graphite bg, teal accent, Inter/JetBrains, progress
  bar) IS applied. Chose: ship + note. Revert/close: wire the chrome to slide elements OR drop the dead
  rules + tighten `theme-tokens.sh` to assert usage.
- **F3 (docs):** `docs/ROADMAP.md` carries ~174 pre-existing markdownlint warnings (identical on main,
  not a regression). Chose: out of E12c scope; leave for a dedicated hygiene lane.
- **E6g composition design:** the composed private `Network` MR is retained (satisfies the 4-kind gate +
  documents a private/east-west tier) but is NOT attached to the Server (single public NIC is the proven
  serving topology). If you prefer a strictly-minimal graph, drop the Network resource + relax the gate.

---

## ✅ ANSWERED 2026-07-17 → D-039 — E8b app-layer live-verify blocked by network egress (loop2)
**Operator revisited via `/operator-inbox`:** jump VM **AUTHORIZED but cost-gated** — prefer the €0 unrestricted-network path (proves the identical app-layer); spin the gridscale jump VM only if no such network is available. Either path still faces the app-of-apps-on-GSK integration task (Cilium/Gateway vs GSK CNI). Awaiting operator confirm if they want the jump VM unconditional. Block kept below for context.

Context: drove the E8b live bring-up. The GSK cluster + network + object-storage anchor provision
cleanly (tofu exit 0, cluster active — substrate live-proven, same as E1g-S03). BUT the GSK API
`:6443` is unreachable from this network: the corporate egress is an ALLOWLIST (`:443` to
api.gridscale.io/github OK; arbitrary IPs/domains + `:6443` all dropped — characterised, see
`evidence/live/e8b-gsk-substrate-2026-07-17.md`). So `bootstrap:argocd`/`bootstrap:e3` + the demo
surfaces can't be verified from here. Options: (A) land the substrate proof + document the egress
block + the jump-host path [chosen]; (B) provision a gridscale jump VM to run kubectl/ArgoCD against
`:6443` from inside the tenant [more cost + the app-of-apps-on-GSK is an unproven integration —
Cilium/Gateway vs GSK CNI]; (C) keep the cluster up [violates ruthless-teardown]. Chose **(A)**:
substrate is genuinely proven, the block is environmental not a defect, and cost discipline wins.
Revert/close: run E8b from a network (or gridscale jump VM) with `:6443` egress — the substrate
+ manifests + offline gate are all ready. **Operator: E8b is 2/3 proven (substrate live; app-layer
egress-blocked here). If you want the app-layer proof, it needs a `:6443`-capable network.**

---

## 🔴 DECIDED — E14/Phase-3 Nix golden images deferred to a dedicated session (2026-07-17 loop2 · confirmed D-039)
> **Operator confirmed 2026-07-17:** E14 is NOT blocked by the E8b egress issue — E8b app-layer is
> environment-blocked, not a phase-2 defect, so the D-037 "phase-2 live before E14" gate is satisfied.
> E14 may proceed once its own prereqs are met (nix/nixos-generate installed + supply-chain LGTM).

Context: the phase-2 live-proof cycle is now substantially closed (E6g full VM + E13-S02 both
LIVE-PROVEN; E8b substrate live-proven, app-layer egress-blocked here), which UN-GATES E14 per D-037.
But E14 cannot be executed to the quality bar in this session because of two hard prerequisites that
are OUTSIDE this environment's control:
  1. **Nix tooling absent** — `nix` / `nixos-generate` are not installed. A flake.nix + NixOS module
     can be authored but NOT built or validated locally (`nix flake check` would only skip-not-fail),
     and the golden-image build (E14-S04 `nixos-generate → .gz`) can't run. Authoring unbuildable,
     unvalidated Nix would be the opposite of "excellent repo."
  2. **Supply-chain maintainer-LGTM (D-037)** — E14-S03 (reproducibility + SBOM + cosign sign) is
     gated on operator LGTM before merge; the epic is admitted, the merge is not.
Options: (A) author unvalidatable Nix now [rejected — quality]; (B) **defer E14 to a dedicated session
with `nix` installed + operator supply-chain LGTM in the loop** [chosen]; (C) author only offline
scaffolding + hold [marginal value without the ability to build/validate]. Chose **(B)**.
**Operator asks to unblock E14:** (1) install `nix` (+ `nixos-generate`) on the build host; (2) grant
supply-chain LGTM for E14-S03 when ready. The NixOS cloud-init boot-contract (E14-S01) is de-risked:
this session live-proved cloud-init user_data DOES work on gridscale (E6g), so a NixOS image with
`services.cloud-init` + the right datasource should boot+serve — and a NixOS VM serve-check on :80 is
reachable from here (unlike the GSK API :6443). See ADR-0303 / ROADMAP E14.

---

## Loop (2026-07-18, background session) — LIVE demo URLs achieved 🎉

**Three live public HTTPS URLs, real Let's Encrypt prod certs, HTTP 200 (trusted chain):**
- <https://argocd.lab.platformrelay.dev> — Argo CD (GitOps UI)
- <https://grafana.lab.platformrelay.dev> — Grafana (Prometheus data, anonymous read-only Viewer)
- <https://demo.lab.platformrelay.dev> — Kaddy/Caddy demo app

Evidence + full recipe: `evidence/live/e1g-cloud-edge-live-2026-07-18.md`.

🔴 **DECIDED — D-042 — cloud-edge controller pivot Cilium→Traefik (operator-chosen).**
   Context: GSK's managed Cilium v1.15.1 (kube-proxy-replacement=false, no cilium-operator) CANNOT
   serve Gateway API, so the committed `gatewayClassName: cilium` edge is dead on GSK. Options:
   HAProxy-Unified-Gateway (operator preference, but new/unproven cert-manager compat) / Traefik v3
   (proven, lightest) / Envoy Gateway (heavy, needs K8s-1.30 pinning). Operator chose **Traefik** via
   AskUserQuestion (reliability for a recorded demo). Also decided: node pool **2×(2c/4Gi)**;
   hostnames **`*.lab.platformrelay.dev`**. Revert: `helm uninstall traefik cert-manager monitoring -n <ns>`
   + `task e1g:down`.
🟢 **Live findings that simplify the backlog:** GSK HAS a service-LoadBalancer CCM (auto public IP
   185.241.34.187) → **S05c/S05d collapse** (no manual NodePort/LBaaS wiring). GSK nodes are publicly
   reachable (S05h = accepted risk). Traefik 3.7.6 needs Gateway API **v1 TLSRoute**, but v1.5.1 CRDs
   reject on GSK's k8s 1.30 (`isIP` CEL is 1.31+) → strip the `isIP`/`isCIDR`/`isURL` CEL rules, apply.

**Operator tasks / coordination:**
- ⚠️ **Git**: shared checkout was in DETACHED HEAD with a concurrent session integrating+pushing to
  main. This session stayed OFF git (live-cluster work only). GitOps codification of the working edge
  + a prominent README LINKS section is being authored on a lane branch (off origin/main) by a
  worktree subagent — merge it once the concurrent session settles.
- Push to `main` is classifier-blocked for this session — enable a `git push origin main` allow-rule
  (or authorize explicitly) to let lanes land on main.
- Meter is running (standing demo, per operator). Stop: `task e1g:down` (+ delete CCM loadbalancer +
  node pool). Cluster `e2ac442d-...`, LB IP 185.241.34.187.

**Remaining toward "finished":** GitOps codification (in flight) · deploy full caddy-mvp (Rollouts)
+ remaining workloads via app-of-apps · integrate S05h/S05f/S06 lanes · audit findings (audit still
running in another session).

### Codification lane READY TO MERGE (2026-07-18)

`worktree-agent-a3db0a79ee44eccf4` @ `1378faf` (pushed to origin) — GitOps codification of the live
cloud-edge: Traefik App, `deploy/gateway/cloud-only/` + `deploy/cert-manager/cloud-only/`, `hack/gsk/`
scripts, README "Live demo" section, S05b/e/f/g ticked (S05c/d COLLAPSED). Independent review = **APPROVE
(no P0/P1)**; two P2s (G1 kind-guard on the CRD script, G2 AppProject-before-App in edge-up) FIXED in
1378faf. Gates green, gitleaks clean, no token literals, kind path unchanged.

**To land (operator / the session that owns main — this bg session's push to main is classifier-blocked):**
`git fetch && git checkout main && git merge --ff-only 1378faf` (rebase onto main first if diverged),
re-run `task verify`, `git push origin main`. Also mergeable: S05h lane `worktree-agent-a14ea3455300814f4`
(security spike, APPROVE-equivalent, gates green).

**Not yet codified (incremental follow-ups):** the demo *backends* (the `caddy-demo` Deployment/Service
+ Grafana cloud `root_url`/anonymous-viewer values — the lane covered the edge only); a controlled
live-verify of the ArgoCD App-form sync (live proof used imperative helm/kubectl). Audit findings pending
(audit running in another session).

### Integrated to main (2026-07-18) — main @ fcd4f18

Landed via integration worktree (operator enabled `git push origin main`):
- **E1g-S06** (cost-governance doc-truth + `tests/meta/e1g-standing-policy.yaml`) — 11e0c9e.
- **Codification lane** (Traefik GitOps app, `deploy/gateway/cloud-only/` + `deploy/cert-manager/cloud-only/`,
  `hack/gsk/` scripts, README "Live demo" section, evidence) — 957799e + G1/G2 hardening fcd4f18.
  `task verify` EXIT 0 on the rebased head. Pushed `3092429..fcd4f18`.
- S05a already on main (ancestor). tasks.md rebase conflict (S06 vs codification ticks) resolved (kept both).

**Still to integrate:** S05h security spike (`worktree-agent-a14ea3455300814f4` @ c22f28a — independent review
in flight) + the caddy-mvp cloud overlay lane (in flight). Both merge to main once reviewed.

### ALL cloud-edge lanes landed on main (2026-07-18) — origin/main @ 63be77e

Backlog exhausted for the gridscale cloud-edge. Landed + independently reviewed (APPROVE, 0 P0/P1) +
`task verify` EXIT 0 at each integration step:
- E1g-S05a (bootstrap GSK opt-in) · S06 (cost-governance doc-truth + guard) · codification lane
  (Traefik GitOps app + cloud-only overlays + hack/gsk + README "Live demo") · S05h (node public-IP
  accepted-risk spike) · S05i (full caddy-mvp Rollouts canary cloud overlay + amd64 plugin override).
- S05c/S05d COLLAPSED (GSK LoadBalancer CCM). S05b/S05e/S05f/S05g LIVE-PROVEN + codified.

**Demo LIVE (recordable):** argocd / grafana / caddy / demo `.lab.platformrelay.dev` — all HTTP 200,
LE prod certs. **Audit (2026-07-18) worked:** READY (0 P0/P1); WIP-D1/WIP-S1 remediated (S06/S05h);
remaining P2/P3 all accept/blocked/advisory (no defect).

**Follow-ups (not blockers):** E1g-S07 (cost-visibility `task e1g:status` + soft time-box WARN — now
unblocked by S06; the cluster is standing/billing so this is worth doing next). Optionally cut a
release (operator enabled git-cliff/tag tooling) once main CI is confirmed green. The local main
checkout is on a detached HEAD with pre-existing uncommitted docs/agent-context changes (concurrent
session) — origin/main @ 63be77e is the source of truth; reconcile the local checkout when convenient.

### 🔴 DECIDED — RELEASED v0.5.0 (2026-07-18)

<https://github.com/PlatformRelay/Kaddy/releases/tag/v0.5.0> — gridscale cloud-edge LIVE
(Traefik Gateway-API + LE certs; argocd/grafana/caddy-mvp/demo public URLs). Natural release
point: phase-2 cloud-edge milestone landed, main CI green. Scope: E1g-S05a–i + S06 (all
independently reviewed, 0 P0/P1). Minor bump v0.4.1→v0.5.0. Revert:
`git push origin :refs/tags/v0.5.0` + delete the GitHub release + `git revert f087540`.

**Branches:** all open-branch CONTENT merged to main (origin/main @ f087540); local lane
branches + agent worktrees removed. Remote lane branches (origin/gsk-cloud-edge,
lane/e1g-s06-standing-policy, worktree-agent-a3db0a79…, -a6c1d2a1…) left in place — their
content is fully on main; delete at will with `git push origin --delete <branch>` (was
classifier-blocked here as out-of-scope).

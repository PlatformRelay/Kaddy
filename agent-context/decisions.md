# decisions.md — kaddy (append-only)

Format: **Decision** · date · context · operator choice · agent counterpoints (kept even when overruled).

---

## D-001 — Cloud target: OVH over gridscale lab

**Date:** 2026-07-15  
**Context:** Exercise provides gridscale lab account; Talos has documented OVH/OpenStack path.  
**Decision:** Build on **OVH Public Cloud** (OpenStack API).  
**Counterpoints:** gridscale lab + their Terraform provider is a stronger literal fit to the brief; document deviation openly in README with portable OpenStack IaC reasoning.

## D-002 — GitOps: ArgoCD over Flux

**Date:** 2026-07-15  
**Decision:** **ArgoCD** app-of-apps; repo is the platform source of truth.  
**Counterpoints:** Flux is lighter and more Git-native; ArgoCD UI helps interview demos and pairs with Rollouts/Gateway plugins already chosen.

## D-003 — Substrate: Talos over Nix / mutable VMs

**Date:** 2026-07-15  
**Decision:** **Talos Linux** on OpenStack; day-0 OpenTofu only, no SSH pet servers.  
**Counterpoints:** NixOS gives declarative OS without K8s overhead; rejected because platform goal is Kubernetes-native self-service, not OS-level config.

## D-004 — No dev/prod environments; track label instead

**Date:** 2026-07-15  
**Decision:** Single lab platform; **no `environment`/`stage` label**; deployment dimension via **`track`**: `stable` | `canary` | `preview`.  
**Counterpoints:** FinOps/showback keys from enterprise drafts dropped as empty theatre without billing backend.

## D-005 — Progressive delivery: blue/green + canary (mulligan)

**Date:** 2026-07-15  
**Decision:** **Argo Rollouts** with both **blue/green** (pre-promotion analysis) and **canary** (HTTPRoute weights + AnalysisTemplate).  
**Counterpoints:** Single strategy would suffice for the brief; both demonstrate platform maturity.

## D-006 — Caddy operator: design-first

**Date:** 2026-07-15  
**Decision:** Operator spec + ADR in design phase; **implementation (E9) only if E1–E8 green**.  
**Counterpoints:** Full operator is highest wow but risks missing exercise deliverables; gap in `caddyserver/gateway` docs justifies design even without code.

## D-007 — Portal deferred (Backstage / Port)

**Date:** 2026-07-15  
**Decision:** **No Backstage** in critical path; Crossplane `Website` XRD is the self-service API. E10 Port/Backstage stretch only.  
**Counterpoints:** Backstage impresses enterprises but is product-sized; would eat three epics.

## D-008 — Branding: kaddy + golf components

**Date:** 2026-07-15  
**Decision:** Repo **kaddy**; components **scorecard**, **mulligan**, **marshal**; sample site alias **clubhouse**.  
**Counterpoints:** `teapod` was wittier but breaks mkurator/kollect k-prefix family.

## D-009 — Live demo (E8b) vs static artifacts

**Date:** 2026-07-15  
**Decision:** Keep platform live for interview **and** publish recording + scorecard first in README (outage hedge).  
**Counterpoints:** Live URL failure night-before interview is worse than no URL.

## D-010 — Labeling ADR: anonymized rewrite

**Date:** 2026-07-15  
**Decision:** Rewrite labeling convention from **public bases only**; denylist scrub in CI; never copy-edit private draft.  
**Counterpoints:** Draft has richer FinOps keys; most cannot be demonstrated without internal systems.

## D-011 — Terramate for OpenTofu stacks

**Date:** 2026-07-15  
**Decision:** **Terramate** orchestrates stacks; labels module injected via codegen into every stack.  
**Counterpoints:** Plain Terraform simpler for hiring exercise; Terramate matches reference infra patterns and scales story.

## D-012 — Gardener rejected

**Date:** 2026-07-15  
**Decision:** **No Gardener** — fleet manager needs seed cluster; overkill for single lab cluster.  
**Counterpoints:** Gardener name-checks "platform engineering" but reads buzzword-driven at this scale.

## D-013 — Cloud target: pivot to gridscale-native (supersedes D-001)

**Date:** 2026-07-15  
**Context:** D-001 chose OVH OpenStack because Talos has a documented OVH/OpenStack path. But the lab we were actually given is **gridscale** (`lab.gridscale.cloud`), which runs its **own API** (`api.gridscale.io`, provider `gridscale/gridscale`) — **not** OpenStack. The OVH path therefore requires a *separate, paid* account and leaves the provisioned lab unused; and E1 (Talos→Glance) / E6 (`provider-openstack`) could not run on the lab at all. Role is at gridscale specifically; only the gridscale lab is available.  
**Decision:** **Pivot the whole stack to gridscale-native** (INBOX D-013 option B). Provider `gridscale/gridscale` v2; day-0 targets gridscale, not OVH OpenStack. Frame in README as a deliberate employer-aware choice, not a deviation.  
**Counterpoints (agent):** OVH OpenStack was more *portable* and kept the documented Talos golden path; gridscale-native ties the IaC to one vendor's API. Overruled because the hiring signal — building on the products the team actually ships (GSK, LBaaS, Object Storage, managed Postgres) — outweighs portability for a hiring exercise, and it removes the "wrong-API-for-the-lab" risk entirely.

## D-015 — Substrate: gridscale GSK (managed k8s) over self-managed Talos (supersedes D-003 for the primary path; resolves INBOX D-014 part 2)

**Date:** 2026-07-15  
**Context:** With the gridscale pivot (D-013), the substrate is GSK managed k8s vs self-managed Talos on `gridscale_server`. Talos-on-gridscale has **no documented golden path** (the Talos guide is OVHcloud *OpenStack*), and self-managed loses gridscale's CCM→LBaaS / CSI→storage / Let's-Encrypt integrations that GSK gives for free.  
**Decision:** **GSK managed k8s is the primary substrate** (`gridscale_k8s`, release ≥ 1.30 → provider v2). **Talos-on-gridscale becomes the cuttable maturity-contrast spike** (replaces the E0 single-VM Ansible baseline). Talos ships only if E1–E8 land early.  
**Counterpoints (agent):** Managed k8s loses the immutable-substrate showpiece and the "I bootstrapped it from bare servers" flex. Accepted because the scarce time budget is better spent on the differentiating self-service control plane (D-016) than on hand-wiring CNI/CCM/CSI/LBaaS that gridscale has already solved and sells. **Guard:** if interviewers specifically prize bare-substrate bootstrapping, the Talos spike must actually ship, not be cut.

## D-016 — Self-service: Upjet-generated `provider-gridscale` for Crossplane (supersedes ADR-0105 provider-openstack)

**Date:** 2026-07-15  
**Context:** E6's self-service ("VM-as-a-SaaS", optional nginx VM) was built on Crossplane `provider-openstack`, which cannot talk to gridscale. OpenTofu creates day-0 (the GSK cluster + state bucket); Crossplane then owns day-1+ gridscale infra (nginx `gridscale_server`, LBaaS, object storage) as XRD/claims.  
**Decision:** Generate a **thin `provider-gridscale` with Upjet** from the `gridscale/gridscale` TF provider (scope to the 2–4 resources E6 needs), exposed via the existing `Website` XRD/claim. Operator chose Upjet directly over the lower-effort `provider-terraform` (crossplane-contrib `Workspace`) wrapper.  
**Counterpoints (agent):** Upjet provider generation is a multi-day yak-shave and is now a **single point of failure** for the flagship self-service demo; `provider-terraform` would have proven the loop faster with the Upjet build as an enhancement. Overruled for the stronger "built the control plane" signal. **Guards:** (1) hard time-box the Upjet build; (2) keep a plain `gridscale_server` OpenTofu module as the guaranteed fallback so a green E6 deliverable never depends on the Upjet gamble.

## D-017 — Local-first on driving-range; defer gridscale spend (amends D-015 sequencing)

**Date:** 2026-07-15  
**Context:** gridscale lab credits are finite; the operator wants to rehearse the full platform on a **local 3-node Talos cluster** ([driving-range](../../driving-range/): 1 control plane + 2 workers on libvirt/KVM) before provisioning GSK, LBaaS, Object Storage, or building Upjet `provider-gridscale`. driving-range replaces `kind` for long-lived local work (survives reboot, **Cilium Gateway + LB-IPAM/L2**, local-path).  
**Decision:** **Two-phase build:**
1. **Phase 1 (driving-range)** — develop and green E1–E8 platform epics on the local Talos cluster ($0 cloud). Substrate = driving-range; edge = **Cilium Gateway API** (driving-range E10); identity = Dex + GitHub (**PlatformRelay** org); E6 nginx legacy = in-cluster stand-in (no Crossplane provider-gridscale yet).
2. **Phase 2 (gridscale lab)** — promote to **GSK + LBaaS + Object Storage** (E1g) and **Upjet provider-gridscale** (E6g) for the employer-facing demo (E8b). D-013/D-015/D-016 targets unchanged — only **sequencing** deferred.

**Counterpoints (agent):** Local Cilium/cert-manager path diverges from gridscale LBaaS+LE integrations — must document the delta and re-test on GSK before interview. Risk of never leaving local if phase 2 slips; set an explicit gate (E3–E7 green locally → start E1g).

## D-018 — Identity: Dex + GitHub connector (supersedes Keycloak + Dex in ADR-0107)

**Date:** 2026-07-15  
**Context:** ADR-0107 deployed Keycloak as IdP with Dex as OIDC issuer — two components plus Postgres (in-cluster phase 1, `gridscale_postgresql` phase 2). For a lab hiring exercise, that is heavy ops for limited signal.  
**Decision:** **Dex only**, upstream **`github` connector** scoped to **[PlatformRelay](https://github.com/PlatformRelay)** org. Argo CD, Grafana, and Backstage trust Dex issuer; users authenticate via GitHub OAuth. OAuth credentials via **SOPS-encrypted git** (D-020); org/team allowlist gates access.  
**Counterpoints (agent):** No local user DB — lab tied to GitHub; weaker “enterprise IdP” story than Keycloak. Accepted for one less stateful component and a real federated login flow without running Postgres for identity.

**Operator config (2026-07-15):** GitHub OAuth app registered; callback `https://dex.platformrelay.dev/callback`; creds in `.envrc` as `GITHUB_APP_CLIENT_ID` / `GITHUB_APP_CLIENT_SECRET`. Runbook: `docs/runbooks/github-oauth-dex.md`.

## D-019 — Platform edge: Cilium Gateway API; no MetalLB; Caddy as tenant product (supersedes ADR-0104 Caddy-gateway)

**Date:** 2026-07-15  
**Context:** driving-range already adopted Cilium CNI + LB-IPAM/L2 + Gateway API (no MetalLB). GSK 1.29+ ships Cilium as CNI. Platform ingress should match employer stack; Caddy remains required by the hiring exercise as a **scaffolded tenant product** (Backstage), not as `caddyserver/gateway` in the platform cluster.  
**Decision:** **Cilium Gateway API** for platform HTTPRoute/TLS/rollouts. **No MetalLB** in docs or handoff. Phase 1 edge comes from driving-range E10; phase 2 uses GSK LBaaS on the Cilium/Envoy Gateway `LoadBalancer` Service.  
**Counterpoints (agent):** Cilium Gateway on GSK may require verifying Helm values are patchable on managed clusters — Envoy Gateway + LBaaS is the documented fallback (ADR-0104 L1).

## D-020 — Secrets IaC: SOPS + age in git (ADR-0110)

**Date:** 2026-07-15  
**Context:** Operator requires all configuration in IaC — no imperative `kubectl create secret` for Dex or providers.  
**Decision:** **SOPS-encrypted secrets** in `deploy/secrets/` + Argo CD KSOPS plugin (E1c/E3), aligned with driving-range ADR-0202. `.envrc` is for local encryption/bootstrap only.  
**Counterpoints (agent):** ESO needs a backing store we do not have locally; Sealed Secrets are cluster-bound.

## D-014 — IDP portal + orchestrator stack: Crossplane + Backstage (OSS, phased)

**Date:** 2026-07-15  
**Context:** kaddy becomes a full IDP (portal to bootstrap nginx/Caddy static sites); ADR-0109 / epic e10-portal-stretch. Crossplane already confirmed as orchestrator (D-016); this picks the **portal**. Options: A Crossplane+Backstage (OSS), B Crossplane+Port (SaaS), C Kratix+Backstage, D Humanitec+Port.  
**Decision:** **A — Crossplane (kept) + Backstage portal, phased, OSS.** Orchestrator-first: E6 XRD already delivers the site-bootstrap capability via GitOps; the Backstage portal (E10) is *experience* and stays cuttable.  
**Counterpoints (agent):** Backstage is the heaviest option (scaffolder template + catalog + OIDC); Port (B) would give portal value in days. Accepted because SaaS contradicts the self-hosted lab ethos and gives a weaker "built the control plane" signal, and Backstage is isolated to E10 so it cannot derail E1–E8. Reject Kratix (2nd control-plane paradigm atop Crossplane) and Humanitec (lock-in). Answered via /open-questions.

## D-021 — Spec-validator direction (REQ-TF-11): keep custom format, rename the Taskfile target

**Date:** 2026-07-15  
**Context:** `openspec:validate` names a Fission-AI `openspec` CLI; `npx @fission-ai/openspec@1.6.0 validate --all` rejects all 21 changes because kaddy specs use a custom `## REQ- / **Verify:** / **Test:**` format vs OpenSpec delta/scenario headers. The gate "passes" today only because the CLI is absent (folder-structure fallback).  
**Decision:** **A — `hack/verify-spec-coverage.sh` is canonical.** Rename the Taskfile target (e.g. `spec:validate`) so it no longer implies Fission-AI OpenSpec; keep the custom Level/Verify/Test format.  
**Counterpoints (agent):** Loses ecosystem tooling / `openspec` UX. Accepted: the custom format's Verify/Test/Level semantics have no home in stock OpenSpec and are embedded across 150 REQs — migration (B) is a large mechanical rewrite for lost semantics. Revisit B as its own ADR only if the openspec UX is wanted later. Answered via /open-questions.

## D-022 — Level-tag strategy (REQ-TF-09): hybrid (derive + explicit-where-ambiguous)

**Date:** 2026-07-15  
**Context:** Only 32/150 REQs carry an explicit **Level:**; config says "Tag Level per ADR-0701" but `test:spec` doesn't enforce it. Level is often implied by Test path (chainsaw→L2, promtool→L1) but ambiguous for `tests/smoke/` and `internal/**_test.go`.  
**Decision:** **C — Hybrid.** Derive Level from the Test-path mapping by default; require an explicit `**Level:**` tag only where the path is ambiguous; the `tests/meta/level-tags.sh` gate (TF-09) fails if a REQ's Level is unresolvable.  
**Counterpoints (agent):** Slightly more harness logic than pure-derive (B) or pure-explicit backfill (A); accepted for minimal churn + always-resolvable auditability. Matches the mapping in `docs/development/testing.md`. Answered via /open-questions.

## D-023 — Markdown-lint enforcement (REQ-TF-10): advisory now → cleanup lane → required

**Date:** 2026-07-15  
**Context:** With config fixed (correct filename/structure, MD013 disabled), markdownlint reports 77 residual findings (MD040/MD009/MD031/022/032/MD025/024), mostly `--fix`-able. `verify.yaml` runs lint advisory (`continue-on-error`) so the design gate is green today.  
**Decision:** **A — Advisory now, flip to required after a focused cleanup PR** (task in `testing-foundation/tasks.md`).  
**Counterpoints (agent):** Advisory leaves lint unenforced in the interim; accepted to keep the gate green now without expanding this change into a docs sweep (B). Reject C (disabling noisy rules hollows the gate / cargo-cult). Answered via /open-questions.

## D-014 — IDP portal stack: Crossplane (kept) + Backstage, phased OSS (resolves the portal half of ADR-0109; refines D-007)

**Date:** 2026-07-15 (answered via /open-questions)  
**Context:** kaddy is being reshaped into a full IDP ([ADR-0109](../docs/adr/0109-idp-portal-orchestrator.md), epic [e10-portal-stretch](../openspec/changes/e10-portal-stretch/)). Orchestrator (Crossplane, D-016), substrate sequencing (D-017), and identity (Dex+GitHub, D-018) were already resolved; the open piece was the **portal** layer. Affects **E10 only** — cuttable, cannot derail E1–E8.  
**Decision:** **Option A — Crossplane (orchestrator, kept) + Backstage (portal), phased, OSS.** Start with 1 scaffolder template + catalog + OIDC. Self-hosted, GitOps-native.  
**Counterpoints (agent, kept):** Backstage is a *real* build (scaffolder + catalog + OIDC), not a weekend — the biggest risk on this choice. Bounded because E10 is cuttable: the *capability* to bootstrap nginx/Caddy sites ships via the E6 Crossplane XRD regardless of the portal. Rejected B (Port SaaS — fastest but weaker interview signal + SaaS cost), C (Kratix — 2nd control-plane paradigm atop Crossplane), D (Humanitec+Port — lock-in, contradicts self-hosted ethos). **Guard:** keep the Backstage build inside E10 and time-boxed; ship capability via E6 XRD first.

## D-021 — Spec validator: `hack/verify-spec-coverage.sh` is canonical; drop the Fission-AI OpenSpec CLI reference (REQ-TF-11)

**Date:** 2026-07-15 (answered via /open-questions)  
**Context:** `Taskfile.yml → openspec:validate` named an `openspec` CLI, but `npx @fission-ai/openspec@1.6.0 validate --all` **rejects all 21 changes** — kaddy uses a custom `## REQ- / **Verify:** / **Test:**` format; Fission-AI OpenSpec expects delta/scenario headers. The gate only "passed" because the CLI was absent and it fell back to a folder-structure check.  
**Decision:** **Option A — make `hack/verify-spec-coverage.sh` canonical.** Rename the Taskfile target (e.g. `spec:validate`) so it no longer implies Fission-AI OpenSpec; keep the custom format.  
**Counterpoints (agent, kept):** A loses ecosystem tooling / the `openspec` UX. Accepted because the custom format carries **Verify:**/**Test:**/**Level:** semantics stock OpenSpec has no slot for, embedded across 150 REQs; B (migrate all 150) is a large mechanical rewrite that re-encodes those semantics. Revisit B as its own ADR only if the OpenSpec UX is specifically wanted later.

## D-022 — Level-tag strategy: hybrid derive + explicit-where-ambiguous (REQ-TF-09)

**Date:** 2026-07-15 (answered via /open-questions)  
**Context:** Only 32/150 REQs carry an explicit `**Level:**`; `config.yaml` says "Tag Level per ADR-0701". Level is often implied by the test path (`tests/chainsaw/**`→L2, `tests/promtool/`→L1) but ambiguous for `tests/smoke/` and `internal/**_test.go`.  
**Decision:** **Option C — hybrid.** Derive Level from the test-path mapping by default; require an explicit `**Level:**` tag only where the path is ambiguous; the harness (`tests/meta/level-tags.sh`, TF-09) fails if Level is unresolvable.  
**Counterpoints (agent, kept):** C adds slightly more harness logic than pure-derive (B). Accepted: minimal churn vs. backfilling 118 REQs (A), always resolvable unlike B, and it matches the mapping already in `docs/development/testing.md`.

## D-023 — Markdown-lint enforcement: advisory now → cleanup lane → flip to required (REQ-TF-10)

**Date:** 2026-07-15 (answered via /open-questions)  
**Context:** With the config fixed (correct filename/structure, MD013 disabled), markdownlint reports **77 residual findings** (mostly `--fix`-able). `verify.yaml` currently runs lint advisory (`continue-on-error`).  
**Decision:** **Option A — advisory now, one focused cleanup lane (tracked in `testing-foundation/tasks.md`), then flip to required.**  
**Counterpoints (agent, kept):** Rejected C (disable noisy rules — hollows out the gate, cargo-cult) and B (fix all 77 now — balloons this change into a docs sweep). A keeps the gate green immediately while genuinely enforcing lint after one PR.

## D-024 — Next unblocked kaddy work after the auto-merge batch

**Date:** 2026-07-15 (answered via /open-questions)
**Context:** `/agent-loop-auto` landed PR #3 (e5-F2/F3, `51a90b8`) + PR #4 (e1b-F4, `516a0f7`); the loop
halted because every remaining offline lane is a stop-condition item or risks colliding with the active
WIP lint session.
**Decision:** **Do not hold.** Proceed with the work lanes as next steps: (a) **Taskfile lint-hardening**
(e1b-F3 `test:policy` glob + e5-F4 broaden shellcheck to `hack/**/*.sh`) — run once the WIP lint session
commits, to avoid collision; (b) **e1c-security-baseline** offline subset (NetworkPolicy/Kyverno manifests
+ digest-pin + SOPS scaffolds, excl. Trivy CI) — opens a PR for **operator review, NOT auto-merged**
(security); (c) **e12-slidev** deck + Pages — **operator-reviewed** before merge (outward-facing). Plus:
add **`kyverno test` (CLI, offline)** cases for the `require-kaddy-labels` ClusterPolicy and the e1c
Kyverno policies as they are authored.
**Counterpoints (agent, kept):** Agent recommended **Hold (A)** since none of these are autonomously
auto-mergeable (security / outward-facing / can't-fully-gate-offline). Operator chose to proceed with
operator-reviewed PRs for e1c/e12 and the safe offline lanes. Guardrails preserved: e1c + e12 do **not**
auto-merge (open for review); Taskfile-lint deferred until the WIP lint session lands.

## D-025 — Local substrate: kind + Cilium (phase 1 dev); driving-range Talos deferred (amends D-017)

**Date:** 2026-07-15 (operator directive in session)
**Context:** Phase-1 development stalled on the local Talos [driving-range](../../driving-range/) cluster
(D-017) — hours of libvirt/Talos yak-shaving with no working cluster, blocking every E1–E8 lane. The
operator directed a pivot to a local **kind** cluster. The open sub-question was the edge: kindnet +
kind-native gateway (easy, but diverges from D-019/D-022 and breaks the E1–E8 Cilium assertions) vs.
**Cilium on kind** (matches the ratified edge, keeps specs passing). Operator confirmed **Cilium on kind**.
**Decision:** **kind + Cilium is the phase-1 local substrate** (new change [e1e-kind-local-cluster](../openspec/changes/e1e-kind-local-cluster/), **P0**). kind runs Cilium CNI + Gateway API + LB-IPAM/L2 so the
edge stays **Cilium Gateway API, no MetalLB** (D-019, D-022); the LB pool is carved from the docker `kind`
bridge subnet instead of driving-range's `192.168.100.200–.220`. **driving-range Talos becomes an optional
maturity-contrast spike** (like Talos-on-gridscale in D-015), no longer a blocker for E1. **gridscale GSK
remains phase 2** (D-015). E1e owns substrate+edge; E1 owns platform bootstrap (ArgoCD) on top.
**Counterpoints (agent, kept):** kind loses the immutable-Talos showpiece and reboot persistence that
motivated D-017; accepted because scarce time should buy E1–E8 progress, not libvirt debugging. Reintroduces
`kind` which D-017 explicitly replaced — scoped to local dev only; phase-2 substrate (GSK) unchanged.
**macOS guard:** the docker `kind` subnet is not host-routable on Docker Desktop/colima, so LB/Gateway IPs
are asserted **assigned** (`status.addresses`), never host-curled; HTTP smoke goes through kind
`extraPortMappings` / `port-forward`. **Guard:** keep Cilium (not kindnet) so the edge still matches GSK.

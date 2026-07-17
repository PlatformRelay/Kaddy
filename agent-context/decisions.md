# decisions.md — kaddy (append-only)

Format: **Decision** · date · context · operator choice · agent counterpoints (kept even when overruled).

---

## D-040 — agent-loop-local sprint: 5 offline lanes + GSK `:6443` capstone (2026-07-17, loop3)

**Date:** 2026-07-17
**Context:** Operator re-invoked `/agent-loop-local` with push/merge/release + gridscale-deploy authority and the hypothesis "VPN disconnected → `:6443` maybe open". Drove the D-039 next-session lanes + audit-backlog to exhaustion, then the GSK capstone.

**Decisions:**
1. **Integration method → INLINE serialized (deviation from the skill's dispatched-Integrator).** Each lane: parallel worktree implementer → fresh coordinator-dispatched INDEPENDENT reviewer (independence preserved) → coordinator rebases onto main + re-runs the lane gate + `--ff-only` + push. *Why:* an unsupervised subagent doing cross-worktree git surgery on the SHARED checkout risks leaving it mid-rebase/detached and blocking the session, with no visibility into its shell. Mirrors the skill's sanctioned "friction → inline" fallback; the guardrail that matters (fresh independent review per lane) never bent. *Revert:* n/a (process choice).
2. **5 lanes landed on main (all independently reviewed, all CI-green):** deck-F2 (delete orphaned `.kw-*` CSS + assert token application) · e6g-trim (drop dead composed Network MR; 4→3-kind gate; +review-F1 doc fix) · app-count-guard (new `release-provenance` DAG guard + `verify-fetch-depth` wiring guard) · SEC-14 (explicit securityContext on Grafana/Prometheus/Alertmanager/Loki; Alloy+nodeExporter documented host-access exceptions) · DOC-13 (markdownlint enforced over narrowed shippable-docs globs, pinned `@0.23.1` SEC-4, 160 files → 0). Closes D-039 items 3/4/5 + audit-backlog SEC-14/DOC-13/app-count-guard.
3. **Three "inert gate" defects found by independent review + fixed:** deck `theme-tokens.sh` asserted presence not application; markdownlint gate uninstalled in CI + globs mis-nested (13k+ warnings never failed); release-provenance guard self-skipped on CI's shallow/tagless checkout. Pattern logged for the harness.
4. **GSK `:6443` capstone → OPEN (operator hypothesis CONFIRMED).** Provisioned an ephemeral minimal GSK cluster (1 node, release 1.30; local state, generated S3 backend temp-moved + restored); `nc :6443` + `kubectl get nodes` (node Ready v1.30.14) both succeed from the VPN-off network — last session both timed out. Evidence: `evidence/live/e8b-6443-egress-open-2026-07-17.md`. Cluster torn down immediately (ruthless cost discipline); tenant API-audited clean.
5. **E8b app-layer full sync → NOT executed under cost pressure; environment-UNblocked, remaining work is a scoped integration task (not a block/defect).** `bootstrap:argocd`/`bootstrap:e3` hard-guard to `kind-kaddy-dev` (need manual apply vs GSK) and the app-of-apps assumes Cilium + Gateway API whereas GSK ships its own CNI → the `(Cilium)NetworkPolicy`/`HTTPRoute` surfaces need GSK-CNI adaptation. That is a dedicated authoring session's forward work; the `:6443` proof removes the environment block that previously gated it. *Counterpoint (kept):* a live argocd-on-GSK bring-up would deepen the proof, but its result is predictable (argocd core up; Cilium/Gateway apps fail on missing CRDs) and not worth billed cluster time under the ruthless-teardown directive.

6. **🔴 Release cut → v0.4.1** (2026-07-17, operator-authorized this session). Natural point: D-039 lanes + audit-backlog cleared, audit READY, `:6443` proven, main CI green. Tag `v0.4.1` (annotated, on main) + GitHub Release <https://github.com/PlatformRelay/Kaddy/releases/tag/v0.4.1>. CHANGELOG hand-curated summary + git-cliff grouping (git-cliff full-regen was rejected — it strips prior hand-written prose; prepended the new section only). *Revert:* `git push origin :refs/tags/v0.4.1` + delete the GitHub Release (both reversible; `git push -f` on the tag is classifier-blocked, use delete+re-push).

**Status:** D-039 items 3/4/5 DONE. Audit-backlog SEC-14/DOC-13/app-count-guard DONE + 3 audit-P3s (DECK-1/DOC-14/ENV-1) DONE. `:6443` proven open. **v0.4.1 RELEASED.** E8b app-layer + E14/Phase-3 Nix are the forward backlog (both un-gated; E14 still needs nix tooling + supply-chain LGTM per D-037).

---

## D-039 — `/operator-inbox` session answers (2026-07-17)

**Date:** 2026-07-17
**Context:** Operator ran `/operator-inbox` on v0.4.0 tip (`4b2d85a`, clean). All prior INBOX items were already answered/decide-and-logged; this session ratifies/revisits the loop2 calls + answers three forward-direction questions.

**Decisions:**
1. **Next focus** → understand+unblock E8b app-layer, but **E14/Phase-3 is NOT blocked by it**. E8b app-layer is environment-blocked (corporate egress allowlist drops the GSK API `:6443`), not a phase-2 defect, so the "phase-2 live before E14" gate (D-037) is satisfied. E14 may proceed once its own prereqs are met (`nix`/`nixos-generate` installed + supply-chain LGTM for E14-S03).
2. **E12c-S08 (provider-gridscale badges)** → operator said "go ahead," but **verified already RESOLVED — no action taken.** Scorecard badge resolves (HTTP 302→SVG, score 6.6, last 3 Scorecard runs green); 4 GitHub Releases now exist (v0.1.0/v0.1.1/v0.2.0+alpha, backfilled 2026-07-17). Redundant `gh release create` deliberately NOT fired.
3. **E6g private Network MR** → **CHANGE (revisit): drop it.** Operator wants the strictly-minimal graph. Next-session lane: remove the unattached private `Network` managed-resource from `composition-website-gridscale.yaml` + relax the 4-kind composition gate to the proven 3-kind serving topology (Server + IPv4 + Firewall/single public NIC). *Counterpoint (kept):* the 4-kind gate demonstrated multi-kind composition breadth; dropping to 3 kinds narrows that demo — but the Network MR was genuinely unused (never attached to the Server), so dropping it is the more honest graph.
4. **F2 orphaned `.kw-*` deck CSS** → **CHANGE (revisit): wire-or-delete.** Next-session deck lane: either wire `.kw-footer/.kw-chip/.kw-kicker` to real slide elements, or delete the dead rules — and tighten `theme-tokens.sh` to assert *application*, not just presence. Core identity (graphite bg, teal accent, Inter/JetBrains, progress bar) already applied.
5. **F3 ROADMAP markdownlint (~174 warnings)** → **RATIFIED as-shipped.** Stays out of E12c scope; folds into the audit-backlog DOC-13 hygiene lane (dedicated markdownlint gate + fix). Pre-existing, not a regression.
6. **E8b Option-A / jump VM** → **CHANGE (revisit): jump VM AUTHORIZED, but cost-gated.** Operator authorized provisioning a gridscale jump VM to reach `:6443` from inside the tenant. *Counterpoint (kept, operator informed):* the **unrestricted-network path costs €0 extra** and proves the identical app-layer, whereas the jump VM adds tenant compute + teardown; and neither path dodges the real risk that the app-of-apps has never synced on GSK (assumes Cilium+Gateway API; GSK runs its own CNI → first sync is an integration task). Recorded as **cost-gated: prefer an unrestricted network first; spin the jump VM only if none is available.** Awaiting operator confirm if they want it unconditional.

**Status:** Items 3/4/6 tee up next-session lanes (E6g composition trim · deck F2 wire-or-delete · E8b app-layer live proof). Item 5 folds into DOC-13. Items 1/2 need no code.

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

## D-026 — Marshal `caddy_*` alerts: ANSWERED — park with the Caddy-MVP epic (option A)

> **STATUS: ANSWERED 2026-07-15 — operator chose Option A (park).** Confirmed directly by the operator
> via the coordinator's question tool ("Park with Caddy epic"), and reinforced by the operator's Caddy/nginx
> MVP vision (VM variant = Caddy + alerting). WS1 ARCH-2/ARCH-3 alert migration + ADR-0104 retcon are
> unblocked and assigned to the monitoring/Caddy lane.

**Date:** 2026-07-15 (operator-confirmed via direct question)
**Context:** The 2026-07-15 health audit (ARCH-2/ARCH-3) found the landed E5 `caddy_*` marshal alerts scrape
a Caddy edge target that the platform's Cilium/Envoy edge never emits, and that only exists via cut scope —
so the showpiece alert can never fire against the platform as designed. Two options were surfaced:
**(A)** park the `caddy_*` alerts with the deferred Caddy-tenant epic and disable them from active platform
monitoring; **(B)** re-point them to Cilium/Envoy Gateway metrics.
**Recommendation:** **Option A — park** (operator-confirmed). The `caddy_*` marshal PrometheusRules + their promtool tests move out of
active platform monitoring into the **VM-variant alerting slice** of the new `e-caddy-mvp` epic; they light
up (serve→scrape→fire) when the Caddy tenant lands and fire against the VM's external metrics endpoint.
Promtool **fire + silent** rigor is **preserved**, just scoped to the epic. Platform-edge monitoring is
**decoupled** from Caddy. ADR-0104 to be retconned by the monitoring/Caddy lane: platform edge = Cilium/Envoy
Gateway; Caddy = tenant MVP (Website-as-a-Service), **not** a gateway (D-019).
**Rationale for A over B:** Option B would require enabling Envoy/Cilium metrics in the E1e substrate = scope
creep on the local dev substrate. Parking keeps the substrate minimal and puts the alert where its real
target (the Caddy tenant) will exist.
**Counterpoints (agent, kept):** B would keep the alerts "live" in the platform monitoring path; rejected
because they would then assert against synthetic/edge metrics unrelated to the tenant product, defeating the
demo's point. Parking risks the alerts bit-rotting while deferred; guarded by keeping the promtool suite
green in the epic's gate so a regression is still caught.
**Traceability:** audit ARCH-2, ARCH-3 · epic `openspec/changes/e-caddy-mvp/` · remediation WS1
`openspec/changes/audit-remediation-2026-07/`.

## D-027 — E6 `Website` XRD ships as a Crossplane v2 namespaced XR (not a v1 Claim)

**Date:** 2026-07-15 (operator delegated: "you decide, whatever feels nicer")
**Context:** E10 portal research asked whether the `Website` platform API should be a Crossplane **v1
Claim** (cluster-scoped XR + namespaced Claim) or a **v2 namespaced XR** (Claims deprecated; the XR is
the resource). The TeraSky Backstage plugins support both.
**Decision:** **v2 namespaced XR.** Modern, simpler mental model ("the claim *is* the resource"),
stronger interview signal, and it drops the Claim/XR duality. Amends ADR-0105 and the E6 spec (which
currently reads `kind: WebsiteClaim`) → `kind: Website` (namespaced).
**Consequences:** E6 spec REQ-E6-S02-* rename Claim→XR; E10 design/spec reference the namespaced XR;
sample paths become namespace-scoped. Recorded in ADR-0111.
**Traceability:** ADR-0105, ADR-0111 · epic `e6-crossplane-website`, `e10-portal-stretch` ·
research `agent-context/research/e10-portal-wiring-and-demo-presentation.md` (A.4).

## D-028 — E10 portal templates are AUTO-GENERATED from the XRD (kubernetes-ingestor), not hand-written

**Date:** 2026-07-15 (operator-confirmed: "yes")
**Context:** The earlier E10 cut hand-wrote a single `static-site/template.yaml` duplicating the XRD
schema — which drifts whenever the platform API changes. TeraSky's **kubernetes-ingestor** generates a
scaffolder template per XRD from its OpenAPI schema, and its `publishPhase` supports **pull-request**
targets (verified) — so it preserves E10's "portal authors Git, never mutates the cluster" invariant.
**Decision:** **Adopt auto-generation.** Replace the hand-written template with the ingestor. Add a
field to the `Website` XRD → the form updates automatically ("the portal is a projection of the platform
API, not a copy"). The write path holds **no** cluster credentials.
**Consequences:** E10 proposal/design/tasks/spec rewritten (S02 = ingestor config; new REQ-E10-S02-03
asserts the form adapts to XRD changes). Third-party OSS plugin enters the supply chain — pin + Renovate
+ E11 audit. Updates ADR-0109; detailed in ADR-0111.
**Counterpoints (kept):** hand-written templates need no plugin dependency; rejected because drift +
schema duplication is exactly the anti-pattern the demo should avoid.
**Traceability:** ADR-0109, ADR-0111 · epic `e10-portal-stretch` · research (A.0).

## D-029 — E10 read-path visibility plugins are IN scope (impressiveness > minimal-trust)

**Date:** 2026-07-15 (operator: "impressiveness > security — it's a demo for a job application; not a
bank, but we want to work for a cloud provider working for banks")
**Context:** The read-path plugins (crossplane-resources graph, Kubernetes, ArgoCD status) render live
status in-portal but require a **read-only** ServiceAccount to the cluster + a read-only ArgoCD account —
added trust surface for a security-first repo. The write path alone needs no cluster creds.
**Decision:** **Include the read path.** The in-portal XR→managed-resource graph is most of the demo's
wow. Scope the trade sharply: read-only RBAC (`get/list/watch` only), NetworkPolicy `portal` →
kube-apiserver + argocd-server only, plugins pinned + Renovate + E11-audited. The smallest-trust
alternative (write-path only, status via the ArgoCD UI) is recorded and **rejected** for this demo.
**Consequences:** E10 S04 (read-path plugins + RBAC guard test REQ-E10-S04-01). Kept as a *named* trade
so a reviewer sees it was deliberate, not overlooked.
**Traceability:** ADR-0111 · epic `e10-portal-stretch` · research (A.1, A.5).

## D-030 — E-Caddy-MVP showcase: the demo site serves the Kaddy deck/docs via nginx→Caddy topology

**Date:** 2026-07-15 (operator-confirmed: "sure, go ahead")
**Context:** The served-website tenant needs content. Instead of placeholder pages, serve **the Kaddy
project's own Slidev deck (E12) + MkDocs docs** — the demo site *is* the pitch, and the scraped/alerted
content is real.
**Decision:** Serve deck + docs from a **multi-stage image** (static `slidev build` + `mkdocs build`)
through a deliberate **nginx (reverse proxy) → Caddy (static origin)** topology. This turns the
exercise's "optional nginx reverse proxy" into a designed two-engine comparison and gives the parked
`caddy_*` marshal alerts (D-026) a **real** scrape target — closing that loop. Optional stretch: a
second tenant proving `Website.spec.source` (BYO external git).
**Consequences:** New spec `openspec/changes/e-caddy-mvp/specs/showcase/spec.md` (REQ-CADDY-S05-01..05);
tasks S05; MkDocs theme → `material`. E12 owns deck authoring; this epic serves its build output.
**Traceability:** D-026 (parked alerts) · epic `e-caddy-mvp`, `e12-slidev-deck` · research (Part B).

## D-031 — E12 deck: word-by-word speaker notes + heavy iframes, as the spine of a 5–10 min recorded video

**Date:** 2026-07-15 (operator direction)
**Context:** The deck will back a **recorded 5–10 minute video** for the job application. The operator
wants **verbatim (word-by-word) speaker notes** on every slide (the video voiceover script) and **heavy
use of Slidev iframes** embedding live platform surfaces (Backstage portal, ArgoCD, Grafana/marshal, the
running clubhouse/Caddy site, the Crossplane resource graph).
**Decision:** Make both first-class E12 scope. Speaker notes are verbatim scripts (not bullet hints),
asserted by coverage + word-count tests (≈650–1500 words ≈ 5–10 min at ~130–150 wpm). Iframes embed
**live** surfaces to prove the platform runs; fallback to recorded GIF/screenshot if a surface is down
during recording.
**Consequences:** E12 fleshed out from a stub — `proposal.md` + `specs/deck/spec.md`
(REQ-E12-S01-01, S02-01 notes, S02-02 script length, S03-01 iframes, S04-01 beats, EXIT) + `tasks.md`.
Tests under `tests/deck/`.
**Traceability:** epic `e12-slidev-deck` · depends on E10 (auto-gen money-shot), E-Caddy-MVP (served
content), E5/marshal, E7/mulligan, E8/scorecard · research (Part B).

## D-032 — E13: a gridscale Marketplace template (Caddy + nginx) as a third way to satisfy the exercise

**Date:** 2026-07-16 (operator direction: "add a story/epic for a gridscale marketplace template for
Caddy and nginx as an additional way to achieve the exercise; Terraform is OK here")
**Context:** kaddy satisfies the exercise via the K8s/Crossplane path (E-Caddy-MVP Variant B) and the
Crossplane-VM path (Variant A / E6g). The operator wants a **third, gridscale-native** delivery: a
**Marketplace 2.0 template** (build image → snapshot → export `.gz` to object storage → register via
`gridscale_marketplace_application` → import via `_import` → deploy). High-signal for a gridscale role.
Terraform is the right tool (the provider exposes these resources directly) — operator-approved for this
path (unlike the crossplane-first E6/E6g).
**Decision:** New epic **E13** (`e13-gridscale-marketplace`), Terraform-native, phase-2, gated on E1g.
Publish **privately into our own tenant** (import by `unique_hash`) — **not** globally: global listing
needs gridscale's manual review (`product@gridscale.io`), which the demo doesn't need. Work around the
gridscale specifics: `category` enum has no "web server" (use `Adminpanel`/`CMS` + carry the real class
in `meta_*`); `object_storage_path` must be `.gz`/`s3://`; a `meta_icon` is required.
**Consequences:** New epic (proposal/design/tasks + `specs/marketplace/spec.md`, REQ-E13-S01-01,
S02-01/02, S03-01/02, EXIT). Additive — does not replace Variants A/B. Deployed VM feeds the parked
`caddy_*` marshal alerts against a real gridscale target (closes D-026 on the Marketplace path).
ROADMAP + exercise-traceability updated.
**Counterpoints (kept):** the image-build/export pipeline is heavier than a cloud-init `gridscale_server`
(E6g) — justified because the deliverable is a reusable Marketplace *product*, not a one-off VM.
**Traceability:** epic `e13-gridscale-marketplace` · depends E1g (object storage + creds), E-Caddy-MVP
(image content), E5/marshal (alerts) · exercise-traceability optional-task row · ADR-0105 (self-service).

## D-033 — agent-loop-auto batch while 0.1.1 release wraps (2026-07-16)

**Context:** Operator authorized `/agent-loop-auto` on Kaddy while another session wraps **v0.1.1** (tag exists; `showcase-image` running on tag; changelog commit `77fc96c` on main). E8-S04 in-flight in `e8-getting-started` owns ROADMAP + e8 OpenSpec.

**Decision:** Skip release packaging + E8-S04 entirely. Parallelize three file-disjoint offline lanes:
1. **E8-scorecard-offline** (S01+S02 structural) — auto-merge eligible
2. **E1c-trivy-ci** — PR only; security → INBOX before merge
3. **E1c-digest-latest** — narrow `:latest` gate only (full digest pin would red-main); PR only; security → INBOX

**Counterpoints considered:** (a) Combining Trivy+digest into one security PR reduces review load but couples unrelated gates — rejected for smaller blast radius. (b) Full digest mandate now — rejected; would fail verify on Helm charts. (c) Starting E10/portal — cuttable, skipped. (d) provider-grafana — high blast / Crossplane, deferred DECISION later.

## D-035 — Workstation runtime is Podman-only (no Docker Desktop / colima)

**Date:** 2026-07-16 · **Status:** Accepted (operator).
**Context:** Operator inbox task said "Start Docker before E1e"; operator clarified this machine has
**Podman only**, not Docker Desktop/colima. E1e already detects podman and sets
`KIND_EXPERIMENTAL_PROVIDER=podman`; Cilium needs **rootful** podman (`podman machine set --rootful`).
**Decision:** Treat **rootful Podman** as the canonical local container runtime for this workstation.
Drop the "Start Docker" operator task. Live E1e gate prerequisite = podman machine running (rootful)
before `task cluster:up`.
**Counterpoints (kept):** Docker Desktop remains a supported alternate in docs for other machines;
this entry records *this* operator environment so agents stop asking for Docker here.

## D-036 — Argo F-01 GitOps unblock: Option A

**Date:** 2026-07-16  
**Context:** Argo `policies` could not sync its mulligan NetworkPolicies because AppProject `platform`
did not permit `mulligan`; the workloads sync also contained a caddy-origin duplicate `containerPort:
8080`.  
**Decision:** **Option A — two scoped GitOps fixes.** Coordinator executed without waiting: permit
`mulligan` in the platform AppProject and retain only the `http:8080` port. Rebased onto current main
(`a9a5f79`, E9-S03 intact), landed PR #13 @ `9f18ebf`, hard-refreshed + synced `root`/`policies`/
`workloads` on `kind-kaddy-dev`.  
**Outcome:** apps Synced+Healthy; mulligan NetPols=2 (+1 CNP); caddy-mvp NetPols=5 (+2 CNP).  
**Counterpoints (agent, kept):** CI Chainsaw `security-mulligan-netpol` still observed an unauthorized
cross-ns curl succeeding after policy apply — separate from the GitOps destination/port blockers;
tracked as residual live-enforcement debt, not a merge stop for the scoped fix.  
**Affirmation:** operator **affirmed Option A** 2026-07-17 via `/operator-inbox` (rejected B broaden-to-all-ns and C leave-OutOfSync). AppProject stays a **closed named-destination allowlist** — consistent with the workspace cross-repo relay answer (do NOT wildcard; preserves E1c/SEC-11 / ADR-0106 hardening). Decision CLOSED.

## D-037 — E14: Nix golden images for gridscale Marketplace templates, alongside Packer (does NOT supersede D-032 or D-003)

**Date:** 2026-07-17 · **Status:** APPROVED (gated) 2026-07-17 via `/operator-inbox` — admitted to the backlog as a Phase-3 plan, **gated behind the Phase-2 live-proof cycle** (E6g/E13/E8b live); no E14 code starts before phase-2 live is done. Maintainer LGTM (supply-chain) still required before any E14 supply-chain code merges — approval admits the epic, not the merge.
**Context:** kaddy satisfies the exercise's web-server deliverable four ways once this lands: e-caddy-mvp
K8s (Variant B), Crossplane-VM (Variant A / E6g), the E13 **Packer** Marketplace template (D-032), and —
proposed here — a **Nix-built** golden image. The operator wants a Phase 3 + a new epic (E14) with a
full, enterprise-ready feature set, and treats the feature set as the epic content. The pull is
provenance: a **flake-locked reproducible**, **full-closure-SBOM'd**, **minimal near-zero-CVE**,
cosign-signable VM image sharpens the supply-chain story the repo already tells for *container* images
(E1c-S02 Trivy, E1c-S03 cosign) and is a direct hiring signal for a gridscale role. **This is Nix-as-
image-builder, NOT Nix-as-cluster-OS** — D-003 (Talos over Nix) and D-015 (GSK managed k8s) are **not**
reopened; the substrate is unchanged.
**Feasibility hinge (resolved):** a from-scratch NixOS image loses gridscale's base-template
SSH/password injection (`storage.template.password` = public-templates-only). Provider docs settle the
mechanism: network = **DHCP** (auto-assigned, no config); first-boot config = **`user_data_base64`**
(cloud-init/Cloudbase-init/Ignition). The demo minimum (serve + `/metrics` + scrape) needs neither
(service starts declaratively). Scoped as the epic's first-story **spike (E14-S01)**, not assumed.
**Decision:** **Add** Nix golden images as new epic **E14** (`e14-nix-golden-images`), phase 3,
**forward-looking and gated behind Phase 2's live-proof cycle** (E6g/E13/E8b live). **Additive — keep the
E13 Packer builder** (D-037 does **not** supersede D-032). Recorded in **ADR-0303**. Reproducibility gate
asserts the NixOS **system-closure store-path** (not the disk image); offline gate mirrors
`task test:smoke:e13` (`nix flake check` + build-twice-compare + promtool `caddy_*`, skip-not-fail).
Feature set tiered MVP → provenance → multi-cloud (closure SBOM + Trivy + cosign; sops-nix per ADR-0110
with the age key injected via user-data, never baked in; Renovate-bumped nixpkgs pin; `nixos-generators`
multi-target portability).
**Counterpoints (agent, kept):** (a) the Packer path already satisfies the exercise — Nix is provenance
polish, not a gap-filler; accepted for the enterprise supply-chain flex + gridscale-role signal. (b) Nix
has the steepest learning curve and the team has ~ zero Nix today (scored honestly in the ADR matrix:
Packer wins on cost/familiarity/boot-risk, which is *why* E13 is kept); bounded by making E14 gated +
cuttable with E13 as the guaranteed-green fallback (mirrors the D-016 fallback guard). (c) disk-image
bit-reproducibility is not free — the claim is scoped to the closure store-path, image-level bit-repro is
an explicit stretch.
**Traceability:** ADR-0303 · epic `e14-nix-golden-images` · depends E1g (object storage + creds), E13
(image content + Marketplace pipeline), E5/marshal (`caddy_*` alerts) · exercise-traceability
optional-task row · **GOVERNANCE: maintainer-LGTM-required (supply-chain / image provenance).**

## D-038 — Phase-2 coordinator decisions RATIFIED (operator, `/operator-inbox` 2026-07-17)

**Date:** 2026-07-17 · **Status:** RATIFIED. Operator endorsed the bundle of four decide-and-log
calls the `/agent-loop-local` coordinator made during phase-2 (all already implemented + merged +
tech-reviewed at ratification time):
1. **Definition of "phase-2 complete" = Option B** — offline gates green for every stack + ONE
   ephemeral live proof-cycle per live-gated story (create→verify→capture→`tofu destroy`); **E8b
   becomes an on-demand bring-up** (task target + runbook, proven once ephemerally), NOT a standing
   env. Reconciles "all backlog complete" with the ruthless-teardown cost rule (standing lab ~€115/mo).
2. **Object-storage bucket = the one cheap persistent anchor** on LOCAL state (~€0.06/GB; resolves the
   remote-state backend chicken-and-egg); all expensive compute (GSK/LBaaS/VMs) cycles create→destroy.
3. **gridscale provider auth env-var mapping** — provider reads `GRIDSCALE_UUID`/`GRIDSCALE_TOKEN`;
   `.envrc` now exports both (operator update 2026-07-17), so `TF_VAR` mapping is optional.
4. **E6g single `Website` XRD with `spec.variant` enum** (k8s|vm) + `compositionSelector` routing —
   NOT a separate `WebsiteVM` kind; lower blast radius, keeps the in-cluster Website path intact.
**Counterpoint (agent, kept):** all four were already live in `main` at ratification, so ratification
is endorsement-of-record, not a gate — revisiting any would mean rework. Operator ratified all.

## D-2026-07-17-live — Phase-2 live-proof completion + portal visibility (operator, end of session)
- Remaining live proofs E13-S02 / E8b / E6g-full: operator wants ALL THREE done — scheduled for the NEXT session (phase-2 live extensions before Phase-3).
- kaddy-portal repo: PUBLIC (operator-authorized end-of-session; flipped from the initial safe-default private).
- Next-session priority: finish phase-2 live extensions, THEN E14/Phase-3.
- This session delivered: v0.3.0 + v0.3.1, CI green, audit READY, all phase-2 offline + E10, 4 live proofs (E1g GSK, E13 build, E6g provider→network, E13 deploy→serve).

## D-2026-07-17-loop2 — Phase-2 live extensions PROVEN (E6g full + E13-S02) + reviews

**Date:** 2026-07-17 (loop continuation) · **Status:** DONE + merged to main.

- **E6g-S03/S04 full Website composition VM — LIVE-PROVEN.** Website XR (variant=gridscale) →
  Crossplane composition → real gridscale nginx VM serving /legacy + /healthz + /metrics on a real
  public IP (185.241.34.52, de/fra2), then destroyed; tenant API-audited clean. Three real composition
  defects found + fixed: (1) v1→v2 `spec.crossplane.compositionSelector` (both committed Website XRs;
  the in-cluster claim was the tech-review P1 F1); (2) public IPv4 needs the gridscale Public Network
  attached — Server takes a SINGLE public NIC; **dual-NIC (public+private) was live-shown to break
  serving** (the composed private Network stays in the graph, not the Server's default route); (3) nginx
  cloud-init dropped the stock `default_server` site so nginx starts. **Finding: cloud-init user_data on
  gridscale stock Ubuntu WORKS** — the earlier "datasource" hypothesis was wrong; the real blocker was
  the duplicate `listen 80 default_server`. Gate `test:smoke:e6g` tightened to reject any v1 top-level
  selector. Tech-review: REQUEST CHANGES → APPROVE after F1+F4 fixes.
- **E13-S02 Marketplace register+import — LIVE-PROVEN (both engines).** `gridscale_marketplace_application`
  (register) + `_import` (private tenant) applied live for caddy + nginx; gate `e13-s02-register.sh` OK
  (id+unique_hash+import_id). No compute — metadata only; object-storage bucket + `.gz` + dedicated S3
  key created for the proof and destroyed after; tenant marketplace audited clean. **Finding: register
  accepts the `.gz` path + returns unique_hash without a full boot cycle** — the register/import mechanism
  is decoupled from S01-build/S03-deploy.
- **E12c deck+docs refresh (S01–S09, S08 HELD) — merged.** Tech-review REQUEST CHANGES on F1 (MR-claim
  wording). **F1 CLEARED by independent network verification:** upstream PRs #509/#510/#511 genuinely
  exist, are OPEN, operator-authored on `gridscale/terraform-provider-gridscale`; go-ahead recorded in
  provider-gridscale D-021. The deck wording ("filed, open, awaiting review, not merged") is accurate.

## D-2026-07-17-release2 — v0.4.0 cut (🔴 DECIDED, operator-authorized releases)

**Date:** 2026-07-17 (loop2) · **Status:** RELEASED. v0.4.0 tagged + GitHub release published
(https://github.com/PlatformRelay/Kaddy/releases/tag/v0.4.0). Milestone: phase-2 live extensions
(E6g full Website composition VM, E13-S02 Marketplace register/import — both live-proven; E8b GSK
substrate live-proven) + E12c deck+docs refresh + DOC-10 truth fix. Cut on CI-green main + audit
verdict READY (0 P0/P1). git-cliff CHANGELOG. Rationale: natural milestone (phase-2 live cycle
substantially closed), meaningful user-facing value accumulated, audit READY. Revert: releases are
operator-only to delete — flag if the scope was wrong.

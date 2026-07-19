# Changelog — kaddy

All notable changes to the kaddy platform. Generated with git-cliff from
gitmoji-conventional commit history.

## [0.6.0] — 2026-07-19

**The Nix "fourth way" goes live — a reproducible, flake-locked golden image, served and
scraped on gridscale.** E14 completes the golden-image story: alongside the Packer/Ubuntu
path, kaddy now ships a **Nix-built** gridscale Marketplace image (`caddy-nix`) — a
minimal-CVE, full-closure NixOS 24.11 image built reproducibly from a flake, exported to
object storage, registered + imported as a one-click Marketplace app, and **live-proven
end-to-end**: deploy → `GET /` 200 + `/healthz` + `:2019/metrics` (158 `caddy_` series) →
Prometheus `up=1` on the standing GSK cluster, with every ephemeral VM torn down clean
(0 orphans). The serve failure that stumped two earlier attempts turned out to be a caddy
version skew — nixos-24.11's caddy 2.8.4 rejects the golden Caddyfile's `metrics { per_host }`
block, so `caddy run` exited before binding :80 — fixed at source by pinning caddy ≥ 2.9. The
Marketplace also gains engine-OS naming + logos (`caddy-ubuntu`, `caddy-nix`), and E13-S05
live-proved the one-click Caddy deploy path end to end.

### Features
- **e14-s01:** Nix-built gridscale golden image (flake + nixos-generators)
- **e14-s02:** Register kaddy-nix Marketplace app from the Nix .gz (LIVE)
- **marketplace:** Rename templates to engine-OS names + add logos (LIVE)
- **deck:** Rebuild interview presentation

### Fixes
- **e14-s01:** Address independent review (P1 gate wiring + Caddyfile validation)
- **e14:** Add qemu-guest profile so the Nix image boots on gridscale (virtio)
- **e14:** Pin caddy >=2.9 so the Nix golden image serves (E14-S03)

### Tests
- **e13-s05:** Live-prove one-click Marketplace deploy (Caddy)

### Documentation
- **e1g-s06:** Reconcile retired "no standing env" prose → go-live carve-out + doc-truth guard
- **e14-s03:** Nix VM deploy — mechanism proven, then boot-to-serve LIVE-PROVEN (caddy ≥2.9 pin)
- **e14-s03:** QEMU boot test narrows the diagnosis — image boots, Caddy version skew found
- **coord:** Handover 2026-07-19 loop2 — E14 Nix path + marketplace rename/icons

### Chores
- **marketplace:** Tofu fmt the caddy/nix stack edits (align icon_path)
- **e14:** Add hack/e14-s03-live-prove.sh — one-shot live deploy→prove→teardown
- **e14:** Scrape-prove hook + teardown-order fix + wire nix into e13:up/down

## [0.5.0] — 2026-07-18

**The gridscale cloud-edge goes live — real public URLs with real certs.** The phase-2
substrate swap is complete and running: the kaddy platform serves on a standing gridscale
GSK cluster behind a **Traefik v3 Gateway-API edge** with **publicly-trusted Let's Encrypt**
certificates. Four live HTTPS surfaces — **Argo CD**, **Grafana**, the full **caddy-mvp**
(Argo Rollouts canary showcase), and a demo landing page — on `*.lab.platformrelay.dev`,
all HTTP 200 with a verifiable chain. Highlights: **E1g-S05a** adds a GSK-targetable
bootstrap opt-in (`KADDY_GSK_CONTEXT`) that hardens rather than weakens the kind-only
prod-nuke guard; **E1g-S05b/e/f/g** are codified into cloud-only GitOps overlays (Traefik
controller app, `clubhouse` Gateway + per-host HTTPS listeners, cert-manager **DNS-01**
Cloudflare issuers with a token-less ExternalSecret, real hostnames) plus replayable
`hack/gsk/` scripts and a prominent README "Live demo" section; **E1g-S05i** codifies the
caddy-mvp canary edge. Three findings shaped the build: GSK's managed Cilium **cannot** serve
Gateway API (→ Traefik, decision **D-042**), GSK **has** a service-LoadBalancer CCM (auto
public IP — collapses S05c/S05d), and Gateway API v1.5.1 CRDs need their k8s-1.31-only `isIP`
CEL rules stripped to apply on GSK's k8s 1.30. **E1g-S05h** records the GSK node public-IP
exposure as an accepted risk with compensating controls; **E1g-S06** reconciles the
cost-governance prose into a recorded, time-boxed go-live standing carve-out with an offline
doc-truth guard. Every lane independently reviewed (0 P0/P1); `task verify` green throughout.

### Features
- **e1g-s05a:** GSK-targetable bootstrap opt-in via shared context guard
- **e1g:** Codify live GSK cloud-edge into GitOps overlays + LINKS (S05b/e/f/g)
- **e1g-s05i:** Codify live caddy-mvp Rollouts canary on GSK cloud-edge

### Documentation
- **inbox:** Log v0.4.1 release + audit-P3 fixes (DECK-1/DOC-14/ENV-1)
- **e1g:** Decompose deferred cloud-edge into E1g-S05a-h + E13-S05; live GSK substrate evidence (2026-07-18)
- **inbox:** Handover 2026-07-18 — flag STANDING GSK substrate (billing) + D-041 + E1g-S05a-h/E13-S05
- **e1g:** Backlog E1g-S06/S07 — go-live cost-governance for standing infra (audit WIP-D1)
- **e1g-s06:** Reconcile "no standing env" prose -> go-live recorded+time-boxed carve-out + doc-truth guard (WIP-D1)
- **e1g-s06:** Fix doc-truth overclaim (F-01) + guard-scope caveat (F-02)
- **e1g-s06:** D-042 forward-ref framing (NEW-A) + restore ROADMAP typo (NEW-B)

### Other
- **e1g-s05b:** Guard gsk CRD apply against kind (S05a helper) + apply AppProject before Traefik App (review G1/G2)
- **e1g:** S05h spike — GSK node public-IP exposure is accepted risk (no provider/API mitigation)

## [0.4.1] — 2026-07-17

**Hardening, real CI gates, and a live `:6443` proof.** A remediation loop that burned
down the D-039 next-session lanes and the audit backlog, then closed the one remaining
environment block. Highlights: **SEC-14** pins explicit `securityContext` on the
observability workloads (Grafana/Prometheus/Alertmanager/Loki; Alloy + node-exporter kept
as documented host-access exceptions); **DOC-13** turns the markdownlint gate from inert to
genuinely enforced in CI (pinned `markdownlint-cli2@0.23.1`, narrowed to shippable docs, 0
issues across 160 files); a new **release-provenance** guard fails CI on a false "shipped in
vX" claim (with a companion guard that keeps the CI checkout deep + tagged); the **E6g**
Website composition drops a dead composed `Network` managed-resource (proven 3-kind serving
topology); and the deck token gate + provenance guard were fixed to actually run where
they're wired (three "inert gate" defects found by independent review). Finally, with the
corporate VPN disconnected, the **GSK API `:6443` egress is now OPEN** — proven on an
ephemeral cluster (`kubectl get nodes` → Ready) then torn down (tenant clean), un-blocking
the E8b app-layer. Audit verdict: **READY** (0 P0/P1, 0 regressions).

### Security
- **SEC-14:** Explicit securityContext on observability workloads (Grafana/Prometheus/Alertmanager/Loki; Alloy + node-exporter documented host-access exceptions)

### Fixes
- **e1g:** Scrub leftover `.terraform` in the offline gate + teardown (ENV-1); reconcile the e6g evidence Network-MR claim (DOC-14)

### Refactoring
- **deck:** Delete orphaned `.kw-*` CSS; assert token *application* not mere presence (D-039 F2)
- **e6g:** Drop the unattached composed Network MR; relax the composition gate to the proven 3-kind topology (D-039)

### Tests
- **meta:** Add a release-provenance ancestry guard — an epic's commits must be ancestors of the tag it claims to have shipped in
- **meta:** Give the release-provenance guard teeth on CI (fetch full history + tags; wiring guard; fail-not-skip on CI)

### CI & build
- **doc13:** Enforce markdownlint over shippable docs (narrowed globs, line-length noise relaxed) and pin `markdownlint-cli2@0.23.1` (SEC-4)
- **deck:** Wire `theme-tokens.sh` into the deck CI composite + guard the wiring so it can't silently un-wire (DECK-1)

### Documentation
- **e8b:** Live-prove GSK `:6443` egress OPEN with the VPN disconnected (ephemeral cluster, torn down, tenant clean)
- **e6g:** Drop the stale composed-Network claim in the openspec tasks (review F1)
- **inbox / coord:** Log the D-039 operator answers, the loop3 lanes, and decision D-040

## [0.4.0] — 2026-07-17

**Phase-2 live extensions + deck refresh.** The gridscale delivery is now proven live end-to-end on
real infrastructure (ephemeral create→verify→destroy, tenant clean after each): the **E6g Website
Crossplane composition** provisions a real gridscale nginx VM serving `/legacy` + `/metrics` on a
public IP; the **E13 Marketplace** register+import works for both Caddy and nginx engines; and the
**E8b GSK substrate** (cluster + network + object-storage anchor) provisions cleanly. The **E12c deck
refresh** reframes the interview deck around landed gridscale value (the provider + 3 upstream bug-fix
PRs) with a gate-exempt appendix and a hybrid workshop visual identity. Audit verdict: **READY**.

### Features
- **deck:** E12c-S01 appendix-exempt gates + raised main budget
- **deck:** E12c-S02 gridscale value hero + Crossplane-as-IaC
- **deck:** E12c-S03 agentic-workflow beat (epic -> plan -> story -> test)
- **deck:** E12c-S04 appendix — NixOS path, repo-tree, quickstart, solved-different-ways
- **deck:** E12c-S05 hybrid k8s-workshop styling port (ADR-0112)
- **deck:** E12c-S06 wire recorded-surface fallback slots to guide names
- **deck:** E12c-S07 Kaddy README badge row

### Fixes
- **deck:** E12c-S05 theme-tokens.sh — drop backticks in fail message
- **e6g:** Live-prove Website composition VM + fix real defects
- **e6g:** Migrate in-cluster Website claim to v2 selector + tighten gate

### Tests
- **e13:** Live-prove S02 Marketplace register+import (both engines)
- **e6g:** Init v1_sel guard var (tech-review F4)

### Documentation
- **inbox:** Session close — phase-2 live-proof cycle + operator answers
- **adr:** ADR-0303 + E14 — Phase 3 Nix golden images (forward-looking)
- **e12c:** Ratify design-lane spec + admit E12c/D-038 to backlog
- **roadmap:** Complete E12c backlog rows (S05-S07,S09)
- **hygiene:** E12c-S09 rename HIRING_EXERCISE, fix broken E14 links
- **hygiene:** E12c-S09 complete — commit the README+ROADMAP link fixes
- **coord:** Log E6g/E13-S02 live proofs + deck merge + review outcomes
- **DOC-10:** Drop stale 15/15 GitOps-apps count + fix its guard
- **e8b:** GSK substrate live-proven; app-layer egress-blocked (decide-and-log)

## [0.3.1] — 2026-07-17

### Tests
- **e6g:** Live-prove provider-gridscale actuates real gridscale infra
- **e13:** Live-prove deploy->serve->scrape on a real gridscale VM

### Chores
- **release:** V0.3.1 — phase-2 live-proof cycle

## [0.3.0] — 2026-07-17

### Features
- **gridscale:** E1g day-0 IaC — Terramate stacks + offline gates
- **gridscale:** E6g — consume Upjet provider-gridscale (offline)
- **gridscale:** E8b — on-demand live demo env (offline)
- **gridscale:** E13 — gridscale Marketplace template (offline)
- **portal:** E10 Backstage portal — GitOps wiring (offline)

### Fixes
- **e13:** Correct gridscale packer builder args + strict validate gate
- **e8b:** SEC-19 dataplane carve-out for the demo surfaces
- **e13:** Packer build needs ssh_password + a template UUID

### Tests
- **e1g:** Live-prove GSK substrate on gridscale
- **e13:** Live-prove the Caddy golden-image build on gridscale

### Documentation
- **inbox:** V0.2.0 released; phase-2 next (E1g→E6g→E8b)
- **inbox:** Phase-2 live provisioning permitted but cost-sensitive (destroy after each test)
- **inbox:** DOC-10 guard-gap follow-up (release-provenance assertion)
- **status:** DOC-10 #6 — README/ROADMAP intro reflect phase-2 + E10 landed

### Chores
- **release:** V0.3.0 — phase 2 (gridscale) + E10 portal

## [0.2.0] — 2026-07-16

### Features
- **e1c:** Add narrowed :latest image gate (REQ-E1c-S03-01)
- **ci:** Add Trivy CRITICAL scan-gate (E1c-S02)
- **scorecard:** Offline E8 fixture capture and load gates
- **ci:** Wire image digest gate into verify matrix
- **scorecard:** Publish evidence HTML to GitHub Pages
- **e1c:** Add offline External Secrets pattern for gridscale creds
- **branding:** Land kaddy logos, favicons, and og-image
- **taskfile:** Wire task deck:build + e12 guard into test:meta:ci — closes E12-S01 CI wiring (deck.yaml job pre-existed; tick tasks.md honestly)
- **e8:** Getting Started guide + honest five-minute path
- **caddy-mvp:** Variant B offline tenant manifests (S02)
- **showcase:** Bake MkDocs Material /docs/ into showcase image
- **caddy-mvp:** Revive caddy_http_* alerts against K8s origin
- **caddy-mvp:** Dual HTTPRoute for nginx showcase topology
- **caddy-mvp:** GitOps Application for re-homed monitoring slice
- **e9:** S01 CRD types green — Caddy/CaddySite validation + defaults (REQ-E9-S01-01), design.md samples
- **e9:** S02 green — caddyadmin client (idempotent @id upsert, ErrUnavailable taxonomy) + Caddy/CaddySite reconcilers with Ready conditions, finalizer drain
- **e9:** S03 observability bundle — ServiceMonitor + PrometheusRule + Taskfile envtest gate

### Fixes
- **websites:** Pin kaddy-showcase to multi-arch 0.1.1 — GHCR public + arm64 included; side-load retired
- **e1c:** Treat :Latest as floating tag in image digest gate
- **tests:** SEC-5 guard also scans flow-style '{ uses: ... }' steps (review F-1)
- **policies:** Default-deny netpol baseline for mulligan (audit F-01)
- **tests:** Tighten e12 deck CI guard to require upload-artifact path
- **caddy-mvp:** Route showcase hop by header, not path
- **tests:** Harden batch2 meta guard; clear stale S05 promtool note
- **caddy-mvp:** Exclude promtool projection from Argo directory sync
- **e9:** PATCH-based idempotent upsert (real Caddy verb semantics), exact+subtree path match, admin.listen admission pattern, least-privilege RBAC, lint clean
- **gitops:** Unblock tenant policy and rollout sync
- **chainsaw:** Poll-until-denied mulligan netpol probe — de-flake Cilium programming race
- **chainsaw:** Use HTTP_000 as positive deny signal — close vacuous-pass hole (tech-review F1)
- **test:** Make test:promrules hermetic — project rules before promtool
- **gitops:** Pin observability grandchildren onto the observability AppProject (SEC-17)
- **gitops:** Correct blackbox-exporter status in observability project header (tech-review L2-1)
- **docs:** E9 landed AFTER v0.1.1, not shipped in it (tech-review L1-1)
- **tls:** Point ACME staging solver at the real clubhouse/gateway Gateway (SEC-13)
- **operator:** Self-heal CaddySite watches + non-swallowing status update (ARCH-9)
- **operator:** CRD-gate observability Owns() + behavioral self-heal test (tech-review F1/F2)

### Tests
- **meta:** WS3 CI-wiring guards — TEST-1 advisory strict-spec job + repo-wide SEC-5 SHA-pin assert
- **policies:** Failing chainsaw suite — mulligan default-deny baseline (audit F-01)
- **security:** Enforce — not just presence — of the mulligan netpol baseline
- **meta:** Failing e12-deck-ci-wired guard — asserts deck.yaml runs the exit gate + publishes slides/dist + task deck:build exists (red: deck:build unwired)
- **e8:** Failing E8-S04 getting-started + demo contracts
- **docs:** DOC-10 expects E1d-S03 deferred as pending
- **caddy-mvp:** Add showcase promtool suite for re-homed caddy_* alerts
- **e8:** Strengthen Pages publish smoke contract
- **ci:** Require S05-03 + E8-S03 smokes in test:meta:ci
- **e9:** S01 API-shape envtest suite (red) — CRD Established, Caddy/CaddySite defaults + validation contract from design.md
- **e9:** S02 red — admin client contract (idempotent @id upsert), TestCaddy_Reconcile_Ready, CaddySite idempotency vs fake admin server
- **e9:** Review red — fake admin server now models REAL Caddy verbs (POST appends, PUT inserts, PATCH replaces); expect PATCH upserts, exact+subtree path match, admin.listen admission, missing-ref requeue
- **gitops:** Assert platform AppProject allows mulligan
- **caddy-mvp:** Complete epic test-artifact coverage (S01-04, S03, S04, S05, EXIT)
- **operator:** Hoist repeated site names to constants (golangci goconst)

### Documentation
- **e1c:** External Secrets pattern for gridscale creds (E1c-S04)
- **testing:** Document offline E8 L3/L4 scorecard gates
- **e-caddy-mvp:** Honest phase-1 gate status for Variant B
- **e1c:** Tick Trivy + digest gates done in tasks.md
- **e1c:** Tick SOPS/KSOPS items done in tasks.md
- **arch:** Note E8 offline scorecard evidence status
- **audits:** E11-S01 first dated security & compliance audit — PASS WITH NOTES (0 P0, 1 P1, 8 P2, 2 P3)
- **testing:** Retcon chainsaw layout to all 10 suites, pin chainsaw@v0.2.15, real CI workflow table (DOC-4/DOC-5/TEST-6, DOC-11)
- **substrate:** Retcon dev prereqs/gates + driving-range runbook to kind+Cilium reality, flag ADR-0102 amendment in index (ARCH-1/DIR-5 residuals, D-025)
- **status:** Traceability status-truth sweep — 14/14 apps, E5/E6/E7 landed markers, E6g re-scopes; seed audit history with 07-16 runs (DOC-2/DOC-8/DOC-10 class)
- **review:** E7-S04 honest partial marker, qualify 14/14 leaf apps, add E11-S01 audit history row; gitignore mkdocs site/ (review F1-F3, F5)
- **audit-remediation:** Tick WS2 (docs retcon fa81b37) + WS3 (CI gates 19b0db7) done — ARCH-5 stays blocked on REQ-TF-11
- **e8:** Expand E8-S04 getting-started + reviewer demo contract
- **e8:** Getting Started + honest five-minute reviewer path (E8-S04)
- **roadmap:** DOC-10 status-truth — 14/14 apps, E1c/E6/E8 done markers
- **inbox:** Podman-only runtime; mark Pages/policies/direnv done
- **roadmap:** DOC-10 status-truth — E1d + E11-S01 landed markers
- **roadmap:** Mark E1d-S03 Grafana OAuth deferred (not done)
- **e8:** Tick Pages live URL 200 + offline scorecard gate
- **roadmap:** E8-S03 Pages live URL confirmed HTTP 200
- **e8:** Flip reviewer surfaces to Pages live (keep deck unpublished)
- **e8:** Keep deck Pages labeled unavailable in Getting Started
- **e8:** Repair Getting Started artifacts table
- **audits:** E11-S02 second dated audit with diff vs S01
- **audits:** Fix E11-S02 finding rollup (11 P2 inventory)
- **inbox:** Reopen Argo policies/workloads re-sync after E11-S02
- **e12:** Tick ROADMAP S01–S04 — recording-ready gates green
- **e9:** Mark S01–S03 done on ROADMAP
- **e9:** Point EXIT Test path at operator/ envtest file
- Release-truth sweep — README/ROADMAP reflect v0.1.1 + E9 (DOC-10)
- **release:** V0.2.0 changelog — E9 operator, Caddy-MVP tenant, audit hardening

### CI & build
- **e8:** Run offline scorecard in verify workflow
- **verify:** STRICT_TEST_FILES=1 advisory job (TEST-1, non-blocking) + wire WS3 meta guards into task verify
- **caddy-mvp:** Wire S02 offline smokes into test:meta:ci
- **e8:** Harden scorecard-pages for enabled site
- **caddy-mvp:** Wire monitoring GitOps smoke; status 15/15 apps

### Chores
- **agent-context:** Record D-033 + reconcile PR ledger (8 merged, 9/10 closed via ref-push)
- **inbox:** Operator task — enable GitHub Pages for scorecard-pages workflow
- **inbox:** Operator tasks — sync policies app (mulligan netpol live) + note parallel session's e8 tech-review dispatch
- **inbox:** Tick PR #11 merged (E8-S04, operator merge authorization 2026-07-16)
- **e8:** Tick E8-S01..S04 tasks and ROADMAP status
- **e9:** Kubebuilder v4 scaffold — kaddy-operator module, Caddy + CaddySite APIs (gateway.kaddy.io/v1alpha1)
- **e9:** Tick S01+S02 in tasks.md
- **agent-context:** Sync INBOX + decisions bookkeeping after D-036 loop

### Other
- **e-caddy-mvp:** S00 — full spec surface for S01-S03 with REQ IDs + Test:/Verify: contracts
- **e-caddy-mvp:** Code-labelled Caddy SLI series + rollout-aware S05-03 Verify (review F1/F2)

## [0.1.1] — 2026-07-16

### Features
- **crossplane:** Website platform API — v2 namespaced XRD + Composition + demo claim (REQ-E6-S01-01, REQ-E6-S02-01, REQ-E6-S02-02, REQ-E6-S03-01, REQ-E6-S04-01, REQ-E6-S04-02, REQ-E6-S05-01, REQ-E6-EXIT)
- **crossplane:** Closed-list RBAC for composed Website kinds (REQ-E6-S02-02)
- **secrets:** SOPS-encrypted ArgoCD OIDC client pair for the KSOPS chain (REQ-E1d-S01-05)
- **identity:** Dex OIDC issuer rendered via KSOPS (REQ-E1d-S01-01/-02/-03/-06, ADR-0107/0110)
- **bootstrap:** KSOPS on the repo-server + ArgoCD OIDC wiring (REQ-E3-S01-03 debt, REQ-E1d-S02-01/-03)
- **policies:** Identity namespace default-deny netpol baseline (REQ-E1d-S04-01/-02)
- **ci:** Chainsaw substrate parity — build CI cluster from hack/cluster (Cilium+GW-API+local-CA), un-skip 9 suites (TEST-9, SEC-5)

### Fixes
- **docs:** Mkdocs strict-build link fixes
- **crossplane:** Numeric runAsUser for the function runtime pod (REQ-E6-S02-01)
- **crossplane:** Admit caddy's cap_net_bind_service file capability (REQ-E6-S03-01)
- **observability:** Raise Grafana resources — 200m/256Mi starved it into a liveness crash-loop (post-E6 load)
- **websites:** Pin kaddy-showcase to the real GHCR tag 0.1.0 (metadata-action strips the v; package now public — side-load retired)
- **websites:** Back to side-loaded v0.1.0 — GHCR 0.1.0 is amd64-only, node is arm64; multi-arch 0.1.1 pending
- **e1d:** SSA overlay with distinct field manager + Kyverno-compliant netpol probes
- **ci:** Apply vendored rollouts install.yaml with -n argo-rollouts — upstream manifest is namespace-less (Argo CD destination supplies it live)
- **ci:** Apply gateway/mulligan namespace.yaml before their dirs (alphabetical apply order) + multi-arch showcase image
- **ci:** Actually RUN the per-scenario chainsaw suites — default discovery only loads chainsaw-test.yaml files
- **tests:** Chainsaw asserts arrays length-strictly — filter conditions with jmespath in never-executed suites
- **tests:** 120s timeout on the bluegreen preview-service assert — 30s default too tight for green pod availability on the loaded CI node
- **tests:** Quote rollouts-pod-template-hash in the bluegreen selector assert — unquoted dashes parse as JMESPath arithmetic, expression could never be true

### Tests
- **e6:** Green live exit bundle — probe run-label, honest caddy metric assert, runbook caveats (REQ-E6-S04-01, REQ-E6-S05-01)
- **e1d:** Live smoke bundle + chainsaw identity suite (REQ-E1d-EXIT)

### Documentation
- **e1d:** Runbook rewritten to live reality + honest scoping (REQ-E1d-S03 deferral)

### Chores
- **release:** V0.1.1 changelog

## [0.1.0] — 2026-07-16

### Features
- **marshal:** Caddy PodMonitor, clubhouse ServiceMonitor, blackbox Probe
- **labels:** OpenTofu labeling module + tofu test suite (ADR-0301)
- **policy:** Conftest deny for plans missing ADR-0301 tags (REQ-E1b-S03-01)
- **policy:** Kyverno require-kaddy-labels ClusterPolicy manifest (REQ-E1b-S05-01)
- **iac:** Add terraform-docs and fmt gates for labels module
- **cluster:** Cilium-ready kind config + pinned versions (E1e S01/S05)
- **cluster:** Idempotent kind bring-up + Cilium/cert-manager install scripts (E1e S01-S03)
- **cluster:** LB-IPAM pool + L2 policy, local CA issuer, smoke Gateway (E1e S02-S04)
- **bootstrap:** GREEN REQ-E1-S01-01 local substrate handoff runbook
- **bootstrap:** REQ-E1-S03-01 cluster baseline assertion (E1e-satisfied)
- **bootstrap:** GREEN REQ-E1-S02-01 pinned ArgoCD v3.4.5 + insecure server + Gateway overlay
- **bootstrap:** GREEN REQ-E1-EXIT ArgoCD reachable via Gateway HTTPRoute (https 127.0.0.1:30443)
- **ci:** Add gitleaks + E1e meta gates to verify.yaml (SEC-1, TEST-2)
- **gitops:** App-of-apps + observability spine + ACME issuers (REQ-E3-S01-01, REQ-E3-S02-02, REQ-E3-S03-01)
- **slides:** Build the E12 interview deck (Slidev scaffold + content)
- **workloads:** Add clubhouse static site Deployment + Service (REQ-E4-S01)
- **gateway:** Platform Gateway + HTTPRoute + local-CA TLS for clubhouse (REQ-E4-S02/S03)
- **slides:** AI section-cover visual layer — CoverArt dividers + placeholder fallback (E12b)
- **spec:** Epic-writer batch — e13 gridscale-marketplace, ADR-0111 portal auto-gen, e10/e12 slice redesign, showcase spec
- **rollouts:** Argo Rollouts progressive delivery via Gateway API (E7)
- **policy:** Kyverno admission baseline — data-classification values, pod-security trio, verifyImages placeholder; refine require-kaddy-labels excludes (REQ-E1b-S05-02, REQ-E1c-S03-02, ADR-0106)
- **netpol:** Default-deny baseline + explicit allows for gateway/monitoring/argocd (REQ-E1c-S01-01..03, SEC-6)
- **gitops:** Restricted per-domain AppProjects (authored, unwired) + manual-sync policies Application (security-review P1-2, REQ-E1c-APPPROJECT)
- **ci:** Wire task test:kyverno (pinned CLI v1.18.2) into Taskfile + verify.yaml (H1 follow-up)
- **deck:** Verbatim word-by-word voiceover on every slide (30/30, 1358 words ≈ 9-10 min) + coverage/wordcount gates (REQ-E12-S02-01/02)
- **deck:** Embed the five platform surfaces — live iframes (argocd, grafana, clubhouse) + honest Backstage/Crossplane-graph fallbacks, URLs documented (REQ-E12-S03-01, partial-by-design)
- **monitoring:** Fireable marshal alerts on probe + Envoy edge signals, TDD fire/silent suites (ARCH-2, REQ-E5-S03-02..06, S06-02/03/05)
- **gitops:** Monitoring child app syncs deploy/monitoring — blackbox exporter + CA courier + clubhouse probe + edge/rollouts scrape + kaddy-marshal dashboard (ARCH-8, REQ-E5-S09-01, S02-01..03, S01-02, S05-01/S08-01)
- **ci:** Deck workflow — recording-ready exit gate on push/PR + dist artifact (E12-S01 CI)
- **kyverno:** Vendor pinned v1.18.2 engine + platform-project child app (E1c cutover step 1)
- **policies:** Flip disallow-privileged-containers Audit -> Enforce (zero live violations)
- **policies:** Flip disallow-latest-tag Audit -> Enforce (zero live violations)
- **policies:** Flip require-run-as-nonroot Audit -> Enforce with narrow alloy*/e1e-smoke excludes (documented)
- **apps:** AppProject cutover — every child off project:default (SEC-11 / review P1-2)
- **observability:** Grafana admin from Kubernetes Secret, not chart default (SEC-12 / review P1-3)
- **showcase:** Multi-stage slidev→caddy image, pinned + non-root (REQ-CADDY-S05-02)
- **ci:** Build, push + keyless cosign-sign kaddy-showcase (SEC-8)
- **policies:** Keyless attestor replaces placeholder cosign key (REQ-E1c-S03-02)

### Fixes
- **marshal:** CaddyTargetDown detects absent targets + wire coverage gate (REQ-E5-S03-01, REQ-E5-S06-05)
- **cluster:** Make E1e bring-up green on podman — kubeconfig isolation, rootful guard, IPv4 LB subnet, nodePort HTTP smoke
- **cluster:** E1e Cilium 1.18 apiVersions + prove LB-IPAM assigns + nodePort HTTP smoke
- **bootstrap:** Guard bootstrap:argocd to kind-kaddy-dev context + 600s cold-pull rollout timeout
- **ci:** Broaden scrub PATHS to deploy/.github/hack/tests (SEC-2)
- **ci:** Pin chainsaw + kyverno installs to exact versions (SEC-4)
- **ci:** Fix markdownlint config path + drop failure-swallowing || true (TEST-8)
- **ci:** Install pinned ripgrep — E1e meta gates use rg, absent on runner (TEST-2/SEC-4)
- **observability:** Loki writable PVC + single default datasource (REQ-E3-S02-03, REQ-E3-S02-05)
- **observability:** Ignore Grafana checksum drift so kps settles Synced (REQ-E3-S01-01)
- **ci:** Apply only staging issuer in chainsaw CI + doc fix (N1, N3)
- **gitops:** Bless root selfHeal in REQ/README/test; pin yq (tech-review F1 P1, F2 P3)
- **gitops:** Drop redundant directory:{recurse:false} from child Apps (root-OutOfSync); chainsaw runs on push to main
- **test:** Harden e4-s03-03 redirect check against doubled kubectl attach stream (REQ-E4-S03-03)
- **gitops:** Workloads App recurse:true so clubhouse/ subdir syncs (E4 GitOps convergence)
- **spec:** Sanitize malformed e8 Test path (spaces in filename — TEST-5 class)
- **demo:** Self-healing port-forwards + dedicated high ports for the e5 smoke/fire tooling (REQ-E5-S03-05)
- **monitoring:** Gate ClubhouseProbeLatencyHigh on probe success — outages are ClubhouseDown's job, not latency (REQ-E5-S03-03, TDD silent-case first)
- **kyverno:** Strip empty CRD label/annotation maps (SSA perpetual-OutOfSync)
- **policies:** VerifyImages Audit rule needs mutateDigest:false (rejected by Kyverno policy webhook on first live sync)
- **policies:** Narrow excludes for smoke probes + upstream controllers; probe-egress CNP to the edge
- **policies:** Also exclude the clubhouse-smoke-* HTTPS-gate probe pod (gateway ns, name-scoped)
- **netpol:** Gateway hairpin needs client-egress allow to the backend pod (Cilium preserves client identity through the Gateway proxy)
- **smoke:** E1c-exit portable to bash 3.2 (no associative arrays)
- **ci:** Create grafana-admin Secret in chainsaw CI — kps existingSecret made Grafana unready, helm --wait deadline (E1c follow-up)

### Tests
- **marshal:** Promtool L1 tests + PrometheusRule alerts for caddy/http
- **marshal:** Assert every alert rule has a promtool test (S06-05)
- **labels:** Negative-branch coverage for validations (REQ-E1b-EXIT)
- **cluster:** E1e meta + smoke suites and Taskfile targets
- **bootstrap:** RED REQ-E1-S01-01 handoff runbook smoke
- **bootstrap:** RED REQ-E1-S02-01 argocd-server Running smoke
- **e4:** Live HTTPS-no-k smoke + chainsaw for clubhouse (REQ-E4-S01/S02/S03)
- **e1b:** Add missing TEST-3 meta + exit-gate smoke tests (H2)
- **policy:** Kyverno CLI suites — pass+fail fixtures per admission policy (REQ-E1b-S05-*, ADR-0106, D-024)
- **deck:** Slidev-build reproducibility gate — exit 0 + refreshed slides/dist (REQ-E12-S01-01)
- **deck:** Exit-recording-ready composite gate + honest E12 tasks reconciliation (REQ-E12-EXIT)
- **caddy-mvp:** Skip-stub edge-route chainsaw suite — STRICT_TEST_FILES now fully green (REQ-CADDY-S01-01)
- **e5:** Live smoke bundle + marshal fire demo + chainsaw marshal suite (DIR-2, REQ-E5-S03-05, S04-01, S07-01/02, S08-02, REQ-E5-EXIT)
- **kyverno:** Fixtures for the E1c cutover excludes (28/28) — skips proven name/namespace-scoped via rogue-pod fail cases
- **chainsaw:** Un-skip labeling (TEST-4) + E1c security suites, live-verified
- **showcase:** Structural image gate for REQ-CADDY-S05-02 (TDD)

### Documentation
- **marshal:** Record tech-review carry-forwards (F1-F4)
- **labels:** Record tech-review carry-forwards + S04 descope recommendation
- **spec:** Defer REQ-E1b-S04-01 Terramate codegen to E1g (operator-ratified descope)
- **decisions:** Record operator calls D-014/D-021/D-022/D-023
- **spec:** E1e kind+Cilium local substrate (P0, D-025); reconcile E1 off driving-range
- **spec:** Record E1e implementation deviations (rootful podman, operator.replicas=1)
- **bootstrap:** Check E1 task boxes (S01/S02/S03 + smoke:e1 green)
- **inbox:** Audit-remediation plan digest + D-026 marshal park (operator-confirmed A)
- **plan:** Audit-remediation backlog (WS1-WS5) + mint e-caddy-mvp epic; marshal decision left OPEN (rec A)
- **substrate:** Retcon Talos->kind+Cilium as phase-1 substrate (ARCH-1, ARCH-6, DOC-1, DOC-2, DIR-5)
- **status:** Flip landed-artifact checkboxes to truth (DOC-3, DOC-6, TEST-7)
- **drift:** Fix Chainsaw dirs, workflow names, skill path, audit history, spec backticks (DOC-4, DOC-5, DOC-7, DOC-8, TEST-5, TEST-6)
- **plan:** Reconcile marshal decision to ANSWERED (Option A) + fix ADR-0107 link
- **agents:** Track AGENTS.md in the repo (un-ignore, ARCH-1/DOC-1)
- **agents:** Retcon substrate Talos->kind+Cilium in AGENTS.md (ARCH-1, DOC-1)
- **adr:** Retcon ADR-0104 — edge = Cilium/Envoy Gateway; Caddy = tenant MVP not gateway (ARCH-2, D-026)
- **spec:** Reconcile E5 + WS1 for the caddy_* alert migration (ARCH-2/ARCH-3, D-026)
- **spec:** Align config.yaml canonical label line to reconciled ADR-0301 (ARCH-4)
- **e2:** Gateway-spike decision doc — Cilium L0 proven by E1e/E1 (REQ-E2-S03)
- **e7:** Cross-ref E2 gateway-spike decision for HTTPRoute weights (REQ-E2-S03-02)
- **security:** Data-flow security review of the merged spine
- **status:** Status-truth sweep — flip E1/E2/E3/E4/E12 markers; update README spine + INBOX audit (DOC-10/DIR-1)
- **policy:** Enforcement-status matrix + Kyverno/netpol/AppProject cutover runbook; reconcile e1c tasks to offline subset (E1c/H1)
- **spec:** Re-point e5 marshal REQs at the served site + add S08 Grafana/S09 GitOps REQs (ARCH-2/ARCH-8/DIR-2, REQ-E5-S02-*/S03-*/S08-*/S09-01)
- **policies:** Truth pass — live enforcement matrix, cutover log, hairpin gotcha; tick cluster tasks (E1c)
- **release:** Pre-tag status-truth (E5/E7/E1c live), relocate FOLLOWUPS, pin monitoring yq (audit MUST + DOC-12 + SEC-16)
- **policies:** Keyless flip criteria + honest S05-02/e1c task ticks

### Refactoring
- **kaddy:** Pivot to spec-driven platform on main
- **cluster:** Address tech-review P2/P3 — v2 pool API, stronger smoke assertions, kubeconfig self-heal
- **monitoring:** Park caddy_* marshal alerts into e-caddy-mvp VM slice (ARCH-2/ARCH-3, D-026)
- **labels:** Reconcile to canonical bare-key label set (ARCH-4/WS5)
- **rollouts:** Honest S01-02/S02-02/S02-03 scoping + canaryMetadata track labels (E7)
- **deck:** Narrative-arc restructure — ordered beat markers + per-section time budget (590s) + portal-hero section + status truth refresh (REQ-E12-S04-01)

### CI & build
- **verify:** Add kaddy Taskfile verify workflow (verify + L0/L1 gates)

### Chores
- **ci:** Remove stale PocketIDP ci.yaml (wrong-repo remnant)
- **e4:** Add task bootstrap:e4 + test:smoke:e4; mark E4 tasks (REQ-E4)
- **release:** Git-cliff config for gitmoji-conventional changelog
- **release:** V0.1.0 changelog

### Other
- **ws4:** Enumerate missing test artifacts + chainsaw un-skip tasks (TEST-3, TEST-4)



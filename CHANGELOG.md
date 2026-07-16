# Changelog — kaddy

All notable changes to the kaddy platform. Generated with git-cliff from
gitmoji-conventional commit history.

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

### Other
- **ws4:** Enumerate missing test artifacts + chainsaw un-skip tasks (TEST-3, TEST-4)



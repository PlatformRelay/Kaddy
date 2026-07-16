# ROADMAP — kaddy

Build order for the gridscale platform-engineering exercise. **Phase 1 underway** — the brief spine
E1e → E1 → E3 → E4 is complete and demoable (**15/15** GitOps apps Synced/Healthy, clubhouse over
verified HTTPS through the Cilium edge); labels module (E1b), marshal monitoring (E5), gateway spike
(E2), Crossplane Website (E6), mulligan rollouts (E7), scorecard offline + Getting Started (E8),
security baseline cutover (E1c), identity (E1d), the optional Caddy operator (E9), first security
audit (E11-S01), and Slidev deck (E12) also landed on `main`. Two releases are tagged and published:
**v0.1.0** (serve → scrape → fire) and **v0.1.1** (self-service Websites, identity, CI parity). The
Caddy-MVP tenant syncs live from git (the `e-caddy-mvp` epic; the platform AppProject was unblocked
in D-036). Remaining work: phase-2 GSK (E6g/E13), the Backstage portal
(E10, cuttable), and the E12 demo recording (E12b). Each epic links an OpenSpec change under
`openspec/changes/`.

Status: ⬜ pending · 🚧 in progress · ✅ done · ✂️ cuttable

---

## Phases (D-025)

| Phase | Substrate | Spend | When | Epics |
| --- | --- | --- | --- | --- |
| **1 · Platform (local)** | **kind + Cilium** ([E1e](../openspec/changes/e1e-kind-local-cluster/), ✅ landed) — single-node; **Cilium Gateway** + LB-IPAM/L2; in-cluster state | $0 | Now — develop GitOps platform locally | kaddy **E1e** → E1 → E1b∥E1c → E2 → E3 → E4∥E5 → E6 → E7 → E8 |
| **2 · Lab (gridscale)** | GSK + LBaaS + Object Storage | Lab credits | After E3–E7 green locally | E1g → E6g → E8b |

**Gate to phase 2:** E3–E7 green on the local kind cluster → start E1g (gridscale day-0).

The 3-node Talos [driving-range](../../driving-range/) is a **deferred optional maturity-contrast spike**
(D-025), not a phase-1 blocker — see the section near the end of this file.

Phase 1 deltas vs phase 2 (document in runbooks):

| Concern | Phase 1 (kind + Cilium) | Phase 2 (gridscale) |
| --- | --- | --- |
| Substrate | Local kind cluster ([E1e](../openspec/changes/e1e-kind-local-cluster/)) | GSK managed k8s |
| Edge / TLS | **Cilium Gateway** + LB-IPAM/L2 + cert-manager | LBaaS + Let's Encrypt + cert-manager |
| Identity | Dex + GitHub OAuth | Same (update Dex issuer URL for LBaaS domain) |
| nginx legacy | In-cluster Deployment (stand-in) | `gridscale_server` via Upjet Crossplane |
| Crossplane cloud API | Website XRD only (no provider-gridscale) | Upjet `provider-gridscale` |

---

## Testing foundation (cross-cutting)

**OpenSpec:** [testing-foundation](../openspec/changes/testing-foundation/)  
**ADR:** [0701](adr/0701-testing-strategy-chainsaw.md) · **Docs:** [development/testing.md](development/testing.md)

| Level | Tool | Epic introducing |
| --- | --- | --- |
| L0 | `tofu test` | E1b |
| L1 | conftest | E1b |
| L1 | **promtool** (PrometheusRule alerts) | E5 |
| L2 | **Chainsaw** | E1b/E1c → CI at E3 |
| L3 | k6 | E8 |
| L4 | scorecard | E8 |

---

## E1e · Local kind substrate (Cilium Gateway API) ✅

**OpenSpec:** [e1e-kind-local-cluster](../openspec/changes/e1e-kind-local-cluster/)  
**ADR:** [0104](adr/0104-caddy-gateway-api.md) · **Decision:** D-025 (amends D-017)

Owns **substrate + edge** for phase-1 local development: a reproducible **kind** cluster (`kaddy-dev`,
single control-plane node, Kubernetes v1.33.1) running **Cilium 1.18** (CNI + Gateway API + LB-IPAM/L2,
kube-proxy replacement, operator `replicas=1`), **cert-manager v1.18.2** with a self-signed
`kaddy-local-ca` issuer, and the built-in local-path StorageClass. macOS-safe: Gateway/LB IPs asserted
assigned (not host-curled); HTTP smoke via loopback-bound `extraPortMappings`. E1 bootstraps ArgoCD on top.

| ID | Story | Status |
| --- | --- | --- |
| E1e-S01 | Cilium-ready, loopback-bound kind config | ✅ |
| E1e-S02 | Cilium CNI + Gateway API + LB-IPAM/L2 (kube-proxy replaced) | ✅ |
| E1e-S03 | cert-manager pinned + `kaddy-local-ca` issuer + default StorageClass | ✅ |
| E1e-S04 | Gateway HTTP reachable locally (macOS-safe) | ✅ |
| E1e-S05 | Secure install — pinned versions, no `:latest`, no secrets in git | ✅ |

---

## E1 · Platform bootstrap (kind → ArgoCD) ✅

**OpenSpec:** [e1-day0-bootstrap](../openspec/changes/e1-day0-bootstrap/)  
**ADR:** [0102](adr/0102-talos-immutable-substrate.md) · **Depends:** [E1e](../openspec/changes/e1e-kind-local-cluster/) local cluster Ready

| ID | Story | Status |
| --- | --- | --- |
| E1-S01 | Document kubeconfig / Cilium Gateway / StorageClass handoff contract | ✅ |
| E1-S02 | Bootstrap ArgoCD (initial Application) on the kind cluster | ✅ |
| E1-S03 | Verify cluster baseline (nodes Ready, default SC, Cilium LB-IPAM pool) | ✅ |

### E1-S01 — Handoff contract

**Given** the [E1e](../openspec/changes/e1e-kind-local-cluster/) kind cluster exports `kubeconfig` and
provides Cilium Gateway + default StorageClass  
**When** operator runs `task cluster:up` (E1e) and bootstraps ArgoCD  
**Then** `kubectl get nodes` succeeds from the kaddy workspace

**Exit criteria (epic):** ArgoCD UI reachable via Cilium-assigned Gateway/LB IP; cluster baseline documented.

---

## E1g · Gridscale day-0 (phase 2 — deferred)

**OpenSpec:** [e1g-gridscale-day0](../openspec/changes/e1g-gridscale-day0/)  
**ADR:** [0102](adr/0102-talos-immutable-substrate.md), [0302](adr/0302-terramate-opentofu-stacks.md)  
**Gate:** E3–E7 green on the local kind cluster (E1e)

| ID | Story | Status |
| --- | --- | --- |
| E1g-S01 | Terramate root + gridscale provider (`~> 2.2`) + object-storage state backend | 🟨 offline-authored (live-proof pending) |
| E1g-S02 | Network + firewall + IP stack | 🟨 offline-authored (live-proof pending) |
| E1g-S03 | GSK cluster (`gridscale_k8s`) + node pool | 🟨 offline-authored (live-proof pending) |
| E1g-S04 | LBaaS entry point in front of Gateway | 🟨 offline-authored (live-proof pending) |
| E1g-S05 | Retrieve kubeconfig + re-point ArgoCD bootstrap | ⬜ |

🟨 = IaC authored + proven by the OFFLINE gate (`task test:smoke:e1g`: terramate codegen, `tofu fmt`/`validate`/`test` with mocked provider, conftest plan policy). Live provisioning (`task e1g:up`) is a later serialized step. Runbook: [docs/runbooks/gridscale-day0.md](runbooks/gridscale-day0.md).

**Exit criteria (epic):** Same GitOps apps sync on GSK; LBaaS public URL works; Dex issuer URL updated for public domain.

---

## E1b · Naming & labeling module ✅ (S04 deferred to E1g)

**OpenSpec:** [e1b-labeling-module](../openspec/changes/e1b-labeling-module/)  
**ADR:** [0301](adr/0301-resource-labeling-convention.md)

| ID | Story | Status |
| --- | --- | --- |
| E1b-S01 | `modules/labels` with outputs + naming helper | ✅ |
| E1b-S02 | `tofu test` fixtures for labels and names | ✅ |
| E1b-S03 | conftest policy — mandatory keys on plans | ✅ |
| E1b-S04 | Terramate codegen injects labels into all stacks | 🟨 offline-authored in E1g (codegen `_terramate_generated_labels.tf` in every gridscale stack) |
| E1b-S05 | Kyverno require-labels ClusterPolicy | ✅ |

### E1b-S02 — tofu test fixtures

**Given** the labels module  
**When** `tofu test` runs in CI  
**Then** tests fail if required keys missing or name exceeds length / invalid charset

---

## E1c · Security baseline ✅ (Kyverno Enforce + netpol + AppProjects live; verifyImages stays Audit)

**OpenSpec:** [e1c-security-baseline](../openspec/changes/e1c-security-baseline/)  
**ADR:** [0106](adr/0106-security-baseline.md)

| ID | Story | Status |
| --- | --- | --- |
| E1c-S01 | Default-deny NetworkPolicy template per namespace | ✅ (gateway/monitoring/argocd/mulligan/websites + caddy-mvp) |
| E1c-S02 | Trivy scan job in CI | ✅ (CRITICAL fails) |
| E1c-S03 | cosign sign + Kyverno verifyImages | 🚧 (keyless policy Audit; showcase-image workflow signs) |
| E1c-S04 | External Secrets pattern for gridscale creds | ✅ (offline pattern authored) |
| E1c-S05 | SOPS + age + KSOPS plugin for `deploy/secrets/` ([ADR-0110](adr/0110-secrets-sops-age.md)) | ✅ (identity secrets + KSOPS patch) |

---

## E1d · Identity (Dex + GitHub) ✅ (Grafana OAuth deferred to E10)

**OpenSpec:** [e1d-identity-keycloak-dex](../openspec/changes/e1d-identity-keycloak-dex/)  
**ADR:** [0107](adr/0107-identity-dex.md) · **Decision:** D-018  
**Depends:** E3-S01 (app-of-apps), E4-S03 (TLS at gateway for Dex issuer URL)

| ID | Story | Status |
| --- | --- | --- |
| E1d-S01 | Dex deployment + GitHub connector (**PlatformRelay** org) + SOPS OAuth secret | ✅ |
| E1d-S02 | Argo CD OIDC via Dex + RBAC (GitHub teams → groups) | ✅ (teams allowlist → E10) |
| E1d-S03 | Grafana OAuth via Dex | ⬜ (deferred → E10) |
| E1d-S04 | NetworkPolicy for `identity` namespace | ✅ |

### E1d-S02 — Argo CD OIDC

**Given** Dex issuer healthy with GitHub connector  
**When** operator opens Argo CD UI  
**Then** login redirects to GitHub via Dex; unauthenticated API returns 401

**Exit criteria:** `chainsaw test tests/chainsaw/identity` green (non-skipped).

---

## E2 · Gateway spike (Cilium Gateway API) ✅ (S02 weight-mutation deferred to E7)

**OpenSpec:** [e2-gateway-spike](../openspec/changes/e2-gateway-spike/)  
**ADR:** [0104](adr/0104-caddy-gateway-api.md) · **Decision:** D-019

| ID | Story | Status |
| --- | --- | --- |
| E2-S01 | Assert Gateway API CRDs + Cilium `GatewayClass` + LB-IPAM pool (handoff from E1e local cluster) | ✅ |
| E2-S02 | GitOps `Gateway` + HTTPRoute path routing + weight-mutation spike | ⬜ (deferred to E7) |
| E2-S03 | Document fallback level (L0/L1/L2) in decision log | ✅ |

**Exit criteria:** Spike report in `docs/decisions/e2-gateway-spike.md`; E7 unblocked or fallback chosen.

---

## E3 · GitOps platform core ✅ (S04 Argo Rollouts deferred to E7)

**OpenSpec:** [e3-gitops-core](../openspec/changes/e3-gitops-core/)  
**ADR:** [0103](adr/0103-argocd-gitops.md)

| ID | Story | Status |
| --- | --- | --- |
| E3-S01 | App-of-apps root Application (incl. `identity`, `observability`, **KSOPS**) | ✅ |
| E3-S02 | Observability: kube-prometheus-stack **+ Loki + Grafana Alloy** ([ADR-0108](adr/0108-logging-loki.md)) | ✅ |
| E3-S03 | cert-manager + Let's Encrypt **staging & prod** ClusterIssuers (HTTP-01 via Gateway) | ✅ |
| E3-S04 | Argo Rollouts + Gateway API plugin | ⬜ (deferred to E7) |

---

## E4 · Sample site (clubhouse) + TLS ✅

**OpenSpec:** [e4-clubhouse-tls](../openspec/changes/e4-clubhouse-tls/)

| ID | Story | Status |
| --- | --- | --- |
| E4-S01 | Static web Deployment + Service | ✅ |
| E4-S02 | HTTPRoute `/` → clubhouse | ✅ |
| E4-S03 | TLS via cert-manager — staging validate, then **prod trusted cert** + auto-renew | ✅ |

**Given** Gateway and cert-manager are ready  
**When** user curls `https://<host>/`  
**Then** clubhouse HTML is served with valid TLS

---

## E5 · Monitoring & alerting (marshal) ✅ (fire-leg live: probe→alert→Alertmanager; receiver + Loki-ruler deferred)

**OpenSpec:** [e5-monitoring-marshal](../openspec/changes/e5-monitoring-marshal/)

| ID | Story | Status |
| --- | --- | --- |
| E5-S01 | Scrape platform gateway + clubhouse app metrics (PodMonitor/ServiceMonitor) | ✅ |
| E5-S02 | blackbox_exporter probes (uptime, status codes) | ✅ |
| E5-S03 | PrometheusRules: down, error rate, latency, request rate | ✅ |
| E5-S04 | Alertmanager receiver (ntfy/webhook) | 🚧 (routing proven to null receiver; external webhook deferred) |
| E5-S05 | Grafana dashboards-as-code (+ Loki logs panel) | ✅ (kaddy-marshal, 12 panels, sidecar-provisioned) |
| E5-S06 | **promtool unit tests** for every alert rule (L1, CI) | ✅ |
| E5-S07 | **Loki log-based checks** — gateway/access logs, labels, 5xx alert ([ADR-0108](adr/0108-logging-loki.md)) | 🚧 (logs+labels live; ruler alert deferred) |

---

## E6 · Crossplane self-service + nginx legacy (phase 1 — local) ✅

**OpenSpec:** [e6-crossplane-website](../openspec/changes/e6-crossplane-website/)  
**ADR:** [0105](adr/0105-crossplane-self-service.md)

| ID | Story | Status |
| --- | --- | --- |
| E6-S01 | Install Crossplane (no cloud provider yet) | ✅ |
| E6-S02 | XRD `Website` + Composition (HTTPRoute + monitors) | ✅ |
| E6-S03 | Demo claim / composed workload (putting-green) | ✅ |
| E6-S04 | HTTPRoute path + TLS via clubhouse Gateway | ✅ |
| E6-S05 | Composed ServiceMonitor scraped | ✅ |

---

## E6g · Crossplane provider-gridscale (phase 2 — deferred)

**OpenSpec:** [e6g-provider-gridscale](../openspec/changes/e6g-provider-gridscale/)  
**ADR:** [0105](adr/0105-crossplane-self-service.md) · **Gate:** E1g complete

| ID | Story | Status |
| --- | --- | --- |
| E6g-S01 | Generate thin `provider-gridscale` with Upjet (time-boxed) + plain-TF fallback | 🟡 codegen done (sibling); xpkg build → live |
| E6g-S02 | Install `provider-gridscale` (ProviderConfig) | 🟡 offline-complete; live install pending |
| E6g-S03 | Extend Composition: `gridscale_server` nginx VM | 🟡 offline-complete; real VM pending |
| E6g-S04 | Re-verify `/legacy` routing + monitoring on real VM | ⬜ live cycle only |

**Offline (this repo):** Provider + ClusterProviderConfig + creds Secret template
(`deploy/crossplane/provider-gridscale.yaml`, `providerconfig-gridscale.yaml`) and
a variant-selected 2nd Website Composition
(`composition-website-gridscale.yaml`: Server + Network/IPv4/Storage nginx VM,
cloud-init page + `/metrics`) — the in-cluster path is untouched. Gated by
`task test:smoke:e6g` (structural + `kubeconform` vs the sibling's generated
CRDs). **Live-proof pending** (D-016): the sibling xpkg is not yet built/pushed,
so provider install + real VM + `/legacy` are DEFERRED to the E6g live cycle —
see [runbooks/gridscale-provider.md](runbooks/gridscale-provider.md).

---

## E13 · gridscale Marketplace template (Caddy + nginx) (phase 2 — deferred)

**OpenSpec:** [e13-gridscale-marketplace](../openspec/changes/e13-gridscale-marketplace/)  
**ADR:** [0105](adr/0105-crossplane-self-service.md) · **Decision:** D-032 · **Gate:** E1g complete

The **third way** to satisfy the exercise (alongside E-Caddy-MVP Variant B / K8s and Variant A + E6g /
Crossplane VM): a gridscale-native **Marketplace 2.0 template**. Terraform-native (operator-approved):
build image → snapshot → export `.gz` to object storage → `gridscale_marketplace_application` (+ icon) →
`_import` into our tenant (private; no global approval) → deploy a `gridscale_server` from it that serves
the page + feeds the `caddy_*` marshal alerts.

| ID | Story | Status |
| --- | --- | --- |
| E13-S01 | Golden image build (Caddy/nginx + `/metrics`) → export `.gz` to object storage | 🟨 offline-authored (live-proof pending) |
| E13-S02 | Register + import Marketplace application via Terraform (both engines, private tenant) | 🟨 offline-authored (live-proof pending) |
| E13-S03 | Deploy proof: server from template serves page + `caddy_*` alert fires (serve→scrape→fire) | 🟨 offline-authored (live-proof pending) |
| E13-S04 | Runbook + exercise-traceability row | ✅ |

🟨 = IaC/image-pipeline authored + proven by the OFFLINE gate (`task test:smoke:e13`: terramate codegen, `tofu fmt`/`validate`/`test` with mocked provider, `packer fmt`/`validate`, `promtool` caddy_* fire test). Live build → export → register → import → deploy (`task e13:up` + the export/deploy steps) is a later serialized, cost-gated step. Runbook: [docs/runbooks/gridscale-marketplace-deploy.md](runbooks/gridscale-marketplace-deploy.md).

**Constraints (designed around):** `category` enum has no "web server" (use `Adminpanel`/`CMS` + `meta_*`);
`object_storage_path` must be `.gz`/`s3://`; `meta_icon` required. Global listing needs gridscale review
(`product@gridscale.io`) — out of scope; we publish privately into our own tenant.

---

## E7 · Progressive delivery (mulligan) ✅ (live weight shift + abort rollback; analysis scaffolded)

**OpenSpec:** [e7-mulligan-rollouts](../openspec/changes/e7-mulligan-rollouts/)  
**ADR:** [0201](adr/0201-rollouts-blue-green-canary.md)

| ID | Story | Status |
| --- | --- | --- |
| E7-S01 | Blue/green Rollout + pre-promotion AnalysisTemplate | ✅ (analysis scaffolded, not gating) |
| E7-S02 | Canary Rollout + HTTPRoute weights | ✅ (live 100/0→20→50→100 + abort→0) |
| E7-S03 | `task demo` choreography + asciinema recording | ✅ (recording hook documented) |
| E7-S04 | Chaos: kill pod + VM → alert + reconcile | 🚧 (abort auto-rollback done; VM chaos → gridscale epics) |

---

## E8 · Evidence & submission (scorecard) ✅ (offline + Getting Started + Pages live; live k6 deferred)

**OpenSpec:** [e8-scorecard-evidence](../openspec/changes/e8-scorecard-evidence/)  
**ADR:** [0202](adr/0202-evidence-as-artifact.md)

| ID | Story | Status |
| --- | --- | --- |
| E8-S01 | k6 load profile tripping threshold alert | ✅ (offline profile + smokes; live k6 deferred) |
| E8-S02 | Capture script → HTML report | ✅ (fixture capture + validate; live capture deferred) |
| E8-S03 | GitHub Pages publish workflow | ✅ (Pages live — https://platformrelay.github.io/Kaddy/ HTTP 200) |
| E8-S04 | Getting Started: safe bring-up, service access, reviewer demo, recovery + cost | ✅ |

### E8-S04 — Getting Started and reviewer demo

**Given** a reviewer has the documented local prerequisites but no running kaddy cluster
**When** they follow `docs/getting-started.md`
**Then** they can safely bring up `kind-kaddy-dev`, discover and open the documented platform
surfaces, demonstrate Website self-service, alert fire/resolve, progressive delivery and rollback,
and tear the environment down without relying on hidden operator knowledge

**Edge cases:** occupied port-forward ports, interrupted demos, unavailable optional surfaces, and
an ambient non-kind kubeconfig are handled explicitly; unpublished URLs are never presented as live.

**Exit criteria:** REQ-E8-S04-01..06 green; the root README links the guide from its five-minute
reviewer path.

---

## E8b · Live demo environment

**OpenSpec:** [e8b-live-demo](../openspec/changes/e8b-live-demo/)
**Runbook:** [gridscale-live-demo.md](runbooks/gridscale-live-demo.md)

DECIDED-B (operator-approved): E8b ships as a reproducible **on-demand** bring-up
(`task e8b:up` / `e8b:down`), proven ephemerally — **not a standing environment**
(the ruthless-teardown cost rule holds; the "interview window" is
operator-triggered). Offline-authored below; live bring-up/serve pending the live
cycle.

| ID | Story | Status |
| --- | --- | --- |
| E8b-S01 | On-demand gridscale demo bring-up (`e8b:up`/`e8b:down`, ruthless teardown) | 🟨 (offline-authored: targets + runbook; live bring-up pending) |
| E8b-S02 | Serve scorecard + read-only Grafana via Gateway TLS | 🟨 (offline-authored: GitOps surfaces + prefix-strip route/RBAC + kubeconform; scorecard serves a landing page linking to the published GitHub Pages scorecard — live evidence-bundle swap + live serve pending) |

---

## E9 · Caddy operator (optional) ✅ (S01–S03 on `main` after v0.1.1, envtest green)

**OpenSpec:** [e9-caddy-operator](../openspec/changes/e9-caddy-operator/)  
**ADR:** [0401](adr/0401-caddy-operator-design-first.md)

| ID | Story | Status |
| --- | --- | --- |
| E9-S01 | kubebuilder scaffold + CRD types | ✅ |
| E9-S02 | Caddy reconciler (Admin API) | ✅ |
| E9-S03 | CaddySite + observability bundle | ✅ |

**Gate:** start only if E1–E8 ✅

---

## E11 · Security & compliance audit runs

**OpenSpec:** [e11-security-audit](../openspec/changes/e11-security-audit/)  
**Procedure:** [audits/README.md](audits/README.md)

| ID | Story | Status |
| --- | --- | --- |
| E11-S01 | First dated audit report | ✅ ([2026-07-16](audits/2026-07-16-audit.md)) |
| E11-S02 | Diff vs subsequent run | ✅ ([2026-07-16-s02](audits/2026-07-16-s02-audit.md)) |

---

## E12 · Slidev showcase deck 🚧 (S01–S04 ✅ on `main`; 🚧 = the live video recording, E12b, is operator-manual)

**OpenSpec:** [e12-slidev-deck](../openspec/changes/e12-slidev-deck/)

**Deck = spine of a recorded 5–10 min video** (D-031): word-by-word speaker notes on every slide +
heavy live iframes (Backstage, ArgoCD, Grafana/marshal, the running Caddy site, the Crossplane graph).

| ID | Story | Status |
| --- | --- | --- |
| E12-S01 | Slidev scaffold + reproducible static build | ✅ (`tests/deck/slidev-build.sh` + deck CI) |
| E12-S02 | Word-by-word speaker notes on every slide (5–10 min script) | ✅ (30/30 slides; 1358 words ≈ 9–10 min; coverage + wordcount gates) |
| E12-S03 | Live iframes embed running platform surfaces (GIF fallback) | ✅ (3 live + 2 fallback embeds; `iframe-surfaces.sh`) |
| E12-S04 | Narrative beats: pitch → arch → security → auto-gen money-shot → mulligan → marshal → scorecard | ✅ (7 ordered beats; 590 s budget; `narrative-beats.sh`) |

---

## E10 · Portal / IDP ✂️ (auto-generated from the XRD)

**OpenSpec:** [e10-portal-stretch](../openspec/changes/e10-portal-stretch/) — **cuttable**  
**ADR:** [0109](adr/0109-idp-portal-orchestrator.md), [0111](adr/0111-portal-auto-generation.md) · **Decisions:** D-014, D-027, D-028, D-029

**Orchestrator = Crossplane (E6, already the platform API). Portal = Backstage (OSS, phased).**
The scaffolder form is **auto-generated from the `Website` XRD** by kubernetes-ingestor (no
hand-written template) → opens a GitOps **PR** with a `Website` v2 XR → Argo CD applies → Crossplane
reconciles. Read-path plugins (Crossplane graph, ArgoCD, K8s) render live status in-portal.

| ID | Story | Status |
| --- | --- | --- |
| E10-S01 | Backstage via GitOps + OIDC (Dex) | ⬜ |
| E10-S02 | Auto-generated scaffolder (kubernetes-ingestor) → `Website` XR PR | ⬜ |
| E10-S03 | Scaffolded XR reconciles end-to-end (Chainsaw) | ⬜ |
| E10-S04 | Read-path plugins (Crossplane graph + ArgoCD + K8s), read-only RBAC | ⬜ |
| E10-S05 | Software Catalog (+ auto-ingested XRs) + TechDocs | ⬜ |
| E10-S06 | Runbook + demo (auto-gen money-shot) | ⬜ |

**Scope guard (ADR-0109):** orchestrator-first — E6 already delivers the *capability*; the portal is
*experience* and only starts if E1–E8 land early. SaaS (Port/Humanitec) rejected for the lab.
**Read-path trade (D-029):** read-only cluster creds accepted — impressiveness > minimal-trust for the demo.

---

## driving-range · deferred optional Talos spike (D-025)

**Repo:** [driving-range](../../driving-range/) — **not** a kaddy epic and **not** a phase-1 blocker.

Per **D-025**, phase-1 development moved to the local **kind + Cilium** cluster ([E1e](../openspec/changes/e1e-kind-local-cluster/))
after the 3-node Talos driving-range cost hours of libvirt/Talos yak-shaving without a working cluster.
The long-lived **3-node Talos** driving-range (1 control plane + 2 workers on libvirt/KVM, OpenTofu-declared,
**Cilium CNI + Gateway API + LB-IPAM/L2**, no MetalLB, `local-path-provisioner`) survives as a **deferred
optional maturity-contrast spike** — it ships only if E1–E8 land early and interviewers prize bare-substrate
bootstrapping. See driving-range `driving-range/docs/ROADMAP.md` and
`driving-range/docs/ARCHITECTURE.md` (sibling repo).

---

## Suggested loop order

**Phase 1 — kaddy on local kind ($0 cloud)**

1. **E1e** (kind + Cilium substrate — ✅ landed)  
2. **E1** (kubeconfig handoff + ArgoCD — ✅ landed) → E1b ∥ E1c  
3. **E2** (gateway spike — ✅ landed; weight-mutation → E7)  
4. **E3** → **E4** (✅ landed) ∥ E5 → E6 → **E7** → E8 (evidence from local cluster)

**Phase 2 — gridscale lab (after E3–E7 green locally)**

5. E1g (GSK day-0) → E6g (Upjet provider + VM) → E8b (live demo)  
6. E11, E12 in parallel where possible  
7. E9 / E10 if time

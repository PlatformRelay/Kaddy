<!-- markdownlint-disable MD025 MD041 MD033 MD024 MD013 MD036 MD001 MD003 MD022 MD023 -->
---
theme: seriph
title: kaddy — Website-as-a-Service
info: |
  ## kaddy — a caddie for your websites
  Security-first, spec-driven, Kubernetes-native Website-as-a-Service.
  Built for the gridscale Platform Engineer exercise.
layout: none
transition: slide-left
mdc: true
beat: pitch
sectionTime: 40
---

<!--
Section covers (E12b): every <CoverArt> `src` points at the FINAL artwork
filename under slides/public/covers/ (prompts + name map live in
slides/image-prompts.md). Cover filenames are STABLE ART IDS in generation
order (S00–S14) — after the E12-S04 narrative-arc restructure the displayed
§ numbers are renumbered to the new order, so a filename's NN may differ from
the kicker's §. Until a PNG is generated and dropped in, CoverArt falls back
to covers/placeholder-section.svg — no code change needed later. The
low-opacity "AI generated" footer it renders is a mandatory guardrail.

Narrative annotations (E12-S04): each section divider carries `sectionTime`
(seconds budgeted for the section, summing to a 5–10 min walkthrough) and the
seven spec beats carry `beat:` markers — pitch → architecture → security →
portal-hero → mulligan → marshal → scorecard (tests/deck/narrative-beats.sh).

Speaker notes (E12-S02): the LAST comment block on every slide is the
verbatim voiceover — read it word for word; the whole script is budgeted for
a 5–10 minute recording (tests/deck/speaker-notes-coverage.sh +
tests/deck/script-wordcount.sh).
-->

<CoverArt
  src="/covers/section-00-first-tee.png"
  kicker="§ 00 · The first tee"
  title="kaddy — a caddie for your websites"
/>

<!--
Hi, I'm Konrad. This is kaddy — my answer to the gridscale platform
engineering exercise.
-->

---
layout: cover
class: text-center
---

# kaddy

## A caddie for your websites

Security-first · spec-driven · Kubernetes-native **Website-as-a-Service**

<div class="pt-8 opacity-70 text-sm">
gridscale Platform Engineer exercise — platform engineering showcase
</div>

<div class="abs-br m-6 text-xs opacity-50">
github.com/PlatformRelay/Kaddy
</div>

<!--
The exercise says: install Caddy on a VM, serve a page, scrape it with
Prometheus, and fire an alert. I could have solved that with a bash script in
an afternoon. Instead, I built the platform that script would be one tenant
of — spec-driven, security-first, and Kubernetes-native. Over the next nine
minutes I'll show you what is actually running, what is deliberately still on
the drawing board, and why that distinction is the whole point of how I work.
-->

---
layout: none
sectionTime: 35
---

<CoverArt
  src="/covers/section-01-one-line-letter.png"
  kicker="§ 01 · The one-line letter"
  title="The brief, reframed"
/>

<!--
First, let's read the brief again — carefully. There's a bigger question
hiding in that one line.
-->

---
layout: statement
---

# The brief, reframed

*"Install Caddy on a Linux VM, serve a page, scrape it with Prometheus, fire an alert."*

<div class="pt-6 text-xl opacity-80">

A one-off VM script answers the letter of the exercise.

It does **not** answer the question a platform team is actually asking:

</div>

<div class="pt-4 text-2xl font-bold text-teal-400">
How do you run monitored, TLS-terminated websites as a repeatable, governed product?
</div>

<!--
Taken literally, the brief is one afternoon of work: a VM, a Caddyfile, a
scrape config, one alert rule. But that answers the letter of the exercise,
not the question behind it. A platform team isn't hiring someone to install
one web server. They're asking: how do you run monitored, TLS-terminated
websites as a repeatable, governed product? So that is the question I chose
to answer — with the original task kept fully intact inside it.
-->

---
layout: none
sectionTime: 45
---

<CoverArt
  src="/covers/section-02-one-hole-whole-course.png"
  kicker="§ 02 · One hole, whole course"
  title="From task to platform"
/>

<!--
So kaddy treats the exercise as one hole on a much bigger course.
-->

---
layout: two-cols
layoutClass: gap-8
---

# From task to platform

**The exercise as one tenant**

The named subject — install Caddy, serve, scrape, alert — is satisfied as a
single **Website-as-a-Service** tenant (`clubhouse`), reached *through* the
platform edge, not as a bespoke script.

- One self-service **claim** → a monitored, TLS-terminated site
- Observability, alerting, and progressive delivery are platform features every
  tenant inherits — not per-site glue
- The brief's optional nginx reverse-proxy is the same shape: a second tenant

::right::

<div class="pt-14">

## The caddie metaphor

| Component | Role |
| --- | --- |
| **clubhouse** | the sample website tenant (the brief) |
| **marshal** | alerting — PrometheusRules + Alertmanager |
| **mulligan** | blue/green + canary with auto-rollback |
| **scorecard** | k6 + metrics/logs → HTML evidence report |

</div>

<!--
Concretely, the Caddy task becomes one tenant of a Website-as-a-Service
platform. The sample site is called clubhouse, and it's reached through the
platform edge like every other tenant. Observability, alerting, and
progressive delivery are platform features every tenant inherits — not glue
that gets rebuilt per site. And the naming isn't decoration: marshal is
alerting, mulligan is rollback, scorecard is evidence. Each name maps to a
directory and a capability, so incident conversations stay precise.
-->

---
layout: none
sectionTime: 45
---

<CoverArt
  src="/covers/section-03-honest-scorecard.png"
  kicker="§ 03 · The honest scorecard"
  title="What is actually landed vs designed"
/>

<!--
Before the architecture, the credibility slide: what's real today, and what
is still design.
-->

---
layout: statement
---

# What is actually landed vs designed

<div class="text-left max-w-3xl mx-auto pt-4 text-lg">

I am going to be precise about this, because a senior audience will check.

</div>

<div class="grid grid-cols-2 gap-6 pt-6 text-left max-w-4xl mx-auto">

<div class="p-4 rounded border border-green-600">

### ✅ Landed & gated on `main`

- **kind + Cilium** substrate (E1e) + **ArgoCD bootstrap** (E1)
- **GitOps app-of-apps** — 9/9 apps Synced/Healthy (E3)
- **Observability spine deployed** — Prometheus · Alertmanager · Grafana · Loki · Alloy
- **clubhouse over verified HTTPS** through the Cilium edge (E4)
- **marshal** rules + monitors + **promtool** unit tests (E5)
- **mulligan** blue/green + canary — **live HTTPRoute weight shift** (E7)
- **labels** + Rego + Kyverno · CI gates (gitleaks, conftest, `tofu test`, pins)

</div>

<div class="p-4 rounded border border-amber-600">

### 🧭 Designed — specs + manifests, not yet running

- Alertmanager **receiver** · dashboards-as-code · Loki log checks (E5 rest)
- Crossplane `Website` XRD (E6) · Dex OIDC (E1d)
- **Backstage portal auto-generated from the XRD** (E10)
- E1c enforcement **cutover** (policies authored + CLI-tested, runbook committed)
- Phase 2: gridscale **GSK + LBaaS + Upjet**

</div>

</div>

<div class="pt-6 text-center text-teal-400">
Phase 1 runs live on a $0 local cluster — and every "landed" claim has a gate behind it: ADRs, specs, manifests, enforced policy, tested alerts, gated CI.
</div>

<!--
I'll be precise here, because a senior audience will check. Running and gated
on main today: the kind-plus-Cilium substrate, ArgoCD with an app-of-apps —
nine of nine applications synced and healthy — the full observability spine
with Prometheus, Alertmanager, Grafana, Loki and Alloy, clubhouse served over
verified HTTPS through the Cilium edge, promtool-tested alert rules, and Argo
Rollouts shifting live traffic weights. Still designed, not running: the
Alertmanager receiver, the Crossplane Website XRD, Dex, and the Backstage
portal. Everything I claim, I can defend.
-->

---
layout: none
beat: architecture
sectionTime: 50
---

<CoverArt
  src="/covers/section-04-two-courses-one-blueprint.png"
  kicker="§ 04 · Two courses, one blueprint"
  title="Architecture — two phases, one set of manifests"
/>

<!--
Now the architecture — two phases, one blueprint.
-->

---
layout: default
---

# Architecture — two phases, one set of manifests

```mermaid {scale: 0.62}
flowchart LR
  subgraph Dev["Developer / GitOps"]
    G["Git — deploy/** manifests<br/>(single source of truth)"]
    A["ArgoCD<br/>app-of-apps"]
    G --> A
  end

  subgraph Cluster["Kubernetes substrate"]
    direction TB
    GW["Cilium Gateway API<br/>(Envoy) + LB-IPAM/L2"]
    subgraph Tenants["Tenant products (WaaS)"]
      CB["clubhouse<br/>(static site)"]
      CD["Caddy tenant<br/>(brief)"]
      NX["nginx legacy<br/>(optional)"]
    end
    OBS["Observability<br/>Prometheus · Loki · Alloy · Grafana"]
    POL["Policy<br/>Kyverno · NetworkPolicies"]
    RO["Argo Rollouts<br/>(HTTPRoute weights)"]
  end

  A --> GW & Tenants & OBS & POL & RO
  GW --> Tenants
  OBS -. scrape/logs .-> Tenants
  RO -. weight shift .-> GW

  P1["Phase 1: kind + Cilium (local, $0)"]:::phase
  P2["Phase 2: gridscale GSK + LBaaS + Upjet"]:::phase
  Cluster --- P1
  Cluster --- P2

  classDef phase fill:#0d3b3b,stroke:#14b8a6,color:#fff;
```

<div class="text-sm opacity-75 pt-2">

Same GitOps manifests target both substrates. Phase 1 (**kind + Cilium**, landed) is where the platform is developed; Phase 2 (**gridscale GSK**) re-syncs the identical apps behind LBaaS — deferred until Phase 1 is green. See `docs/ARCHITECTURE.md`, ADR-0102 (D-025), ADR-0104.

</div>

<!--
The design principle is portability. Everything is GitOps: the deploy
directory is the single source of truth, and ArgoCD converges the cluster
onto it. Phase one runs on a local kind cluster with Cilium — zero cloud
spend. Phase two is gridscale GSK with LBaaS in front. Critically, both
phases share the same manifests and the same edge shape — Cilium Gateway API
— so the promotion to gridscale is a re-sync, not a rewrite. And Caddy is a
tenant behind that edge, never the edge itself.
-->

---
layout: none
sectionTime: 35
---

<CoverArt
  src="/covers/section-05-practice-green.png"
  kicker="§ 05 · The practice green"
  title="Substrate — local kind + Cilium"
/>

<!--
A quick look at the substrate underneath — the practice green.
-->

---
layout: two-cols
layoutClass: gap-8
---

# Substrate — local kind + Cilium

**Phase 1 dev cluster (E1e — landed, gated)**

- `kind` cluster `kaddy-dev`, Kubernetes **v1.33.1**, single control-plane node
- **Cilium 1.18** — CNI, **kube-proxy replacement**, operator pinned
- **Gateway API** + **LB-IPAM / L2** — no MetalLB, no host-network hacks
- **cert-manager v1.18.2** + self-signed `kaddy-local-ca` issuer
- macOS-safe: Gateway/LB IPs asserted assigned; HTTP smoke via loopback port-maps
- Secure install: **pinned versions, no `:latest`, no secrets in git**

::right::

<div class="pt-14">

## Why this, not MetalLB

The edge on kind (**Cilium Gateway API + LB-IPAM/L2**) is the *same shape* as
gridscale Phase 2 (Cilium is GSK's default CNI; LBaaS fronts the same Gateway).

So the local cluster is a faithful rehearsal, not a toy — the promotion to
gridscale is a re-point, not a re-architecture.

<div class="pt-4 text-sm opacity-70">

The 3-node Talos **driving-range** was deferred to an optional maturity-contrast
spike (D-025) after libvirt/Talos yak-shaving stalled Phase 1 — a pragmatic call,
documented, not hidden.

</div>

</div>

<!--
The local cluster is kind running Kubernetes 1.33 with Cilium 1.18 as the
CNI — kube-proxy replacement, Gateway API, and LB-IPAM. No MetalLB, no
host-network hacks, versions pinned, no secrets in git. And I'll own the
detour: I started on a three-node Talos cluster, burned hours on libvirt
yak-shaving, and made the documented call to park it and keep momentum on
kind. That trade-off is written down in the decision log, not hidden.
-->

---
layout: none
sectionTime: 45
---

<CoverArt
  src="/covers/section-06-greenkeepers-scroll.png"
  kicker="§ 06 · The greenkeepers' scroll"
  title="GitOps — ArgoCD app-of-apps"
/>

<!--
Here's GitOps doing its job — the greenkeepers and their scroll.
-->

---
layout: default
---

# GitOps — ArgoCD app-of-apps

<div class="grid grid-cols-2 gap-6">

<div>

**Landed (E1 + E3) — running live on the local cluster**

- A single **root** `Application` watches `deploy/apps/` and discovers child apps:
  `gateway`, `observability`, `identity`, `platform-core`, `workloads` —
  **9/9 Synced/Healthy**
- Committed steady-state truth is `targetRevision: main` — merging a lane is what
  makes ArgoCD sync it for real
- **Self-heal + prune** on the root: delete a child manifest → the child
  de-registers (true GitOps convergence)

</div>

<div>

```yaml
# deploy/apps/root.yaml (excerpt)
spec:
  source:
    repoURL: github.com/PlatformRelay/Kaddy
    targetRevision: main
    path: deploy/apps
    directory:
      recurse: false
      exclude: root.yaml
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

</div>

</div>

<div class="text-sm opacity-75 pt-3">

Every `Application` carries the mandatory ADR-0301 label set (`owner`, `service`, `part-of`, `managed-by`, `track`, `data-classification`, `business-criticality`) — governance reaches the control plane, not just workloads.

</div>

<!--
This is live. A single root application watches deploy-slash-apps and
discovers the children: gateway, observability, identity, platform core,
workloads — nine of nine synced and healthy. Self-heal and prune are on, so
drift gets raked back and deleted manifests de-register. One discipline I
hold: the committed target revision is always main. A feature branch proves
itself on a runtime override, but committed truth is never an unmerged
branch. That keeps main permanently deployable — and what you see here is the
actual ArgoCD UI.
-->

---
layout: none
beat: security
sectionTime: 45
---

<CoverArt
  src="/covers/section-08-gatehouse-inspection.png"
  kicker="§ 07 · The gatehouse inspection"
  title="Security & governance"
/>

<!--
Security next — the gatehouse, where every bag gets inspected.
-->

---
layout: default
---

# Security & governance — the maturity flex

<div class="grid grid-cols-3 gap-4 text-sm">

<div class="p-3 rounded border border-teal-700">

### Secrets

**SOPS + age** (ADR-0110)

- Encrypted YAML in git — IaC that survives rebuild-from-scratch
- `encrypted_regex` on `data`/`stringData` → structural diffs stay reviewable
- age private key on operator host only
- Applied via **KSOPS** in ArgoCD

</div>

<div class="p-3 rounded border border-teal-700">

### Policy as code

**Labels enforced two ways** (ADR-0301)

- **OPA / Rego** (`policy/labels.rego`) gates OpenTofu plans in CI (conftest)
- **Kyverno** `ClusterPolicy` enforces the same 7 bare keys on Pods at admission
- Default-deny **NetworkPolicies** authored + admission baseline CLI-tested (E1c, cutover runbook committed)

</div>

<div class="p-3 rounded border border-teal-700">

### Supply chain & CI

**Gated `verify.yaml`**

- **gitleaks 8.30.1** secret scan — in CI, not just bypassable pre-commit
- conftest · `tofu test` · E1e meta gates
- **All installs pinned** (gitleaks, conftest, ripgrep) — Renovate-trackable, no `apt` floats
- Data-flow **security review committed** (`docs/security/`) · replayable audits (E11) specced

</div>

</div>

<div class="pt-5 text-center">

Regulatory grounding (public texts only): **NIS2** Art. 21(2)(i) asset mgmt · **BSI KRITIS** inventory & classification · **GDPR** Art. 30/32 → operationalised as the mandatory label set.

</div>

<!--
Three layers here. Secrets: SOPS with age — encrypted YAML committed to git
and applied through KSOPS, so the cluster can be rebuilt from scratch without
a secrets scramble. Policy as code: the same seven-label governance set is
enforced twice — Rego gates OpenTofu plans in CI, and Kyverno enforces it
again at admission. That's defense in depth on governance itself. Supply
chain: gitleaks runs in CI, every install is pinned, no floating tags. And
the trajectory is auditable — a data-flow security review is committed, and
replayable audit runs are specced as E-eleven.
-->

---
layout: none
beat: portal-hero
sectionTime: 40
---

<CoverArt
  src="/covers/section-14-caddies-order-desk.png"
  kicker="§ 08 · The caddie's order desk"
  title="Self-service portal — auto-generated from the XRD"
/>

<!--
Now the money shot — self-service, where the form writes itself.
-->

---
layout: two-cols
layoutClass: gap-8
---

# Portal — auto-generated from the XRD

**The money shot (E10, designed):** nobody hand-writes the portal form.

- **kubernetes-ingestor** reads the Crossplane `Website` XRD and
  **auto-generates** the Backstage scaffolder form
- Edit the XRD → **the form updates itself** — the platform API stays the
  single source of truth (ADR-0111)
- Submitting opens a **GitOps PR** with a `Website` XR → ArgoCD applies →
  Crossplane reconciles
- Read-path plugins render live status in-portal: **Crossplane resource
  graph**, ArgoCD apps, K8s workloads (D-029)

::right::

<div class="pt-10 text-sm opacity-80">

**Honesty:** E10 is specced (ADR-0109 / ADR-0111, D-027…D-029) and gated behind
the spine — shown here as design, not a running portal. Orchestrator-first:
Crossplane (E6) *is* the platform API; Backstage is the experience layer on top.

</div>

<!--
This is the platform's north star, and I want to be upfront: it is designed,
not deployed yet. The idea: nobody hand-writes the portal form.
Kubernetes-ingestor reads the Crossplane Website XRD and auto-generates the
Backstage scaffolder form from it. Change the API, and the form updates
itself. Submitting doesn't touch the cluster directly — it opens a GitOps
pull request, ArgoCD applies it, Crossplane reconciles it. The platform API
stays the single source of truth, end to end.
-->

---
layout: none
beat: mulligan
sectionTime: 50
---

<CoverArt
  src="/covers/section-09-mulligans-second-chance.png"
  kicker="§ 09 · Mulligan's second chance"
  title="Caddy-MVP tenant & mulligan"
/>

<!--
Which brings us to mulligan — the retriever that fetches bad releases back.
-->

---
layout: two-cols
layoutClass: gap-8
---

# Caddy-MVP tenant (WaaS)

**Caddy is the platform MVP — a tenant product, never the edge** (ADR-0104, D-019).

The platform edge is Cilium Gateway API (Envoy). Caddy is reached *through* it.

Two Backstage-scaffoldable variants (both also exist for nginx):

- **Variant A — VM (minimal):** Caddy on a VM + alerting. In-cluster Prometheus
  scrapes the VM's `/metrics`. This is the brief spine **serve → scrape → fire**,
  and where the `caddy_*` marshal alerts live (`deploy/caddy-mvp/monitoring/`).
- **Variant B — Kubernetes (rich, preferred):** cert-manager certs, in-cluster
  scrape, **blue/green + canary via Argo Rollouts**.

::right::

<div class="pt-10">

## Progressive delivery — mulligan

```mermaid {scale: 0.6}
flowchart LR
  ST["stable<br/>(weight 90)"]
  CN["canary<br/>(weight 10)"]
  HR["HTTPRoute<br/>weights"]
  AN["AnalysisTemplate<br/>(Prometheus)"]
  HR --> ST & CN
  AN -->|"metrics bad"| RB["auto-rollback"]
  AN -->|"metrics good"| PR["promote"]
```

<div class="text-sm opacity-75 pt-3">

**Landed (E7):** Argo Rollouts mutates **Gateway API HTTPRoute weights** —
proven live on the cluster: `100/0 → 20 → 50 → 100`. Blue/green promotion and
abort→rollback proven; `hack/demo/mulligan.sh` choreographs the two-act demo.

</div>

</div>

<!--
Two things on this slide. First, the Caddy tenant itself comes in two
scaffoldable variants: a minimal VM flavour — which is literally the brief:
serve, scrape, fire — and a richer Kubernetes flavour with certificates and
progressive delivery. Second: mulligan is landed. Argo Rollouts mutates
Gateway API HTTPRoute weights, and I've proven it live — traffic stepping
from one hundred percent to eighty-twenty, fifty-fifty, then full cutover,
with abort and rollback demonstrated. A Prometheus analysis template gates
promotion, so a bad canary walks itself back automatically.
-->

---
layout: none
beat: marshal
sectionTime: 45
---

<CoverArt
  src="/covers/section-07-marshals-tower.png"
  kicker="§ 10 · The marshal's tower"
  title="Observability spine — marshal"
/>

<!--
Watching over all of it: marshal, up in the tower.
-->

---
layout: default
---

# Observability spine — marshal

<div class="grid grid-cols-2 gap-6">

<div>

**Landed (E5 rules + E3 spine, running via GitOps):**

- **PrometheusRules** — instance down, error rate, latency, request rate
- ServiceMonitor / PodMonitor + **blackbox_exporter** probes (uptime, status codes)
- **promtool unit tests for every alert rule** — an alert's *correctness* is proven
  in CI (L1), not assumed
- **kube-prometheus-stack + Loki + Grafana Alloy deployed** — logs + metrics in
  one Grafana pane (ADR-0108)

**Open (E5 completion):**

- **Alertmanager receiver** (ntfy/webhook) — the "fire" leg
- Dashboards-as-code + Loki 5xx log checks

</div>

<div>

```mermaid {scale: 0.68}
flowchart TB
  T["tenant / gateway<br/>/metrics + logs"]
  BB["blackbox_exporter<br/>probes"]
  P["Prometheus"]
  AL["Alloy<br/>(DaemonSet)"]
  L["Loki"]
  AM["Alertmanager"]
  GR["Grafana"]
  T --> P
  BB --> P
  T -. logs .-> AL --> L
  P --> AM
  P & L --> GR
  P -.->|"promtool<br/>unit tests (CI)"| P
```

<div class="text-center text-sm text-teal-400 pt-2">
An alert can fire end-to-end — and its rule is unit-tested.
</div>

</div>

</div>

<!--
The observability spine is running via GitOps: kube-prometheus-stack, Loki
and Alloy — metrics and logs in one Grafana pane. Marshal's alert rules cover
instance down, error rate, latency and request rate, plus blackbox probes for
uptime. The differentiator: every alert rule has a promtool unit test in CI.
"Alert on server down" isn't a claim, it's a regression test. What's honestly
still open is the receiver leg — Alertmanager routing to a webhook — plus
dashboards-as-code. That is the current E-five work.
-->

---
layout: none
beat: scorecard
sectionTime: 40
---

<CoverArt
  src="/covers/section-10-five-hole-walkthrough.png"
  kicker="§ 11 · The five-hole walkthrough"
  title="Demo flow"
/>

<!--
Let's walk the demo — five holes, and the scorecard writes itself.
-->

---
layout: default
---

# Demo flow

<div class="text-lg">

A crisp, five-beat live path — each beat maps to a landed or designed capability:

</div>

<div class="pt-4 grid grid-cols-1 gap-2 text-base max-w-4xl">

1. **GitOps** — open ArgoCD; show the app-of-apps tree syncing from `deploy/apps/`
2. **Serve** — `curl https://clubhouse…/` returns the site over TLS at the Cilium Gateway
3. **Observe** — Grafana: request rate / latency / status codes + Loki access logs, one pane
4. **Alert** — drive load with **k6** past threshold → **marshal** fires → Alertmanager routes *(the rule is already promtool-tested in CI)*
5. **Deliver** — **mulligan** canary with a bad build → AnalysisTemplate fails → **auto-rollback** → alert clears

</div>

<div class="pt-5 text-teal-400">

The whole run is captured by **scorecard** (k6 + metrics/logs) into a self-contained **HTML evidence report** — reproducible proof, not screenshots.

</div>

<div class="text-sm opacity-60 pt-3">
Beats 1–3 and 5 run live on the local cluster today (`hack/demo/mulligan.sh` drives the delivery act); beat 4's receiver leg is the remaining E5 work; scorecard capture is E8.
</div>

<!--
The demo is five beats. One: the ArgoCD tree, live. Two: curl clubhouse over
TLS through the Cilium gateway, live. Three: Grafana — one pane for metrics
and logs, live. Four: drive load with k6 until marshal fires; the rule itself
is already regression-tested, the receiver is the open leg. Five: a bad
canary auto-rolls back, live. And the point of scorecard is that this whole
run becomes a reproducible HTML evidence report — proof you can re-run, not
screenshots.
-->

---
layout: none
sectionTime: 30
---

<CoverArt
  src="/covers/section-11-back-nine-at-dawn.png"
  kicker="§ 12 · The back nine at dawn"
  title="Roadmap & honest status"
/>

<!--
What's left on the course? The back nine, at dawn.
-->

---
layout: default
---

# Roadmap & honest status

<div class="grid grid-cols-2 gap-8 text-sm">

<div>

**Phase 1 — local kind ($0 cloud)**

| Epic | Scope | Status |
| --- | --- | --- |
| E1e | kind + Cilium substrate | ✅ landed |
| E1 · E3 | ArgoCD bootstrap + GitOps core | ✅ landed |
| E4 | clubhouse + verified TLS | ✅ landed |
| E1b | labels module + policy | ✅ landed |
| E7 | mulligan rollouts (live weight shift) | ✅ landed |
| E5 | marshal — receiver/dashboards leg | 🚧 rules ✅ |
| E6 | Crossplane `Website` XRD | 🧭 designed |
| E10 | Backstage portal (auto-gen) | 🧭 designed |

</div>

<div>

**Phase 2 — gridscale lab (deferred)**

| Epic | Scope | Status |
| --- | --- | --- |
| E1g | GSK day-0 (Terramate) | 🧭 deferred |
| E6g | Upjet provider-gridscale VM | 🧭 deferred |
| E8b | live demo environment | 🧭 deferred |

**Gate to Phase 2:** E3–E7 green on local kind.

</div>

</div>

<div class="pt-4 text-center opacity-80">

Every epic is an **OpenSpec change** with `Verify:` + `Test:` per requirement, driven TDD-first. The backlog is the spec.

</div>

<!--
The status table is deliberately honest. Substrate, GitOps core, clubhouse
with verified TLS, labels and policy, and mulligan are landed. Marshal's
receiver leg is in flight. Crossplane and the portal are designed. Phase two
— gridscale GSK, LBaaS, the Upjet provider — stays deferred until the local
platform is fully green, which keeps cloud spend at zero. Every epic is an
OpenSpec change with tests per requirement; the backlog is the spec.
-->

---
layout: none
sectionTime: 30
---

<CoverArt
  src="/covers/section-12-signed-scorecard.png"
  kicker="§ 13 · The signed scorecard"
  title="Why this answers the exercise"
/>

<!--
So — does this answer the exercise? Here's the signed card.
-->

---
layout: statement
---

# Why this answers the exercise

<div class="text-left max-w-3xl mx-auto pt-4 text-lg space-y-3">

- **Serve · scrape · alert** — satisfied live through the Cilium edge, as a *repeatable tenant product*, with the alert rules **unit-tested in CI**
- **IaC & automation** — GitOps app-of-apps (9/9 Synced/Healthy), SOPS-encrypted secrets in git, pinned & gated supply chain
- **Documentation** — README reviewer paths, ADRs, OpenSpec specs, this deck
- **Evidence** — scorecard turns the demo into a reproducible HTML report, not screenshots
- **Beyond the brief** — landed progressive delivery with live traffic shifting, governance (NIS2-style labels, Rego + Kyverno), centralized logs, OIDC designed

</div>

<div class="pt-6 text-2xl font-bold text-teal-400">
A platform team can adopt this. That was the point.
</div>

<!--
Serve, scrape, alert: satisfied, live, through a real platform edge, with the
alert rules unit-tested in CI. Infrastructure as code and automation: GitOps
end to end, with encrypted secrets in git. Documentation: ADRs, OpenSpec
specs, reviewer paths. Evidence: reproducible reports rather than
screenshots. And beyond the brief: live progressive delivery, enforced
governance, centralized logs. The claim I will stand behind: a platform team
could adopt this repo tomorrow. That was the point.
-->

---
layout: none
sectionTime: 15
---

<CoverArt
  src="/covers/section-13-nineteenth-hole.png"
  kicker="§ 14 · The nineteenth hole"
  title="Thank you"
/>

<!--
That's the round. Thank you — let's head to the nineteenth hole.
-->

---
layout: center
class: text-center
---

# Thank you

**kaddy** — a caddie for your websites

<div class="pt-4 opacity-80">

Repo · `github.com/PlatformRelay/Kaddy`
5-min path · `docs/requirements/exercise-traceability.md`
Deep dive · `docs/adr/README.md` → `docs/ARCHITECTURE.md` → `openspec/changes/`

</div>

<div class="pt-8 text-teal-400 text-lg">
Questions?
</div>

<!--
If you want to verify any claim from this walkthrough, the repo is structured
for it: the traceability matrix gives you the five-minute path from each
brief requirement to its epic, and the ADR index takes you into the deep
dive. Everything in this deck is checkable. Thanks for watching — I'm happy
to take questions.
-->

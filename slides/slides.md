---
theme: seriph
fonts:
  sans: 'Inter'
  mono: 'JetBrains Mono'
title: Kaddy — a simple two-VM monitoring exercise, gone wildly overboard into platform engineering
info: |
  A 5-10 minute demo-video companion for kaddy: the highlights, the live surfaces, and how AI built it.
favicon: '/branding/favicon-32.png'
seoMeta:
  ogTitle: Kaddy — a simple two-VM monitoring exercise, gone wildly overboard into platform engineering
  ogDescription: From a hiring brief about two VMs with monitoring to a security-first Website-as-a-Service platform.
  ogImage: https://raw.githubusercontent.com/PlatformRelay/Kaddy/main/slides/public/branding/og-image.png
layout: none
transition: slide-left
mdc: true
editor: false
contextMenu: false
beat: pitch
sectionTime: 80
---

<!-- markdownlint-disable MD025 MD041 MD033 MD024 MD013 MD036 MD001 MD003 MD022 MD023 -->

<CoverArt
  src="/covers/section-00-first-tee.png"
  kicker="The first tee"
  title="Kaddy — a simple two-VM monitoring exercise, gone wildly overboard into platform engineering"
/>

<!--
Hi, I am Konrad. The brief asked for two VMs with monitoring. I went overboard and built a small Website-as-a-Service platform instead. This video shows the highlights and a few live demos.
-->

---
layout: default
---

<div class="kd-kicker">The brief</div>

# One small ask, one platform answer

<div class="kd-vs mt-8">
  <div class="kd-vs-col">
    <KdIcon name="material-symbols:description-outline-rounded" size="2em" />
    <h3>The exercise</h3>
    <p>Install Caddy on a Linux VM, serve a page, scrape it with Prometheus, fire an alert.</p>
  </div>
  <div class="kd-vs-badge">became</div>
  <div class="kd-vs-col kd-vs-col-accent">
    <KdIcon name="material-symbols:hub-outline-rounded" size="2em" />
    <h3>The platform</h3>
    <p>So I built a platform: websites as a self-service product — delivered, monitored, governed, and proven with evidence.</p>
  </div>
</div>

<div class="mt-7">
  <span class="kd-chip kd-chip-ok"><KdIcon name="material-symbols:check-circle-rounded" /> literal VM path kept and proven</span>
  <span class="kd-chip"><KdIcon name="mdi:golf" /> everything else is the overboard part</span>
</div>

<!--
The literal exercise is in the repository and proven: Caddy serves, Prometheus scrapes, an alert fires. Around it I built the reusable platform a team would actually want: the same website capability as a product, with delivery, monitoring, policy, and evidence built in.
-->

---
layout: default
---

<div class="kd-kicker">How it was built</div>

# Built with AI — outcomes declared first, then verified

<div class="kd-grid kd-grid-2 mt-4">
  <div class="kd-spec">

```md
## REQ-E13-S03-01: Server deployed from the
## template serves the sample page
**Given** a gridscale_server created from the
  imported Marketplace template
**When** it boots
**Then** the sample page is served over HTTP (200)
  — proving one-click deploy from the template
**Test:** tests/smoke/e13-s03-deploy.sh
**Verify:** curl -sf -o /dev/null -w '%{http_code}' \
  "http://${MARKETPLACE_VM_HOST}/" | grep -q '^200$'
```

  <p class="kd-small kd-muted">A real OpenSpec requirement: the desired outcome is declared up front — Given / When / Then — and every REQ- names its test and a one-line verification.</p>
  </div>
  <div>
    <div class="kd-loop">
      <div class="kd-step"><span><KdIcon name="material-symbols:edit-document-outline-rounded" /></span><strong>Spec</strong><code>OpenSpec proposal + REQs</code></div>
      <div class="kd-step"><span><KdIcon name="mdi:robot-outline" /></span><strong>Implementer agent</strong><code>own worktree · TDD</code></div>
      <div class="kd-step kd-step-accent"><span><KdIcon name="material-symbols:rate-review-outline-rounded" /></span><strong>Review agent</strong><code>independent · gate matrix</code></div>
      <div class="kd-step"><span><KdIcon name="mdi:source-merge" /></span><strong>Integrate</strong><code>rebase · CI · next lane</code></div>
    </div>
    <div class="kd-callout mt-4">The author agent never reviews its own code — a separate review agent gates every lane.</div>
  </div>
</div>

<!--
I built this with AI agents, but inside a spec-to-test loop. I declare the desired outcome as a requirement like this real one, with a named test and a verify command. Implementer agents work test-first in isolated worktrees, and an independent review agent gates every lane before it merges. AI accelerates; the spec keeps every claim checkable.
-->

---
layout: none
title: Architecture
beat: architecture
sectionTime: 90
---

<CoverArt
  src="/covers/section-04-two-courses-one-blueprint.png"
  kicker="Architecture"
  title="An API for websites, not a pile of pipelines"
/>

<!--
The architectural bet: treat websites as an API on a Kubernetes control plane, not as a stack of one-off pipelines.
-->

---
layout: default
---

<div class="kd-kicker">Platform API</div>

# Why Kubernetes + Crossplane, not Terraform alone

<div class="kd-vs mt-3">
  <div class="kd-vs-col">
    <h3><KdIcon name="mdi:file-code-outline" /> Terraform alone</h3>
    <p class="kd-small">Great at infrastructure as code — but state lives at apply-time. There is no always-on API for current state, and integrating it into a web frontend means glue.</p>
  </div>
  <div class="kd-vs-badge">vs</div>
  <div class="kd-vs-col kd-vs-col-accent">
    <h3><KdIcon name="mdi:kubernetes" /> Kubernetes control plane</h3>
    <p class="kd-small">Schema validation, robust access control, a live API for desired <em>and</em> current state, a runtime — for free. Plus the operator ecosystem for everything a product team needs.</p>
  </div>
</div>

<div class="kd-diagram mt-5">
  <div class="kd-node kd-node-primary">Website claim</div>
  <div class="kd-arrow">→</div>
  <div class="kd-node">Crossplane Composition</div>
  <div class="kd-arrow">→</div>
  <div v-click class="kd-node">workload + Service</div>
  <div v-click class="kd-node">HTTPRoute + TLS</div>
  <div v-click class="kd-node">ServiceMonitor</div>
</div>

<div v-click class="kd-callout mt-4">One declared Website intent; the platform supplies delivery, TLS, and monitoring — and Backstage can read the same API back.</div>

<!--
Terraform manages infrastructure as code well, but it lacks a live API you can always query for current state, and integrating it into a frontend takes glue. Kubernetes resources and operators are the natural partner: schema validation, access control, an API, and a runtime for free. So a Website claim goes through a Crossplane Composition into a workload, a TLS route, and a ServiceMonitor — governed resources from one intent.
-->

---
layout: default
---

<div class="kd-kicker">Ecosystem contribution</div>

# provider-gridscale, shipped to the Upbound Marketplace

<div class="kd-grid kd-grid-2 mt-4">
  <div>
    <div class="kd-stat"><em>32</em><span>gridscale resources exposed as Kubernetes APIs, generated with Upjet</span></div>
    <div class="mt-4">
      <span class="kd-chip kd-chip-ok"><KdIcon name="material-symbols:deployed-code-rounded" /> published + consumed by kaddy</span>
    </div>
    <p class="kd-small mt-4"><a href="https://marketplace.upbound.io/providers/platformrelay/provider-gridscale">marketplace.upbound.io/providers/platformrelay/provider-gridscale</a></p>
    <p class="kd-small kd-muted">Real value for gridscale customers: a second choice of IaC tool — Kubernetes-native, alongside Terraform. Plus 3 fixes to the upstream Terraform provider — <a href="https://github.com/gridscale/terraform-provider-gridscale/pull/509">#509</a> · <a href="https://github.com/gridscale/terraform-provider-gridscale/pull/510">#510</a> · <a href="https://github.com/gridscale/terraform-provider-gridscale/pull/511">#511</a> — filed and open: two approved, the third in review; not merged yet.</p>
  </div>
  <div class="kd-surface">
    <div class="kd-surface-label"><KdIcon name="mdi:package-variant-closed" /> Upbound Marketplace</div>
    <img src="/surfaces/marketplace-listing.png" alt="Upbound Marketplace listing for provider-gridscale" />
  </div>
</div>

<!--
The gridscale integration produced a real contribution: provider-gridscale, an Upjet-generated Crossplane provider publishing thirty-two gridscale resources as Kubernetes APIs, live on the Upbound Marketplace. That gives gridscale customers a second choice of infrastructure-as-code tool alongside Terraform. I also filed three fixes upstream — two are approved, the third is in review — none merged yet, and I say so.
-->

---
layout: default
---

<div class="kd-kicker">Golden images</div>

# gridscale Marketplace VM — and a Nix flake

<div class="kd-grid kd-grid-2 mt-5">
  <div class="kd-card kd-card-ok">
    <KdIcon name="mdi:storefront-outline" size="1.6em" />
    <h3>Packer → gridscale Marketplace</h3>
    <p>Caddy and nginx VM templates, registered and imported into the tenant. One-click deploy from the Marketplace is live-proven: the deployed VM serves.</p>
  </div>
  <div class="kd-card kd-card-warn">
    <KdIcon name="mdi:snowflake" size="1.6em" />
    <h3>Nix flake image</h3>
    <p>A flake-locked NixOS image as a reproducible alternative build. The image build is proven; gridscale boot-to-serve is still open — honestly labeled.</p>
  </div>
</div>

<div class="mt-6">
  <span class="kd-chip"><KdIcon name="mdi:golf-tee" /> the literal Caddy-on-a-VM brief lives here</span>
</div>

<!--
Two golden-image routes. Packer builds the gridscale Marketplace templates — registered, imported, and live-proven with a one-click deploy that serves. And a Nix flake builds the same image reproducibly; that build is proven, while boot-to-serve on gridscale is still open and labeled as such.
-->

---
layout: default
beat: security
---

<div class="kd-kicker">Guardrails</div>

# Secure by default, enforced by default

<div class="kd-iconrow mt-8">
  <div><KdIcon name="material-symbols:key-vertical-rounded" size="2.2em" /><strong>SOPS + age</strong><span>secrets encrypted in Git</span></div>
  <div><KdIcon name="material-symbols:policy-rounded" size="2.2em" /><strong>Kyverno Enforce</strong><span>+ default-deny networking</span></div>
  <div><KdIcon name="mdi:github" size="2.2em" /><strong>Dex GitHub OIDC</strong><span>identity, no local admins</span></div>
  <div><KdIcon name="material-symbols:fact-check-outline-rounded" size="2.2em" /><strong>Dated audits</strong><span>replayable security + compliance runs</span></div>
</div>

<div class="kd-callout mt-10">Controls fail close to the change — enforced at admission, not documented in a wiki.</div>

<!--
Guardrails are defaults, not add-ons: secrets stay encrypted in Git, admission policy is enforced with default-deny networking, identity is GitHub-backed with no local admins, and dated audits keep the whole posture replayable and reviewable.
-->

---
layout: default
beat: portal-hero
---

<div class="kd-kicker">Experience layer</div>

# Backstage: self-service on the platform API

<div class="kd-grid kd-grid-2 mt-4">
  <div>
    <p class="kd-lede">The portal is designed around the Website XRD — not a second source of truth.</p>
    <ul class="mt-3">
      <li>the XRD schema becomes the scaffolder form</li>
      <li>submitting opens a Git change with a Website claim</li>
      <li>Argo CD syncs it; Crossplane reconciles it</li>
      <li>the portal reads the same platform API back</li>
    </ul>
    <div class="mt-4"><span class="kd-chip kd-chip-ok"><KdIcon name="mdi:web-check" /> portal.lab.platformrelay.dev · HTTPS 200</span></div>
  </div>
  <div class="kd-surface" data-surface="backstage" data-surface-mode="static">
    <div class="kd-surface-label"><KdIcon name="mdi:view-dashboard-outline" /> Backstage · live on GSK</div>
    <img src="/surfaces/backstage-portal.png" alt="Backstage portal on portal.lab.platformrelay.dev" />
  </div>
</div>

<!--
Backstage is the experience layer, and the portal is designed around the platform API. The Website XRD projects the self-service form, a submission becomes a Git change, and Argo CD plus Crossplane reconcile it — then the portal reads that same API back. It runs on the cloud edge at portal.lab with a public HTTPS 200.
-->

---
layout: none
title: Delivery and operations
beat: mulligan
sectionTime: 130
---

<CoverArt
  src="/covers/section-09-mulligans-second-chance.png"
  kicker="Delivery &amp; operations"
  title="Roll forward on evidence — take a mulligan for free"
/>

<!--
Delivery and operations: releases decided by observed behavior, and monitoring that is tested like code.
-->

---
layout: default
---

<div class="kd-kicker">mulligan · Argo Rollouts</div>

# Canary releases judged by Prometheus

<div class="kd-weights mt-4">
  <div class="kd-wrow"><span>start</span><div class="kd-wbar"><i style="width:100%">stable 100</i></div></div>
  <div v-click class="kd-wrow"><span>shift</span><div class="kd-wbar"><i style="width:80%">80</i><b style="width:20%">20</b></div></div>
  <div v-click class="kd-wrow"><span>gate</span><div class="kd-wbar"><i style="width:50%">50</i><b style="width:50%">50</b></div></div>
  <div v-click class="kd-wrow"><span>promote</span><div class="kd-wbar"><b style="width:100%">canary → stable 100</b></div></div>
  <div v-click class="kd-wrow kd-wrow-abort"><span>abort</span><div class="kd-wbar"><i style="width:100%">rollback — weights snap to stable</i></div></div>
</div>

<div class="kd-grid kd-grid-3 mt-5">
  <div class="kd-card"><strong>Traffic</strong><span class="kd-muted">Argo Rollouts shifts live Gateway API HTTPRoute weights</span></div>
  <div class="kd-card"><strong>Decision</strong><span class="kd-muted">Prometheus AnalysisTemplate gates promote or rollback</span></div>
  <div class="kd-card kd-card-ok"><strong>Also</strong><span class="kd-muted">blue-green with an active/preview flip, same controller</span></div>
</div>

<div class="mt-4"><span class="kd-chip"><KdIcon name="mdi:console-line" /> task demo · task demo:chaos</span></div>

<!--
Progressive delivery, live. Argo Rollouts shifts real Gateway API HTTPRoute weights while a Prometheus analysis decides whether to promote or roll back — and an aborted canary snaps the route straight back to stable. Blue-green works through the same controller, and both flows run as one scripted task demo.
-->

---
layout: default
beat: marshal
---

<div class="kd-kicker">marshal</div>

# Monitoring that is tested like code

<div class="kd-grid kd-grid-2 mt-4">
  <div>
    <ul>
      <li>Prometheus + blackbox probes on every website</li>
      <li>alert rules <strong>unit-tested with promtool</strong></li>
      <li>12-panel dashboard-as-code, Loki logs included</li>
      <li>down / error-rate / latency alerts, routing proven</li>
    </ul>
    <div class="mt-4">
      <span class="kd-chip kd-chip-warn"><KdIcon name="material-symbols:pending-actions-rounded" /> open: external receiver · Loki ruler alert</span>
    </div>
  </div>
  <div class="kd-surface" data-surface="grafana" data-surface-mode="static">
    <div class="kd-surface-label"><KdIcon name="mdi:chart-line" /> Grafana · grafana.lab.platformrelay.dev</div>
    <img src="/surfaces/grafana-alerting.png" alt="Grafana dashboard on GSK" />
  </div>
</div>

<!--
Marshal is the monitoring product. Metrics and blackbox probes feed alert rules that are unit-tested with promtool, dashboards are provisioned as code with Loki logs alongside, and alert routing is proven to the configured sink. Two things stay open and say so: the external receiver and the Loki ruler alert.
-->

---
layout: none
title: Evidence
beat: scorecard
---

<CoverArt
  src="/covers/section-12-signed-scorecard.png"
  kicker="Evidence"
  title="Make every claim easy to check"
/>

<!--
The last habit: turn each demo into evidence a reviewer can replay and challenge.
-->

---
layout: default
---

<div class="kd-kicker">Live showcase + scorecard</div>

# Live on gridscale — and captured as evidence

<div class="kd-grid kd-grid-2 mt-4">
  <div class="kd-surface">
    <div class="kd-surface-label"><KdIcon name="mdi:web" /> demo.lab.platformrelay.dev · live</div>
    <iframe src="https://demo.lab.platformrelay.dev/" title="Clubhouse website" data-surface="clubhouse" data-surface-mode="live"></iframe>
  </div>
  <div>
    <div class="kd-diagram">
      <div class="kd-node">k6</div>
      <div class="kd-node">metrics + alerts</div>
      <div class="kd-node">logs</div>
      <div class="kd-node">rollout</div>
      <div class="kd-arrow">→</div>
      <div class="kd-node kd-node-primary">one HTML scorecard</div>
    </div>
    <p class="kd-small kd-muted mt-3">Replayable capture with fixture and live modes, published via GitHub Pages — evidence as an output, not a screenshot folder.</p>
    <div class="mt-3">
      <span class="kd-chip kd-chip-ok"><KdIcon name="mdi:check-network-outline" /> caddy.lab · demo.lab · portal.lab · grafana.lab — HTTPS 200</span>
    </div>
  </div>
</div>

<!--
Everything shown here runs on the public gridscale edge — caddy.lab, demo.lab, portal.lab, and grafana.lab all answer HTTPS 200. And each run can be captured as a scorecard: load, metrics, alerts, logs, and rollout state rendered into one self-contained HTML report, published through Pages.
-->

---
layout: default
class: text-center
---

<div class="kd-kicker">Closing</div>

# Built, proven, still open

<div class="kd-grid kd-grid-3 mt-8 text-left">
  <div class="kd-card"><KdIcon name="material-symbols:construction-rounded" /><strong>Built</strong><span class="kd-muted">Website-as-a-Service on Kubernetes, Crossplane, and gridscale</span></div>
  <div class="kd-card kd-card-ok"><KdIcon name="material-symbols:verified-rounded" /><strong>Proven</strong><span class="kd-muted">live cloud edge, canary + rollback, tested alerts, one-click Marketplace VM</span></div>
  <div class="kd-card kd-card-warn"><KdIcon name="material-symbols:pending-actions-rounded" /><strong>Open</strong><span class="kd-muted">external alert receiver → Nix boot proof → upstream merges</span></div>
</div>

<p class="mt-8 kd-lede">Happy to open any artifact and walk through the trade-offs.</p>

<div class="kd-footer-link">github.com/PlatformRelay/Kaddy</div>

<!--
That is kaddy: the two-VM exercise answered literally, and a platform built around it — live edge, evidence-gated delivery, tested monitoring, and an honest open list: external alert delivery, the Nix boot proof, and the upstream merges. The repository link has everything, including this deck.
-->

---
layout: none
title: Appendix
---

<!-- APPENDIX -->

<CoverArt
  src="/covers/section-08-gatehouse-inspection.png"
  kicker="Appendix"
  title="Checkable detail — not part of the talk"
/>

<!--
Everything after this divider is reviewer material: the portal flow in detail, the delivery-path boundaries, and the quickstart.
-->

---
layout: default
---

<div class="kd-kicker">Appendix A</div>

# The portal flow, end to end

<div class="kd-grid kd-grid-2 mt-4">
  <div>
    <div class="kd-flow kd-flow-vertical kd-flow-compact">
      <div class="kd-step"><span>1</span><strong>Website XRD schema</strong>projects the scaffolder form fields</div>
      <div class="kd-step"><span>2</span><strong>Form submit</strong>opens a Git change carrying a Website claim</div>
      <div class="kd-step"><span>3</span><strong>Argo CD</strong>syncs the change into the cluster</div>
      <div class="kd-step"><span>4</span><strong>Crossplane</strong>reconciles site, route, and monitor</div>
      <div class="kd-step"><span>5</span><strong>Portal</strong>reads the same API back as status</div>
    </div>
    <p class="kd-small kd-muted mt-3">The E10 form-to-PR smoke remains follow-on proof; the public route and portal serve are live-proven.</p>
  </div>
  <div class="kd-stack">
    <div class="kd-surface kd-surface-clamp" data-surface="argocd" data-surface-mode="static">
      <div class="kd-surface-label"><KdIcon name="mdi:source-branch-sync" /> Argo CD · app-of-apps on GSK</div>
      <img src="/surfaces/argocd-app-of-apps.png" alt="Argo CD root app-of-apps tree on GSK" />
    </div>
    <div class="kd-surface kd-surface-fallback" data-surface="crossplane-graph" data-surface-mode="fallback">
      <div class="kd-surface-label"><KdIcon name="mdi:graph-outline" /> Crossplane resource graph</div>
      <p>Reserved for the live claim → composition resource graph during a recorded demo.</p>
    </div>
  </div>
</div>

<!--
For reviewers: the portal flow concretely. The Website XRD schema projects the form, a submission opens a Git change with a Website claim, Argo CD syncs it, Crossplane reconciles the site with its route and monitor, and the portal reads the same API back. The E10 form-to-PR smoke remains follow-on proof.
-->

---
layout: default
---

<div class="kd-kicker">Appendix B</div>

# Delivery paths — the same intent, solved different ways

<div class="kd-grid kd-grid-2 mt-4">
  <div class="kd-card kd-card-ok"><strong>Caddy VM</strong><span class="kd-muted">Packer gridscale Marketplace template — the literal brief; deploy + serve proven</span></div>
  <div class="kd-card kd-card-ok"><strong>In-cluster tenant</strong><span class="kd-muted">TLS, monitoring, progressive delivery behind the shared platform edge</span></div>
  <div class="kd-card kd-card-ok"><strong>Crossplane Website</strong><span class="kd-muted">self-service API; local claim and an ephemeral real gridscale VM serve proven</span></div>
  <div class="kd-card kd-card-warn"><strong>Nix image</strong><span class="kd-muted"><code>nix/flake.nix</code> — flake-locked image build proven; boot-to-serve remains open (E14 / ADR-0303)</span></div>
</div>

<div class="kd-callout mt-5">Boundaries stay honest: a build is not a boot, a claim is not a merge — the 3 upstream provider PRs are filed and open, not merged.</div>

<!--
The paths are deliberately not interchangeable: the Packer Marketplace VM answers the brief directly, the in-cluster tenant carries the platform behavior, the Crossplane Website is the self-service API with a real ephemeral VM serve proven, and the Nix image build is proven while its gridscale boot-to-serve stays open under E14.
-->

---
layout: default
---

<div class="kd-kicker">Appendix C</div>

# Reviewer quickstart

<div class="kd-grid kd-grid-2 mt-4">
  <div class="kd-card kd-code-list">
    <code>deploy/</code><span>GitOps apps + manifests</span>
    <code>openspec/</code><span>epics, REQs, verification</span>
    <code>tests/</code><span>the gate matrix</span>
    <code>evidence/</code><span>scorecards + live proofs</span>
    <code>docs/</code><span>ADRs, audits, runbooks</span>
  </div>
  <div>
    <div class="kd-card">
      <h3><KdIcon name="mdi:console-line" /> Three commands</h3>
      <ul>
        <li><code>task cluster:up</code> — local platform on kind</li>
        <li><code>task verify</code> — the full offline gate matrix</li>
        <li><code>task demo</code> — the mulligan canary, live</li>
      </ul>
    </div>
    <p class="kd-small kd-muted mt-3">Runbooks for every live surface sit in <code>docs/runbooks/</code>.</p>
  </div>
</div>

<!--
To replay this yourself: the repository structure maps intent to proof — deploy for state, openspec for requirements, tests for gates, evidence for results. Task cluster colon up brings the platform up locally, task verify runs the offline gates, and task demo runs the canary shown in the video.
-->

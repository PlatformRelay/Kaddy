---
theme: seriph
fonts:
  sans: 'Inter'
  mono: 'JetBrains Mono'
title: kaddy — Website-as-a-Service
info: |
  A factual interview walkthrough of kaddy: what I built, what I proved, and what remains open.
favicon: '/branding/favicon-32.png'
seoMeta:
  ogTitle: kaddy — a caddie for your websites
  ogDescription: Security-first, spec-driven, Kubernetes-native Website-as-a-Service.
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
  title="kaddy — a caddie for your websites"
/>

<!--
Hi, I am Konrad. I built kaddy as a practical answer to a platform engineering exercise: a Website-as-a-Service product with repeatable delivery, controls, operations, and evidence. I will separate what is built and proven from what is still open.
-->

---
layout: default
---

<div class="kd-kicker">The brief</div>

# One website, treated as a product

<div class="kd-grid kd-grid-2 mt-8">
  <div class="kd-card kd-card-accent">
    <KdIcon name="material-symbols:description-outline-rounded" size="1.5em" />
    <h3>The requested outcome</h3>
    <p>Install Caddy on Linux, serve a page, scrape it with Prometheus, and fire an alert.</p>
  </div>
  <div class="kd-card">
    <KdIcon name="material-symbols:account-tree-outline-rounded" size="1.5em" />
    <h3>The platform question</h3>
    <p>How can a team deliver monitored, TLS-terminated websites repeatedly, with policy and evidence built in?</p>
  </div>
</div>

<div class="kd-callout mt-8">
  I kept the literal VM path, then built the reusable platform around it.
</div>

<!--
The brief asks for a Caddy server, a page, monitoring, and an alert. I kept that outcome visible throughout the repository. I also treated it as a product question: how would a platform team make the same capability repeatable for the next website, with sensible defaults and proof that it works?
-->

---
layout: default
---

<div class="kd-kicker">Product shape</div>

# From one task to four deliberate paths

<div class="kd-diagram mt-5">
  <div class="kd-node kd-node-primary">Website intent</div>
  <div class="kd-arrow">→</div>
  <div class="kd-node">Packer Marketplace VM</div>
  <div class="kd-node">In-cluster tenant</div>
  <div class="kd-node">Crossplane Website</div>
  <div class="kd-node">Nix-built image</div>
</div>

<div class="kd-grid kd-grid-3 mt-7">
  <div class="kd-card"><strong>marshal</strong><span class="kd-muted">metrics, logs, alerts</span></div>
  <div class="kd-card"><strong>mulligan</strong><span class="kd-muted">progressive delivery and rollback</span></div>
  <div class="kd-card"><strong>scorecard</strong><span class="kd-muted">replayable HTML evidence</span></div>
</div>

<div class="mt-6">
  <span class="kd-chip kd-chip-ok"><KdIcon name="material-symbols:check-circle-rounded" /> shared platform capabilities</span>
</div>

<!--
The same intent now has several delivery paths. Packer produces the gridscale Marketplace VM. Kubernetes runs the richer in-cluster tenant. Crossplane exposes a Website API and demo claim. Nix builds a reproducible image, although boot-to-serve is not yet proven. Marshal, mulligan, and scorecard provide shared operations around those paths.
-->

---
layout: default
---

<div class="kd-kicker">Current status</div>

# Built and proven — with a short open list

<div class="kd-grid kd-grid-2 mt-5">
  <div class="kd-card kd-card-ok">
    <h3><KdIcon name="material-symbols:verified-rounded" /> Landed at documented scope</h3>
    <ul>
      <li>Website XRD, Composition, and demo claim</li>
      <li>Dex GitHub OIDC; dashboards-as-code</li>
      <li>Kyverno Enforce and default-deny baseline</li>
      <li>scorecard HTML generation and Pages workflow</li>
      <li>two dated audits; public GSK HTTPS showcase edge</li>
      <li>Packer serving proof; Nix image build</li>
    </ul>
  </div>
  <div class="kd-card kd-card-warn">
    <h3><KdIcon name="material-symbols:pending-actions-rounded" /> Still open</h3>
    <ul>
      <li>external Alertmanager receiver</li>
      <li>Loki ruler alert</li>
      <li>Nix boot-to-serve</li>
      <li>three upstream pull-request merges</li>
    </ul>
  </div>
</div>

<!--
This is the status line I use for the rest of the walkthrough. The Website API, including its ephemeral gridscale VM proof, identity, dashboards, enforced policy, scorecard publishing, audits, cloud edge, Packer path, Nix build, and Backstage public route are present at their documented scope. The open work is narrower: external alert delivery, Loki ruler, Nix boot, and upstream merges.
That separation matters because several artifacts are complete at one layer but not at the next. A committed configuration is not automatically a running service, an image build is not a successful boot, and an open pull request is not an upstream merge. I use those boundaries consistently.
-->

---
layout: default
---

<div class="kd-kicker">External contribution</div>

# Work that also improved the gridscale ecosystem

<div class="kd-grid kd-grid-2 mt-6">
  <div class="kd-card kd-card-accent">
    <KdIcon name="mdi:package-variant-closed" size="1.7em" />
    <h3><code>provider-gridscale</code></h3>
    <p>An Upjet-generated Crossplane provider exposing <strong>32 gridscale resources</strong> as Kubernetes APIs.</p>
    <p class="kd-small"><a href="https://marketplace.upbound.io/providers/platformrelay/provider-gridscale">marketplace.upbound.io/providers/platformrelay/provider-gridscale</a></p>
  </div>
  <div class="kd-card">
    <KdIcon name="mdi:source-pull" size="1.7em" />
    <h3>3 upstream pull requests</h3>
    <p>Security and correctness fixes found while generating the provider. They are filed and open, not merged.</p>
    <p class="kd-small"><a href="https://github.com/gridscale/terraform-provider-gridscale/pull/509">#509</a> · <a href="https://github.com/gridscale/terraform-provider-gridscale/pull/510">#510</a> · <a href="https://github.com/gridscale/terraform-provider-gridscale/pull/511">#511</a></p>
  </div>
</div>

<div class="mt-6"><span class="kd-chip kd-chip-ok"><KdIcon name="material-symbols:deployed-code-rounded" /> shipped</span> <span class="kd-chip kd-chip-warn"><KdIcon name="material-symbols:merge-type-rounded" /> upstream review open</span></div>

<!--
Building the gridscale integration produced useful work outside this repository. Provider-gridscale publishes thirty-two gridscale resources through Crossplane’s API model. During generation I found three issues in the Terraform provider and submitted fixes upstream. The provider is shipped; the pull requests are still open, so I do not count them as merged value.
-->

---
layout: default
---

<div class="kd-kicker">How I worked</div>

# Built with AI, bounded by a spec-to-test loop

<div class="kd-flow mt-7">
  <div class="kd-step"><span>1</span><strong>OpenSpec</strong><code>proposal.md</code></div>
  <div class="kd-step"><span>2</span><strong>REQ</strong><code>Given / When / Then</code></div>
  <div class="kd-step"><span>3</span><strong>Test</strong><code>Test:</code> + <code>Verify:</code></div>
  <div class="kd-step"><span>4</span><strong>Review</strong><code>gate matrix</code></div>
</div>

<div class="kd-callout mt-8">
AI accelerates implementation; OpenSpec, tests, and review keep every claim checkable.
</div>

<div class="kd-small kd-muted mt-4">
  The authoritative coverage script derives the current requirement total; this deck avoids freezing that count.
</div>

<!--
I built with AI, but not on trust alone. OpenSpec records the decision and the expected behavior; each requirement names a test and a verification command; review gates keep those pieces connected. That loop lets me move quickly while still giving a reviewer a small, reproducible path from intent to proof.
-->

---
layout: none
title: Shared platform applications, different edges
beat: architecture
sectionTime: 110
---

<CoverArt
  src="/covers/section-04-two-courses-one-blueprint.png"
  kicker="Architecture"
  title="Shared platform applications, different edges"
/>

<!--
The architecture reuses the platform applications and manifests, while allowing each substrate to use the edge it can actually support.
-->

---
layout: default
---

<div class="kd-kicker">Platform API</div>

# Website intent becomes governed resources

<div class="kd-diagram mt-6">
  <div class="kd-node kd-node-primary">Website claim</div>
  <div class="kd-arrow">→</div>
  <div class="kd-node">Crossplane Composition</div>
  <div class="kd-arrow">→</div>
  <div class="kd-node">workload + Service</div>
  <div class="kd-node">HTTPRoute + TLS</div>
  <div class="kd-node">ServiceMonitor</div>
</div>

<div class="kd-grid kd-grid-2 mt-5">
  <div class="kd-card kd-card-ok"><strong>Simple request</strong><span class="kd-muted">a team declares a Website rather than assembling every resource by hand</span></div>
  <div class="kd-card kd-card-ok"><strong>Governed output</strong><span class="kd-muted">delivery, TLS, monitoring, policy, and evidence are part of the composition</span></div>
</div>

<!--
A Website claim is the platform contract. Crossplane Composition turns it into a workload, Service, HTTPRoute, TLS relationship, and ServiceMonitor. The important pitch is static and simple: a team declares intent once, while the platform supplies the governed resources needed to deliver and operate it.
-->

---
layout: default
beat: security
---

<div class="kd-kicker">Controls and cost</div>

# Secure defaults, with a time-boxed cloud lab

<div class="kd-grid kd-grid-3 mt-6">
  <div class="kd-card">
    <KdIcon name="material-symbols:key-vertical-rounded" size="1.5em" />
    <h3>Secrets</h3>
    <p>SOPS + age keep credentials encrypted in Git; rendered values stay out of source.</p>
  </div>
  <div class="kd-card kd-card-warn">
    <KdIcon name="material-symbols:policy-rounded" size="1.5em" />
    <h3>Guardrails</h3>
    <p>Kyverno Enforce, default-deny networking, identity, and dated audits make defaults visible.</p>
  </div>
  <div class="kd-card kd-card-accent">
    <KdIcon name="mdi:cash-clock" size="1.5em" />
    <h3>Cost governance</h3>
    <p>The GSK lab is time-boxed: bring it up for proof, capture evidence, then tear it down.</p>
  </div>
</div>

<div class="kd-callout mt-7">Controls fail close to the change; cloud spend stays an explicit operator decision.</div>

<!--
The platform starts from secure defaults: encrypted secrets, enforced admission and network policy, identity, and audit evidence. I apply the same discipline to cost. The GSK lab is a deliberate, time-boxed proof environment: create, verify, capture evidence, and tear down when the demo does not need to remain live.
-->

---
layout: default
beat: portal-hero
---

<div class="kd-kicker">Experience layer</div>

# The portal is designed; the platform API already exists

<div class="kd-grid kd-grid-2 mt-5">
  <div>
    <div class="kd-card">
      <h3><KdIcon name="mdi:view-dashboard-outline" /> Backstage on GSK</h3>
      <ul>
        <li>Website XRD projects a self-service form</li>
        <li>the form opens a GitOps change</li>
        <li>the portal shows reconciliation state</li>
        <li><code>portal.lab.platformrelay.dev</code> joins the shared HTTPRoute edge</li>
      </ul>
    </div>
  </div>
    <div class="kd-surface kd-surface-live" data-surface="backstage" data-surface-mode="live">
    <div class="kd-surface-label"><KdIcon name="mdi:application-brackets-outline" /> Backstage · GSK showcase</div>
    <p>Live public route (200): Gateway listener + Let's Encrypt certificate + HTTPRoute → <code>backstage:7007</code>.</p>
  </div>
</div>

<div class="kd-small kd-muted mt-4">The portal is the experience layer; Git and the platform API remain the source of truth.</div>

<!--
The portal is designed around the platform API rather than around a second source of truth. Backstage runs on GSK and turns the Website XRD into a guided self-service path: request a site, open a GitOps change, and inspect the resulting resources. Its public showcase route follows the same Gateway API HTTPRoute pattern as the other GSK services.
-->

---
layout: default
beat: mulligan
---

<div class="kd-kicker">mulligan</div>

# Metrics decide whether a canary promotes or rolls back

<div class="kd-diagram mt-6">
  <div class="kd-node kd-node-primary">Canary release</div>
  <div class="kd-arrow">→</div>
  <div class="kd-node">Prometheus metrics</div>
  <div class="kd-arrow">→</div>
  <div class="kd-node">analysis gate</div>
  <div class="kd-node">promote</div>
  <div class="kd-node">rollback</div>
</div>

<div class="kd-grid kd-grid-2 mt-7">
  <div class="kd-card kd-card-ok"><strong>Canary</strong><span class="kd-muted">progressively shift traffic only while observed behavior stays healthy</span></div>
  <div class="kd-card kd-card-ok"><strong>Automatic recovery</strong><span class="kd-muted">a failed analysis stops promotion and rolls the route back safely</span></div>
</div>

<!--
Mulligan is stakeholder-readable progressive delivery. Prometheus metrics feed an analysis gate while traffic shifts through a canary. Healthy behavior promotes the release; an unhealthy result automatically rolls it back through the same declared route. The point is not an animation of percentages: releases are connected to observed behavior and recover safely.
-->

---
layout: none
title: Evidence turns delivery into confidence
beat: marshal
sectionTime: 110
---

<CoverArt
  src="/covers/section-08-gatehouse-inspection.png"
  kicker="Operations and evidence"
  title="Evidence turns delivery into confidence"
/>

<!--
Operations make the platform credible: measure service behavior, capture the result, and use it to decide the next action.
-->

---
layout: default
beat: scorecard
---

<div class="kd-kicker">GSK showcase</div>

# What runs on GSK, with evidence

<div class="kd-grid kd-grid-3 mt-5">
  <div class="kd-card">
    <KdIcon name="mdi:web" size="1.5em" />
    <h3>Public services</h3>
    <p>Argo CD, Grafana, Caddy demo and canary, plus Backstage on the shared GSK edge.</p>
  </div>
  <div class="kd-card kd-card-ok">
    <KdIcon name="mdi:source-branch-sync" size="1.5em" />
    <h3>Route and images</h3>
    <p><code>portal.lab.platformrelay.dev</code> Backstage HTTPRoute is live; Caddy images are live-proven on GSK — showcase <code>:0.6.0</code> (caddy-mvp) and <code>caddy:2.11.4-alpine</code> (caddy-demo).</p>
  </div>
  <div class="kd-card">
    <KdIcon name="material-symbols:fact-check-outline-rounded" size="1.5em" />
    <h3>scorecard</h3>
    <p>Capture k6, metrics, alerts, logs, and rollout state as one reviewable HTML report.</p>
  </div>
</div>

<div class="kd-grid kd-grid-2 mt-6">
  <div class="kd-card"><strong>Route proof</strong><span class="kd-muted">the Backstage public route is a listener, certificate, and HTTPRoute to <code>backstage:7007</code></span></div>
  <div class="kd-card kd-card-ok"><strong>Honest evidence</strong><span class="kd-muted">the deck separates live proof, remaining work, and open follow-ons</span></div>
</div>

<!--
The GSK showcase makes the platform tangible: its operations surfaces, Caddy workloads, and Backstage share one cloud edge. Backstage's public route is live through the same listener, certificate, and HTTPRoute pattern as the other services. Caddy images are live-proven on GSK: caddy-mvp serves the versioned kaddy-showcase image and caddy-demo serves the current Caddy Alpine base, both returning HTTPS 200. Scorecard turns the result into evidence instead of relying on selected screenshots.
-->

---
layout: default
---

<!-- APPENDIX -->

<div class="kd-kicker">Experience layer</div>

# Backstage runs on GSK; its public route joins the showcase

<div class="kd-grid kd-grid-2 mt-5">
  <div>
    <div class="kd-card kd-card-accent">
      <h3><KdIcon name="material-symbols:dynamic-form-rounded" /> Intended flow</h3>
      <ol>
        <li>Ingest the Website XRD schema</li>
        <li>Generate the scaffolder form</li>
        <li>Open a GitOps change</li>
        <li>Show Crossplane, Argo CD, and workload status</li>
        <li>Expose the portal through the shared Gateway API edge</li>
      </ol>
    </div>
    <p class="kd-muted mt-4">Backstage serves on GSK. The showcase route <code>portal.lab.platformrelay.dev</code> is live: a fifth Gateway listener, Let's Encrypt certificate, and HTTPRoute to <code>backstage:7007</code> return 200.</p>
  </div>
  <div class="kd-stack">
    <div data-surface="argocd" data-surface-mode="static" class="kd-surface kd-surface-fallback">
      <div class="kd-surface-label"><KdIcon name="mdi:source-branch-sync" /> Argo CD · static</div>
      <p>Public GSK GitOps surface retained for deep-dive recording, not required by the spoken pitch.</p>
    </div>
    <div data-surface="backstage" data-surface-mode="live" class="kd-surface kd-surface-live">
      <div class="kd-surface-label"><KdIcon name="mdi:view-dashboard-outline" /> Backstage · GSK route live</div>
      <p>The shared HTTPRoute returns 200 on <code>portal.lab.platformrelay.dev</code>; its Let's Encrypt certificate is Ready.</p>
    </div>
    <div data-surface="crossplane-graph" data-surface-mode="fallback" class="kd-surface kd-surface-fallback">
      <div class="kd-surface-label"><KdIcon name="mdi:graph-outline" /> Crossplane graph · fallback</div>
      <p>Reserved for the live resource graph and reconciliation status.</p>
    </div>
  </div>
</div>

<!--
The portal is the experience layer, not the source of truth. The intended flow derives a form from the Website XRD, opens a GitOps change, and renders reconciliation status. Backstage serves on GSK and its public Gateway API HTTPRoute is proven: the dedicated listener, Let's Encrypt certificate, and portal Service on port 7007 return 200 at the public URL. The form-to-PR and read-path smoke remain distinct follow-on evidence.
-->

---
layout: none
title: Observe changes, then recover safely
beat: mulligan
sectionTime: 180
---

<CoverArt
  src="/covers/section-09-mulligans-second-chance.png"
  kicker="Operations and delivery"
  title="Observe changes, then recover safely"
/>

<!--
Operations connect the website to delivery decisions: measure the release, route traffic, and reverse a bad change before it becomes expensive.
-->

---
layout: default
---

<div class="kd-kicker">mulligan</div>

# Progressive delivery at the Gateway API

<div class="kd-diagram mt-5">
  <div class="kd-node kd-node-primary">Argo Rollout</div>
  <div class="kd-arrow">→</div>
  <div class="kd-node">HTTPRoute weights</div>
  <div class="kd-arrow">→</div>
  <div class="kd-node">stable + canary</div>
</div>

<div class="kd-diagram mt-4">
  <div class="kd-node">Prometheus analysis</div>
  <div class="kd-arrow">→</div>
  <div class="kd-node">health gate</div>
  <div class="kd-arrow">→</div>
  <div class="kd-node kd-node-primary">promote or rollback</div>
</div>

<div class="kd-grid kd-grid-3 mt-5">
  <div class="kd-card"><strong>Traffic shift</strong><span class="kd-muted">Gateway API backend weights</span></div>
  <div class="kd-card"><strong>Decision</strong><span class="kd-muted">Prometheus AnalysisTemplate</span></div>
  <div class="kd-card kd-card-ok"><strong>Proof</strong><span class="kd-muted">promotion and abort/rollback exercised</span></div>
</div>

<!--
Mulligan is the progressive delivery path. Argo Rollouts changes Gateway API backend weights, while a Prometheus analysis decides whether the release continues. The repository includes the stable and canary services, route integration, analysis templates, and a demo flow that exercises promotion and abort. The GSK proof also exposed an architecture-specific plugin binary issue, which is now handled explicitly.
The important point is not the animation of percentages. The release decision is connected to observed behavior, and rollback uses the same declared route model as promotion. That keeps delivery inside the platform contract and gives me a concrete failure mode to demonstrate rather than only showing a healthy deployment.
-->

---
layout: default
beat: marshal
---

<div class="kd-kicker">marshal</div>

# Monitoring is useful when it changes action

<div class="kd-grid kd-grid-2 mt-5">
  <div class="kd-card">
    <h3><KdIcon name="material-symbols:monitor-heart-rounded" /> Landed</h3>
    <ul>
      <li>Prometheus and blackbox scraping</li>
      <li>down, rate, error, and latency alerts</li>
      <li>promtool tests for alert rules</li>
      <li>12-panel dashboard-as-code with Loki panel</li>
      <li>Alertmanager routing proven to the configured sink</li>
    </ul>
  </div>
  <div class="kd-card kd-card-warn">
    <h3><KdIcon name="material-symbols:notifications-active-outline-rounded" /> Remaining</h3>
    <ul>
      <li>external Alertmanager receiver</li>
      <li>Loki ruler-based 5xx alert</li>
    </ul>
    <div class="kd-callout mt-6">The core fire path exists; the external notification destination remains open.</div>
  </div>
</div>

<!--
Marshal covers the operational loop. Metrics and blackbox probes feed tested alert rules, dashboards are provisioned as code, and Loki logs appear alongside metrics. Alertmanager routing has been exercised to the configured sink. The remaining work is precise: connect an external receiver and move the log-based check into a Loki ruler alert.
-->

---
layout: default
---

<div class="kd-kicker">Demo surfaces</div>

# GSK showcase: every service has an edge

<div class="kd-grid kd-grid-3 mt-5">
  <div class="kd-surface">
    <div class="kd-surface-label"><KdIcon name="mdi:web" /> Website</div>
    <iframe src="https://demo.lab.platformrelay.dev/" title="Clubhouse website" data-surface="clubhouse" data-surface-mode="live"></iframe>
  </div>
  <div class="kd-surface">
    <div class="kd-surface-label"><KdIcon name="mdi:chart-line" /> Grafana</div>
    <iframe src="https://grafana.lab.platformrelay.dev/alerting/list" title="Grafana alerting" data-surface="grafana" data-surface-mode="live"></iframe>
  </div>
  <div class="kd-card kd-card-accent">
    <KdIcon name="mdi:view-dashboard-outline" size="1.7em" />
    <h3>Backstage</h3>
    <p>Running on GSK; the public <code>portal.lab.platformrelay.dev</code> HTTPRoute is live and returns 200.</p>
  </div>
</div>

<div class="kd-callout mt-5">Caddy images are live-proven on GSK: <code>kaddy-showcase:0.6.0</code> for caddy-mvp (Healthy) and <code>caddy:2.11.4-alpine</code> for caddy-demo; <code>caddy.lab.platformrelay.dev</code> and <code>demo.lab.platformrelay.dev</code> return HTTPS 200.</div>

<!--
These compact surfaces support a GSK-first demonstration without taking over the explanatory slides. Argo CD, Grafana, the Caddy tenant, and Backstage share the cloud edge; the portal route is live with its public 200 recorded. Caddy images are live-proven on GSK at the versioned kaddy-showcase pin for the full canary and the current Caddy Alpine base for the landing page. Live frames use public *.lab.platformrelay.dev URLs; if a public frame is unavailable during a review, the repository still contains the manifests, tests, and generated evidence, so the claim does not depend on a browser tab.
-->

---
layout: default
---

<div class="kd-kicker">Delivery choices</div>

# Different paths answer different needs

<div class="kd-grid kd-grid-2 mt-5">
  <div class="kd-card kd-card-ok"><strong>Packer Marketplace VM</strong><span class="kd-muted">literal server path; image provisioning and serve proof landed</span></div>
  <div class="kd-card kd-card-ok"><strong>In-cluster tenant</strong><span class="kd-muted">TLS, monitoring, and progressive delivery behind the platform edge</span></div>
  <div class="kd-card kd-card-ok"><strong>Crossplane Website</strong><span class="kd-muted">self-service API with local claim and ephemeral real gridscale VM serve proof</span></div>
  <div class="kd-card kd-card-warn"><strong>Nix image</strong><span class="kd-muted">flake-locked image builds; gridscale boot-to-serve remains open</span></div>
</div>

<!--
I keep these paths separate because they solve different problems. Packer is the most direct gridscale Marketplace route. The in-cluster tenant demonstrates richer platform behavior. Crossplane provides the self-service API, with both the local composition and an ephemeral real gridscale VM serve cycle proven. Nix adds reproducible image construction, but it is not complete until the image boots and serves on gridscale.
-->

---
layout: none
title: Make every claim easy to check
beat: scorecard
sectionTime: 155
---

<CoverArt
  src="/covers/section-12-signed-scorecard.png"
  kicker="Evidence and next steps"
  title="Make every claim easy to check"
/>

<!--
The final section turns the walkthrough into evidence and leaves a short, explicit list of what I would do next.
-->

---
layout: default
---

<div class="kd-kicker">scorecard</div>

# Evidence is an output, not a screenshot folder

<div class="kd-diagram mt-6">
  <div class="kd-node">k6 run</div>
  <div class="kd-node">metrics + alerts</div>
  <div class="kd-node">logs</div>
  <div class="kd-node">rollout state</div>
  <div class="kd-arrow">→</div>
  <div class="kd-node kd-node-primary">self-contained HTML</div>
</div>

<div class="kd-grid kd-grid-3 mt-7">
  <div class="kd-card"><strong>Repeatable</strong><span class="kd-muted">fixture and live capture modes</span></div>
  <div class="kd-card"><strong>Publishable</strong><span class="kd-muted">GitHub Pages workflow landed</span></div>
  <div class="kd-card kd-card-ok"><strong>Reviewable</strong><span class="kd-muted">inputs and report stay together</span></div>
</div>

<!--
Scorecard collects the operational evidence into a self-contained HTML report. It records load, metrics, alerts, logs, and rollout state rather than relying on selected screenshots. Fixture mode keeps the renderer testable in CI, while the live path captures a real run. The Pages workflow publishes the report artifact, making review possible without recreating my environment.
The report also exposes provenance: capture mode, timestamps, and the source material travel with the rendered result. That makes the demonstration easier to repeat and easier to challenge. If a threshold, route, or rollout behavior changes, the next report records the new outcome instead of leaving an old screenshot as permanent truth.
-->

---
layout: default
---

<div class="kd-kicker">What I would do next</div>

# Close the remaining loops in risk order

<div class="kd-flow kd-flow-vertical mt-5">
  <div class="kd-step"><span>1</span><strong>Operations</strong>external Alertmanager receiver and Loki ruler</div>
  <div class="kd-step"><span>2</span><strong>Image proof</strong>boot the Nix image on gridscale and verify serve → scrape → alert</div>
  <div class="kd-step"><span>3</span><strong>Upstream</strong>respond to review and land the three provider fixes</div>
</div>

<!--
My next work would close operational loops before adding breadth. First I would deliver alerts to an external receiver and add the Loki ruler. The public Backstage route on the GSK showcase edge is already proven; the generated form-to-PR experience remains separate follow-on evidence. After that I would complete the Nix boot-to-serve proof. Upstream review continues in parallel because merge timing is not fully mine to control.
-->

---
layout: default
class: text-center
---

<div class="kd-kicker">Closing</div>

# What I built, proved, and left open

<div class="kd-grid kd-grid-3 mt-9 text-left">
  <div class="kd-card"><KdIcon name="material-symbols:construction-rounded" /><strong>Built</strong><span class="kd-muted">a reusable Website-as-a-Service platform and several delivery paths</span></div>
  <div class="kd-card kd-card-ok"><KdIcon name="material-symbols:verified-rounded" /><strong>Proved</strong><span class="kd-muted">local and GSK edges, controls, delivery, monitoring, images, and evidence at documented scope</span></div>
  <div class="kd-card kd-card-warn"><KdIcon name="material-symbols:pending-actions-rounded" /><strong>Open</strong><span class="kd-muted">a small set of runtime and end-to-end proof gaps</span></div>
</div>

<p class="mt-9 kd-lede">I would be happy to open any artifact and walk through the trade-offs.</p>

<div class="kd-footer-link">github.com/PlatformRelay/Kaddy</div>

<!--
Kaddy answers the original exercise through a literal VM path and a broader platform product. The repository shows the architecture changes I made after live cloud evidence, the controls I enforced, and the tests behind the claims. It also keeps the remaining gaps visible. I am happy to inspect any artifact or discuss where I would simplify it for a production team.
The implementation is intentionally more complete than a single installation script, but each added layer has a reason: repeatability, safe change, operational visibility, or reviewable evidence. In a real team I would keep the same boundaries and adjust the amount of machinery to the expected number of tenants, operators, and compliance needs.
-->

---
layout: default
---

<div class="kd-kicker">Appendix A</div>

# Golden images: Packer and Nix

<div class="kd-grid kd-grid-2 mt-5">
  <div class="kd-card kd-card-ok">
    <h3>Packer Marketplace VM</h3>
    <p>Ubuntu-based Caddy and nginx images, provisioned by the Packer templates. The image path and serving behavior are landed at documented scope.</p>
  </div>
  <div class="kd-card kd-card-warn">
    <h3>Nix image build</h3>
    <p><code>nix/flake.nix</code>, lock file, NixOS module, and image build proof are landed. The image is built, but gridscale boot-to-serve remains open under E14 / ADR-0303.</p>
  </div>
</div>

<div class="kd-callout mt-7">Build proof is not boot proof; the deck keeps that boundary explicit.</div>

<div class="kd-card mt-5">
  <strong>Pitch honesty boundary</strong>
  <span class="kd-muted">Upstream PRs are filed and open, not merged. Backstage's public HTTPRoute proof is live and separately recorded from E12d; the talk narrative was never used as its proof. E10 form-to-PR smoke remains follow-on work.</span>
</div>

<!--
For image questions, Packer and Nix are parallel paths. Packer provisions a familiar base image and has the serving proof. The Nix flake and module now build an image reproducibly. That corrects the old appendix wording: flake dot nix does exist. What is still missing is boot-to-serve on gridscale, so Nix is built but not fully proven. The pitch treats Backstage as the experience layer while recording the live public route separately from this deck epic; it never turns filed upstream pull requests into claimed merges.
-->

---
layout: default
---

<div class="kd-kicker">Appendix B</div>

# The delivery paths are not interchangeable

<div class="kd-grid kd-grid-3 mt-5">
  <div class="kd-card"><strong>Caddy VM</strong><span class="kd-muted">Packer Marketplace artifact; literal brief and direct operational model</span></div>
  <div class="kd-card"><strong>In-cluster tenant</strong><span class="kd-muted">Kubernetes workload behind the shared edge, with rollout and monitoring</span></div>
  <div class="kd-card"><strong>Crossplane Website</strong><span class="kd-muted">API-driven composition; local workload and ephemeral real VM serve paths proven</span></div>
</div>

<div class="kd-card kd-card-warn mt-6">
  <strong>Nix image</strong>
  <span class="kd-muted">A fourth image-building route: build landed, boot-to-serve open.</span>
</div>

<p class="kd-muted mt-5">This “different ways” view separates packaging, runtime, and self-service rather than presenting them as one implementation.</p>

<!--
These routes differ in ownership and runtime. The Packer VM is a direct Marketplace artifact. The in-cluster tenant inherits Kubernetes platform capabilities. Crossplane is the self-service control-plane path and can compose different targets. Nix changes how a VM image is built, not how the Kubernetes platform runs. Keeping those distinctions clear prevents evidence from one route being borrowed by another.
-->

---
layout: default
---

<div class="kd-kicker">Appendix C</div>

# Repository structure and verification entry points

<div class="kd-grid kd-grid-2 mt-5">
  <div class="kd-card kd-code-list">
    <code>deploy/</code><span>GitOps applications and manifests</span>
    <code>stacks/</code><span>OpenTofu and Terramate</span>
    <code>packer/</code><span>Marketplace VM builds</span>
    <code>nix/</code><span>flake-locked image build</span>
    <code>policy/</code><span>Rego and Kyverno controls</span>
  </div>
  <div class="kd-card kd-code-list">
    <code>openspec/</code><span>epics, plans, stories, requirements</span>
    <code>tests/</code><span>gate matrix</span>
    <code>evidence/</code><span>scorecards and live proofs</span>
    <code>docs/</code><span>ADRs, audits, architecture, runbooks</span>
    <code>slides/</code><span>this independent deck theme</span>
  </div>
</div>

<div class="mt-6"><span class="kd-chip"><KdIcon name="mdi:console-line" /> first local entry point: <code>task cluster:up</code></span></div>

<!--
The repository tree follows the operating model. Deploy contains desired cluster state. Stacks and image directories cover infrastructure and VM artifacts. OpenSpec records intent, tests enforce behavior, evidence captures results, and docs explain decisions. For a local exploration, task cluster colon up is the first entry point, followed by the reviewer paths in the root README.
-->

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
sectionTime: 140
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
      <li>two dated audits; public GSK HTTPS proofs</li>
      <li>Packer serving proof; Nix image build</li>
    </ul>
  </div>
  <div class="kd-card kd-card-warn">
    <h3><KdIcon name="material-symbols:pending-actions-rounded" /> Still open</h3>
    <ul>
      <li>Backstage runtime</li>
      <li>external Alertmanager receiver</li>
      <li>Loki ruler alert</li>
      <li>Nix boot-to-serve</li>
      <li>three upstream pull-request merges</li>
    </ul>
  </div>
</div>

<!--
This is the status line I use for the rest of the walkthrough. The Website API, including its ephemeral gridscale VM proof, identity, dashboards, enforced policy, scorecard publishing, audits, cloud edge, Packer path, and Nix build are present at their documented scope. The open work is narrower: portal runtime, external alert delivery, Loki ruler, Nix boot, and upstream merges.
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

# A spec-to-test loop I can replay

<div class="kd-flow mt-7">
  <div class="kd-step"><span>1</span><strong>Epic</strong><code>e5-monitoring-marshal</code></div>
  <div class="kd-step"><span>2</span><strong>Plan</strong><code>proposal.md</code></div>
  <div class="kd-step"><span>3</span><strong>Story</strong><code>tasks.md</code> + <code>REQ-…</code></div>
  <div class="kd-step"><span>4</span><strong>Test</strong><code>promtool</code> + gate matrix</div>
</div>

<div class="kd-callout mt-8">
  OpenSpec records intent; the named test demonstrates behavior; the gate keeps both connected.
</div>

<div class="kd-small kd-muted mt-4">
  The authoritative coverage script derives the current requirement total; this deck avoids freezing that count.
</div>

<!--
I used the same loop for each meaningful change. The OpenSpec change folder names the epic. Proposal dot md explains scope and trade-offs. Tasks dot md and the requirement blocks define testable slices. The requirement names a concrete test and verify command, and the gate matrix checks that connection. I avoid putting a fast-changing requirement count on a slide.
This gives a reviewer three useful entry points: the decision and scope, the expected behavior, and the executable proof. It also made course corrections safer, because a changed cloud assumption could be reflected in the spec and tests instead of being hidden in an ad hoc script.
-->

---
layout: none
title: Shared platform applications, different edges
beat: architecture
sectionTime: 170
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

<div class="kd-kicker">Architecture</div>

# One GitOps platform, two edge implementations

```mermaid {scale: 0.72}
flowchart LR
  Git["GitOps applications<br/>and shared manifests"] --> Argo["Argo CD"]
  Argo --> Core["Identity · policy · observability<br/>tenants · delivery"]
  Core --> Kind["local kind"]
  Core --> GSK["gridscale GSK"]
  Kind --> Cilium["Cilium Gateway API<br/>LB-IPAM / local TLS"]
  GSK --> Traefik["Traefik v3 Gateway API<br/>gridscale LoadBalancer / public TLS"]
```

<div class="kd-grid kd-grid-2 mt-4">
  <div class="kd-card"><strong>Shared</strong><span class="kd-muted">platform applications, workload intent, policy, observability, and GitOps operating model</span></div>
  <div class="kd-card kd-card-warn"><strong>Different by design</strong><span class="kd-muted">edge controller, certificates, hostnames, and substrate-specific overlays</span></div>
</div>

<!--
The reusable part is the platform: Argo CD applications, workload intent, identity, controls, observability, and delivery. The edges differ. Local kind uses Cilium Gateway API. GSK uses Traefik version three behind the gridscale LoadBalancer because the managed Cilium installation cannot serve Gateway API. Promotion therefore includes an intentional edge overlay, not a simple repoint.
That distinction keeps portability honest. I can reuse a large part of the operating model without claiming byte-for-byte identity. Hostnames, certificate issuers, controller installation, and some architecture-specific rollout settings remain explicit. Those differences are reviewable GitOps artifacts rather than undocumented steps applied to the cloud cluster.
-->

---
layout: default
---

<div class="kd-kicker">Cloud learning</div>

# D-042 changed the edge, not the platform goal

<div class="kd-grid kd-grid-3 mt-6">
  <div class="kd-card">
    <span class="kd-chip"><KdIcon name="mdi:laptop" /> local</span>
    <h3>Cilium</h3>
    <p>Gateway API, LB-IPAM/L2, local certificates, <code>.kaddy.local</code>.</p>
  </div>
  <div class="kd-card kd-card-warn">
    <span class="kd-chip kd-chip-warn"><KdIcon name="material-symbols:rule-settings-rounded" /> constraint</span>
    <h3>Managed Cilium</h3>
    <p>GSK’s managed installation lacks the operator capability needed to serve Gateway API.</p>
  </div>
  <div class="kd-card kd-card-accent">
    <span class="kd-chip kd-chip-ok"><KdIcon name="mdi:cloud-check-outline" /> live proof</span>
    <h3>Traefik v3</h3>
    <p>Gateway API, gridscale LoadBalancer, DNS-01, and publicly trusted HTTPS.</p>
  </div>
</div>

<div class="kd-callout mt-7">D-042 records the limitation and the GSK-specific Traefik choice.</div>

<!--
The first cloud deployment disproved an assumption in the early design. GSK does ship managed Cilium, but that installation cannot provide the Gateway API edge used locally. I recorded the constraint in D-zero-four-two and introduced a cloud-only Traefik controller and overlays. The platform contract stayed stable while the substrate integration changed based on evidence.
-->

---
layout: default
---

<div class="kd-kicker">GitOps control plane</div>

# Shared applications, explicit cloud overlays

<div class="kd-grid kd-grid-2 mt-5">
  <div>
    <div class="kd-card">
      <h3><KdIcon name="mdi:source-branch-sync" /> Argo CD app-of-apps</h3>
      <ul>
        <li>root application discovers platform children</li>
        <li>automated prune and self-heal</li>
        <li>mandatory ownership and classification labels</li>
        <li>cloud-only edge kept outside the local root</li>
      </ul>
    </div>
  </div>
  <div class="kd-surface">
    <div class="kd-surface-label"><KdIcon name="mdi:application-brackets-outline" /> Live surface · Argo CD</div>
    <iframe src="https://127.0.0.1:30443/applications" title="Argo CD applications" data-surface="argocd" data-surface-mode="live"></iframe>
  </div>
</div>

<div class="kd-small kd-muted mt-4">The UI is supporting evidence; Git remains the source of truth.</div>

<!--
Argo CD is the common operating model. A root application discovers the platform children and reconciles them with prune and self-heal enabled. The GSK Traefik application is intentionally outside the local root so kind never installs a competing controller. This is shared GitOps with explicit substrate boundaries, rather than pretending every object is portable.
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

<div class="kd-grid kd-grid-2 mt-7">
  <div class="kd-card kd-card-ok"><strong>Landed</strong><span class="kd-muted">Website XRD, Composition, demo claim, route, TLS, and monitor at documented local scope</span></div>
  <div class="kd-card kd-card-ok"><strong>Cloud proof</strong><span class="kd-muted">a gridscale variant provisioned a real nginx VM, served <code>/legacy</code>, <code>/healthz</code>, and <code>/metrics</code>, then cleaned up</span></div>
</div>

<!--
Crossplane provides the platform API. A namespaced Website claim is composed into the in-cluster workload, service, route, certificate relationship, and monitor. That local path and demo claim are landed. The gridscale variant was also exercised end to end: it provisioned a real nginx VM, served the legacy page, health endpoint, and metrics over its public address, and then deleted every composed resource.
-->

---
layout: none
title: Secure defaults, enforced in layers
beat: security
sectionTime: 165
---

<CoverArt
  src="/covers/section-08-gatehouse-inspection.png"
  kicker="Platform controls"
  title="Secure defaults, enforced in layers"
/>

<!--
Next are the platform controls: practical defaults that are visible in manifests, admission behavior, CI, and audit evidence.
-->

---
layout: default
---

<div class="kd-kicker">Security and governance</div>

# Controls close to the change

<div class="kd-grid kd-grid-3 mt-5">
  <div class="kd-card">
    <KdIcon name="material-symbols:key-vertical-rounded" size="1.5em" />
    <h3>Secrets</h3>
    <p>SOPS + age in Git, rendered through KSOPS; private key stays outside the repository.</p>
  </div>
  <div class="kd-card kd-card-ok">
    <KdIcon name="material-symbols:policy-rounded" size="1.5em" />
    <h3>Admission and network</h3>
    <p>Kyverno policies in <strong>Enforce</strong>; default-deny baselines with explicit allows.</p>
  </div>
  <div class="kd-card">
    <KdIcon name="material-symbols:shield-lock-rounded" size="1.5em" />
    <h3>Identity and supply chain</h3>
    <p>Dex GitHub OIDC, no guest portal actions, pinned tooling, gitleaks, and policy tests.</p>
  </div>
</div>

<div class="kd-grid kd-grid-2 mt-6">
  <div class="kd-card"><strong>Audit trail</strong><span class="kd-muted">two dated security/compliance audits plus a data-flow security review</span></div>
  <div class="kd-card kd-card-warn"><strong>Known cloud risk</strong><span class="kd-muted">GSK node public exposure is documented with compensating controls and time-boxed operation</span></div>
</div>

<!--
The controls are layered and testable. Secrets stay encrypted in Git and are rendered by KSOPS. Kyverno rejects nonconforming workloads in Enforce mode, while default-deny network policies require explicit traffic paths. Dex provides GitHub-backed identity. CI checks secrets and policy artifacts. Two dated audits make the remaining findings visible, including the accepted GSK node exposure risk.
I chose controls that fail close to the change. A bad image tag or security context should fail admission; a missing label should fail the relevant policy gate; an unintended connection should meet a deny rule. The cloud-node risk cannot be removed through the current provider API, so the mitigation and time boundary are documented instead of implied away.
-->

---
layout: default
beat: portal-hero
---

<div class="kd-kicker">Experience layer</div>

# The portal is designed; the platform API already exists

<div class="kd-grid kd-grid-2 mt-5">
  <div>
    <div class="kd-card kd-card-accent">
      <h3><KdIcon name="material-symbols:dynamic-form-rounded" /> Intended flow</h3>
      <ol>
        <li>Ingest the Website XRD schema</li>
        <li>Generate the scaffolder form</li>
        <li>Open a GitOps change</li>
        <li>Show Crossplane, Argo CD, and workload status</li>
      </ol>
    </div>
    <p class="kd-muted mt-4">Backstage configuration and tests are present. Runtime deployment remains open.</p>
  </div>
  <div class="kd-stack">
    <div data-surface="backstage" data-surface-mode="fallback" class="kd-surface kd-surface-fallback">
      <div class="kd-surface-label"><KdIcon name="mdi:view-dashboard-outline" /> Backstage · fallback</div>
      <p>Reserved for the generated Website form once runtime proof lands.</p>
    </div>
    <div data-surface="crossplane-graph" data-surface-mode="fallback" class="kd-surface kd-surface-fallback">
      <div class="kd-surface-label"><KdIcon name="mdi:graph-outline" /> Crossplane graph · fallback</div>
      <p>Reserved for the live resource graph and reconciliation status.</p>
    </div>
  </div>
</div>

<!--
The portal is the experience layer, not the source of truth. The intended flow derives a form from the Website XRD, opens a GitOps change, and renders reconciliation status. The configuration, schema annotations, RBAC, and tests are in the repository. Backstage itself is not running yet, so these are explicit fallback surfaces rather than simulated screenshots.
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

# Three compact views, one evidence path

<div class="kd-grid kd-grid-3 mt-5">
  <div class="kd-surface">
    <div class="kd-surface-label"><KdIcon name="mdi:web" /> Website</div>
    <iframe src="https://clubhouse.kaddy.local:8443/" title="Clubhouse website" data-surface="clubhouse" data-surface-mode="live"></iframe>
  </div>
  <div class="kd-surface">
    <div class="kd-surface-label"><KdIcon name="mdi:chart-line" /> Grafana</div>
    <iframe src="http://127.0.0.1:3000/alerting/list" title="Grafana alerting" data-surface="grafana" data-surface-mode="live"></iframe>
  </div>
  <div class="kd-card kd-card-accent">
    <KdIcon name="material-symbols:fact-check-outline-rounded" size="1.7em" />
    <h3>Capture</h3>
    <p>Run the behavior, collect k6, metrics, alerts, logs, and rollout state, then render one HTML report.</p>
  </div>
</div>

<div class="kd-small kd-muted mt-5">Live frames are optional recording aids; the evidence artifacts remain reviewable without them.</div>

<!--
These compact surfaces support a demonstration without taking over the explanatory slides. I can show the website response, inspect Grafana, and connect both to the same scorecard capture. If a local frame is unavailable during a review, the repository still contains the manifests, tests, and generated evidence, so the claim does not depend on a browser tab.
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
  <div class="kd-step"><span>2</span><strong>Experience</strong>deploy Backstage and prove the generated form and graph</div>
  <div class="kd-step"><span>3</span><strong>Image proof</strong>boot the Nix image on gridscale and verify serve → scrape → alert</div>
  <div class="kd-step"><span>4</span><strong>Upstream</strong>respond to review and land the three provider fixes</div>
</div>

<!--
My next work would close operational loops before adding breadth. First I would deliver alerts to an external receiver and add the Loki ruler. Then I would run Backstage and prove the generated experience. After that I would complete the Nix boot-to-serve proof. Upstream review continues in parallel because merge timing is not fully mine to control.
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

<!-- APPENDIX -->

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

<!--
For image questions, Packer and Nix are parallel paths. Packer provisions a familiar base image and has the serving proof. The Nix flake and module now build an image reproducibly. That corrects the old appendix wording: flake dot nix does exist. What is still missing is boot-to-serve on gridscale, so Nix is built but not fully proven.
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

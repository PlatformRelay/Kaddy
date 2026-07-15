# Security review — merged platform spine (2026-07-16)

**Scope:** data-flow security review of the now-merged spine
(E1e substrate → E1 ArgoCD → E3 observability → E4 clubhouse/TLS).
**Type:** read-only. No cluster mutation, no manifest/policy/CI changes — the
only artifact produced is this document.
**Reviewer method:** static read of manifests, workflows, policies, ADRs, and
`hack/` scripts, plus **read-only** live probes against the `kind-kaddy-dev`
cluster (`get netpol/cnp/gateway/svc/clusterpolicy`, no writes).

## Threat model (read this first)

The current substrate is a **local `kind` + Cilium lab**, not a public edge.
That materially changes severity, so it is stated up front and applied
consistently below:

- **No untrusted network path exists today.** The Gateway/LoadBalancer external
  IPs live on the non-host-routable podman bridge (`10.89.0.0/24`), and the only
  host reachability is via NodePorts **bound to `127.0.0.1`** in the kind config
  (`hack/cluster/kind/cluster.yaml:25,30`). There is no `0.0.0.0`/wildcard bind
  anywhere in `deploy/` or `hack/`.
- Therefore **there is no exploitable P0/P1 in the lab as it stands.** The P1s
  below are ranked **P1-on-the-public-path** (they MUST change before the
  gridscale/production edge) and behave as P2 in the lab today. This is called
  out per finding so severity is not inflated.
- The production threat model (phase 2: provider-gridscale LBaaS + a real public
  hostname + DNS) is different — a real Internet ingress, multi-tenant blast
  radius, and rate-limited public ACME. Findings tagged **prod-path** are the
  gate items for that transition.

## Verdict

**Lab posture: acceptable and, in several places, exemplary.** Context isolation,
TLS-at-the-edge, pod hardening, and secret hygiene are done to a standard that
reads as enterprise-serious. **Production readiness: NOT yet** — the gaps are
concentrated in three roadmapped-but-unbuilt controls (network segmentation,
RBAC scoping, image supply-chain) plus one governance control that is present in
Git but **inert in the cluster**. None are regressions; all are either
accepted-with-target or newly precise characterisations of a known gap.

Finding counts: **P0 ×0 · P1 ×3 · P2 ×5 · P3 ×4** (+ what is sound, below).

## The core data-flow chain (the synthesis finding)

Three individually-defensible "it's fine, it's behind the Gateway" decisions
share a single root cause and compound into one chain:

1. `argocd-server` runs `--insecure` (plain HTTP `:80`) —
   `deploy/bootstrap/argocd.yaml:33`. Defensible *only* because TLS terminates at
   the Cilium Gateway in front of it.
2. Grafana ships with the chart-default admin credentials `admin/prom-operator`
   — `deploy/observability/kube-prometheus-stack.yaml:78-79`. Defensible *only*
   because it has no ingress and is ClusterIP-only.
3. The clubhouse app and every observability component are ClusterIP services.

The shared root is **the absence of a default-deny NetworkPolicy** (confirmed
live: `kubectl get netpol -A` returns only ArgoCD's own chart-bundled policies,
scoped to the `argocd` namespace; `kubectl get cnp -A` is empty). With no
default-deny, **any pod can reach any pod cluster-wide** — so the "it's only
reachable in-cluster" premise that makes (1), (2), and (3) acceptable is exactly
the premise that a single compromised or malicious workload voids. The
plain-HTTP ArgoCD API, the default Grafana admin, and every backend become
reachable from any pod on the cluster. In the lab this is contained (single
operator, no tenants); on the multi-tenant gridscale path it is the primary
lateral-movement surface. Fixing the NetworkPolicy gap (SEC-6 / E1c) is what
retroactively justifies the other two.

## Findings

### P1 (public-path — MUST change before the gridscale edge; P2 in lab)

**P1-1 · No default-deny NetworkPolicy (network segmentation absent).**
`deploy/` contains zero `NetworkPolicy`/`CiliumNetworkPolicy` objects; live
`get netpol -A` shows only ArgoCD's bundled per-component policies and `get cnp`
is empty. ADR-0106 *specifies* default-deny in every namespace with explicit
allow-lists (ingress from Gateway ns, Prometheus → metrics, DNS egress,
Crossplane → gridscale API), but E1c has not landed. **This is the root of the
chain above.** Status: **roadmapped (SEC-6 / E1c) — accepted-with-target, not a
regression.** Fix target: land the E1c default-deny baseline before any workload
is reachable from an untrusted network.

**P1-2 · ArgoCD app-of-apps runs entirely under `project: default` with
auto-prune + selfHeal + a cluster-wide root finalizer.**
Every Application (`deploy/apps/root.yaml:32`, `platform-core.yaml:29`,
`gateway.yaml:26`, `workloads.yaml:26`, `observability.yaml:29`,
`identity.yaml:32`) uses `project: default`, which is **unrestricted** — no
`sourceRepos`, `destinations`, or `clusterResourceWhitelist` constraints (live
`get appprojects` shows only `default`). Combined with `prune: true` on the root
and `selfHeal: true` on the root and `platform-core`, plus the root's
cluster-scoped `resources-finalizer.argocd.argoproj.io`
(`deploy/apps/root.yaml:29`), the **blast radius is the whole cluster**: a
malicious or mistaken merge to a whitelisted (in-cluster) repo path can create,
mutate, or prune any namespace-or-cluster-scoped resource, and selfHeal will
re-assert it against a human trying to intervene. In the lab (single trusted Git
source, single operator) this is acceptable; on the shared path it wants a
restricted `AppProject` per tenant/domain. Status: **partially roadmapped
(SEC-7 / E1d RBAC), but the AppProject-scoping angle is a newly precise call-out
here** — the audit's SEC-7 framed RBAC broadly; the unrestricted-project +
selfHeal + finalizer *composition* is the concrete blast-radius mechanism. Fix
target: minimal per-domain `AppProject`s with `destinations` +
`clusterResourceWhitelist`, before multi-source or multi-tenant GitOps.

**P1-3 · Grafana admin uses chart-default static credentials.**
`admin/prom-operator` is hard-set via chart defaults
(`deploy/observability/kube-prometheus-stack.yaml:78-79`, with a comment
acknowledging "lab only"). It is live in-cluster now. Contained today only by the
absence of ingress and of pod-to-pod reachability (see the chain). Status: **new
precise finding (live credential), lab-contained.** Fix target: source Grafana
admin from a Secret/KSOPS and front Grafana with the Dex/GitHub OIDC path
(ADR-0107) before any exposure. Note this is coupled to the identity epic being
deferred (KSOPS not yet on the demoable path — `deploy/apps/identity.yaml`).

### P2 (lab-acceptable posture; harden on the way to prod)

**P2-1 · Kyverno ADR-0301 label policy is present in Git but INERT in the
cluster.**
`deploy/policies/kyverno/require-kaddy-labels.yaml` declares
`validationFailureAction: Enforce`, which *looks* like hard admission denial —
but it is **not enforced anywhere**:

- No Application syncs `deploy/policies/` — the app-of-apps children cover
  `cert-manager`, `gateway`, `workloads`, `observability`, `identity` only;
  nothing points at `deploy/policies` (`grep deploy/policies deploy/apps
  Taskfile.yml` → nothing). The manifest is orphaned from GitOps.
- Kyverno is not installed on the live cluster: `get clusterpolicy` →
  *"the server doesn't have a resource type"*; there is no `kyverno` namespace.

**The honest dual truth:** the ADR-0301 label contract *is* enforced at CI
plan-time — the Rego policy `policy/labels.rego` runs via conftest
(`task test:policy`, L1, wired in `verify.yaml:53`) and *does* deny OpenTofu
plans missing the mandatory keys. But **in-cluster admission enforcement does
not exist** — the `Enforce` in the manifest is aspirational, not active. Anyone
reading only the manifest would wrongly conclude Pods are admission-gated on
labels. Status: **new precise finding.** Fix target: wire `deploy/policies/`
into the app-of-apps and install Kyverno (this is the deferred Chainsaw
labeling/security suite dependency, TEST-4) — or, if enforcement is
intentionally CI-only for now, annotate the manifest as not-applied to prevent a
false sense of admission control.

**P2-2 · Observability workloads inherit chart-default pod security (no explicit
hardening at the manifest layer).**
The clubhouse Deployment is exemplary (see "What is sound"), but the
Helm-installed observability stack sets **no explicit** `securityContext` in its
values (`grep securityContext deploy/observability/` → none): Prometheus, Loki,
Alloy, Grafana, node-exporter run with whatever the upstream charts default to.
node-exporter and Alloy (DaemonSet mounting `/var/log`,
`deploy/observability/alloy.yaml:48-49`) are inherently node-privileged log/host
collectors. Lab-acceptable; charts' defaults are reasonable. Fix target: pin
`runAsNonRoot` / `readOnlyRootFilesystem` / dropped caps via chart values where
the workload allows, and let the (future) default-deny + Kyverno baseline
enforce it.

**P2-3 · GitHub Actions are pinned by mutable tag, not commit SHA.**
`actions/checkout@v4`, `arduino/setup-task@v2`, `actions/setup-go@v5`,
`helm/kind-action@v1`, `opentofu/setup-opentofu@v1` across
`.github/workflows/verify.yaml` and `chainsaw.yaml` are tag-pinned. A tag can be
force-moved, so a compromised action could exfiltrate the workflow's
`GITHUB_TOKEN` (both workflows correctly scope `permissions: contents: read`,
which limits the damage). Status: **known — audit SEC-5, Renovate-mitigated
(P3-adjacent).** The *tool* installs (gitleaks 8.30.1, conftest 0.56.0, ripgrep
14.1.1, chainsaw v0.2.15, kyverno v1.18.2, cert-manager v1.18.2, yq v4.44.3) and
the kind node image `v1.33.1` **are** exactly pinned (SEC-4 done — verified).
Fix target: SHA-pin actions (Renovate can maintain the digests).

**P2-4 · No image digests / no in-cluster image provenance (Trivy/cosign).**
Images are pinned by exact tag (e.g. `nginxinc/nginx-unprivileged:1.29.0-alpine`,
`deploy/workloads/clubhouse/deployment.yaml:51`) — good, no floating `:latest` —
but not by digest, and there is no Trivy scan-gate or Kyverno `verifyImages`
policy. ADR-0106 specifies both. Status: **roadmapped (SEC-8 / E1c) —
accepted-with-target.** Fix target: Trivy CI gate + digest pinning + cosign
verify on the release path.

**P2-5 · Leftover live test artifacts (`e1e-smoke` namespace + gateway) remain
in the cluster.**
Live `get ns` shows an active `e1e-smoke` namespace with a programmed
`kaddy-smoke` Gateway and a `cilium-gateway-kaddy-smoke` LoadBalancer on
NodePort 30080. This is cluster hygiene, not a committed-artifact issue (nothing
in `deploy/` provisions it persistently), but a stale edge listener widens the
in-cluster surface. Lab-only. Fix target: ensure smoke suites tear down their
namespaces (or the bootstrap does) so no orphaned gateway lingers.

### P3 (accept-with-note)

**P3-1 · LE staging/prod ACME solver references a non-existent Gateway (latent
prod-path issuance break).**
`cluster-issuer-staging.yaml:41-43` and `cluster-issuer-prod.yaml:37-39` set the
HTTP-01 `gatewayHTTPRoute` solver `parentRef` to a Gateway named `kaddy` in
namespace `default` — but the real platform Gateway is `clubhouse` in namespace
`gateway` (`deploy/gateway/gateway.yaml:17-18`). On kind this never fires (no
public inbound path; issuance is intentionally not attempted). On the cloud edge
this would silently fail every HTTP-01 order. Status: **new, correctness-adjacent,
prod-path only.** Fix target: point the solver `parentRef` at the real Gateway
before the cloud edge, or switch to DNS-01.

**P3-2 · gitleaks allowlist skips `agent-context/`.**
`.github/gitleaks.toml:8-10` allowlists `references/`, `agent-context/`, and
`tests/fixtures/`. `agent-context/` is gitignored (and holds cached vendor docs),
so nothing there is committed today — but a broad path-allowlist means any secret
that *did* land there would be invisible to the scanner. Status: **known —
audit SEC-3 (clean now), accept-with-note.** The scrub-denylist (`task scrub`)
independently scans `deploy/`, `.github/`, `hack/`, `tests/` (SEC-2 fix), which
narrows the gap. Fix target: keep the allowlist as narrow as possible; re-audit
if `agent-context/` ever becomes committed.

**P3-3 · ArgoCD `--insecure` (plain HTTP behind the Gateway).**
`deploy/bootstrap/argocd.yaml:33`. **Acceptable** as configured: TLS terminates
at the Cilium Gateway and the server speaks HTTP only on the in-cluster `:80`
(avoids double-TLS). The only reason to flag it: it is one leg of the core chain
above — it is safe *because of* network isolation the cluster does not yet
enforce. Accept in lab; revisit under the default-deny baseline.

**P3-4 · Self-signed `kaddy-local-ca` is a 10-year ECDSA-P256 root
(`deploy/cluster-local/cluster-issuer.yaml:24`).**
Appropriate for a local dev root; the long duration and self-signed trust are
lab-scoped by design (curl uses `--cacert`, so no `-k`). Accept-with-note: this
CA must never be trusted outside the lab; the cloud path uses Let's Encrypt
(`deploy/cert-manager/cloud-only/`), correctly excluded from sync.

## What is genuinely sound (credit where due)

- **Let's Encrypt prod is correctly gated.** The prod ClusterIssuer only performs
  ACME **account registration** (outbound-only, benign, no rate-limited issuance)
  and the only Certificates referencing `letsencrypt-prod`/`-staging` live in the
  non-recursively-synced `deploy/cert-manager/cloud-only/` subdirectory
  (`platform-core` directory-syncs `deploy/cert-manager` with recurse OFF), so
  **no prod certificate is ever issued on kind.** Honest caveat: account
  *registration* does touch the prod ACME endpoint — but that carries no
  issuance/rate-limit risk. The staging→prod promotion gate is documented.
- **Context isolation is consistently enforced.** Every mutating path guards
  `current-context == kind-kaddy-dev` before acting: `Taskfile.yml:250,297,344`,
  `tests/smoke/lib.sh:31-32`, `hack/cluster/common.sh:100-105`, and the smoke
  libs pin `KUBECONFIG` to the isolated `.state/kubeconfig` (never the shared
  `~/.kube/config` with real GKE prod contexts). This is the single most
  important guard on this workstation and it is airtight.
- **clubhouse pod security is exemplary.** `runAsNonRoot: true`, `runAsUser: 101`,
  `seccompProfile: RuntimeDefault`, `allowPrivilegeEscalation: false`,
  `readOnlyRootFilesystem: true`, `capabilities.drop: [ALL]`, writable-`/tmp`
  emptyDir, resource requests+limits, non-privileged port 8080 on
  nginx-unprivileged (`deploy/workloads/clubhouse/deployment.yaml:44-96`). This is
  the template the observability workloads should match (P2-2).
- **No plaintext secrets committed.** The only Secret *body* in `deploy/` is
  SOPS-age encrypted (`deploy/secrets/identity/dex-github.enc.yaml`,
  `encrypted_regex: ^(data|stringData)$`); all other `kind: Secret` hits are
  `certificateRefs`/`secretName` *references*. The age private key is never
  committed (`.sops.yaml` documents `~/.config/sops/age/keys.txt`);
  `.gitignore:56` covers `.state/`, and lines 17-19 cover kubeconfigs. gitleaks
  runs in CI (`verify.yaml:28-29`), not only as bypassable pre-commit.
- **TLS-at-the-edge is coherent.** HTTPS listener terminates the local-CA
  `clubhouse-tls` Secret in the Gateway's own namespace; an HTTP→HTTPS 301
  redirect is wired (`deploy/gateway/httproute-redirect.yaml`); cert auto-renewal
  is owned by cert-manager (`renewBefore: 720h`). `allowedRoutes.from: Same`
  keeps route attachment same-namespace (no over-broad cross-namespace grant).
- **Supply-chain pinning (SEC-4) is done** for tools, charts, and the node image
  (exact versions throughout the workflows and `deploy/observability/*` Helm
  `targetRevision`s). Only Actions remain tag-pinned (P2-3).

## Prioritized hardening backlog

Ordered by "what unblocks the most" and "what must precede the gridscale edge".

1. **[P1, prod-path] Land the E1c default-deny NetworkPolicy baseline (SEC-6).**
   Default-deny per namespace + explicit allows (Gateway→app ingress,
   Prometheus→metrics, DNS egress, future Crossplane→gridscale:443). This is the
   keystone — it retroactively justifies ArgoCD `--insecure`, Grafana defaults,
   and ClusterIP backends. *Blocks nothing; unblocks the credibility of the whole
   in-cluster trust story.*
2. **[P1, prod-path] Scope ArgoCD with restricted `AppProject`s (SEC-7 angle).**
   Replace `project: default` with per-domain projects constraining `sourceRepos`,
   `destinations`, and `clusterResourceWhitelist`; reconsider root selfHeal +
   cluster-wide finalizer for the multi-source/tenant path.
3. **[P1→P2] Remove the Grafana default admin credential.**
   Source admin from a Secret/KSOPS; front Grafana (and ArgoCD) with Dex/GitHub
   OIDC (ADR-0107). Coupled to un-deferring the identity/KSOPS epic.
4. **[P2] Decide and make honest the Kyverno label-enforcement story.**
   Either wire `deploy/policies/` into the app-of-apps and install Kyverno so
   `Enforce` is real (also un-skips the Chainsaw labeling/security suites, TEST-4),
   or annotate the manifest as not-applied so no one mistakes CI-time Rego for
   in-cluster admission control.
5. **[P2] Add explicit pod-security to the observability charts.**
   Match the clubhouse template where each workload allows; enforce via the
   default-deny + (future) Kyverno baseline.
6. **[P2] Image supply-chain (SEC-8 / E1c):** Trivy CI scan-gate (fail on
   CRITICAL), digest-pin published images, cosign-verify release images.
7. **[P2/P3] SHA-pin GitHub Actions (SEC-5)** with Renovate-maintained digests.
8. **[P3, prod-path] Fix the ACME HTTP-01 solver `parentRef`** to reference the
   real `clubhouse`/`gateway` Gateway (or move to DNS-01) before the cloud edge.
9. **[P3] Cluster hygiene:** ensure smoke suites tear down the `e1e-smoke`
   namespace/gateway so no orphaned edge listener lingers.

## New vs known/roadmapped (cross-check against 2026-07-15 audit)

- **Newly precise / not previously called out this way:**
  - P2-1 (Kyverno `Enforce` is inert — orphaned from app-of-apps AND not
    installed; only CI-time Rego actually denies).
  - P1-2's specific mechanism (unrestricted `default` project + selfHeal +
    cluster-wide finalizer = concrete blast-radius composition).
  - P1-3 (live Grafana default admin credential).
  - P3-1 (ACME solver `parentRef` points at a non-existent Gateway — latent
    prod-path break).
- **Known / roadmapped — accepted-with-target (NOT new P1s):**
  - P1-1 NetworkPolicy = **SEC-6 / E1c** · P2-4 Trivy/cosign = **SEC-8 / E1c** ·
    the RBAC/OIDC parts of P1-2/P1-3 = **SEC-7 / E1d**. Per
    `openspec/changes/audit-remediation-2026-07/proposal.md:98-100` these are
    unbuilt future epics, not regressions.
- **Known / accept-with-note (unchanged):**
  - P2-3/P2-4 SHA-pinning = **SEC-5** (Renovate-mitigated) · P3-2 gitleaks
    allowlist = **SEC-3** (clean now) · SEC-4 tool/image pinning is **done**
    (verified this pass).

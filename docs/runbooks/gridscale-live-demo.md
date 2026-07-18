# Runbook — gridscale live demo (E8b)

Bring the kaddy platform up **on the phase-2 gridscale substrate** for a live
demo (e.g. an interview walkthrough), show the read-only demo surfaces, then
**tear it all down**. This composes directly on top of the E1g gridscale day-0
runbook ([gridscale-day0.md](gridscale-day0.md)) — read that first; this runbook
only adds the demo layer and the demo choreography.

## Framing — on-demand by default (DECIDED-B, reconciled by D-042)

The E8b story was originally phrased as "keep the gridscale stack running through
the interview window". That contradicts the project's ruthless-teardown cost
rule (the gridscale GSK cluster + LBaaS cost real money every hour they are up).

**Reconciled, operator-approved definition:** E8b is a **reproducible on-demand
bring-up**, proven ephemerally. The "interview window" is an
**operator-triggered** `task e8b:up` … demo … `task e8b:down` cycle, run just
before the demo and torn down immediately after — it is **not always-on** infra.
If you need it live for a 30-minute interview, bring it up 10 minutes before and
tear it down the moment you are done.

### Go-live standing carve-out (D-042, supersedes the dev-phase absolute)

The dev-phase DECIDED-B rule treated a standing environment as forbidden — an
overspend guard for the build phase, now superseded for go-live (see below).
The project has now entered **go-live**,
where a standing live substrate is intentional (planned ~1–2 weeks, decision
**D-042**). Under go-live a standing substrate is permitted, but **only when it
is recorded and time-boxed**:

- **recorded** — what is up, since-when, a teardown-by date, and an owner are
  captured (`evidence/live/e1g-gsk-2026-07-18.md`); and
- **time-boxed** — an explicit teardown deadline, surfaced by **E1g-S07**
  (`task e1g:status`, a soft WARN once the default ~14-day window is exceeded).

This carve-out is cost-governance, not a licence for "always-on": it does **not**
declare standing infra always fine, and it does **not** weaken the ephemeral
`e8b:up`/`e8b:down` demo cycle or the per-story create→verify→destroy live-proof
discipline, both of which stay ephemeral-by-default.

## TL;DR

```bash
# OFFLINE (safe, no creds, no cost) — validates targets, runbook, manifests.
task test:smoke:e8b

# LIVE (COSTS MONEY) — only around an actual demo. Bring up, demo, tear DOWN.
task e8b:up      # compose E1g substrate + re-sync GitOps app-of-apps + wait healthy
# … run the demo (see "Demo" below) …
task e8b:down    # RUTHLESS teardown — delegates to e1g:down. Run after EVERY demo.
```

## What E8b adds on top of E1g

E1g gives you the gridscale substrate (object-storage state anchor → network →
GSK cluster → LBaaS) and the ruthless `e1g:up` / `e1g:down` discipline. E8b adds:

1. **On-demand bring-up** (`task e8b:up`): runs `e1g:up` for the substrate, then
   re-syncs the phase-1 GitOps app-of-apps onto the GSK cluster (the E1g-S05
   substrate swap — same ArgoCD bootstrap the local kind cluster uses) and waits
   for it to go healthy.
2. **Read-only demo surfaces** (E8b-S02, GitOps): a static **scorecard** evidence
   site and an **anonymous-viewer Grafana**, exposed **read-only** behind the
   platform Gateway with phase-2 Let's Encrypt TLS. These are GitOps-managed by
   the `e8b-demo` Argo CD Application (`deploy/monitoring/e8b-demo/`) so they
   appear automatically once the app-of-apps syncs.

## Bring-up → verify → demo → teardown checklist

### 1. Bring-up

```bash
task e8b:up
```

This runs `task e1g:up` (bootstraps the object-storage anchor and echoes the
network/k8s/lbaas provisioning sequence). Provision network → k8s → lbaas and
thread the outputs per [gridscale-day0.md](gridscale-day0.md) (backend-config +
kubeconfig handoff), then `export KUBECONFIG=<GSK kubeconfig>` and let `e8b:up`
continue: it re-runs the ArgoCD bootstrap (`task bootstrap:argocd`) and the
app-of-apps (`task bootstrap:e3`) against the GSK cluster and waits for the
argocd-server rollout.

> **Bootstrap context opt-in (E1g-S05a).** Every `bootstrap:*` task refuses to
> run against any context other than `kind-kaddy-dev` by default — the local
> prod-nuke guard (`hack/lib/guard-context.sh`). To bootstrap onto GSK, first
> select the GSK context, then export its name so the guard opts in to exactly
> that one context (it is never a blanket disable — the active context must match
> the named value, and unset behaviour is the byte-for-byte kind-only default):
>
> ```bash
> export KUBECONFIG=<GSK kubeconfig>                       # from the k8s stack output
> kubectl config use-context kaddy-gsk-admin@kaddy-gsk     # the GSK context
> export KADDY_GSK_CONTEXT=$(kubectl config current-context)
> task bootstrap:argocd && task bootstrap:e3               # now proceed against GSK
> ```
>
> Offline-provable: `bash tests/smoke/bootstrap-guard.sh` (part of
> `task test:smoke:e1g`) asserts all four guard branches with a mocked kubectl.

### 2. Verify

```bash
# The demo App and its surfaces are Synced/Healthy and serving read-only.
# The serve check targets GSK, NOT kind — name the GSK context so the smoke
# lib's prod-context guard opts in to it (without it, the guard hard-pins
# kind-kaddy-dev and the check fails against GSK):
export KUBECONFIG=<GSK kubeconfig>            # from the k8s stack output
export E8B_GSK_CONTEXT=$(kubectl config current-context)   # the GSK context name
E8B_LIVE=1 task test:smoke:e8b
```

`tests/smoke/e8b-serve.sh` (invoked when `E8B_LIVE=1`) asserts the `e8b-demo`
Application is Synced/Healthy, both Deployments are Available, the scorecard site
serves, Grafana answers anonymously **and rejects an anonymous write** (proving
the Viewer role is genuinely read-only). It requires `E8B_GSK_CONTEXT` to be the
active context (explicit opt-in past the kind-only safety guard).

> **Verify-at-live (not offline-checkable):** Grafana runs with
> `readOnlyRootFilesystem: true` and only `/var/lib/grafana` writable — if it
> errors on a plugin/log path at boot, add the needed `emptyDir` mount. And
> `GF_SERVER_DOMAIN`/`root_url` are not set, so any absolute redirect defaults to
> `localhost`; set `GF_SERVER_DOMAIN` to the public LBaaS domain if a redirect
> misbehaves. Both are cluster-runtime concerns the offline gate can't catch.

### 3. Demo

Walk the reviewer through the read-only surfaces behind the platform Gateway
(phase-2 LBaaS public IP + Let's Encrypt TLS):

- **`/scorecard`** — the static evidence landing page (links to the published
  GitHub Pages scorecard and to Grafana).
- **`/grafana/`** — Grafana as an **anonymous Viewer**: browse dashboards and
  the in-cluster Prometheus datasource; no login, no editing, no sign-up.

Optionally run the E8-S04 demo choreography (`task demo`, `task demo:fire`,
`task demo:chaos`) against the GSK cluster.

### 4. Teardown (do NOT skip)

```bash
task e8b:down
```

This delegates to **`task e1g:down`** — the ruthless reverse-order destroy
(lbaas → k8s → network → object-storage). The demo surfaces are GitOps-managed on
the ephemeral GSK cluster, so destroying the substrate reclaims everything. Then
**confirm in the gridscale panel that nothing lingers** (a leftover LBaaS or node
pool keeps billing).

## Cost note

The demo runs on the same GSK node pool + LBaaS + public IPs as E1g (see the cost
table in [gridscale-day0.md](gridscale-day0.md) — the GSK node pool dominates).
Because the E8b demo is **on-demand and ephemeral-by-default**, its cost is bounded
to the minutes the demo actually runs. **Always `task e8b:down` immediately after
the demo.** Never leave the demo up "just in case" — bring it up again on demand
next time. (A deliberately *standing* go-live substrate is a separate, recorded and
time-boxed carve-out — see the go-live carve-out above and D-042.)

## Read-only posture (why the demo is safe to expose)

- **Grafana** runs with `GF_AUTH_ANONYMOUS_ORG_ROLE=Viewer`, the login form and
  basic auth disabled, sign-up disabled, and no admin identity provisioned — a
  reviewer can look but cannot mutate. Container is `runAsNonRoot` with a
  read-only root filesystem and all capabilities dropped.
- **Scorecard** is a static nginx-unprivileged site (`readOnlyRootFilesystem`,
  `runAsNonRoot`, caps dropped) serving committed HTML — no mutating endpoint.
- Cross-namespace routing (HTTPRoute in `gateway` → Services in `monitoring`) is
  authorised by a narrowly-scoped `ReferenceGrant` (HTTPRoute→Service only).

## Phase-2 edge TLS (Let's Encrypt, cloud-only)

`deploy/monitoring/e8b-demo/cloud-only/certificate-cloud-only.yaml` holds the
Let's Encrypt Certificates for the demo host (staging → prod). They are
**cloud-only** and **excluded from GitOps sync by location** (the `e8b-demo` App
syncs with `recurse: false`, so the `cloud-only/` subdir is never applied) — the
same pattern as `deploy/cert-manager/cloud-only/`. On the cloud edge, point the
platform Gateway's `certificateRefs` Secret at `e8b-demo-tls-le-staging` first
(untrusted chain — expected), then flip to `e8b-demo-tls-le-prod`.

## References

- [gridscale-day0.md](gridscale-day0.md) — the E1g substrate this composes on.
- `deploy/monitoring/e8b-demo/` — the read-only demo surfaces (GitOps).
- `deploy/apps/e8b-demo.yaml` + `deploy/apps/projects/e8b-demo.yaml` — the child
  Application and its dedicated closed-list AppProject (destinations = monitoring
  - gateway).
- OpenSpec: `openspec/changes/e8b-live-demo/`

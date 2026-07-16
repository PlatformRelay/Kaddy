# Spec — E-Caddy-MVP · S02 Variant B — Kubernetes tenant (RICH, preferred/primary)

Epic: `e-caddy-mvp` · **Story:** S02 · **Refs:** proposal "Variant B — Kubernetes-based (RICH)";
ADR-0104/D-019 (edge = Cilium Gateway); ADR-0103 (GitOps); ADR-0201/E7 (Rollouts); ADR-0301
(labels); ADR-0106/E1c (security baseline); D-030 (showcase content + nginx→Caddy topology)

> **UNBLOCKED — implement next.** Phase-1 preconditions E1 / E3 / E4 / E7 are green on `main`.
>
> **Shape (as decided in `proposal.md` — not redesigned here):** the rich tenant is a **dedicated
> manifest set** (`Deployment`/`Rollout` + Service + HTTPRoute + Certificate + monitors) under
> `deploy/workloads/caddy-mvp/`, namespace `caddy-mvp`, synced by the existing `workloads`
> Application (its docstring names the Caddy/nginx MVP as its intended tenant home, and it already
> carries the Rollouts `ignoreDifferences` pattern). It is **not** composed through the E6
> `Website` XR: the XR composes a plain Deployment (no Rollout, single engine), so it cannot
> express progressive delivery nor the two-engine showcase topology. The XR path stays proven by
> E6's `putting-green` demo claim and by the S05 BYO stretch (REQ-CADDY-S05-05).
>
> The tenant workloads are the S05 showcase pair: **`caddy-origin`** (static origin serving the
> baked `ghcr.io/platformrelay/kaddy-showcase` image, REQ-CADDY-S05-02) fronted by
> **`nginx-proxy`** (REQ-CADDY-S05-03). S02 owns the platform mechanics (GitOps wiring, TLS,
> rollouts, scrape, netpol); S05 owns content + topology semantics.

---

## REQ-CADDY-S02-01: tenant reached through the edge with cert-manager TLS

**Priority:** must · **Level:** L2 · **Refs:** preferred/primary path, E4 pattern, kaddy-local-ca
**Given** the tenant Gateway listener (host `caddy-mvp.kaddy.local`, mulligan pattern) whose TLS
secret is issued by a cert-manager `Certificate` in ns `caddy-mvp` referencing the platform
`ClusterIssuer` **`kaddy-local-ca`**, and an HTTPRoute attaching the tenant Service(s) to it
**When** the manifests sync and a client requests `https://caddy-mvp.kaddy.local/` through the edge
**Then** the `Certificate` is Ready, the HTTPRoute is Accepted, and the site returns HTTP-200 over
HTTPS **through** the Cilium Gateway (macOS guard: HTTP smoke via kind `extraPortMappings` /
in-cluster probe pod, never host-routed LB IPs — D-025)
**Test:** `tests/chainsaw/caddy-mvp/k8s-tls/chainsaw-test.yaml`
**Verify:**

```bash
kubectl get certificate -n caddy-mvp -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' | grep -q True
```

---

## REQ-CADDY-S02-02: blue/green + canary via Argo Rollouts, analysis-gated (k8s-only)

**Priority:** must · **Level:** L2 · **Refs:** E7 mulligan (proven live), ADR-0201
**Given** `caddy-origin` as an Argo **Rollout** with `canary` strategy — `trafficRouting.plugins`
key **`argoproj-labs/gatewayAPI`** shifting the tenant HTTPRoute `backendRefs[].weight` between
`caddy-origin-stable`/`caddy-origin-canary` Services (steps 20% → 50%, E7 pattern) — and
`nginx-proxy` as a Rollout with `blueGreen` strategy (`activeService`/`previewService`, mulligan-bg
pattern); an `AnalysisTemplate` querying the live Prometheus for the canary's Caddy SLI (5xx share
of `caddy_http_request_duration_seconds_count{code=~"5..",track="canary"}` — Caddy's
status-code-labelled series; `caddy_http_requests_total` carries no `code` label, and `track`
reaches Prometheus only via the monitor's `podTargetLabels` projection) gates promotion; the `workloads` Application gains
an `ignoreDifferences` entry (jqPathExpressions on `.spec.rules[].backendRefs[].weight`) for the
tenant HTTPRoute so Argo CD does not fight the controller
**When** a new revision rolls out and the analysis evaluates
**Then** promotion proceeds on healthy analysis, and a failing analysis **aborts** the rollout —
weights return to 100/0 stable and the canary ReplicaSet scales down (the mulligan). Demoed
**only** on this variant, never on the VM variant
**Test:** `tests/chainsaw/caddy-mvp/k8s-rollout/chainsaw-test.yaml`
**Verify:**

```bash
kubectl argo rollouts status caddy-origin -n caddy-mvp --timeout 120s | grep -q 'Healthy'
```

---

## REQ-CADDY-S02-03: native in-cluster scrape of the tenant pod

**Priority:** must · **Level:** L3 · **Refs:** DIR-2, D-026 re-home path (REQ-CADDY-S05-04)
**Given** the Caddy origin pod with the Caddy `metrics` endpoint enabled and the parked PodMonitor
(`deploy/caddy-mvp/monitoring/prometheus/caddy-podmonitor.yaml`, pins `job="caddy"`) re-pointed at
namespace `caddy-mvp` and GitOps-synced (its current `namespaceSelector: gateway` is the parked
pre-ADR-0104 wiring)
**When** Prometheus service discovery refreshes
**Then** `up{job="caddy", namespace="caddy-mvp"} == 1` and `caddy_http_requests_total` series are
present — giving the parked `caddy_*` marshal rules (D-026) their real in-cluster target
**Test:** `tests/smoke/caddy-mvp-s02-03.sh`
**Verify:**

```bash
# via port-forwarded Prometheus (tests/smoke/e5-lib.sh helpers)
curl -s 'http://127.0.0.1:9090/api/v1/query?query=up{job="caddy",namespace="caddy-mvp"}' | jq -e '.data.result[0].value[1]=="1"'
```

---

## REQ-CADDY-S02-04: GitOps wiring + platform guardrails

**Priority:** must · **Level:** L2 · **Refs:** ADR-0103, ADR-0301, E1c (cosign/Kyverno), E1b
**Given** the tenant manifests committed under `deploy/workloads/caddy-mvp/` (namespace,
Rollouts, Services, HTTPRoute, Certificate, AnalysisTemplate) — synced by the existing `workloads`
Application (recurse:true), **no** new Application and **no** imperative kubectl
**When** Argo CD reconciles one sync loop
**Then** all tenant resources are Synced/Healthy; every resource carries the mandatory ADR-0301
labels (`owner`, `service`, `part-of`, `managed-by`, `data-classification`,
`business-criticality`, `track`) so Kyverno admission passes; pods satisfy the hardening baseline
(runAsNonRoot, readOnlyRootFilesystem, drop ALL, seccomp RuntimeDefault); the image is the
digest-pinned, cosign-signed `ghcr.io/platformrelay/kaddy-showcase` (E1c verifyImages passes)
**Test:** `tests/chainsaw/caddy-mvp/k8s-tenant/chainsaw-test.yaml`
**Verify:**

```bash
kubectl -n argocd get application workloads -o jsonpath='{.status.sync.status}/{.status.health.status}' | grep -q 'Synced/Healthy'
```

---

## REQ-CADDY-S02-05: default-deny NetworkPolicy baseline for the tenant namespace

**Priority:** must · **Level:** L2 · **Refs:** ADR-0106 ("a workload with no NetworkPolicy is a finding"), E6 websites.yaml pattern
**Given** `deploy/policies/network/caddy-mvp.yaml` — default-deny for ns `caddy-mvp` plus the
minimum allows: Cilium Gateway (reserved `ingress` identity) → `nginx-proxy`; `nginx-proxy` →
`caddy-origin`; Prometheus (ns `monitoring`) → metrics ports; DNS egress to CoreDNS :53; probe-pod
hairpin legs mirroring the `websites` baseline
**When** the policies sync and a pod in an unrelated namespace attempts to reach the tenant
**Then** the unrelated connection is denied while the edge path, the proxy→origin hop and the
scrape keep working (allow + deny both asserted — not just "policy object exists")
**Test:** `tests/chainsaw/caddy-mvp/k8s-netpol/chainsaw-test.yaml`
**Verify:**

```bash
kubectl get networkpolicy -n caddy-mvp -o name | grep -q default-deny
```

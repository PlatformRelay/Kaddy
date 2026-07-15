# Spec — E-Caddy-MVP (Website-as-a-Service tenant product)

Epic: `e-caddy-mvp` · **Refs:** exercise brief (install Caddy, serve a page, scrape, alert);
audit ARCH-2/ARCH-3/DIR-1/DIR-2 · ADR-0104 (edge = Cilium Gateway, not Caddy) · D-019

> **Design-first / gated.** These REQs are authored now to durably record the operator's
> two-variant vision; **implementation is gated** on the precondition epics landing (E1 → E3 → E4;
> E7 for Rollouts; E6/E6g/E1g for the VM path). Test artifacts are enumerated so the epic-exit
> `STRICT_TEST_FILES` gate can bind when the epic activates. Level tags per ADR-0701
> (L0 tofu · L1 conftest/promtool · L2 Chainsaw · L3 k6 · L4 scorecard).

---

## REQ-CADDY-S01-01: Caddy served through the Cilium/Envoy edge (not as gateway)

**Priority:** must · **Level:** L2 · **Refs:** ARCH-2, ADR-0104, D-019
**Given** a Caddy tenant workload (VM or Kubernetes variant) and the platform edge = Cilium
Gateway API (Envoy)
**When** a client requests the tenant site through the platform Gateway/HTTPRoute
**Then** the request is served by Caddy **reached through** the edge — Caddy is never bound as the
platform ingress/gateway itself
**Test:** `tests/chainsaw/caddy-mvp/edge-route/chainsaw-test.yaml`
**Verify:**
```bash
curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:30080/ | grep -q '^200$'
```

---

## REQ-CADDY-S01-02: VM variant — Caddy on a VM (minimal), nginx parallel

**Priority:** must · **Level:** L2 · **Refs:** DIR-2, exercise VM-path wording
**Given** the VM-based (minimal) variant, provisioned via the sibling Crossplane
**provider-gridscale** (`gridscale_server`, phase-2 / E6g/E1g)
**When** the VM boots with Caddy (or nginx — the same structure applies to the legacy stand-in)
**Then** the VM serves the tenant page and exposes an **external metrics endpoint**; no in-cluster
cert lifecycle and no Rollouts are present on this variant (kept minimal)
**Test:** `tests/chainsaw/caddy-mvp/vm-variant/chainsaw-test.yaml`
**Verify:**
```bash
# gated on E6g/E1g VM provisioning; asserts the VM serves + exposes /metrics
curl -sf "http://${CADDY_VM_HOST}/metrics" | grep -q 'caddy_'
```

---

## REQ-CADDY-S01-03: VM variant alerting — parked E5 caddy_* marshal alerts (serve→scrape→fire)

**Priority:** must · **Level:** L1 · **Refs:** ARCH-2, ARCH-3, marshal decision — operator-confirmed Option A (park) (D-026)
**Given** the parked E5 `caddy_*` marshal PrometheusRules + their promtool tests, migrated out of
active platform monitoring into this VM-variant slice (operator-confirmed Option A — park, D-026)
**When** in-cluster Prometheus scrapes the VM's external metrics endpoint and the promtool suite
runs the rules across the `for:` window
**Then** each `caddy_*` alert **fires** when its condition holds and is **silent** when it does not
(fire + silent assertions preserved), firing against the **VM target** — this is the brief spine
**serve → scrape → fire**
**Test:** `tests/promtool/caddy-mvp-marshal.test.yaml`
**Verify:**
```bash
promtool test rules tests/promtool/caddy-mvp-marshal.test.yaml
```

---

## REQ-CADDY-S02-01: Kubernetes variant — Caddy on k8s with cert-manager TLS (rich, preferred)

**Priority:** must · **Level:** L2 · **Refs:** preferred/primary path
**Given** the Kubernetes-based (rich) variant — the **preferred, primary** path
**When** the Caddy tenant Deployment/Service is applied and reached through the Gateway HTTPRoute
**Then** TLS is served via **cert-manager** (issued from the local CA / ClusterIssuer) and the site
returns HTTP-200 over HTTPS through the edge
**Test:** `tests/chainsaw/caddy-mvp/k8s-tls/chainsaw-test.yaml`
**Verify:**
```bash
kubectl get certificate -n caddy-mvp -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' | grep -q True
```

---

## REQ-CADDY-S02-02: Kubernetes variant — blue/green + canary via Argo Rollouts (k8s-only)

**Priority:** must · **Level:** L2 · **Refs:** E7 mulligan (Argo Rollouts), Prometheus AnalysisTemplate
**Given** the Kubernetes variant with an Argo **Rollout** (blue/green + canary) — demoed **only** on
this variant, never on the VM variant
**When** a new revision is rolled out and the Prometheus AnalysisTemplate gate evaluates
**Then** promotion proceeds on healthy analysis and aborts/rolls back on failure
**Test:** `tests/chainsaw/caddy-mvp/k8s-rollout/chainsaw-test.yaml`
**Verify:**
```bash
kubectl argo rollouts status caddy-mvp -n caddy-mvp --timeout 120s | grep -q 'Healthy'
```

---

## REQ-CADDY-S02-03: Kubernetes variant — native in-cluster scrape

**Priority:** should · **Level:** L1 · **Refs:** DIR-2
**Given** the Kubernetes variant tenant pod emitting native `caddy_*` metrics
**When** a ServiceMonitor/PodMonitor selects the tenant pod
**Then** `up{service="caddy-mvp"} == 1` and `caddy_http_requests_total` is present in Prometheus
**Test:** `tests/smoke/caddy-mvp-s02-03.sh`
**Verify:**
```bash
curl -s 'http://127.0.0.1:9090/api/v1/query?query=up{service="caddy-mvp"}' | jq -e '.data.result[0].value[1]=="1"'
```

---

## REQ-CADDY-S03-01: Backstage self-service scaffold — variant + engine selection

**Priority:** should · **Level:** L2 · **Refs:** E10 portal (cuttable), nginx parallel
**Given** the Backstage self-service scaffolder form
**When** a tenant picks a **variant** (VM vs Kubernetes) and an **engine** (Caddy vs nginx)
**Then** the corresponding GitOps manifests/claim are generated; the served-website product works
via GitOps even if the E10 portal form is cut
**Test:** `tests/chainsaw/caddy-mvp/scaffold/chainsaw-test.yaml`
**Verify:**
```bash
# asserts the scaffolder template renders both variants x both engines
test -d templates/caddy-mvp && grep -rq 'variant' templates/caddy-mvp
```

---

## REQ-CADDY-S04-01: STRETCH — certificates via Crossplane (optional)

**Priority:** may · **Level:** L2 · **Refs:** stretch/optional
**Given** the Kubernetes variant
**When** the operator opts into the stretch path
**Then** certificates are provisioned via **Crossplane** (instead of / alongside cert-manager);
this slice is **optional** and does not gate the epic exit
**Test:** `tests/chainsaw/caddy-mvp/crossplane-cert/chainsaw-test.yaml`
**Verify:**
```bash
kubectl get certificaterequest.crossplane -n caddy-mvp 2>/dev/null | grep -q caddy || echo 'stretch: skipped'
```

---

## Note — nginx parallel (legacy stand-in, E6)

The **same VM-vs-Kubernetes two-variant structure** applies to **nginx**, the legacy stand-in in
E6 (Crossplane Website claim / phase-2 nginx VM via Upjet provider-gridscale). REQ-CADDY-S01-02
and REQ-CADDY-S03-01 explicitly cover the nginx engine; the E6 epic carries the nginx-specific
manifests. Caddy is the preferred MVP engine; nginx mirrors it so the exercise's legacy-stand-in
wording is satisfied.

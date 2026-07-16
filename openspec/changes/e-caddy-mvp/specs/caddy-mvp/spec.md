# Spec — E-Caddy-MVP (Website-as-a-Service tenant product)

Epic: `e-caddy-mvp` · **Refs:** exercise brief (install Caddy, serve a page, scrape, alert);
audit ARCH-2/ARCH-3/DIR-1/DIR-2 · ADR-0104 (edge = Cilium Gateway, not Caddy) · D-019 · D-026

> **S00 (2026-07-16): full spec surface authored.** This file is the epic umbrella — it carries the
> cross-cutting edge invariant, the **Variant A (VM)** slice (**BLOCKED** on E6g/E1g, see banner
> below), the S04 stretch and the epic EXIT. The per-story contracts live in sibling specs:
>
> | Story | Spec file | Status |
> | --- | --- | --- |
> | S01 — Variant A · VM (minimal + alerting) | this file (below) | **BLOCKED** on E6g / E1g (phase 2) |
> | S02 — Variant B · Kubernetes tenant (rich) | [`../k8s-tenant/spec.md`](../k8s-tenant/spec.md) | **UNBLOCKED** (E1/E3/E4/E7 green) — implement next |
> | S03 — Backstage self-service scaffold | [`../scaffold/spec.md`](../scaffold/spec.md) | surface = E10 (cuttable); GitOps path portal-free |
> | S05 — Showcase content (deck + docs) | [`../showcase/spec.md`](../showcase/spec.md) | partially landed (image + CI signing) |
> | S04 — stretch (Crossplane certs) | this file (below) | optional, does not gate exit |
>
> Level tags per ADR-0701 (L0 tofu · L1 conftest/promtool · L2 Chainsaw · L3 k6 · L4 scorecard).
> Test paths that do not exist yet follow the repo convention for unimplemented epics (E10/E13
> style): referenced by future path; `STRICT_TEST_FILES=1` stays advisory in CI and turns blocking
> only at epic EXIT.

---

## REQ-CADDY-S01-01: Caddy served through the Cilium/Envoy edge (not as gateway)

**Priority:** must · **Level:** L2 · **Refs:** ARCH-2, ADR-0104, D-019
**Given** a Caddy tenant workload (VM or Kubernetes variant) and the platform edge = Cilium
Gateway API (Envoy)
**When** a client requests the tenant site through the platform Gateway/HTTPRoute
**Then** the request is served by Caddy **reached through** the edge — Caddy is never bound as the
platform ingress/gateway itself. This invariant is **cross-cutting**: it binds both variants and
the S05 showcase topology (`Gateway → nginx-proxy → caddy-origin`); no manifest in this epic may
attach Caddy as a Gateway/GatewayClass implementation
**Test:** `tests/chainsaw/caddy-mvp/edge-route/chainsaw-test.yaml`
**Verify:**

```bash
curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:30080/ | grep -q '^200$'
```

> The Chainsaw suite exists today as a `skip: true` stub (house convention); the S02 lane flips
> `skip` off and asserts the tenant HTTPRoute path when the Kubernetes tenant lands.

---

## S01 — Variant A · VM-based (MINIMAL) — serve → scrape → fire

> **BLOCKED — do not implement.** Variant A is gated on phase-2 **E6g** (Upjet provider-gridscale
> `gridscale_server`) and **E1g** (gridscale day-0 / credentials). These REQs are authored now so
> the contract is stable and the parked D-026 artifacts stay owned, but **no VM provisioning, no
> scrape wiring and no live gate may start** until E6g/E1g land. The epic EXIT (below) is
> satisfiable by Variant B alone, so this blockage does not gate the epic.

---

## REQ-CADDY-S01-02: VM variant — Caddy on a VM (minimal), nginx parallel

**Priority:** must · **Level:** L2 · **Refs:** DIR-2, exercise VM-path wording · **Blocked:** E6g/E1g
**Given** the VM-based (minimal) variant: a `gridscale_server` provisioned via the sibling
Crossplane **provider-gridscale** (Upjet, E6g) with cloud-init installing the engine — Caddy with
its `metrics` endpoint enabled (or nginx + exporter: the same structure applies to the legacy
stand-in engine)
**When** the VM boots
**Then** the VM serves the tenant page on HTTP and exposes an **external metrics endpoint**
reachable by in-cluster Prometheus; deliberately minimal — **no** in-cluster cert lifecycle, **no**
Rollouts on this variant
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
active platform monitoring into this epic (operator-confirmed Option A — park, D-026); the parked
artifacts live at `deploy/caddy-mvp/monitoring/` (`rules/marshal-caddy.yaml` CR +
`rules/marshal-caddy.rules.yaml` standalone projection) with the suite at
`tests/promtool/caddy-mvp-marshal.test.yaml`
**When** in-cluster Prometheus scrapes the VM's external metrics endpoint (`job="caddy"`) and the
promtool suite runs the rules across the `for:` window
**Then** each `caddy_*` alert **fires** when its condition holds and is **silent** when it does not
(fire + silent assertions preserved), firing against the **VM target** — this is the brief spine
**serve → scrape → fire**. (The K8s path re-homes the same rules against the showcase Caddy origin
— REQ-CADDY-S05-04; both close D-026 with a real target.)
**Test:** `tests/promtool/caddy-mvp-marshal.test.yaml`
**Verify:**

```bash
promtool test rules tests/promtool/caddy-mvp-marshal.test.yaml
```

---

## REQ-CADDY-S01-04: VM variant — in-cluster Prometheus scrapes the VM's external endpoint

**Priority:** must · **Level:** L3 · **Refs:** DIR-2, D-026 · **Blocked:** E6g/E1g
**Given** a `ScrapeConfig` (prometheus-operator CR, GitOps-managed under
`deploy/caddy-mvp/monitoring/prometheus/`) whose static target is the VM's external metrics
endpoint, relabeled to `job="caddy"` so the parked rules (REQ-CADDY-S01-03) match without edits
**When** Prometheus service discovery refreshes
**Then** `up{job="caddy"} == 1` for the VM target, and stopping the VM (or its Caddy unit) flips
the target down so `CaddyTargetDown` fires — the live half of serve → scrape → fire
**Test:** `tests/smoke/caddy-mvp-s01-04.sh`
**Verify:**

```bash
# via port-forwarded Prometheus (tests/smoke/e5-lib.sh helpers)
curl -s 'http://127.0.0.1:9090/api/v1/query?query=up{job="caddy"}' | jq -e '.data.result[0].value[1]=="1"'
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

## REQ-CADDY-EXIT: brief spine demonstrable end-to-end (serve → scrape → fire)

**Priority:** must · **Level:** L4 · **Refs:** audit DIR-1, DIR-2, ARCH-2, ARCH-3
**Given** at least one landed variant (Variant B suffices while Variant A is blocked on E6g/E1g)
**When** the exit smoke runs: the tenant page is fetched through the platform edge, Prometheus is
queried for the tenant's `caddy_*` series, and the Caddy target is killed (pod delete / scale to 0)
**Then** the page serves 200 through the edge, `up{job="caddy"} == 1` beforehand, and
`CaddyTargetDown` reaches Alertmanager within its `for:` window + 2m — closing audit DIR-1, DIR-2,
ARCH-2 and ARCH-3
**Test:** `tests/smoke/caddy-mvp-exit.sh`
**Verify:**

```bash
bash tests/smoke/caddy-mvp-exit.sh
```

---

## Note — nginx parallel (legacy stand-in, E6)

The **same VM-vs-Kubernetes two-variant structure** applies to **nginx**, the legacy stand-in in
E6 (Crossplane Website claim / phase-2 nginx VM via Upjet provider-gridscale). REQ-CADDY-S01-02
and REQ-CADDY-S03-01 explicitly cover the nginx engine; the E6 epic carries the nginx-specific
manifests. Caddy is the preferred MVP engine; nginx mirrors it so the exercise's legacy-stand-in
wording is satisfied. On the Kubernetes path the nginx engine additionally appears as the
**reverse proxy** in the S05 showcase topology (REQ-CADDY-S05-03) — a designed two-engine
comparison, not an afterthought.

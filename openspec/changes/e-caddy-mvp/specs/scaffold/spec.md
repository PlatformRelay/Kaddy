# Spec — E-Caddy-MVP · S03 Backstage self-service scaffold

Epic: `e-caddy-mvp` · **Story:** S03 · **Refs:** E10 portal (cuttable ✂️), D-028 (templates
AUTO-GENERATED from the XRD via kubernetes-ingestor, never hand-written), D-027 (`Website` = v2
namespaced XR), ADR-0109/0111

> The **surface** is E10's; this story only pins what the served-website product needs from it and
> proves the epic survives E10 being cut. Per D-028 there is **no hand-written template
> directory**: the scaffolder form is a projection of the `Website` XRD's OpenAPI schema
> (kubernetes-ingestor), and its `publishPhase` opens a **git PR** — the portal authors git, never
> mutates the cluster. The **VM variant option is gated on E6g/E1g**: until the phase-2 VM XRD
> exists there is nothing to project, so the form legitimately offers the Kubernetes variant only
> (offering an unbacked VM choice would be a lie in the UI).

---

## REQ-CADDY-S03-01: self-service form offers engine (Caddy/nginx) — auto-generated, PR-publishing

**Priority:** should · **Level:** L2 · **Refs:** D-028, D-027, E10 S02 (ingestor), nginx parallel
**Given** the E10 Backstage portal with kubernetes-ingestor projecting the `Website` XRD
(`websites.platform.kaddy.io`, v2 namespaced) into a scaffolder template
**When** a tenant fills the form picking an **engine** (Caddy or nginx, via the XRD's image/engine
field) — and, once the E6g/E1g VM XRD exists, a **variant** (Kubernetes / VM)
**Then** the scaffolder output is a **git PR** containing only a declarative `Website` XR YAML (no
cluster credentials in the write path); merging it lets GitOps reconcile the site with either
engine through the same edge path
**Test:** `tests/chainsaw/caddy-mvp/scaffold/chainsaw-test.yaml`
**Verify:**

```bash
# the form is a projection of the XRD — no hand-written template may exist (D-028)
kubectl get xrd websites.platform.kaddy.io -o jsonpath='{.status.conditions[?(@.type=="Established")].status}' | grep -q True && \
  ! test -d templates/caddy-mvp
```

---

## REQ-CADDY-S03-02: GitOps path works portal-free (E10 stays cuttable)

**Priority:** must · **Level:** L2 · **Refs:** proposal "works via GitOps even if E10 is cut", ADR-0103
**Given** a tenant defined **only** by YAML committed to git (the S02 manifest set under
`deploy/workloads/caddy-mvp/`, or a one-file `Website` XR) — no Backstage runtime present or
required
**When** Argo CD reconciles one sync loop
**Then** the served-website product is fully materialized and healthy from git alone — proving the
Backstage form is a convenience surface, not a dependency, so cutting E10 cannot strand this epic
**Test:** `tests/smoke/caddy-mvp-s03-02.sh`
**Verify:**

```bash
kubectl -n argocd get application workloads -o jsonpath='{.status.health.status}' | grep -q Healthy
```

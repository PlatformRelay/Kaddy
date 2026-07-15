# Change: E-Caddy-MVP — Website-as-a-Service tenant product (Caddy, nginx parallel)

> **Epic ID minted:** `e-caddy-mvp` (new slug). Supersedes the framing of the optional
> `e9-caddy-operator` and the cuttable `e10-portal-stretch` for the *served-website* concern —
> see "Relationship to E9 / E10" below. This is a **stub/design-first** change opened by the
> `audit-remediation-2026-07` planning lane to give the platform MVP a home; implementation is
> gated on the phase-1 precondition epics landing.

## Why

The exercise's named subject is *"install Caddy and serve a page, scrape it, fire one alert."*
The operator's direction (audit ARCH-2/ARCH-3) reframes this precisely:

- **Caddy is the platform MVP** — a **Website-as-a-Service (WaaS) tenant product**, reached
  **through** the platform edge (Cilium Gateway API / Envoy), **not** the edge itself
  (ADR-0104, D-019: *"we won't use caddy as a gateway"*).
- *"caddy will be the MVP of our platform, but for now we are building the preconditions to
  show it off"* — so the current phase is the **precondition epics**, and this epic is the
  demo that sits on top of them once they land.

Today that spine is empty: no Prometheus + web server is deployed (DIR-2), and the landed E5
`caddy_*` marshal alerts scrape a Caddy target that the Cilium/Envoy edge never emits (ARCH-2)
and that only exists via cut scope (ARCH-3). This epic gives the MVP a coherent home and
decouples platform-edge monitoring from the tenant product.

## What (this change — stub / design-first)

- This epic's **proposal + story map** (variants below). No product code lands here yet.
- **Home for the parked `caddy_*` marshal alerts** (recommendation A — park; OPEN for operator, D-026):
  the alerts + their promtool fire/silent tests move out of active platform monitoring and
  into the **VM-variant alerting slice** of this epic. They are the *alerting slice of the VM
  variant*, not dead code — they fire against the VM's metrics endpoint when the tenant lands.
- **nginx parallel** noted and mirrored in E6 (Crossplane Website claim): nginx is the legacy
  stand-in with the same two-variant structure.

## Product shape — two variants, both Backstage-scaffoldable

A self-service Backstage form picks the variant. Both variants exist for **Caddy AND nginx**
(nginx mirrors the same structure as the legacy stand-in).

### Variant A — VM-based (MINIMAL) · the brief spine
- Just Caddy (or nginx) on a VM + **alerting**.
- In-cluster Prometheus scrapes the **VM's external metrics endpoint**.
- This is the brief spine **serve → scrape → fire**, and exactly where the parked `caddy_*`
  marshal alerts live and fire (against the VM target).
- VM provisioning ties to the sibling **Crossplane provider-gridscale** repo
  (`gridscale_server` resource, already advanced) — phase-2 territory (E6g / E1g).
- Kept deliberately **simple**: no Rollouts, no in-cluster cert lifecycle.

### Variant B — Kubernetes-based (RICH) · the preferred/primary path
- Certificates via **cert-manager**.
- **Blue/green + canary** progressive delivery via **Argo Rollouts** (mulligan, E7) — demoed
  **only** on this variant.
- In-cluster ServiceMonitor/PodMonitor scrape (native `caddy_*` from the tenant pod).
- **Stretch / optional slice:** certificates via **Crossplane** (instead of / alongside
  cert-manager).

> Operator note: VMs are the less-preferred path but **both** are prepared because the
> exercise wording calls for a VM path; **Kubernetes is the preferred, richer path**.

## Preconditions (phase-1 epics that must land first)

The demo spine is built through the **normal epic sequence**, not as a one-off:

```
E1e (kind + Cilium substrate, landed) → E1 (GitOps bootstrap) → E3 (GitOps core / observability)
  → E4 (sample site / clubhouse-tls) → [E-Caddy-MVP tenant demo]
E7 (mulligan / Argo Rollouts) → Variant B progressive-delivery slice
E6 + E6g (Crossplane Website + provider-gridscale) → Variant A VM provisioning + nginx parallel
```

Implementation of this epic is **gated** on those preconditions (Variant A on E6g/E1g VM path;
Variant B on E7 for Rollouts, E3 for in-cluster Prometheus).

## Non-goals

- **Caddy as platform ingress / gateway.** The platform edge is Cilium Gateway API (Envoy);
  Caddy is a tenant product reached *through* it (ADR-0104, D-019). Never the edge.
- Enabling Envoy/Cilium metrics in the E1e substrate to re-point `caddy_*` alerts — that is
  scope creep; the alerts are recommended parked with this epic instead (see marshal decision, rec A · OPEN).
- Full IDP scaffolder breadth (that is E10's concern; this epic is the served-website MVP only).

## Marshal-alert decision (OPEN · recommendation A — park)

The broken `caddy_*` marshal alerts are **recommended to be parked with this epic** and
**disabled from active platform monitoring**. This is the planning-lane **recommendation A**;
the A/B choice is **OPEN for the operator** (`agent-context/INBOX.md`, D-026) and recorded
**PROPOSED** (not ratified) in `agent-context/decisions.md`. Rationale: Option B (re-point to
Cilium/Envoy Gateway metrics) would require enabling Envoy metrics in the E1e substrate = scope
creep. Promtool rigor (fire + silent assertions) is **preserved**, scoped to this epic's
VM-variant alerting slice (REQ-CADDY-S01-03). **Until the operator confirms A, the ARCH-2/ARCH-3
alert-migration + ADR-0104 retcon are blocked.** On confirmation, the monitoring/Caddy lane
retcons ADR-0104 (platform edge = Cilium/Envoy Gateway; Caddy = tenant MVP, not gateway).

## Relationship to E9 / E10

- **E9 (`e9-caddy-operator`, optional):** a Caddy lifecycle CRD/operator — a *different* concern
  (managing Caddy pods), not the served-website MVP. Remains optional; this epic does not depend
  on it. If a tenant operator is ever needed it slots under Variant B, but the MVP does not
  require it.
- **E10 (`e10-portal-stretch`, cuttable ✂️):** the broader IDP scaffolder/portal. The Backstage
  *self-service form* referenced above is E10's surface, but the served-website product itself is
  this epic. E10 stays cuttable; this epic carries the MVP even if E10 is cut (the variants can be
  applied by GitOps without the portal form).
- **New slug justification:** neither E9 (operator/CRD) nor E10 (portal breadth) *is* the
  served-website MVP; a dedicated `e-caddy-mvp` names it cleanly. Reshaping E9 was rejected — the
  opening `git status` shows `e9-caddy-operator/specs/operator/spec.md` already modified by another
  lane, so reshaping risks a collision.

## Links

- ADR-0104 (edge Cilium Gateway) · D-019 · audit ARCH-2, ARCH-3, DIR-1, DIR-2
- Marshal decision: OPEN (recommendation A — park) · `agent-context/INBOX.md` D-026 · `decisions.md` (PROPOSED)
- Preconditions: E1 · E3 · E4 · E7 (Variant B) · E6 / E6g / E1g (Variant A VM + nginx)
- Remediation backlog: `openspec/changes/audit-remediation-2026-07/` (WS1)

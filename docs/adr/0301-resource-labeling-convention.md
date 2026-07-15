# ADR-0301: Resource naming & labeling convention

**Theme:** 03 · IaC & labeling · **Status:** Current

## Context

At scale, unattributed resources break FinOps, incident routing, DLP queries, and compliance audits.
Cloud and Kubernetes well-architected frameworks recommend a **small mandatory label set** applied
consistently.

kaddy applies **labels everywhere**: gridscale labels, Kubernetes labels, OCI image labels, Prometheus
alert labels, Argo CD Applications.

**Sanitization:** this ADR is rewritten from **public sources only**. No employer-specific policy
IDs, internal EAM systems, or org billing keys.

## Regulatory basis (public texts only)

| Source | Operationalised by |
| --- | --- |
| NIS2 (EU) 2022/2555 Art. 21(2)(i) — asset management | `owner`, mandatory inventory via labels |
| Commission Implementing Reg. (EU) 2024/2690 rec. 24–26 | `data-classification`, `owner` |
| § 8a BSIG / BSI KRITIS guidance — inventory & classification | `owner`, `data-classification`, `business-criticality` |
| GDPR Art. 30/32 | `personal-data` (when applicable) |
| PCI-DSS scoping | optional `pci` label |

## Decision — mandatory core

Design to strictest syntax: GCP-compatible lowercase `[a-z0-9_-]{0,63}` for values (intersection
with Kubernetes label values).

**Canonical form (single source of truth): the BARE keys below.** There is exactly one canonical
label set — these bare keys. Enforcement (OPA `policy/labels.rego`, Kyverno
`require-kaddy-labels`) checks these bare keys and nothing else. The Kubernetes-recommended
`app.kubernetes.io/*` keys are an explicit, **documented addition** (see *Kubernetes mapping*
below) — a mirror emitted alongside the canonical keys, **never a competing canonical set**.
Artifacts may carry both forms; only the bare form is authoritative and enforced.

| Key | Req | Example | Purpose |
| --- | --- | --- | --- |
| `owner` | yes | `platform-team` | DRI for incidents |
| `service` | yes | `clubhouse` | App identity — mirrored to `app.kubernetes.io/name` |
| `component` | opt | `web` | Role — mirrored to `app.kubernetes.io/component` |
| `part-of` | yes | `kaddy` | Platform/product — mirrored to `app.kubernetes.io/part-of` |
| `managed-by` | yes | `argocd` / `crossplane` / `terramate` | IaC tool — mirrored to `app.kubernetes.io/managed-by` |
| `data-classification` | yes | `internal` | `public` / `internal` / `confidential` / `restricted` |
| `business-criticality` | yes | `business-operational` | Blast radius tier |
| `track` | yes | `stable` | `stable` / `canary` / `preview` — **replaces environment/stage** |

The mandatory core is therefore: `owner`, `service`, `part-of`, `managed-by`,
`data-classification`, `business-criticality`, `track` (all bare). `component` is **optional**;
when set it is emitted in both bare (`component`) and k8s (`app.kubernetes.io/component`) form.

### Annotations (high cardinality — not labels)

| Key | Example |
| --- | --- |
| `kaddy.io/managed-in-repo` | `platformrelay/kaddy` |
| `kaddy.io/source-commit` | `abc1234` |
| `kaddy.io/contact` | on-call routing hint |

### Optional regulatory keys

| Key | Values |
| --- | --- |
| `personal-data` | `none` / `pseudonymised` / `personal` / `special-category` |
| `pci` | `true` / `false` |

### Kubernetes mapping (documented addition — not a replacement)

The canonical bare key is authoritative; the `app.kubernetes.io/*` key is emitted **in addition**
so standard Kubernetes tooling (dashboards, selectors) works. Both are present on the same
resource; policy enforces only the bare key.

| Canonical (bare, enforced) | K8s-recommended mirror (additive, not enforced) |
| --- | --- |
| `service` | `app.kubernetes.io/name` |
| `component` (opt) | `app.kubernetes.io/component` |
| `part-of` | `app.kubernetes.io/part-of` |
| `managed-by` | `app.kubernetes.io/managed-by` |
| `source-commit` (annotation) | `app.kubernetes.io/version` |

Prefixed keys use **`kaddy.io/`** when a prefix is required.

## OpenTofu module (`modules/labels`)

Reusable module (E1b) exports:

- `local.labels` — map for Kubernetes / unified use
- `local.gridscale_labels` — list of `key=value` for gridscale resource labels
- `local.name(prefix, suffix)` — deterministic resource naming `{prefix}-{service}-{suffix}`

**Tests:**

- `tofu test` — naming length, forbidden chars, required keys always present
- **conftest/OPA** — policies reject plans missing mandatory tags

Terramate codegen injects module outputs into every stack (see ADR-0302). Reference layout:
Terramate `stacks/` + `modules/` + `policy/` pattern (local design reference only — not committed).

## Enforcement

- CI: `task scrub` + conftest on TF plans
- Cluster: Kyverno ClusterPolicy `require-kaddy-labels`
- Alerts: PrometheusRule templates inject `owner`, `service`, `severity` for self-routing

## Consequences

- No `environment`/`stage`/`dev`/`prod` keys — single lab (D-004).
- Teams must set `track` on Rollout-managed pods via pod template labels.

## Counterpoints

- Larger enterprise FinOps key sets (billing-code, org-unit) dropped — no billing backend in lab.

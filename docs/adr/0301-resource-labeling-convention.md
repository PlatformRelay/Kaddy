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

| Key | Req | Example | Purpose |
| --- | --- | --- | --- |
| `owner` | yes | `platform-team` | DRI for incidents |
| `service` | yes | `clubhouse` | App identity → `app.kubernetes.io/name` |
| `component` | opt | `web` | Role → `app.kubernetes.io/component` |
| `part-of` | yes | `kaddy` | Platform/product → `app.kubernetes.io/part-of` |
| `managed-by` | yes | `argocd` / `crossplane` / `terramate` | IaC tool |
| `data-classification` | yes | `internal` | `public` / `internal` / `confidential` / `restricted` |
| `business-criticality` | yes | `business-operational` | Blast radius tier |
| `track` | yes | `stable` | `stable` / `canary` / `preview` — **replaces environment/stage** |

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

### Kubernetes mapping

| kaddy key | K8s recommended |
| --- | --- |
| `service` | `app.kubernetes.io/name` |
| `component` | `app.kubernetes.io/component` |
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

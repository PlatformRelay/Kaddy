# Runbook — gridscale day-0 (E1g)

Bootstrap the phase-2 gridscale substrate: Object Storage state anchor →
network → GSK cluster → LBaaS. Authored as Terramate + OpenTofu stacks under
`stacks/gridscale/`. This runbook covers the **offline gate**, the **live
bootstrap order**, the **env-var mapping**, and — most importantly — the
**ruthless teardown discipline** (this infra costs money and is torn down after
every test).

## TL;DR

```bash
# OFFLINE (safe, no creds, no cost) — run any time, wired into task verify.
task test:smoke:e1g

# LIVE (costs money) — only when explicitly provisioning.
task e1g:up      # bootstrap anchor, then provision per this runbook
task e1g:down    # RUTHLESS teardown — run after EVERY live test
```

## Stack layout & dependency order

```text
stacks/gridscale/
  object-storage/   # state anchor (LOCAL state) — bootstrapped FIRST
  network/          # private network + firewall + public IPv4/IPv6
  k8s/              # gridscale_k8s GSK cluster, ONE minimal node pool
  lbaas/            # gridscale_loadbalancer entry point (listens on network IPs)
```

Provision order: **object-storage → network → k8s → lbaas**.
Teardown order (reverse): **lbaas → k8s → network → object-storage**.

`terramate.tm.hcl` (root) holds shared globals (labels, location, provider pin).
`config.tm.hcl` holds the codegen that injects, into **every** stack:

- `_terramate_generated_provider.tf` — `required_providers` pin + provider auth
- `_terramate_generated_variables.tf` — `gridscale_uuid` / `gridscale_token`
- `_terramate_generated_backend.tf` — S3 backend (workload stacks only)
- `_terramate_generated_labels.tf` — the `modules/labels` call (**E1b-S04**)

Regenerate after editing globals/codegen: `task e1g:generate` (deterministic,
offline). The offline gate fails if committed codegen has drifted.

## State backend (DECIDED-B)

The `object-storage` stack is the single cheap **persistent anchor**. It is
bootstrapped with **LOCAL state** (chicken-and-egg: it *creates* the remote
backend, so it can't use it). It provisions:

- `gridscale_object_storage_accesskey.state` — the key that owns the bucket
- `gridscale_object_storage_bucket.state` — the S3-compatible state bucket
  (default `kaddy-tfstate` on `gos3.io`), with a lifecycle rule that bounds
  growth (expires noncurrent versions + incomplete uploads).

Every **other** stack uses that bucket as its `backend "s3"` remote state. At
live `tofu init`, supply bucket/endpoint/creds via `-backend-config`:

```bash
tofu init \
  -backend-config="bucket=kaddy-tfstate" \
  -backend-config="endpoints={s3=\"https://gos3.io\"}" \
  -backend-config="access_key=$STATE_ACCESS_KEY" \
  -backend-config="secret_key=$STATE_SECRET_KEY"
```

(`STATE_ACCESS_KEY` / `STATE_SECRET_KEY` are the `access_key` / `secret_key`
outputs of the object-storage stack.) The backend block already sets the
`skip_*` / `use_path_style` flags gos3.io needs (it is not real AWS).

## Live output → input wiring (E1g-S05)

The stacks pass values by **input variable** (not `terraform_remote_state`) so
each one validates/tests offline in isolation. At live time you thread the
outputs of one stack into the next explicitly. Concrete handoff:

```bash
# 1) object-storage → backend creds for every workload stack
STATE_ACCESS_KEY=$(cd stacks/gridscale/object-storage && tofu output -raw access_key)
STATE_SECRET_KEY=$(cd stacks/gridscale/object-storage && tofu output -raw secret_key)

# 2) network → lbaas listen IPs + k8s firewall
export TF_VAR_listen_ipv4_uuid=$(cd stacks/gridscale/network && tofu output -raw ipv4_uuid)
export TF_VAR_listen_ipv6_uuid=$(cd stacks/gridscale/network && tofu output -raw ipv6_uuid)

# 3) k8s → kubeconfig, then re-point ArgoCD bootstrap + Dex issuer
(cd stacks/gridscale/k8s && tofu output -raw kubeconfig) > "$KUBECONFIG_OUT"
#   feed the public LBaaS IP/domain into the Dex issuer URL + GitHub OAuth callback
#   then re-run the phase-1 ArgoCD app-of-apps bootstrap against $KUBECONFIG_OUT
```

`task e1g:up` performs step 1 (bootstraps the anchor) and echoes this sequence;
steps 2–3 are run per this runbook because the backend/kubeconfig handoff is
provisioning-time state that is not scripted blind (untested multi-stack backend
plumbing would be worse than an explicit checklist).

## Live conftest carve-out (object-storage has no `labels` arg)

The offline gate runs `conftest` only over the **GSK** plan fixtures. At live
S05 a real `tofu show -json | conftest --policy policy` over the *whole* plan
will **deny** `gridscale_object_storage_bucket` / `gridscale_object_storage_accesskey`
— the gridscale provider gives those resources **no `labels` argument**, so they
can't carry the 7 mandatory ADR-0301 keys `policy/labels.rego` requires. This is
a provider limitation, not a policy bug. Before running conftest against a live
plan, **carve out object-storage** (e.g. `conftest test ... --namespace main`
scoped to labelled resource types, or exclude the two object-storage resource
addresses). Do **not** relax `labels.rego` itself — every resource that *can*
carry labels still must.

## Env-var mapping (KEY-FACT)

The gridscale provider authenticates on `GRIDSCALE_UUID` / `GRIDSCALE_TOKEN`.
The repo `.envrc` exports **different** names: `GRIDSCALE_USER_UUID` /
`GRIDSCALE_API_KEY`. The stacks bridge this at the boundary — the codegen'd
provider reads `var.gridscale_uuid` / `var.gridscale_token`, and the LIVE
`task e1g:up` / `e1g:down` targets map:

| .envrc export         | → TF var mapped in task     | → provider arg |
| --------------------- | --------------------------- | -------------- |
| `GRIDSCALE_USER_UUID` | `TF_VAR_gridscale_uuid`     | `uuid`         |
| `GRIDSCALE_API_KEY`   | `TF_VAR_gridscale_token`    | `token`        |

Credentials touch the stacks **only** through these two task targets. Offline
the vars are unset and the provider is never configured (validate/mocked-test
need no creds). Never hard-code UUIDs/tokens in HCL; never edit `.envrc`.

## Offline gate (what `task test:smoke:e1g` proves)

`tests/smoke/e1g-offline.sh` — no cluster, no gridscale API, no credentials:

1. `terramate generate` is current (committed codegen not drifted)
2. `tofu fmt -check -recursive stacks/gridscale`
3. per stack: `tofu init -backend=false` + `tofu validate`
4. per stack: `tofu test` with `mock_provider "gridscale"` (asserts naming,
   labels wiring, minimal sizing, concrete release, IP/backend wiring)
5. `conftest` on plan fixtures: the good GSK plan passes; a `latest`-release
   plan and an oversized-pool plan are **denied** (`policy/gridscale.rego`).

Provider binaries are fetched once from the public OpenTofu registry into
`$TF_PLUGIN_CACHE_DIR` (default `~/.terraform.d/plugin-cache`) — a public
download, not a gridscale API call. Set the same var in CI to cache across runs.

## Cost estimate & teardown discipline

Rough monthly-run cost if left up (order-of-magnitude, verify in the panel):

| Resource                | Sizing                          | Cost driver     |
| ----------------------- | ------------------------------- | --------------- |
| GSK node pool           | 4 nodes × 2 cores / 4 GiB / 30 GB (D-048 default 3; 4th operator-approved 2026-07-20) | dominant cost   |
| LBaaS                   | 1 load balancer                 | modest hourly   |
| Public IPv4 + IPv6      | 1 each                          | small hourly    |
| Object Storage (state)  | tiny bucket                     | negligible      |

**Ruthless teardown**: run `task e1g:down` after **every** live test. It
destroys in reverse dependency order (lbaas → k8s → network → object-storage)
and reminds you to confirm in the gridscale panel that nothing lingers. The
object-storage anchor is destroyed last because it holds the remote state; if
you want to keep the anchor between tests (cheapest option) destroy only the
workload stacks and leave `object-storage` up.

**Go-live standing carve-out (D-042).** The dev-phase "tear it all down every
time" rule was an overspend guard for the build phase. In **go-live** a standing
live substrate is intentionally permitted — but **only when it is
recorded and time-boxed**: what is up and since-when are captured in
`evidence/live/e1g-gsk-2026-07-18.md`; the teardown-by date and owner (with the
~1–2 week go-live window) will be captured in decision **D-042** (operator-placed)
and surfaced by **E1g-S07** (`task e1g:status`, a soft WARN once the default ~14-day
window is exceeded). This is cost-governance, not a blocker, and it does
**not** relax the ruthless per-test teardown above — that stays the default; the
carve-out covers only the one sanctioned, recorded standing substrate.

## Phase-1 ↔ phase-2 deltas

- **Substrate**: phase-1 kind cluster → phase-2 GSK managed cluster. Same
  GitOps app-of-apps re-syncs onto GSK (E1g-S05, pending live).
- **Ingress/TLS**: phase-1 in-cluster Gateway → phase-2 public LBaaS in front
  of the Gateway; re-test E4/E5 (LoadBalancer/TLS) on GSK.
- **Identity**: the public LBaaS IP/domain feeds the Dex issuer URL + GitHub
  OAuth callback (E1g-S05).
- **Node pool**: default is **3** workers (D-048); the standing go-live substrate
  runs **4** — the 4th node is operator-approved MemoryPressure relief
  (2026-07-20, ~€46/node/mo). Override via the `k8s` stack's `node_count` var
  (capped at 4 by both variable validation and `policy/gridscale.rego`).

## References

- Provider docs: `references/gridscale-terraform-provider/website/docs/`
- ADRs: [0102](../adr/0102-talos-immutable-substrate.md),
  [0302](../adr/0302-terramate-opentofu-stacks.md),
  [0301](../adr/0301-resource-labeling-convention.md)
- OpenSpec: `openspec/changes/e1g-gridscale-day0/`

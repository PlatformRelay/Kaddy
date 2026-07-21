# Security spike — GSK worker-node public-IP exposure (E1g-S05h, 2026-07-18)

**Scope:** definitively establish whether gridscale Managed Kubernetes (GSK)
worker nodes can be provisioned without a public IP, or firewalled, via the
`gridscale/gridscale` Terraform provider or the gridscale API — and record the
residual risk and the recommended mitigation.
**Type:** offline research spike. No cluster, no API, no credentials. The only
artifact is this document; see § Recommendation for why no plan-time IaC guard
can enforce the control.
**Basis:** live facts observed during the 2026-07-18 standing bring-up
(`evidence/live/e1g-gsk-2026-07-18.md`) + the verbatim provider docs cloned at
`references/gridscale-terraform-provider/` and `agent-context/reference/gridscale/`.

## Live facts (empirical basis)

Observed while the GSK substrate was standing (VPN off, from outside the cluster):

- GSK worker nodes come up with **public** `EXTERNAL-IP`s:
  - `node-pool-0-0` = `185.241.34.168`
  - `node-pool-0-1` = `185.241.34.180`
- Those node public IPs are **directly reachable from the internet on arbitrary
  NodePorts** — `nc <node-public-ip> 30443` succeeded from outside the cluster.
  GSK therefore does **not** firewall the node public IPs by default.
- The platform network stack's firewall (`stacks/gridscale/network`,
  `gridscale_firewall.edge`) is **orphaned/inert**: GSK attaches its nodes to
  GSK's own managed `k8s_private_network_uuid`, **not** to
  `gridscale_network.platform`. A `gridscale_firewall` binds to a
  server/network we manage; it cannot attach to the GSK-managed node network,
  so it has zero effect on the node public IPs.

## Question 1 — can a GSK node avoid a public IP?

**No.** There is no provider argument and no documented API parameter to
provision GSK worker nodes without a public IP.

The complete `gridscale_k8s` argument surface (verbatim from
`references/gridscale-terraform-provider/website/docs/r/k8s.html.md`, provider
`2.3.0` — the newest release satisfying the pinned `~> 2.2`, per
`stacks/gridscale/k8s/.terraform.lock.hcl`) is:

- `name`, `release` / `gsk_version` (mutually exclusive), `labels`
- `node_pool { name, node_count, cores, memory, storage, storage_type,
  rocket_storage, taints{}, labels{} }`
- `surge_node`, `cluster_cidr`, `cluster_traffic_encryption`
- `oidc_*` (nine OIDC args), `k8s_hubble`
- `security_zone_uuid` — **DEPRECATED, ForceNew**
- Read-only **exports** (not inputs): `kubeconfig`, `network_uuid` (DEPRECATED),
  `k8s_private_network_uuid`, `service_template_*`, `status`, timestamps.

None of these controls node public-IP assignment. `k8s_private_network_uuid` is
an **exported attribute**, not an input — you cannot use it to force nodes onto
a private-only network of your choosing; GSK mints and owns it.

## Question 2 — can GSK nodes be firewalled at the gridscale layer?

**No, not via anything we manage.**

- `gridscale_firewall` attaches to a `gridscale_server` NIC / a network we own.
  GSK nodes are PaaS-managed servers on GSK's own private network — we have no
  handle to attach a firewall template to them. This is exactly why
  `gridscale_firewall.edge` in `stacks/gridscale/network` is orphaned.
- `security_zone_uuid` (deprecated; resource `gridscale_paas_securityzone`,
  see `references/.../r/securityzone.html.md`) provisions a **PaaS-to-PaaS
  security zone** for private east-west connectivity between PaaS services. It
  is *not* a north-south node-IP firewall and is on the provider's deprecation
  path — using it would add ForceNew churn for no public-IP benefit.

## Newer-release / API survey

- Provider: locked at **`2.3.0`** (`~> 2.2`). `2.3.0` is the current top of the
  `2.x` line and its `gridscale_k8s` schema is the one surveyed above — it adds
  no disable-public-IP / node-firewall argument over `2.2`. This survey is
  authoritative **within the pinned `~> 2.2` constraint**; a provider
  major-version bump (`3.x`) is out of scope for this spike and would need its
  own review if adopted.
- gridscale API (`agent-context/reference/gridscale/managed-kubernetes.md`,
  `api-objects.md`): GSK is created via `POST /objects/paas/services` against a
  Kubernetes `service_template_uuid` with a `parameters` map. The documented
  parameters map to the same `cores`/`memory`/`storage`/`node_count` node
  sizing knobs — there is **no documented parameter** exposing node public-IP
  assignment or a node firewall. The public-IP-per-node behaviour is a fixed
  property of the GSK service template, not a tunable.

**Conclusion:** no safe configuration option exists at either the Terraform or
API layer to remove or firewall the GSK node public IPs. Deliverable #2's
"if a safe config option exists, wire it" branch does **not** apply; the
accepted-risk branch does.

## Residual risk

GSK worker nodes are internet-reachable on their public IPs across the full
NodePort range (30000–32767). Any `Service type=NodePort` — or a
`type=LoadBalancer` Service, which GSK backs by opening a NodePort behind the
LB — is exposed on every node's public IP, not only through the intended LBaaS
edge. This is a real, provider-imposed attack surface: it widens ingress beyond
the single deliberate LBaaS entry point and bypasses the (orphaned) platform
firewall.

**Severity:** medium. The control plane `:6443` and app ingress are the
intended surfaces; the concern is *unintended* NodePort exposure on public node
IPs, especially once E1g-S05c wires a Gateway via NodePort.

## Recommendation — ACCEPTED RISK with compensating controls

Because the provider/API offer no fix, accept the risk and constrain the blast
radius with controls we *do* own:

1. **Never expose app ingress via raw NodePort as the public edge.** Route all
   north-south traffic through **LBaaS** (`stacks/gridscale/lbaas`), whose
   forwarding rules we control (443/80 only, per the network-stack firewall
   intent). The Gateway→node hop in E1g-S05c must be treated as an
   LBaaS-internal backend edge, not a public entry point. The S05c task line
   now carries this as an explicit design constraint (see § Cross-references).
2. **Kubernetes-layer compensating control:** default-deny `NetworkPolicy` /
   Cilium `HostFirewall` on the nodes so that only the LBaaS source ranges and
   the required NodePorts are reachable, even though the IP is public. Tracked
   as follow-up for the S05b/S05c edge build (in-cluster, not IaC — out of this
   spike's offline boundary).
3. **Cap the node count** (enforced: `node_count` default 3, variable validation
   and conftest cap at 4 — the 4th node is operator-approved MemoryPressure
   relief, 2026-07-20) — fewer public IPs, smaller surface.
4. **Ruthless teardown** (DECIDED-B; `task e1g:down`) keeps the exposure window
   short — the substrate is not a standing target.

### Why no plan-time IaC guard can enforce this

No conftest/rego guard was added, and none should be. The actual risk vector is
a **runtime** Kubernetes object — a `Service type=NodePort` (or a
`type=LoadBalancer` Service, which GSK backs by opening a NodePort). That object
is created inside the cluster at runtime; it is **not** present in a
`tofu show -json` plan of the `gridscale_k8s` stack, which is all conftest sees
here. A guard on the `gridscale_k8s` resource therefore cannot observe — let
alone block — the thing that creates the exposure. Adding one would assert a
safety it does not provide (security theater). The enforceable controls are the
LBaaS-only design constraint on S05c (recorded in `tasks.md`) and the in-cluster
`NetworkPolicy`/`HostFirewall` follow-up above.

## Cross-references

- Story: `openspec/changes/e1g-gridscale-day0/tasks.md` → E1g-S05h.
- Decision: `agent-context/decisions.md` D-041 (agent counterpoint #3) —
  gitignored; this doc is the shippable record.
- Live evidence: `evidence/live/e1g-gsk-2026-07-18.md`.
- Provider docs: `references/gridscale-terraform-provider/website/docs/r/k8s.html.md`
  (verbatim), `agent-context/reference/gridscale/managed-kubernetes.md`.
- Downstream constraint: E1g-S05c (Gateway NodePort ← LBaaS) MUST NOT treat the
  node public IP + NodePort as a public entry point; LBaaS is the only edge.

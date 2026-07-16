# deploy/policies — admission + network security baseline (E1c)

Security baseline per ADR-0106 / ADR-0301, addressing the 2026-07-16
security review P1s: inert Kyverno labels policy (P2-1), missing
default-deny NetworkPolicies (P1-1) and the unrestricted ArgoCD
`project: default` blast radius (P1-2, see `deploy/apps/projects/`).

## Honest status: what is enforced vs authored

| Control | Where | Status |
| --- | --- | --- |
| ADR-0301 labels on TF plans | `policy/labels.rego` (conftest, CI L1) | **Enforced** in CI (`task test:policy`) |
| Kyverno ClusterPolicies | `kyverno/` | **Authored, NOT applied** — Kyverno is not installed; no sync has run |
| Default-deny NetworkPolicies | `network/` | **Authored, NOT applied** — cluster apply belongs to the cluster-hardening lane |
| Restricted AppProjects | `deploy/apps/projects/` | **Authored, NOT wired** — root syncs `deploy/apps/` with recurse OFF |
| Offline policy tests | `tests/kyverno/` | **Enforced locally/CI** via `kyverno test tests/kyverno/` |

Nothing in this directory mutates the cluster by being merged: the
`policies` Application (`deploy/apps/policies.yaml`) is registered by the
root app but has a **manual-only syncPolicy** — a human runs the first sync.

## Kyverno policies (`kyverno/`)

| Policy | Action | Purpose |
| --- | --- | --- |
| `require-kaddy-labels` | Enforce | Mandatory ADR-0301 bare-key label set on Pods (REQ-E1b-S05-01) |
| `restrict-data-classification` | Enforce | `data-classification` value must be in the ADR-0301 closed vocabulary (REQ-E1b-S05-02) |
| `disallow-privileged-containers` | Audit | Pod-security baseline (ADR-0106) |
| `require-run-as-nonroot` | Audit | Pod-security baseline; clubhouse is the reference (ADR-0106) |
| `disallow-latest-tag` | Audit | No floating/missing image tags (ADR-0106 / SEC-4) |
| `verify-signed-images` | Audit | REQ-E1c-S03-02 — **placeholder cosign key**, scoped to `ghcr.io/platformrelay/*` only; replace the key when release signing lands |

Both Enforce policies exclude infra namespaces (`kube-*`,
`local-path-storage`, `kyverno`, `cert-manager`, `argocd`, `monitoring`):
chart-/upstream-managed pods do not carry the bare kaddy keys, and without
the exclusion an in-cluster Enforce would deny every system pod restart.
The Audit policies exclude only `kube-*` + `local-path-storage`, so the
observability stack's chart defaults (security review P2-2) show up in the
Audit report before any Enforce flip.

### Testing offline (D-024)

```sh
kyverno test tests/kyverno/
```

CLI pinned to **v1.18.2** (matches the CI install): `brew install kyverno`
or `go install github.com/kyverno/kyverno/cmd/cli/kubectl-kyverno@v1.18.2`.
Every policy has pass + fail fixtures except `verify-signed-images`:
`kyverno test` cannot evaluate verifyImages rules offline (signature
lookup needs registry access). Its in-cluster test is the Chainsaw case
`tests/chainsaw/security/unsigned-image-denied.yaml` (skip until cosign).

## NetworkPolicies (`network/`)

Default-deny baseline (SEC-6 / REQ-E1c-S01-*) for the three namespaces that
exist today, plus the explicit allows that keep the live paths working:

| Namespace | Deny | Allows |
| --- | --- | --- |
| `gateway` | ingress + egress | Cilium Gateway (Envoy) → clubhouse `:8080` (CNP, `ingress` entity); Prometheus (monitoring) → `:8080`; DNS egress → kube-system `:53` |
| `monitoring` | ingress | intra-namespace mesh (Grafana→Prometheus/Loki, Alloy→Loki, Prometheus→Alertmanager); kube-apiserver → operator webhook `:10250` (CNP); egress open (cluster-wide scrapes) |
| `argocd` | ingress | upstream per-component policies remain the allow-list (argocd-server's allow-all keeps the Gateway path working); Prometheus → metrics ports; egress open (Git/Helm pulls) |

**CNI dependency:** enforcement requires Cilium (present on kind, ADR-0104).
The two `CiliumNetworkPolicy` objects are Cilium-specific by necessity —
Gateway/webhook traffic carries reserved identities (`ingress`,
`kube-apiserver`) that plain NetworkPolicy peers cannot select.

**The cluster apply happens in the follow-up cluster-hardening lane**, with
the Chainsaw suite `tests/chainsaw/security/` (REQ-E1c-S01-01..03) proving
deny + allow behaviour live.

## Cutover plan (cluster-hardening lane, in order)

1. **Install Kyverno v1.18.2** (pinned — same version as the CLI/CI) so the
   ClusterPolicy CRD exists.
2. **Human-sync the `policies` Application** (it is manual-only). Enforce
   applies to kaddy workload namespaces; the pod-security trio starts in
   Audit.
3. **Review the Audit report** (PolicyReports), fix violators (P2-2
   observability securityContexts), then **flip the Audit policies to
   Enforce** one by one.
4. **Apply the NetworkPolicy baseline** (same sync), then run the Chainsaw
   security suite to prove Gateway/scrape/DNS paths and the deny branch.
5. **AppProject cutover:** apply `deploy/apps/projects/`, move each
   Application off `project: default` (`policies` → `platform`, etc.), then
   un-skip the Chainsaw labeling suite (TEST-4).

## Follow-ups owned by other lanes (NOT this directory)

- Kyverno install + sync + Enforce flips + netpol apply (cluster lane, list
  above).
- Chainsaw suites: `tests/chainsaw/security/` (REQ-E1c-S01-*, S03-02) and
  un-skipping `tests/chainsaw/labeling/` (TEST-4).
- Trivy CI gate (REQ-E1c-S02-*), digest pinning + `hack/verify-image-digests.sh`
  (REQ-E1c-S03-01), cosign release signing + real key for
  `verify-signed-images` (SEC-8).
- ExternalSecrets/KSOPS items (REQ-E1c-S04-*, S05-02) — identity epic.

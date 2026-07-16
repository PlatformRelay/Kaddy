# deploy/policies — admission + network security baseline (E1c)

Security baseline per ADR-0106 / ADR-0301, addressing the 2026-07-16
security review P1s: inert Kyverno labels policy (P2-1), missing
default-deny NetworkPolicies (P1-1) and the unrestricted ArgoCD
`project: default` blast radius (P1-2, see `deploy/apps/projects/`).

## Honest status: LIVE since the 2026-07-16 cluster cutover

| Control | Where | Status |
| --- | --- | --- |
| ADR-0301 labels on TF plans | `policy/labels.rego` (conftest, CI L1) | **Enforced** in CI (`task test:policy`) |
| Kyverno engine v1.18.2 | `deploy/kyverno/` + `deploy/apps/kyverno.yaml` | **Installed, GitOps-managed** (vendored + pinned) |
| Kyverno ClusterPolicies | `kyverno/` | **LIVE** — see the enforcement matrix below |
| Default-deny NetworkPolicies | `network/` | **LIVE** in gateway/monitoring/argocd; all E1/E4/E5/E7 smokes green post-apply |
| Restricted AppProjects | `deploy/apps/projects/` | **LIVE** — every `deploy/apps` child is off `project: default` (SEC-11) |
| Offline policy tests | `tests/kyverno/` | **Enforced** locally/CI via `kyverno test tests/kyverno/` (28 cases) |
| Live admission/netpol tests | `tests/chainsaw/{labeling,security}/` | labeling un-skipped (CI + live); security suites live-verified, CI-skipped (no Cilium) |

The `policies` Application (`deploy/apps/policies.yaml`) **stays
manual-sync by design**: admission + network controls are high blast
radius, so a human syncs every policy change deliberately
(`argocd app sync policies --core`). The Kyverno ENGINE app is automated —
installing the engine enforces nothing by itself.

## Enforcement matrix (`kyverno/`) — live, verified 2026-07-16

| Policy | Action | Why |
| --- | --- | --- |
| `require-kaddy-labels` | **Enforce** | Mandatory ADR-0301 bare-key label set on Pods (REQ-E1b-S05-01); proven by the labeling Chainsaw suite + `tests/smoke/e1c-exit.sh` |
| `restrict-data-classification` | **Enforce** | ADR-0301 closed vocabulary (REQ-E1b-S05-02) |
| `disallow-privileged-containers` | **Enforce** | Flipped from Audit after a clean PolicyReport (zero violations) + admitted canary restart |
| `disallow-latest-tag` | **Enforce** | Flipped from Audit after a clean PolicyReport (all images pin exact tags) |
| `require-run-as-nonroot` | **Enforce** | Flipped from Audit; two violator classes excluded narrowly (below) instead of blanket-excluding namespaces |
| `verify-signed-images` | **Audit** (operator-ratified) | KEYLESS cosign attestor (GitHub OIDC issuer + `showcase-image.yaml` workflow identity), scoped to `ghcr.io/platformrelay/*`. `mutateDigest: false` (Kyverno requires it for Audit verifyImages). Flip criteria below; Chainsaw case `security/unsigned-image-denied.yaml` stays skipped until the first signed image is deployed |

### Documented excludes (narrow, never blanket)

Both Enforce **governance** policies (labels, data-classification) exclude:

- infra namespaces `kube-*`, `local-path-storage`, `kyverno`,
  `cert-manager`, `argocd`, `monitoring` — chart-/upstream-managed pods do
  not carry the bare kaddy keys (as authored offline);
- `argo-rollouts` — the vendored upstream controller
  (`deploy/rollouts/install.yaml`), same class as `argocd`;
- `e1e-smoke` — ephemeral E1e smoke fixtures, recreated by every
  `task test:smoke:e1e` run (hygiene follow-up: review P2-5);
- Pods `clubhouse-redir-*` / `clubhouse-smoke-*` in `gateway` only — the
  transient E4 smoke curl pods (name+namespace-scoped; a rogue unlabeled
  pod in `gateway` is still denied — fixture-proven).

`require-run-as-nonroot` additionally excludes (name+namespace-scoped):

- `monitoring/alloy*` — the Alloy DaemonSet tails host logs from
  `/var/log` and functionally requires root (upstream default; P2-2);
- `e1e-smoke` — `hashicorp/http-echo` runs as root.

### verify-signed-images — keyless attestor + the Audit→Enforce flip

SEC-8 landed **keyless** (no long-lived release key): kaddy's first
self-published image (`ghcr.io/platformrelay/kaddy-showcase`,
REQ-CADDY-S05-02) is built, pushed and **cosign-signed by digest** in
`.github/workflows/showcase-image.yaml` using ambient GitHub OIDC. The
policy's attestor pins that identity:

- **issuer:** `https://token.actions.githubusercontent.com`
- **subject:** `https://github.com/PlatformRelay/Kaddy/.github/workflows/showcase-image.yaml@*`

The workflow's own `cosign verify` step (same issuer + identity regexp)
is the CI proof that what the policy checks is what CI actually signs.

**Flip to Enforce when BOTH hold:**

1. every `ghcr.io/platformrelay/*` image deployed to the cluster is a
   kaddy image signed by this workflow (the scope currently matches
   nothing live, so Audit is free), **and**
2. signing is **proven in CI** — at least one `showcase-image` run on
   `main` green through the `cosign verify` step (until that first run,
   the workflow is authored but unproven).

Then: flip `validationFailureAction`/`failureAction` to Enforce and
un-skip the `security/unsigned-image-denied.yaml` Chainsaw case.

### Testing offline (D-024)

```sh
kyverno test tests/kyverno/
```

CLI pinned to **v1.18.2** (matches the engine + CI): 28 cases including
skip-proofs for every exclude above plus rogue-pod fail cases proving the
excludes are name-scoped, not namespace-wide. `kyverno test` cannot
evaluate verifyImages rules offline (registry access) — that policy's
in-cluster test is the (skipped) Chainsaw case.

## NetworkPolicies (`network/`) — LIVE

Default-deny baseline (SEC-6 / REQ-E1c-S01-*) plus the explicit allows that
keep the live paths working:

| Namespace | Deny | Allows |
| --- | --- | --- |
| `gateway` | ingress + egress | Cilium Gateway (Envoy) → clubhouse `:8080` (CNP, `ingress` entity); Prometheus (monitoring) → `:8080`; DNS egress → kube-system `:53`; smoke-probe pods (`run` label) → edge + clubhouse hairpin (CNP, below) |
| `monitoring` | ingress | intra-namespace mesh (Grafana→Prometheus/Loki, Alloy→Loki, Prometheus→Alertmanager); kube-apiserver → operator webhook `:10250` (CNP); egress open (cluster-wide scrapes) |
| `argocd` | ingress | upstream per-component policies remain the allow-list (argocd-server's allow-all keeps the Gateway path working); Prometheus → metrics ports; egress open (Git/Helm pulls) |
| `identity` | ingress + egress | Cilium Gateway (Envoy) → dex `:5556` (CNP, `ingress` entity — carries both browser and argocd-server OIDC traffic via the 30443 listener); argocd ns → dex `:5556` (defense-in-depth); DNS egress; dex → GitHub OAuth `:443` (world, port-scoped — toFQDNs tightening is an E10 follow-up) |

**CNI dependency:** enforcement requires Cilium (present on kind, ADR-0104).
The `CiliumNetworkPolicy` objects are Cilium-specific by necessity —
Gateway/webhook traffic carries reserved identities (`ingress`,
`kube-apiserver`) that plain NetworkPolicy peers cannot select.

**Gateway hairpin gotcha (found live, keep in mind for new clients):**
Cilium preserves the ORIGINAL client identity through the Gateway proxy and
re-evaluates the client's egress policy against the BACKEND pod identity
inside Envoy. A client whose egress is restricted therefore needs BOTH
`toEntities: [ingress]` (reach the listener) and an allow to the backend
pods (the proxied hop), or Envoy answers `403 Access denied`. Clients with
unrestricted egress (blackbox prober, external/host traffic) are
unaffected. See `network/gateway.yaml` (`allow-probe-egress-to-edge`).

Live proof: Chainsaw `tests/chainsaw/security/` (deny branch + allow
branch, run per the annotations in each file) and the full
`task test:smoke:e5` / `e4` / `e1` / `e7` bundles green post-apply.

## Cutover log (performed 2026-07-16, this order)

1. Kyverno v1.18.2 installed GitOps-managed (`deploy/apps/kyverno.yaml`).
2. First human sync of the `policies` app (ClusterPolicies + netpols).
   Found live: verifyImages Audit requires `mutateDigest: false` (the
   policy webhook rejects it otherwise — invisible to offline tests).
3. Immediate regression: e4/e5/e1/e7 smoke bundles → two fixes:
   smoke-probe admission excludes + the hairpin CNP leg (above).
4. PolicyReports reviewed → Audit trio flipped to Enforce one by one with
   canary pod restarts between flips (see matrix).
5. AppProject cutover (`deploy/apps/projects/` + every child re-projected,
   root recurses `deploy/apps/`).
6. Grafana admin → `monitoring/grafana-admin` Secret (SEC-12,
   `task bootstrap:e1c`; SOPS/KSOPS ownership lands with E1d).

## Follow-ups owned by other lanes (NOT this directory)

- Trivy CI gate (REQ-E1c-S02-*), digest pinning + `hack/verify-image-digests.sh`
  (REQ-E1c-S03-01). Cosign signing itself landed keyless via
  `showcase-image.yaml` (section above) — remaining: first green main run,
  then the Enforce flip + un-skip its Chainsaw case.
- Helm grandchildren (`kube-prometheus-stack`, `loki`, `alloy`,
  `blackbox-exporter`) still declare `project: default` in
  `deploy/observability/` + `deploy/monitoring/blackbox/` — flip them to
  the `observability` project (they were outside the cutover lane's file
  boundary).
- Observability securityContext hardening (review P2-2) — would let the
  `alloy*` exclude shrink if Alloy ever drops root.
- KSOPS landed with E1d (repo-server plugin + `deploy/secrets/**` render
  chain); remaining: SOPS ownership of `grafana-admin` (still the
  imperative `bootstrap:e1c` random Secret — moving it also requires a
  Grafana restart to re-read the env, which crosses the observability
  lane's boundary; see openspec/changes/e1d-identity-keycloak-dex/tasks.md).
- e1e-smoke namespace teardown (review P2-5) — would let the `e1e-smoke`
  excludes disappear.

# Getting Started — local kind platform

Reproducible path from a clean workstation to a demo-ready `kind-kaddy-dev`
cluster. Follow top to bottom. Every command uses the **isolated** kubeconfig at
`.state/kubeconfig` — never merge into an ambient shared kubeconfig.

Deeper substrate notes: [local-substrate-handoff.md](runbooks/local-substrate-handoff.md).
Website claims: [website-self-service.md](runbooks/website-self-service.md).

### Reviewer artifacts (honest status)

| Artifact | Status |
| --- | --- |
| Slidev deck (`task deck:build`) | Available locally / CI `deck` workflow |
| Scorecard GitHub Pages (`https://platformrelay.github.io/Kaddy/`) | **Unavailable** / not yet published until Pages is enabled on the repo |
| This guide + `task demo*` | Available after the bring-up below |

---

## Prerequisites (pinned)

| Tool | Notes |
| --- | --- |
| [Task](https://taskfile.dev) | `task --version` |
| `kind`, `kubectl`, `helm` | kind node image pinned in `hack/cluster/kind/cluster.yaml` |
| Container runtime | Docker Desktop, Colima, or Podman — required for `task cluster:up` |
| `yq`, `curl`, `jq` | smoke / demo helpers |
| Optional: `argocd` CLI | break-glass password + app sync |

No cloud credentials are required for phase 1.

---

## 1. Bring up the isolated substrate

```bash
cd /path/to/Kaddy
task cluster:up
export KUBECONFIG="$PWD/.state/kubeconfig"
kubectl config use-context kind-kaddy-dev
kubectl get nodes
```

`task cluster:up` is **idempotent**. It creates only the `kaddy-dev` kind cluster
and the `kind-kaddy-dev` context in `.state/kubeconfig`. It never writes the
ambient shared kubeconfig.

If the kind API port drifted after a runtime restart:

```bash
kind export kubeconfig --name kaddy-dev --kubeconfig "$PWD/.state/kubeconfig"
```

Readiness (substrate):

```bash
task test:smoke:e1e
```

---

## 2. Bootstrap the platform (dependency order)

Run in this order. Each bootstrap task refuses non-`kind-kaddy-dev` contexts.

```bash
export KUBECONFIG="$PWD/.state/kubeconfig"

# E1 — Argo CD + Gateway NodePort 30443 (kind loopback mapping)
task bootstrap:argocd

# E1c — random Grafana admin Secret (before observability sync needs it)
task bootstrap:e1c

# E3 — app-of-apps (children sync from main)
task bootstrap:e3

# E6 — Crossplane + Website XRD / demo claim registration
task bootstrap:e6

# E7 — Argo Rollouts + mulligan workloads
task bootstrap:e7
```

Optional identity (Dex + KSOPS) when you have an age key and GitHub OAuth app:

```bash
task bootstrap:e1d   # needs SOPS_AGE_KEY_FILE / ~/.config/sops/age/keys.txt
```

### Readiness checks

Wait until Applications are Synced/Healthy, then prove the Website claim:

```bash
kubectl -n argocd get applications
# expect Synced / Healthy for root, platform-core, observability, workloads, …

kubectl -n websites get website putting-green
task test:smoke:e4    # clubhouse HTTPS through the real Cilium Gateway
task test:smoke:e6    # Website claim → composed workload + TLS route + ServiceMonitor
```

Rerunning this Getting Started path is **idempotent** — bootstrap tasks and
`task cluster:up` reconcile drift without requiring teardown first.

---

## 3. Service access catalogue

Honest local access only. **Do not** curl Cilium LB-IPAM addresses from macOS
(they are not host-routable). **Do not** `kubectl port-forward` selectorless
`cilium-gateway-*` Services — they have no pods to attach to. Use the kind
NodePort mappings, explicit backend port-forwards, or in-cluster smoke tasks.

| Surface | Purpose | Canonical URL / CLI | Local access / verify | Auth source | Path |
| --- | --- | --- | --- | --- | --- |
| Argo CD | GitOps UI + Applications | `https://127.0.0.1:30443/applications` | kind NodePort `30443` (Gateway + HTTPRoute); accept local CA once | `argocd admin initial-password -n argocd` (Secret; do not commit) or Dex when E1d is wired | **Cilium Gateway** |
| clubhouse | Sample site (brief tenant) | `https://clubhouse.kaddy.local/` | Verify via `task test:smoke:e4` (real TLS edge, in-cluster). Direct-backend preview (bypasses Gateway): `kubectl -n gateway port-forward deploy/clubhouse 8080:8080` → `http://127.0.0.1:8080/` — label this preview **not** the edge | n/a (public lab content) | **Gateway** (canonical) / port-forward (preview) |
| Website demo | Composed claim `putting-green` | `https://clubhouse.kaddy.local/putting-green/` | `task test:smoke:e6` | n/a | **Gateway** |
| Grafana | Dashboards + alert visibility | `http://127.0.0.1:23000/` | `kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana "${E5_GRAFANA_PORT:-23000}:80"` | Secret `monitoring/grafana-admin` (`admin-user` / `admin-password`) — derive with `kubectl … jsonpath`, never print into git | port-forward |
| Prometheus | PromQL / targets | `http://127.0.0.1:29090/` | `kubectl -n monitoring port-forward svc/kps-prometheus "${E5_PROM_PORT:-29090}:9090"` | none (local PF) | port-forward |
| Alertmanager | Firing / resolved alerts | `http://127.0.0.1:29093/` | `kubectl -n monitoring port-forward svc/kps-alertmanager "${E5_AM_PORT:-29093}:9093"` | none (local PF) | port-forward |
| mulligan | Progressive delivery | CLI + HTTPRoute weights | `task demo` (canary weights); abort/rollback is Act 4 in [Demo](#demo); observe `kubectl -n mulligan get httproute,rollout` | n/a | Gateway plugin + CLI |

**Crossplane** is API-only (`kubectl get xrd,composition,website -A`) — there is
no browser URL.

Credential helpers (print locally if needed; never commit output):

```bash
# Grafana
kubectl -n monitoring get secret grafana-admin \
  -o jsonpath='{.data.admin-user}' | base64 -d; echo
kubectl -n monitoring get secret grafana-admin \
  -o jsonpath='{.data.admin-password}' | base64 -d; echo

# Argo CD break-glass (when Dex is not yet used)
argocd admin initial-password -n argocd
```

---

## Demo

Record a healthy **baseline**, then run the acts in order. Each act lists what to
show, expected duration, success signal, and a shorter **fallback**.

### Baseline (before Act 1)

```bash
export KUBECONFIG="$PWD/.state/kubeconfig"
kubectl -n argocd get applications
kubectl -n websites get website putting-green
kubectl -n gateway get deploy/clubhouse
```

Success: Applications Synced/Healthy; Website Ready; clubhouse replicas ≥ 1.
Duration: ~30s. Fallback: re-run the bootstrap block above.

### Act 1 — Website claim path

Show: `Website` → composed Deployment/Service/HTTPRoute/ServiceMonitor; path
served at `https://clubhouse.kaddy.local/putting-green/`.

```bash
task test:smoke:e6
kubectl -n websites describe website putting-green
```

Duration: ~1–2 minutes. Success: smoke exits 0; composed resources Ready.
Fallback: `kubectl -n websites get website,deploy,httproute,servicemonitor` and
see [website-self-service.md](runbooks/website-self-service.md).

### Act 2 — marshal fire / resolve

Show: serve → scrape → `ClubhouseDown` firing in Alertmanager → restore → resolve.

```bash
# optional: keep AM visible
kubectl -n monitoring port-forward svc/kps-alertmanager "${E5_AM_PORT:-29093}:9093" &
task demo:fire
```

Duration: ~3–6 minutes (`for: 1m` + scrape/eval). Success: script prints firing
then resolved; Alertmanager briefly shows `ClubhouseDown`.
Fallback: `task test:smoke:e5` (bundle) or inspect PrometheusRule
`marshal.http` only.

### Act 3 — mulligan progressive delivery

Show: blue/green promotion + live canary HTTPRoute weight shifts.

```bash
task demo
kubectl -n mulligan get httproute mulligan -o yaml | yq '.spec.rules[0].backendRefs'
```

Duration: ~2–4 minutes. Success: `task demo` exits 0; weights move
100/0 → 20 → 50 → 100.
Fallback: `kubectl -n mulligan get rollout` and narrate from
[ADR-0201](adr/0201-rollouts-blue-green-canary.md).

### Act 4 — abort rollback (chaos)

Show: failed canary abort → stable-weight rollback.

```bash
task demo:chaos
```

Duration: ~1–3 minutes. Success: canary HTTPRoute weight returns to `0` after abort.
Fallback: narrate `hack/demo/mulligan-abort.sh` and show Rollout status only.

---

## Troubleshooting and recovery

### Occupied local ports

Override the collision-avoiding defaults:

```bash
export E5_GRAFANA_PORT=23100
export E5_PROM_PORT=29190
export E5_AM_PORT=29193
# demo:fire also honors PROM_PORT / AM_PORT
export PROM_PORT=29190 AM_PORT=29193
```

### Interrupted `demo:fire`

Restore the clubhouse replica and tear down stale port-forwards:

```bash
kubectl -n gateway scale deploy/clubhouse --replicas=1
pkill -f 'port-forward.*(kps-prometheus|kps-alertmanager|kube-prometheus-stack-grafana)' || true
```

### Interrupted mulligan / bad weights

Re-run the abort path to snap stable weights, or re-apply workloads:

```bash
task demo:chaos
# or
kubectl -n mulligan apply -f deploy/workloads/mulligan/
```

### Non-destructive diagnostics

```bash
kubectl -n argocd get applications
kubectl -n gateway get gateway,httproute,certificate,deploy
kubectl -n monitoring get prometheus,alertmanager,pods
kubectl get events -A --field-selector type=Warning | tail -40
```

### Full teardown

Stops temporary port-forwards first, then destroys the kind cluster (no hidden
local state beyond the container runtime):

```bash
pkill -f 'kubectl.*port-forward' || true
task cluster:down
```

After teardown, the Getting Started path from §1 is safe to rerun (idempotent).

---

## Related

- Five-minute reviewer path: repo-root `README.md` (not part of this MkDocs tree)
- Scorecard evidence: repo-root `evidence/README.md`
- Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)

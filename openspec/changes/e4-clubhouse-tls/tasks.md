# Tasks — E4

- [x] clubhouse Deployment/Service (REQ-E4-S01-*) — `deploy/workloads/clubhouse/`
      (nginx-unprivileged pinned, non-root, ConfigMap landing page, Service :8080).
      Verified live: Deployment Ready, Service port 8080. Chainsaw
      `tests/chainsaw/gateway/clubhouse-ready.yaml` PASSES live.
- [x] HTTPRoute / (REQ-E4-S02-*) — `deploy/gateway/` platform Gateway (GatewayClass
      cilium, HTTPS+HTTP listeners, TLS from clubhouse-tls) + HTTPRoute `/ → clubhouse`.
      Fills the E2-S02 deferred "platform Gateway". Gateway Programmed, HTTPRoute
      Accepted/ResolvedRefs; `/` returns 200 with `clubhouse` marker. Chainsaw
      `tests/chainsaw/gateway/root-path-200.yaml` PASSES live.
- [x] TLS Certificate (REQ-E4-S03-01/02/03/05) — **kind-honest reinterpretation.**
      Issued `clubhouse-tls` via the in-cluster `kaddy-local-ca` ClusterIssuer
      (`deploy/cert-manager/clubhouse-certificate.yaml`, renewBefore=30d). Smoke curls
      HTTPS through the Gateway with `--cacert` and **NO `-k`** → `HTTP 200 verify=0`.
      HTTP→HTTPS 301 redirect (S03-03) live. Renewal chainsaw
      `tests/chainsaw/tls/certificate-renewal.yaml` PASSES live.
- [ ] **DEFERRED — LE staging→prod (REQ-E4-S03-04):** NOT issuable on kind (no public
      inbound HTTP-01). Manifests captured, documented cloud-only, and excluded from
      GitOps sync (non-recursed `deploy/cert-manager/cloud-only/`). Smoke
      `tests/smoke/e4-s03-04.sh` is a documented SKIP on kind (runs on a real cloud
      edge via `E4_LE_PROD_HOST`). No real LE prod cert was claimed.
- [x] Chainsaw `tests/chainsaw/{gateway,tls}/` — three suites authored + verified
      PASSING against the live kind-kaddy-dev cluster. `skip: true` in CI only: the
      ephemeral chainsaw kind cluster lacks Cilium/Gateway API/kaddy-local-ca/clubhouse
      (installs cert-manager only). Un-skip = infra follow-up (`.github/workflows`,
      outside the E4 lane boundary).
- [x] Gate: `hack/smoke/https-clubhouse.sh` — verified HTTPS through the Cilium edge,
      chain verified via `--cacert` (NO `-k`), `HTTP 200 verify=0`, body marker
      `clubhouse`. Curled in-cluster (macOS loopback maps only 30080/30443, both held;
      Gateway 443 NodePort pinned to a free 30444).
- [x] `task test:smoke:e4` (+ `task bootstrap:e4`) added to Taskfile.yml.

# E1g cloud-edge LIVE — first public HTTPS URL with a real cert (2026-07-18)

Operator goal: a standing gridscale demo with **live URLs + real certs** for a recorded
presentation. This captures the working cloud-edge recipe proven live, so the config is durable
(to be codified into GitOps overlays on `gsk-cloud-edge`).

## PROVEN LIVE

- **<https://argocd.lab.platformrelay.dev/>** → **HTTP 200**, `<title>Argo CD</title>`, TLS chain
  **verifies without `-k`** (publicly-trusted Let's Encrypt **prod** cert
  `CN=argocd.lab.platformrelay.dev`, issuer `Let's Encrypt CN=YR1`, valid Jul 18 → Oct 16 2026).

## Architecture (differs from the kind path — GSK-specific findings)

1. **GSK's managed Cilium (v1.15.1, kube-proxy-replacement=false, no cilium-operator) CANNOT serve
   Gateway API.** The committed `gatewayClassName: cilium` edge is dead on GSK. → use a self-contained
   Gateway API controller. Operator chose **Traefik v3.x** (D-042).
2. **GSK HAS a working service-LoadBalancer CCM** (contradicts prior research): a `type=LoadBalancer`
   Service auto-provisions a gridscale loadbalancer + public IP. Traefik's Service got
   **`185.241.34.187`** (:80/:443). No manual NodePort/LBaaS wiring needed → collapses S05c/S05d.
3. GSK worker nodes have public IPs reachable from the internet (S05h security note — accepted risk).

## Recipe (imperative; to be codified to GitOps)

```bash
# 0. Node pool scaled to 2x (2c/4Gi) via gridscale API PATCH parameters.pools[0].count=2.
# 1. Gateway API CRDs — v1.5.1 STANDARD channel, BUT GSK is k8s 1.30 and the v1.5.1 TLSRoute CRD
#    uses the `isIP()` CEL fn (added in k8s 1.31) so it REJECTS. Strip isIP/isCIDR/isURL CEL rules
#    then apply, so tlsroutes serves v1 (Traefik 3.7.6 watches TLSRoute+BackendTLSPolicy at v1
#    UNCONDITIONALLY; a stale v1alpha2 tlsroutes CRD blocks WaitForCacheSync → no reconciliation).
kubectl apply --server-side --force-conflicts -f <v1.5.1 standard-install, isIP CEL rules stripped>
kubectl get --raw /apis/gateway.networking.k8s.io/v1/tlsroutes   # must be 200

# 2. Traefik (helm traefik/traefik v41.0.2 = app v3.7.6), namespace traefik:
#    providers.kubernetesGateway.enabled=true; kubernetesIngress.enabled=false; gateway.enabled=false;
#    service.type=LoadBalancer (CCM gives public IP). Entrypoints stay DEFAULT (web:8000 / websecure:8443)
#    — do NOT bind privileged 80/443 in-container (NET_BIND_SERVICE crashes on GSK). The Service maps
#    external 80->8000 / 443->8443. Gateway listeners MUST use port 8443 (Traefik matches listener.port
#    to the ENTRYPOINT port, not the Service port).

# 3. cert-manager (helm jetstack) + Cloudflare DNS-01 ClusterIssuers (staging + prod), token from
#    $CLOUDFLARE_TOKEN in a Secret (NEVER committed). DNS-01 (not HTTP-01) so issuance needs no inbound.

# 4. Per host: cert-manager Certificate (secret in ns traefik) + Gateway listener (HTTPS, port 8443,
#    hostname, certificateRefs->secret, allowedRoutes from All) + HTTPRoute (in app ns, parentRef the
#    Gateway listener by sectionName, backendRef the app Service). Cloudflare A record host->185.241.34.187
#    (proxied=false so the cert is real end-to-end).

# 5. argocd: install upstream pinned (v3.4.5). MUST set argocd-cmd-params-cm server.insecure=true AND
#    restart argocd-server (else 307 HTTP->HTTPS redirect LOOP behind the TLS-terminating gateway).
```

## Live objects (this cluster)

- GSK cluster `e2ac442d-7026-4577-8f24-086cfea61be5`, 2 nodes Ready (185.241.34.168 / .180).
- Traefik LB public IP `185.241.34.187`; GatewayClass `traefik` Accepted; Gateway `clubhouse`
  (ns traefik) Programmed; HTTPRoute `argocd` (ns argocd) Accepted/ResolvedRefs.
- ClusterIssuers `letsencrypt-{staging,prod}-dns01` Ready; secret `cloudflare-api-token` (ns cert-manager).
- Cloudflare A records (zone platformrelay.dev): argocd/grafana/demo.lab → 185.241.34.187.

## Update — complete caddy-mvp (Argo Rollouts canary) LIVE (2026-07-18, E1g-S05i)

The full **caddy-mvp** (not just the caddy-demo landing page) now serves publicly:

- **<https://caddy.lab.platformrelay.dev/>** → **HTTP 200** (`curl -w '%{http_code} %{ssl_verify_result}'`
  = `200 0` — publicly-trusted LE **prod** cert `caddy-tls`, Ready=True, notAfter 2026-10-16, verifies
  without `-k`). Backend is the showcase image `ghcr.io/platformrelay/kaddy-showcase:0.1.1`.

### What made it work (the delta over the argocd/grafana/demo edge)

1. **argo-rollouts gatewayAPI plugin ARCH.** `deploy/rollouts/config.yaml` pins the plugin binary to
   `gatewayapi-plugin-linux-arm64` (correct for the local **kind** Apple-Silicon cluster). GSK worker
   nodes are **amd64** (Ubuntu 22.04 / x86-64) → the arm64 binary aborts with `exec format error` and
   stalls ALL Rollout reconciliation (no canary weight is ever shifted). Fix: patch the
   `argo-rollouts-config` ConfigMap to `...-linux-amd64` of the SAME pinned release (v0.16.0) and restart
   the controller. Live-verified on the cluster (CM `data.location` = `...-linux-amd64`; controller
   `quay.io/argoproj/argo-rollouts:v1.9.0`). Codified as `hack/gsk/rollouts-plugin-amd64.sh` (NOT a
   committed second ConfigMap — ArgoCD forbids two same-named resources in one App, and the edge runs no
   ArgoCD Application anyway). Kind arm64 default left untouched.
2. **caddy-mvp cloud HTTPRoute + edge.** Live `caddy-mvp` HTTPRoute (ns caddy-mvp) is parented by the
   `clubhouse` Gateway, sectionName `https-caddy`, host `caddy.lab.platformrelay.dev`, backendRefs
   `caddy-origin-stable` weight 100 / `caddy-origin-canary` weight 0 (both port 8080). Extracted +
   codified into `deploy/gateway/cloud-only/`: the `https-caddy` listener (:8443, cert `caddy-tls`) on the
   clubhouse Gateway, the `caddy-tls` Certificate (DNS-01 prod), and the caddy-mvp HTTPRoute. Kind's
   caddy-mvp (cilium Gateway, `caddy-mvp.kaddy.local`) is UNCHANGED — the cloud route is a name/ns twin
   applied only imperatively on the edge (no ArgoCD App there, so no conflict).

### Live objects (this cluster, read-only extraction)

- Namespaces: `argo-rollouts`, `caddy-mvp`, `caddy-demo` all Active. Nodes 2× amd64 Ready
  (185.241.34.168 / .180).
- `caddy-mvp` Services: `caddy-origin`, `caddy-origin-stable`, `caddy-origin-canary`, `nginx-proxy-active`,
  `nginx-proxy-preview` (all ClusterIP :8080). Rollout `caddy-origin` image
  `ghcr.io/platformrelay/kaddy-showcase:0.1.1`.
- `clubhouse` Gateway now has FOUR HTTPS :8443 listeners: `https-argocd`, `https-grafana`, `https-demo`,
  **`https-caddy`** (cert `caddy-tls`). HTTPRoute `caddy-mvp` Accepted/ResolvedRefs on `https-caddy`.
- `argo-rollouts-config` CM `trafficRouterPlugins.location` = `...gatewayapi-plugin-linux-amd64` (v0.16.0);
  the last-applied annotation still shows the arm64 kind default (proves this was a live arch patch).

### caddy-demo landing page — intentionally live-only

The `caddy-demo` namespace serves a small static links page (a plain `caddy` Deployment + `caddy-index`
ConfigMap, ClusterIP :80, on `demo.lab`). It is a throwaway presentation aid, not a platform artifact —
left **intentionally live-only** (NOT codified). Its edge (listener `https-demo` + `demo-tls` + the
`caddy-demo` HTTPRoute) is already codified by S05e; only the ConfigMap HTML is ephemeral.

## Remaining for the full demo

- Teardown to stop the meter: `task e1g:down` (+ delete the CCM loadbalancer + node pool).

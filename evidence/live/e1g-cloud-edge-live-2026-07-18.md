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

## Remaining for the full demo

- Deploy grafana + the caddy demo app (+ argo-rollouts dep) and add their HTTPRoute+Certificate+listener
  (grafana.lab / demo.lab) — best via the app-of-apps cloud overlay so the argocd UI shows the GitOps story.
- Codify all of the above into `deploy/**/cloud-only/` overlays + a Traefik GitOps app on `gsk-cloud-edge`.
- Teardown to stop the meter: `task e1g:down` (+ delete the CCM loadbalancer + node pool).

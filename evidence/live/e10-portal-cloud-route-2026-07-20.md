# E10 portal cloud HTTPRoute LIVE — portal.lab on clubhouse (2026-07-20)

Lane `portal-cloud-httproute` (`feat/portal-cloud-httproute` @ `f2fd87b`).

## PROVEN LIVE

- **<https://portal.lab.platformrelay.dev/>** → **HTTP 200**, `<title>kaddy Portal</title>`,
  TLS chain **verifies without `-k`** (publicly-trusted Let's Encrypt **prod** cert
  `CN=portal.lab.platformrelay.dev`, issuer `Let's Encrypt CN=YR2`,
  valid Jul 20 → Oct 18 2026).
- `ssl_verify_result=0` via:
  ```bash
  curl -w '%{http_code} %{ssl_verify_result}\n' \
    --resolve portal.lab.platformrelay.dev:443:185.241.34.187 \
    https://portal.lab.platformrelay.dev/
  # → 200 0
  ```
- Public resolvers (`dig @1.1.1.1` / `@8.8.8.8` / `@ns3.cloudflare.com`) return
  `185.241.34.187`. Some local resolvers lag; use `--resolve` or `1.1.1.1` until TTL clears.

## What was applied

| Object | Location | Notes |
| --- | --- | --- |
| Gateway listener `https-portal` | `clubhouse` / ns `traefik` | hostname `portal.lab…`, port **8443**, cert Secret `portal-tls` |
| Certificate `portal-tls` | ns `traefik` | DNS-01 prod `letsencrypt-prod-dns01`; Ready=True ~82s |
| HTTPRoute `portal` | ns `portal` | sectionName `https-portal` → Service `backstage:7007`; Accepted+ResolvedRefs |
| Cloudflare A | `portal.lab.platformrelay.dev` | → `185.241.34.187`, **proxied=false**, ttl 300 (record id `94a9cc7af434ad6c1676b0c8977e73f2`) |

Codified in `deploy/gateway/cloud-only/{gateway-clubhouse,certificates,httproutes,README}.yaml`
(+ `hack/gsk/edge-up.sh` A-record hint + offline gate `tests/smoke/e1g-portal-cloud-route.sh`).

## nip.io left in place (cutover follow-up)

Traefik `IngressRoute` `portal/backstage` matching
`Host(\`backstage.185.241.34.187.nip.io\`)` remains; `http://backstage.185.241.34.187.nip.io/`
still returns **200**. Delete that IngressRoute in a follow-up once operators are on
`portal.lab` only (INBOX DECIDED C-lite).

## Reproduce

```bash
export KUBECONFIG=.state/gsk/kubeconfig
export KADDY_GSK_CONTEXT="$(kubectl config current-context)"
kubectl apply -f deploy/gateway/cloud-only/
# CF A already present; if recreating:
#   type=A name=portal.lab content=185.241.34.187 proxied=false
kubectl wait --for=condition=Ready certificate/portal-tls -n traefik --timeout=180s
curl -fsS -o /dev/null -w '%{http_code} %{ssl_verify_result}\n' \
  --resolve portal.lab.platformrelay.dev:443:185.241.34.187 \
  https://portal.lab.platformrelay.dev/
```

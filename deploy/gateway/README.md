# gateway (app-of-apps child target)

Tracked-but-empty directory that the `gateway` child Application
(`deploy/apps/gateway.yaml`) syncs. Cluster-level Gateway API CRDs, the Cilium
GatewayClass and the LB-IPAM pool are installed at E1e bootstrap and are **not**
owned here. E2 hangs gateway-layer `Gateway` / `HTTPRoute` manifests off this
path. Argo CD tolerates a directory with no renderable manifests (it syncs to an
empty resource set), so this README keeps the path present in Git.

# E6g live proof — provider-gridscale actuates real gridscale infra (2026-07-17)

End-to-end proof of the E6g self-service cloud-API path, using the built provider (the sibling
provider-gridscale repo's packaging step, completed this session):

1. **Built the provider xpkg** from `../provider-gridscale` (`make build`, DOCKER_HOST=colima):
   `provider-gridscale-v0.1.1-24.g60b9e8f.xpkg` (+ arm64 controller image). Cleared the prior
   'no built xpkg' blocker.
2. **Installed it in Crossplane 2.3.3** on the local kind cluster via a local registry
   (kind-registry, containerd config_path + insecure certs.d). Provider **Healthy**, **69
   gridscale CRDs** registered.
3. **ClusterProviderConfig** + a `gridscale-creds` Secret (real creds, never committed).
4. **A `Network` MR provisioned on real gridscale** — `Ready=True Synced=True` (the provider
   actuated the live gridscale API), then **deleted** — tenant API-audited clean (no custom
   networks/servers/storages remain; only gridscale account-default networks).

Proves E6g-S02 (provider install + ProviderConfig) and the core of E6g-S03 (the provider actuates
real gridscale infra) LIVE. Remaining (deferred): the Website Composition → gridscale_server VM
(E6g-S03 full) + /legacy routing on the VM (E6g-S04).

# Tasks — E6g provider-gridscale

- [x] E6g-S01: Upjet generate + build provider-gridscale — *codegen DONE in sibling `../provider-gridscale` (package/crds/*, package/crossplane.yaml); xpkg build/push DEFERRED to live cycle*
- [x] E6g-S02: Install provider + ProviderConfig — offline manifests + **LIVE-PROVEN 2026-07-17**: built the provider xpkg from `../provider-gridscale` (`make build`), installed it in Crossplane 2.3.3 on kind via a local registry — Provider **Healthy**, 69 gridscale CRDs; ClusterProviderConfig + real creds Secret; a `Network` MR provisioned on real gridscale (`Ready=True`) then deleted (tenant clean). Evidence: `evidence/live/e6g-provider-2026-07-17.md`.
- [~] E6g-S03: Extend Composition for gridscale_server nginx — *offline-complete: `deploy/crossplane/composition-website-gridscale.yaml` composes Server (1 core/1 GiB nginx VM, cloud-init page+/metrics) + Network/IPv4/Storage; variant-selected 2nd Composition (in-cluster path untouched). MRs validate vs sibling CRDs. **Provider proven to actuate real gridscale infra (S02 Network MR)**; the full Website-XR→gridscale_server VM provision still DEFERRED*
- [ ] E6g-S04: Re-verify /legacy + chaos on real VM — *live cycle only (demo claim staged at `deploy/examples/gridscale-website/`)*
- [~] Gate: Chainsaw + gridscale smoke — *offline gate `task test:smoke:e6g` EXIT 0 (structural + kubeconform); live Chainsaw `tests/chainsaw/e6g/gridscale-website-composed.yaml` authored (skip:true until provider installed)*

Legend: [x] done · [~] offline-complete, live-proof pending · [ ] not started

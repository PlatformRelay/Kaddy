# Tasks — E6g provider-gridscale

- [x] E6g-S01: Upjet generate + build provider-gridscale — *codegen DONE in sibling `../provider-gridscale` (package/crds/*, package/crossplane.yaml); xpkg build/push DEFERRED to live cycle*
- [~] E6g-S02: Install provider + ProviderConfig — *offline-complete: `deploy/crossplane/provider-gridscale.yaml` (Provider, TODO(live) pkg placeholder) + `providerconfig-gridscale.yaml` (ClusterProviderConfig + inert creds Secret template, JSON-blob shape); wired into the crossplane GitOps app. Live install DEFERRED (xpkg not built)*
- [~] E6g-S03: Extend Composition for gridscale_server nginx — *offline-complete: `deploy/crossplane/composition-website-gridscale.yaml` composes Server (1 core/1 GiB nginx VM, cloud-init page+/metrics) + Network/IPv4/Storage; variant-selected 2nd Composition (in-cluster path untouched). MRs validate against sibling CRDs (kubeconform). Real VM provision DEFERRED to live cycle*
- [ ] E6g-S04: Re-verify /legacy + chaos on real VM — *live cycle only (demo claim staged at `deploy/examples/gridscale-website/`)*
- [~] Gate: Chainsaw + gridscale smoke — *offline gate `task test:smoke:e6g` EXIT 0 (structural + kubeconform); live Chainsaw `tests/chainsaw/e6g/gridscale-website-composed.yaml` authored (skip:true until provider installed)*

Legend: [x] done · [~] offline-complete, live-proof pending · [ ] not started

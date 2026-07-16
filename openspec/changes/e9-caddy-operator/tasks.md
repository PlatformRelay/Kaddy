# Tasks — E9

Design phase (complete):

- [x] proposal.md
- [x] design.md
- [x] specs/operator/spec.md
- [x] ADR-0401

Implementation (optional):

- [x] E9-S01 kubebuilder init + CRD types (`operator/`, envtest-backed API-shape + validation tests)
- [x] E9-S02 Caddy reconciler + Admin client port (`internal/caddyadmin` + reconcilers, fake admin server, race on)
- [x] E9-S03 CaddySite + observability bundle
- [x] Gate: envtest + `task test` / `task test:operator` wiring

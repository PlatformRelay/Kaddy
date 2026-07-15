# Tasks — E1c

- [ ] Chainsaw: default-deny + unauthorized ingress (REQ-E1c-S01-*)
- [ ] Netpol templates in `deploy/security/`
- [ ] Trivy CI job (REQ-E1c-S02-*)
- [ ] Digest verify script (REQ-E1c-S03-01)
- [ ] Kyverno verifyImages + Chainsaw (REQ-E1c-S03-02)
- [ ] ExternalSecret pattern (REQ-E1c-S04-*)
- [ ] `.sops.yaml` + encrypted `deploy/secrets/identity/dex-github.enc.yaml` (REQ-E1c-S05-*)
- [ ] Argo CD KSOPS plugin wiring (REQ-E1c-S05-02; pairs with E3-S01-03)
- [ ] Gate: `task test:chainsaw -- tests/chainsaw/security`

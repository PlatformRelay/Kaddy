# identity (app-of-apps child target — DEFERRED)

Tracked-but-empty directory referenced by the `identity` child Application
(`deploy/apps/identity.yaml`). Identity (Dex + GitHub OIDC connector) is
**deferred** because it needs the KSOPS repo-server plugin to decrypt
`deploy/secrets/identity/*.enc.yaml` at render time (REQ-E3-S01-03, ADR-0110),
which is not on the demoable path tonight. The Application has no automated sync
and this directory stays empty until KSOPS lands.

# Change: E1g — Gridscale day-0 (phase 2)

## Why

Promote the proven GitOps platform from driving-range to **gridscale-native** infrastructure (GSK,
LBaaS, Object Storage) for the employer-facing demo.

## What

- Terramate stacks: network, GSK cluster, object-storage state backend
- LBaaS entry + kubeconfig handoff
- Re-sync same ArgoCD app-of-apps onto GSK
- Update Dex issuer URL / GitHub OAuth callback for public LBaaS domain

## Non-goals

- Rebuilding platform manifests (reuse phase-1 GitOps)
- Upjet Crossplane provider (E6g)

## Gate

E3–E7 green on driving-range (D-017).

## Links

- ADR-0102, ADR-0302 · D-013, D-015
- Stories E1g-S01 … E1g-S06

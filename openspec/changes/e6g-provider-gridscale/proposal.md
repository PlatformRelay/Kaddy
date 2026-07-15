# Change: E6g — Upjet provider-gridscale (phase 2)

## Why

Complete the self-service story with native Crossplane CRDs for gridscale infra — the employer signal
(D-016). Phase 1 proved the Website XRD on driving-range without cloud API coupling.

## What

- Upjet-generated thin `provider-gridscale`
- Extend Website Composition to provision `gridscale_server` nginx VM
- Re-verify `/legacy` routing against real VM

## Gate

E1g complete (GSK cluster + gridscale creds in cluster).

## Links

- ADR-0105 · D-016
- Stories E6g-S01 … E6g-S04

---
theme: default
title: kaddy — Website-as-a-Service
info: |
  Gridscale Platform Engineer exercise showcase.
  Design phase deck — expand in E12.
---

# kaddy

A caddie for your websites

Security-first · spec-driven · Kubernetes-native

---

# What it is

- Internal **Website-as-a-Service** platform
- One claim → monitored, TLS-terminated site
- Exercise deliverables = one tenant (**clubhouse**)

---

# Architecture

See live diagram: `docs/ARCHITECTURE.md`

- **GSK** managed Kubernetes on gridscale (phase 2)
- **driving-range** local Talos (phase 1)
- **ArgoCD** GitOps
- **Caddy** Gateway API
- **Prometheus** gates **mulligan** rollouts

---

# Security-first

- Default-deny **NetworkPolicies**
- **Trivy** + **cosign** + Kyverno
- **Labels everywhere** (ADR-0301)
- Replayable **audits** in `docs/audits/`

---

# Demo cues (E7 / E8)

1. Blue/green — bad green never promoted
2. Canary — analysis fails → rollback → **marshal** alert
3. **scorecard** HTML report published

`task demo` (when implemented)

---

# Questions?

- Repo: github.com/PlatformRelay/Kaddy
- Traceability: `docs/requirements/exercise-traceability.md`

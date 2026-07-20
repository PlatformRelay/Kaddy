# AGENTS.md — kaddy

Entry point for humans and automated assistants working on **kaddy**: a security-first,
spec-driven internal developer platform for monitored, TLS-terminated websites on Kubernetes
(Cilium Gateway API · kind local substrate · ArgoCD · Crossplane · Prometheus · Argo Rollouts).

## Documentation map

| | Document | What it covers |
| --- | --- | --- |
| 🎯 | [README.md](README.md) | Pitch, reviewer paths, status |
| 🎯 | [docs/ROADMAP.md](docs/ROADMAP.md) | Phases 0–2, epics E1–E12, build order |
| 🎯 | [docs/requirements/exercise-traceability.md](docs/requirements/exercise-traceability.md) | Gridscale brief → epic mapping |
| 🏗️ | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Components, data flows, security boundaries |
| 🏗️ | [docs/adr/README.md](docs/adr/README.md) | Architecture decision records |
| 🔒 | [docs/audits/README.md](docs/audits/README.md) | Replayable security/compliance audit procedure |
| 📋 | [docs/development/testing.md](docs/development/testing.md) | Test pyramid, Chainsaw, TDD gates |
| 📋 | [docs/development/DEVELOPMENT.md](docs/development/DEVELOPMENT.md) | Gates, worktrees, **spec-driven** flow, skills pointer |
| 📋 | [skills/README.md](skills/README.md) | Agent skills catalogue (loop, review, audit, handover, …) |
| 📋 | [openspec/config.yaml](openspec/config.yaml) | OpenSpec conventions (OPSX workflow) |
| 🎬 | [slides/README.md](slides/README.md) | Slidev interview deck |
| 📊 | [evidence/README.md](evidence/README.md) | Scorecard evidence harness |
| 🌩️ | `agent-context/reference/gridscale/` | **gridscale cloud API + provider notes** (Phase 2). Curated offline docs — read before touching GSK/LBaaS/Upjet. Gitignored. |
| 🌩️ | `references/README.md` | Cloned gridscale Terraform **examples** + **provider source/docs** (offline). Gitignored. |

## What kaddy is

**kaddy** is a minimal *Website-as-a-Service* platform: one self-service claim provisions a
monitored site behind Caddy with TLS, observability, and progressive delivery. The gridscale
hiring exercise is satisfied as one tenant of the platform — not as a one-off VM script.

Branded components (use in docs, not everywhere):

- **scorecard** — evidence harness (k6 + Prometheus/Alertmanager capture → HTML report)
- **mulligan** — blue/green + canary demo with automated rollback
- **marshal** — alerting pipeline (PrometheusRules + Alertmanager)

## Stack (target)

**Phase 1 (now):** local **kind + Cilium** substrate (E1e, D-025) → kaddy GitOps platform (driving-range Talos deferred to an optional maturity-contrast spike).  
**Phase 2 (deferred):** gridscale GSK + LBaaS + Upjet Crossplane.

| Layer | Phase 1 | Phase 2 |
| --- | --- | --- |
| Substrate | local kind + Cilium (E1e; single control-plane node) | GSK managed k8s (E1g) |
| Day-0 IaC | hack/cluster (kind bring-up) | Terramate on gridscale |
| Ingress | Cilium Gateway + LB-IPAM/L2 | LBaaS + Cilium (GSK default CNI) |
| Infra self-service | Crossplane Website XRD | + Upjet provider-gridscale (E6g) |
| GitOps | ArgoCD app-of-apps | Same manifests on GSK |
| Observability | kube-prometheus-stack + Loki | Same |
| Progressive delivery | Argo Rollouts + Gateway API | Same |
| Policy | Kyverno, NetworkPolicies | Same |
| Identity | Dex + GitHub OAuth | Same |

## Conventions

- **Commits:** `:gitmoji: <type>(<scope>): <summary>` — ASCII shortcode mandatory; no Unicode emoji;
  no AI co-author trailers; never modify git config.
- **TDD:** mandatory for implementation lanes (`GUIDELINES.md` in workspace `agent-context/`).
- **Labels:** mandatory core on every resource — see [ADR-0301](docs/adr/0301-resource-labeling-convention.md).
  No `dev`/`prod` environment key; use `track` (`stable` / `canary` / `preview`).
- **Sanitization:** never commit employer-specific names, internal policy IDs, or internal system
  references. Run `task scrub` before push.
- **Spec-driven:** implementation lanes reference an OpenSpec change under `openspec/changes/`.

## Gate commands

```bash
task verify        # lint + scrub + openspec + test:spec (REQ↔Test coverage)
task test:spec     # every REQ has **Test:** + **Verify:** paths
task test          # L0→L2 (tofu test, conftest, chainsaw) when implemented
task test:chainsaw # L2 only — requires cluster + chainsaw CLI
task test:scorecard # L4 evidence bundle (E8)
```

Full matrix: [docs/development/DEVELOPMENT.md](docs/development/DEVELOPMENT.md) · [docs/development/testing.md](docs/development/testing.md).

## Lab credentials (local only)

Operator secrets live in **`.envrc`** at repo root (gitignored). Copy from
[`.envrc.example`](.envrc.example); run `direnv allow`. **Never commit `.envrc`.**

| Variable | Purpose |
| --- | --- |
| `GRIDSCALE_API_KEY`, `GRIDSCALE_USER_UUID` | gridscale lab API (phase 2 / E1g) |
| `CLOUDFLARE_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` | DNS for **platformrelay.dev** (cert-manager DNS-01, external-dns, OpenTofu) |
| `GITHUB_APP_CLIENT_ID`, `GITHUB_APP_CLIENT_SECRET` | Dex GitHub connector (E1d) — callback `https://dex.platformrelay.dev/callback` |

**Lab domain:** `platformrelay.dev` — Dex issuer `https://dex.platformrelay.dev/`; other hostnames
use subdomains (e.g. `clubhouse.lab.platformrelay.dev`). DNS at Cloudflare.

Session handoff: [`agent-context/LAB-ACCESS.md`](agent-context/LAB-ACCESS.md) (gitignored — local coordination).

Day-0 is **local-first** on the **kind + Cilium** substrate (E1e; D-025 amends D-017); gridscale GSK lands in
phase 2 (E1g). See decisions.md D-013/D-015/D-016/D-017.

## Coordination (gitignored)

| Path | Role |
| --- | --- |
| `agent-context/LAB-ACCESS.md` | Lab creds location, provider env mapping, smoke tests |
| `agent-context/INBOX.md` | Decisions, reviews, PRs waiting on operator |
| `agent-context/decisions.md` | Append-only decision log |
| `agent-context/BACKLOG.md` | Private backlog detail behind ROADMAP |
| `agent-context/coordination/OPERATOR-BOARD.md` | Lanes in flight |

Run `/agent-loop` from the PlatformRelay workspace root targeting **kaddy** for implementation.

## Agent skills

Committed under [`skills/`](skills/) (see full catalogue in [`skills/README.md`](skills/README.md)).
Symlink into `.claude/skills/` for harnesses that expect that path — `.claude/` remains gitignored.

| Skill | When |
| --- | --- |
| [skills/pick-next-story/SKILL.md](skills/pick-next-story/SKILL.md) | Next backlog item without starting the loop |
| [skills/evidence-capture/SKILL.md](skills/evidence-capture/SKILL.md) | Run or document scorecard capture (E8) |
| [skills/kaddy-audit/SKILL.md](skills/kaddy-audit/SKILL.md) | Replayable security/compliance audit (E11) |
| [skills/agent-loop/SKILL.md](skills/agent-loop/SKILL.md) | Implementation loop → PR |
| [skills/agent-loop-auto/SKILL.md](skills/agent-loop-auto/SKILL.md) | Loop with auto-merge |
| [skills/agent-loop-local/SKILL.md](skills/agent-loop-local/SKILL.md) | Loop with local ff-merge |
| [skills/handover/SKILL.md](skills/handover/SKILL.md) | Session wrap-up + next-session prompt |
| [skills/retrospective/SKILL.md](skills/retrospective/SKILL.md) | End-of-session learnings into agent-context |
| [skills/replayable-audit/SKILL.md](skills/replayable-audit/SKILL.md) | Generic replayable health audit |
| [skills/write-story/SKILL.md](skills/write-story/SKILL.md) | INVEST stories / OpenSpec slices |
| [skills/tech-review/SKILL.md](skills/tech-review/SKILL.md) | Independent pre-merge review |

Plus: `design-architecture`, `brainstorm`, `grill-me`, `roast`, `security-review`,
`operator-inbox`, `merge-open-prs`, `changelog` — see the catalogue.

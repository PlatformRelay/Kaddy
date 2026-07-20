# Development — kaddy

## Prerequisites

- Task ([taskfile.dev](https://taskfile.dev))
- pre-commit (optional locally)
- OpenTofu + Terramate (for E1+ lanes)
- `kind`, `kubectl`, `helm` + a container runtime (podman/docker) — local substrate (D-025,
  [local-substrate-handoff.md](../runbooks/local-substrate-handoff.md)); `talosctl` only for the
  deferred driving-range spike
- [direnv](https://direnv.net/) (recommended) — loads lab credentials from `.envrc`

### Lab credentials

Copy `.envrc.example` → `.envrc`, then `direnv allow`. **Never commit `.envrc`.**

| Variable | Purpose |
| --- | --- |
| `GRIDSCALE_API_KEY`, `GRIDSCALE_USER_UUID` | gridscale lab (phase 2) |
| `CLOUDFLARE_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` | Cloudflare DNS for **platformrelay.dev** |
| `GITHUB_APP_CLIENT_ID`, `GITHUB_APP_CLIENT_SECRET` | Dex GitHub OAuth — see [github-oauth-dex.md](../runbooks/github-oauth-dex.md) |

Lab hostnames under `platformrelay.dev`. Dex: `https://dex.platformrelay.dev/` (callback
`/callback`). Operator details: `agent-context/LAB-ACCESS.md` (local, gitignored).

## Worktree discipline

Per PlatformRelay `AGENTS.md`: claim a lane on `agent-context/coordination/OPERATOR-BOARD.md`;
implement in an isolated worktree; one logical change per PR.

## Gates

```bash
task verify   # scrub + lint + openspec structure + spec coverage + fmt + terraform-docs drift
task scrub    # denylist only
task lint     # markdown + shellcheck
```

Implementation lanes add `task test` (L0–L2), promtool, and cluster integration checks per
story — see [testing.md](testing.md) for the full matrix and the CI workflows that run it.

The go-live standing-substrate policy (a standing live env is permitted when **recorded and
time-boxed** — D-042, `tests/meta/e1g-standing-policy.yaml`, surfaced by E1g-S07's soft
`task e1g:status` WARN) is **cost-governance, not a blocker**: the doc-truth guard only reddens
on an unreconciled unqualified "no standing env" absolute, never on the substrate being up.

## Testing

Mandatory TDD — see [testing.md](testing.md) and ADR-0701. Summary:

```bash
task test:unit      # L0 tofu test
task test:policy    # L1 conftest
task test:chainsaw  # L2 cluster e2e
task test:load      # L3 offline by default (SCORECARD_FIXTURES=1)
task test:scorecard # L4 fixture capture + validate — see testing.md
```

Every OpenSpec REQ includes a `Verify:` block — implement the test before the manifest.

## Commits

```text
:sparkles: feat(scope): short summary
```

ASCII gitmoji shortcode mandatory. No AI co-author trailers.

## Spec-driven development

kaddy is built **spec-first**: behaviour is written down before (or as the failing test for)
implementation. The spine:

| Step | Artifact | Role |
| --- | --- | --- |
| Epic / phase | [docs/ROADMAP.md](../ROADMAP.md) | Build order (E1–E12…), EXIT criteria |
| Story slice | OpenSpec change under `openspec/changes/<slug>/` | `proposal.md` · `specs/` · `tasks.md` · `design.md` |
| Requirement | `REQ-E*-S*-**` in `specs/**/spec.md` | Given/When/Then + **`Verify:`** (command) + **`Test:`** (path) |
| Test first | Path named by `Test:` | Failing test before the manifest/code (ADR-0701) |
| Gate | `task verify` · `task test:spec` · story-level tests | Lint, scrub, OpenSpec structure, REQ↔Test coverage |
| Ship | Conventional commits → rebase-merge PR | One logical change per commit |

OpenSpec project conventions live in [`openspec/config.yaml`](../../openspec/config.yaml)
(`schema: spec-driven`). Every REQ must carry **`Verify:`** and **`Test:`**;
`task test:spec` enforces coverage. Epic EXIT uses `STRICT_TEST_FILES=1` so every `Test:` path
exists. Exercise → epic mapping:
[docs/requirements/exercise-traceability.md](../requirements/exercise-traceability.md).

Typical lane flow (via the **agent-loop** skill): claim `OPERATOR-BOARD` → worktree → write/fail
the test named by the REQ → implement → `task verify` (+ story gates) → independent **tech-review**
→ PR (or local ff-merge under agent-loop-local).

## Agent skills

Committed skill definitions live under [`skills/`](../../skills/) (catalogue in
[`skills/README.md`](../../skills/README.md)). Symlink or copy into `.claude/skills/` if your
harness expects that path — `.claude/` itself is gitignored.

Useful entrypoints for this repo: **agent-loop** / **agent-loop-local**, **write-story**,
**tech-review**, **replayable-audit** / **kaddy-audit**, **handover**, **retrospective**.

## Docs

- MkDocs site: `mkdocs serve` (`mkdocs.yml` at repo root; `mkdocs build --strict` must pass)
- ADRs: `docs/adr/`

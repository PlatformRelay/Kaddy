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

## OpenSpec workflow

Each lane references `openspec/changes/<slug>/`. Update `tasks.md` as work progresses; run
`openspec validate` when CLI installed.

## Docs

- MkDocs site: `mkdocs serve` (`mkdocs.yml` at repo root; `mkdocs build --strict` must pass)
- ADRs: `docs/adr/`

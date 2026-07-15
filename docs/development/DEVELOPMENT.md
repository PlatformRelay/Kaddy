# Development — kaddy

## Prerequisites

- Task ([taskfile.dev](https://taskfile.dev))
- pre-commit (optional locally)
- OpenTofu + Terramate (for E1+ lanes)
- `talosctl`, `kubectl` (for cluster lanes)
- [direnv](https://direnv.net/) (recommended) — loads lab credentials from `.envrc`

### Lab credentials

Copy [`.envrc.example`](../../.envrc.example) → `.envrc`, then `direnv allow`. **Never commit `.envrc`.**

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

## Gates (design phase)

```bash
task verify   # scrub + lint + openspec structure
task scrub    # denylist only
task lint     # markdown + shellcheck
```

Implementation lanes add `task test`, `tofu test`, cluster integration checks per story.

## Testing

Mandatory TDD — see [testing.md](testing.md) and ADR-0701. Summary:

```bash
task test:unit      # L0 tofu test
task test:policy    # L1 conftest
task test:chainsaw  # L2 cluster e2e
```

Every OpenSpec REQ includes a `Verify:` block — implement the test before the manifest.

## Commits

```
:sparkles: feat(scope): short summary
```

ASCII gitmoji shortcode mandatory. No AI co-author trailers.

## OpenSpec workflow

Each lane references `openspec/changes/<slug>/`. Update `tasks.md` as work progresses; run
`openspec validate` when CLI installed.

## Docs

- MkDocs site: `mkdocs serve` (when mkdocs.yml wired in E12/E8)
- ADRs: `docs/adr/`

---
name: changelog
description: >-
  Turn gitmoji-conventional commit history into categorized, user-facing release
  notes for a PlatformRelay repo. Respects each repo's cliff.toml. Use when
  cutting a release, when the operator says "write the changelog / release notes",
  or to preview what a version bump would contain.
---

# changelog — release notes from history

Converts commits into release notes. The repos use `git-cliff` (`cliff.toml`) + Conventional Commits
+ gitmoji; prefer the repo's own tooling and only hand-craft the summary layer on top.

## Step 1 — scope the range
Target repo + range: since the last tag (`git describe --tags --abbrev=0`) to `HEAD`, or an explicit
`vX..vY`. Confirm the intended next version from the commit types (feat → minor, fix → patch,
BREAKING → major).

## Step 2 — generate
- **Be on the release branch FIRST.** git-cliff reads from `HEAD` — if you run it while checked out on
  a stale lane/feature branch, the changelog silently omits every commit not in that branch's ancestry
  (and a tag you then cut dangles off `main`). Do `git fetch && git checkout -B main origin/main`
  before generating and tagging; regenerate from `main`'s HEAD.
- If the repo has git-cliff wired (`task changelog:write` / `git cliff`), run it — that is the source
  of truth; don't reinvent its grouping.
- Read the resulting entries and the raw `git log --oneline <range>`, and sanity-check the count
  (does the section have roughly as many entries as `git log <lasttag>..origin/main` shows?).
- After tagging, VERIFY the tag is on `main`: `git merge-base --is-ancestor <vX> origin/main`. If the
  remote tag is wrong, `git push origin :refs/tags/<vX>` (delete) then re-push — `git push -f` on a
  published tag is classifier-blocked.

## Step 3 — categorize + humanize
Group into **Features / Fixes / Performance / Docs / Internal**. For each user-facing entry, rewrite
the commit subject into a sentence a user understands (what changed, why it matters). Filter internal
noise (chore/ci/test) into a collapsed "Internal" section or drop it. Call out **breaking changes**
and required migration steps prominently at the top.

## Step 4 — place it
Update the repo's `CHANGELOG.md` (this is product docs — committed with the release, gitmoji
`docs: :memo:` / per the repo's release recipe). Surface the notes for the release PR/description.

## Do not
- Bypass the repo's `cliff.toml` grouping if git-cliff is configured — build on it.
- Bury breaking changes in the middle — they lead.
- Invent entries not backed by a commit.

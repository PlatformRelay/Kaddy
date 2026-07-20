<!-- markdownlint-disable MD013 -->
# Tasks — E12d Five-minute pitch deck

**Gate:** `task test:spec` + `tests/deck/exit-recording-ready.sh`
**Activation:** ready now (deck + E12c gates exist; this epic *lowers* budgets and reframes narrative).
TDD-ordered vertical slices — failing test first, then content.

> **Boundary:** this change is deck/docs/tests only. Do not implement Backstage or Nix boot-to-serve.
> Prefer editing the current worktree deck reality (`slides/slides.md`) over re-introducing stale
> E12c “no flake.nix” wording.

## E12d-S01 — Five-minute spoken-path budget gates

- [x] Add failing `tests/deck/spoken-path.sh` (asserts pre-`<!-- APPENDIX -->` content-slide count in
      `[8, 12]`, and that main carries the seven `beat:` markers as an ordered subsequence)
- [x] Edit `tests/deck/script-wordcount.sh` — main spoken words **`[450, 900]`** (≈ 3–7 min at
      130–150 wpm; target ~5); document supersession of E12c-S01-02 / REQ-E12-S02-02 ranges
- [x] Edit `tests/deck/narrative-beats.sh` — main `sectionTime` sum **`[240, 360]` s**; keep 7 beats
      pre-sentinel only
- [x] Update reconciliation notes in `openspec/changes/e12-slidev-deck/specs/deck/spec.md` and
      `openspec/changes/e12c-deck-docs-refresh/specs/deck/spec.md` pointing at E12d
- [x] Trim / move slides so the spoken path fits (mechanical cut is OK; narrative polish is S02+)
- [x] Gate: `spoken-path.sh` + `script-wordcount.sh` + `narrative-beats.sh` + `appendix-boundary.sh`
      green

## E12d-S02 — Opening + early gridscale contribution hero

- [x] Add failing pitch anchors to `tests/deck/content-beats.sh` (or new `pitch-beats.sh`) for:
      exercise/Caddy+Prometheus opening; “platform engineer” / built-a-platform claim;
      `provider-gridscale` early in main; Marketplace link; PR #509/#510/#511; contribution framing
      (not “leftover” / dismissive open-list primacy)
- [x] Rewrite opening slides so the spoken arc leads with exercise → platform
- [x] Keep provider slide **early** (first third of main); reframe upstream PRs as **filed
      contribution / value**, honesty chip: open for review / not merged
- [x] Speaker notes ≥ 25 words on touched slides; Gate: content/pitch beats + notes coverage green

## E12d-S03 — Main-arc hygiene (D-042, controls, website intent, portal)

- [x] Extend failing content gate: main must **not** contain a D-042 title/kicker as a spoken slide;
      if retained, only **after** `<!-- APPENDIX -->`
- [x] Extend failing content gate: main controls slide must **not** contain “Known cloud risk” /
      “GSK node public exposure”; must contain teardown / time-boxed / cost-governance language
- [x] Simplify “Website intent becomes governed resources” — static diagram/claim→resources; no
      reliance on click animations for the claim
- [x] Portal slide: title/body say portal designed + platform API exists; **assume Backstage
      deployed for narrative**; must **not** say “runtime remains open” / “not running yet” on the
      main portal slide
- [x] Gate: content/pitch beats green; `speaker-notes-coverage.sh` green

## E12d-S04 — Mulligan stakeholder language + pitch-safe surfaces

- [x] Add failing content gate: mulligan main slide uses stakeholder language
      (Prometheus / metrics → automatic promote or rollback; blue-green or canary)
- [x] Edit `tests/deck/iframe-surfaces.sh`: for the **spoken/main** path, allow all five surfaces as
      `fallback`/`static` (screenshots/GIFs/public URLs); **remove** the hard ≥3 live-iframe
      requirement for pitch readiness (retain surface tags; live iframes may remain in appendix
      only if desired)
- [x] Replace or demote main-path `127.0.0.1` / port-forward iframes to static assets under
      `slides/public/surfaces/` (or documented public lab URLs); update `slides/README.md` demo
      surfaces table
- [x] Gate: `iframe-surfaces.sh` + content beats + `slidev-build.sh` green

## E12d-S05 — How-I-worked (AI + OpenSpec) + honesty appendix

- [x] Reframe/replace the agentic beat: “built with AI” + spec-to-test loop; optional **sample
      OpenSpec** snippet (Given/When/Then + `Test:`/`Verify:`) visible on-slide
- [x] Honesty appendix (or brief main footnote + appendix detail): Nix **build landed /
      boot-to-serve open**; Backstage public HTTPRoute **live/proven independently of E12d** while
      E10 form-to-PR/read-path smoke remains follow-on; upstream PRs **filed, open**
- [x] Ensure main open-list does not lead with dismissive “three upstream merges remaining” as the
      gridscale value story (contribution stay on hero slide)
- [x] Gate: content/pitch beats + `appendix-boundary.sh` + `exit-recording-ready.sh` green
- [x] Honesty retcon (2026-07-20): GSK Caddy image roll **live-proven** —
      `kaddy-showcase:0.6.0` (caddy-mvp Healthy) + `caddy:2.11.4-alpine` (caddy-demo);
      deck/README no longer call the roll “in flight” / “rollout target”

## Out of band (not E12d) — optional E10 follow-on

See ROADMAP **E10-S07** (portal image publish + live smoke). Do **not** implement under E12d.

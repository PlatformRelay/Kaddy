# Proposal — E12 Slidev showcase deck

## Problem

kaddy has a strong platform story — a security-first Website-as-a-Service IDP: Cilium Gateway API
at the edge, ArgoCD GitOps, a Crossplane v2 `Website` API auto-projected into a Backstage portal,
Argo Rollouts (mulligan) progressive delivery, marshal self-routing alerting, and scorecard
evidence. What it does **not** have is a polished, narrated artifact that presents that story. The
placeholder `slides/slides.md` is a bullet-list stub, not a walkthrough.

The concrete deliverable this epic serves is a **recorded 5–10 minute video walkthrough** for a job
application (the gridscale Platform Engineer exercise). The deck is the **spine** of that video: the
video *is* the demo, and the deck plus its narration *is* the script.

## Scope

A Slidev deck in `slides/` engineered specifically to be recorded:

- **Reproducible static build.** `slidev build` produces a static SPA; CI builds it so the deck can
  never rot (E12-S01). This is also the content the `clubhouse`/Caddy tenant serves (E-Caddy-MVP).
- **Word-by-word speaker notes on EVERY slide.** Each slide carries a Slidev presenter-note block
  (`<!-- ... -->`) holding a **verbatim spoken script** to be read aloud during recording — the
  voiceover, not bullet hints. Notes are first-class scope, tested for coverage and depth (E12-S02),
  and together they must form a coherent script paced for 5–10 minutes at ~130–150 wpm
  (≈650–1500 words).
- **Heavy use of live iframes.** Named slides embed **live URLs** of the running platform surfaces —
  the Backstage portal, the ArgoCD UI, Grafana/marshal dashboards, the running clubhouse/Caddy site,
  and the Crossplane resource graph. The deck **proves the platform is real and running**, not a set
  of screenshots (E12-S03).
- **Narrative beats + time budget.** The deck follows a fixed arc — pitch → architecture → security
  posture → the auto-generated portal hero moment (edit the XRD → the form updates) → progressive
  delivery (mulligan) → alerting (marshal) → evidence (scorecard) — with a per-section time budget so
  the whole thing lands inside the 5–10 minute window (E12-S04).

## Non-goals

- **Not a live click-through demo.** The recorded video is the demo; the deck narrates it. No live
  operator clicking is choreographed as a deliverable.
- **No SaaS presentation tooling** (Google Slides, Pitch, Canva, etc.). The deck is code in the repo,
  built and testable like everything else.
- No animation/theme polish beyond what serves the recording; branding is welcome but not gated.

## Dependencies / links

- **E10 (portal)** — the auto-generated Backstage portal is the hero moment (edit XRD → form updates);
  its live UI is embedded via iframe.
- **E-Caddy-MVP** — the served site content **is the deck/docs themselves** (self-referential: the
  clubhouse/Caddy tenant serves this Slidev build); its running URL is embedded via iframe.
- **E5 (marshal)** — the alerting story; Grafana/Alertmanager surfaces embedded via iframe.
- **E7 (mulligan)** — the progressive-delivery (Argo Rollouts) beat.
- **E8 (scorecard)** — the evidence beat closing the deck.

## Counterpoints

- **Live iframes require the live platform to be up during recording.** If a surface is down, the
  embed shows an error. **Fallback:** substitute a pre-recorded GIF / screenshot for any surface that
  is unavailable at record time. The iframe-surfaces test asserts the *embed intent* is present in the
  deck; it does not require the live endpoint to be reachable in CI. This fallback is noted on the
  iframe REQ (`REQ-E12-S03-01`).
- The deck could rot relative to the platform. Mitigated by the CI static build (E12-S01) and by the
  narrative-beats and iframe-surfaces grep tests, which fail if the required story/surfaces are
  dropped.

## Activation

Cuttable / late-parallel. Per `docs/ROADMAP.md`: "E11, E12 in parallel where possible" — E12 can run
in parallel late once the platform surfaces it embeds exist. Implementation via `/agent-loop`.

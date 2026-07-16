<!-- markdownlint-disable MD013 -->
# Section-Cover Image Prompts — Mœbius Continuous Story (kaddy)

One AI-generated cover image per deck slide (`S00`–`S14`), forming a single continuous,
gently comedic story in the style of **Mœbius (Jean Giraud)** — kept for PlatformRelay
brand consistency with the kubernetes-workshop covers. Slides are defined in
[`slides.md`](./slides.md); the platform's golf/caddie naming *is* the story's universe.

> The deck has 15 content slides; each gets one section-cover divider. If a delivery
> trims slides, keep the story readable even when a beat (and its image) is switched
> off — no beat may *depend* on another cover having been shown.
>
> **Filenames are stable art IDs in generation order** (S00–S14). The E12-S04
> narrative-arc restructure renumbered the *displayed* `§` kickers in
> [`slides.md`](./slides.md), so a filename's `NN` may differ from its display
> position (e.g. `section-07-marshals-tower.png` now shows as `§ 10`;
> `section-14-caddies-order-desk.png` shows as `§ 08`). Do not rename files.

## Hard requirement

**Every rendered image must carry a visible `AI generated` footer** on the slide
(small, bottom-corner, low opacity). No exceptions. The deck's `CoverArt` component
renders this footer for every cover; the images themselves must not fake or omit it.

## The story (one sentence)

A small, unflappable caddie named Kaddy arrives at a windswept seaside links with one
modest job — carry a bag for a single hole — and instead, hole by hole, builds a gently
magical, self-running golf resort: one gatehouse, tireless greenkeepers who rake the
course back to their master scroll, a sharp-eyed marshal in a watchtower, a retriever
who fetches every bad shot back for a second try, and an honest scorecard — while a
masked gopher keeps testing the fences and losing.

## Recurring cast (keep consistent across all images for continuity)

- **Kaddy** — a small, calm caddie in a flat cap and pale windbreaker, carrying an
  oversized enchanted golf bag that always produces exactly the right club. Prepared
  for everything, surprised by nothing. *(the platform itself)*
- **The Member** — a cheerful golfer in slightly-too-fancy tweed who just wants to
  play a round without worrying about anything underneath. *(the tenant / website
  owner)*
- **The Clubhouse** — a cosy timber-and-glass clubhouse at the heart of the links,
  lights always on, flag flying. *(clubhouse — the sample website tenant, the brief)*
- **The Gatehouse** — the single ornate entrance arch to the links; every visitor,
  bag, and delivery passes through it, no exceptions. *(Cilium Gateway API — the
  platform edge)*
- **The Greenkeepers** — a tireless crew of identical groundskeepers who work from
  one glowing master course-scroll and gently rake anything that drifts back to
  exactly match the drawing. *(ArgoCD app-of-apps — GitOps convergence)*
- **The Marshal** — a lanky, keen-eyed course marshal with brass binoculars, a loud
  whistle, and a pocket full of signal flags, usually up a timber watchtower.
  *(marshal — monitoring, PrometheusRules, Alertmanager)*
- **Mulligan** — a golden retriever who chases down any badly-struck ball and drops
  it back on the tee before it can land somewhere expensive. *(mulligan —
  blue/green + canary with automatic rollback)*
- **The Scorecard** — Kaddy's leather-bound scorecard that faithfully records every
  stroke, then gets stamped, signed, and sealed. *(scorecard — k6 + metrics/logs →
  the HTML evidence report)*
- **The Gopher** — a sneaky little gopher in a tiny domino mask, **first flicked out
  of a bag at the gatehouse inspection (S08)**, forever digging under fences and
  rattling locked doors, always foiled. *(the threat model)*

## Global style block (prepend to every prompt)

> Mœbius / Jean Giraud comic-book style, clean *ligne claire* ink linework, flat
> gouache/watercolour cel colouring, coastal links palette (fairway green, sea teal,
> sand-dune ochre, coral dawn sky) with a gently surreal retro-futurist mood, warm and
> lightly humorous, wide cinematic framing with lots of open sky, no text, no logos,
> no watermark, no speech bubbles. Consistent characters across a series: a small
> flat-cap caddie named Kaddy with an oversized enchanted golf bag, a tweedy Member,
> a lanky brass-binocular Marshal, a golden retriever named Mulligan, identical
> greenkeepers with one glowing scroll, and a small masked gopher.

## Global negative prompt

> no text, no captions, no lettering, no signatures, no watermark, no logos, no
> modern UI, not photorealistic, no gore, not dark/grim, no brand names, no real
> golf-brand equipment.

## Aspect & placement

- Render **16:9** (matches the deck). Keep the **left third relatively open** so the
  slide title sits over calm space; keep the busy action right-of-centre.
- The mandatory `AI generated` footer is rendered bottom-right at low opacity by the
  deck's `CoverArt` component — compose images so the bottom-right corner stays quiet.
- Target files: `slides/public/covers/section-NN-<slug>.png` (exact names below).

---

## Prompts

### S00 — Title — *The first tee* — `section-00-first-tee.png`

At dawn, Kaddy steps off a small coastal ferry ramp onto a vast, windswept seaside
links, the oversized enchanted golf bag over one shoulder. Rolling dune fairways run
to the horizon; a single flag stirs on the first tee; the sea glitters behind. Empty
course, huge sky, sense of "a big round begins." Warm, hopeful, a little daunting.

### S01 — The brief, reframed — *The one-line letter* — `section-01-one-line-letter.png`

Kaddy stands by the first tee reading a very small letter — clearly one modest
request — while the Member waits beside a single golf bag. Behind and above them,
faint golden dawn-light outlines of an entire resort (gatehouse, watchtower,
clubhouse, eighteen flags) shimmer over the dunes like a mirage: the difference
between the letter and the actual question. Gentle "there's more to this" comedy.

### S02 — From task to platform — *One hole, whole course* — `section-02-one-hole-whole-course.png`

Kaddy plants a flag on one tidy finished hole beside the cosy Clubhouse — then
unrolls a course map showing all eighteen. Around the map's edges the cast is at
work: the Gatehouse arch stands at the entrance, the Marshal surveys from a hillock,
Greenkeepers rake in unison, Mulligan the retriever bounces after a ball. One hole
done, a whole course intended. Bustling, warm "meet the crew" energy.

### S03 — Landed vs designed — *The honest scorecard* — `section-03-honest-scorecard.png`

Kaddy holds a big scorecard open for the Member: the front holes are inked in and
stamped, the back holes only pencil sketches. Behind them the course matches the
card exactly — near holes solid and humming, far holes glowing surveyor's-blueprint
outlines in the mist. Nobody is pretending. Calm, disarming honesty with a smile.

### S04 — Architecture — *Two courses, one blueprint* — `section-04-two-courses-one-blueprint.png`

Kaddy holds up a single translucent master blueprint; through it two vistas line up
perfectly: a small walled practice links in the foreground and a grand cliffside
championship course far across the water — identical hole layouts, same gatehouse
arch at each entrance. Greenkeepers on both sides consult the *same* scroll. Clever
"one drawing, two builds" visual rhyme.

### S05 — Substrate — *The practice green* — `section-05-practice-green.png`

Inside a walled garden, a perfect miniature links: tiny gatehouse arch, tiny flags,
tiny lanterns — a faithful scale model of the big course, not a toy. Kaddy lines up
a putt on it while Mulligan watches, nose level with a miniature clubhouse. Every
detail of the big course present in miniature. Charming, precise, doll-house humour.

### S06 — GitOps — *The greenkeepers' scroll* — `section-06-greenkeepers-scroll.png`

The Greenkeeper crew works from one glowing master scroll on a wooden stand. Where a
bunker has drifted out of shape, their rakes gently pull the sand back until it
matches the drawing exactly; a mis-mown stripe re-mows itself behind them. Kaddy
amends the scroll with a pen — and in the distance the course quietly rearranges to
follow. Serene, self-correcting magic.

### S07 — Observability — *The marshal's tower* — `section-07-marshals-tower.png`

The Marshal stands atop a timber watchtower, brass binoculars up, surrounded by rows
of dials, gauges, and little signal flags. Strings of lantern-lights arc over the
course like glowing graph-constellations, one per hole, showing each hole's pulse.
One gauge quivers into the red; the Marshal's free hand hovers over the whistle.
Wonder plus a hint of "uh oh, that line."

### S08 — Security & governance — *The gatehouse inspection* — `section-08-gatehouse-inspection.png`

At the ornate Gatehouse arch, every bag is inspected before entering the links: one
tidy bag receives a glowing wax seal; from another, the masked **Gopher** is caught
mid-stowaway and comically flicked out by a white-gloved attendant. Behind the arch,
a small heavy key-vault sits under lock, and neat low light-fences divide the
fairways into tidy paddocks. *(Gopher's first appearance.)* Watchful, funny "nothing
dodgy gets onto the course" energy.

### S09 — Caddy-MVP tenant & mulligan — *Mulligan's second chance* — `section-09-mulligans-second-chance.png`

On the Clubhouse hole the Member shanks a shot horribly toward the gorse — and
Mulligan the retriever is already streaking after it, catching the ball mid-air and
trotting it back to the tee before it can land anywhere expensive. Up in the tower
the Marshal watches the gauges, whistle half-raised, then relaxes. The Member gets a
clean second swing; play never stops. Adorable, kinetic "rollback as a good dog."

### S10 — Demo flow — *The five-hole walkthrough* — `section-10-five-hole-walkthrough.png`

Kaddy leads the Member on a brisk walking tour of five flagged holes in a row, each
with its station: the Greenkeepers' scroll, the Gatehouse arch, the Marshal's tower,
a whistle-drill in progress, and Mulligan mid-fetch. In Kaddy's other hand the
Scorecard writes itself, line by line, as they walk. Guided-tour momentum; everything
demonstrably works.

### S11 — Roadmap — *The back nine at dawn* — `section-11-back-nine-at-dawn.png`

From a grassy rise at first light: the front holes finished and gently humming below;
the back nine beyond still surveyor's stakes, string lines, and pencil-sketch
outlines in the sea mist — with one distant grander cliffside site marked by a single
flag. Kaddy and the Greenkeepers study the plan together, unhurried. Clearly next,
clearly planned, no rush.

### S12 — Why this answers the exercise — *The signed scorecard* — `section-12-signed-scorecard.png`

On the Clubhouse steps, Kaddy hands the Member the completed scorecard — every line
legible, the Marshal's stamp, the Greenkeepers' mark, a wax seal from the Gatehouse.
Behind them the whole resort stands orderly in late-afternoon light: gate, tower,
scroll-stand, flags. The Member can check every line. Quiet, earned "here's the
proof" payoff.

### S13 — Thank you — *The nineteenth hole* — `section-13-nineteenth-hole.png`

Golden hour on the Clubhouse terrace — the nineteenth hole. The whole cast raises
glasses and lemonades: Kaddy, the Member, the Marshal (whistle finally pocketed),
the Greenkeepers, Mulligan asleep on a bench with a ball under one paw — and the
Gopher, grudgingly included, sipping at the far end. The links glow behind; a small
ferry light waits on the horizon for the next course. Warm, communal, "onward"
ending.

### S14 — Portal — *The caddie's order desk* — `section-14-caddies-order-desk.png`

*(Displayed as `§ 08` in the deck — the self-service portal beat, between the
gatehouse inspection (S08) and Mulligan's second chance (S09). Story-wise it sits
mid-round; keep the light and cast continuity consistent with S08/S09, not with
the golden-hour S13.)*

At a polished wooden order desk beside the first tee, the Member writes a single
wish — one more hole, please — into a large self-filling order book whose blank
form redraws itself to match the glowing master course-scroll standing open behind
the desk. Kaddy tears off the completed page and hands it to a waiting Greenkeeper,
and far down the fairway a brand-new hole is already sketching itself into
existence, flag rising. No haggling, no queue: the book always asks exactly the
right questions. Delighted, effortless "wish becomes work order" magic.

---

## Branding

Target files live under `slides/public/branding/`. Same global style block, negative
prompt, and `AI generated` guardrail apply (the footer for branding renders wherever
the asset is displayed with attribution space; keep bottom-right corners quiet).

### Logo — dark variant — `logo-dark.png` (also downscaled: `logo-512.png`, favicons)

Square **1:1** app-icon emblem in clean ligne-claire linework: a single upright golf
bag whose tallest club is a course flagpole with a small pennant, forming a subtle
lowercase "k" silhouette. Pale sand and sea-teal linework on a deep teal-black
background, flat cel colouring, generous margin, bold simple shapes that stay
readable at 512 px and at favicon scale (32 px). No text — or at most the lowercase
wordmark **"kaddy"** beneath the mark. No other lettering.

### Logo — light variant — `logo-light.png`

The identical emblem and composition as the dark variant, recoloured: deep-teal ink
linework on a warm off-white/paper background, coral pennant accent. Must remain
recognisably the same mark at 512 px and favicon scale. No text — or at most the
lowercase wordmark **"kaddy"**. No other lettering.

### GitHub social preview / og-image — `og-image.png` (1280×640)

Wide **2:1 (1280×640)** repo-card scene: the seaside links at dawn with Kaddy and
the enchanted golf bag walking in from the right third, the Gatehouse arch and
Marshal's tower small on the skyline, big calm coral-dawn sky. Keep the **left
two-thirds and vertical centre calm and uncluttered** so GitHub's overlay
conventions (repo name + one-liner) sit legibly over open sky. Low horizon, soft
light, minimal detail density. No text in the image itself; the footer guardrail
applies.

---

## Production notes

- **Consistency:** generate S00 first, lock Kaddy's design (flat cap, windbreaker,
  oversized bag), then reuse those exact descriptions (and ideally seed/reference
  images) for S01–S13 and the branding set so the cast stays recognizable.
- **Continuity beats:** the letter arrives (S01) before the course map (S02); the
  honest scorecard (S03) sets up the signed scorecard (S12); the practice green (S05)
  mirrors the two-courses blueprint (S04); the **Gopher is introduced at S08** and
  gets its grudging seat at the nineteenth hole (S13); Mulligan appears from S02 and
  stars at S09. Preserve these when regenerating.
- **Drop-in:** filenames above are final — save each render to
  `slides/public/covers/` (or `slides/public/branding/`) under the exact name and
  the deck picks it up with no code change; until then the `CoverArt` component
  falls back to `covers/placeholder-section.svg`.
- **Left-third open** for the slide title; **`AI generated` footer** on every slide.

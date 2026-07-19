# Five cover prompts — Kaddy interview deck

Generate exactly five 16:9 covers. Together they form a restrained coastal-links story, with content
slides doing the detailed explanation. `CoverArt.vue` renders the mandatory visible
`AI generated` attribution; do not bake text, logos, signatures, or watermarks into the images.

## Shared direction

Clean ligne-claire comic illustration, flat gouache and watercolor cel coloring, warm off-white
highlights, deep navy and graphite shadows, sea-green accents, sand/gold details, and restrained
coral sky. Windswept seaside golf links, gently surreal but professional, warm rather than comic.
Wide cinematic composition with the left third calm and dark enough for a large title. Keep the
bottom-right quiet for the attribution.

Recurring cast:

- Kaddy: a calm small caddie in a flat cap and pale windbreaker with an oversized golf bag;
- the Member: a friendly golfer in practical tweed;
- the Marshal: a tall observer with brass binoculars;
- Mulligan: a golden retriever retrieving a bad ball;
- the Greenkeepers: a coordinated crew working from one shared plan;
- the Gopher: a small masked threat-model character, used sparingly.

Negative prompt: no words, captions, lettering, logos, watermark, signature, photorealism, modern
software UI, brand names, gore, visual clutter, or real golf-equipment branding.

## 1. Opening

Target: `public/covers/section-00-first-tee.png`

At dawn, Kaddy arrives at a windswept seaside first tee carrying the oversized bag. A modest
clubhouse glows in the middle distance; the whole course stretches beyond it. The Member waits
without ceremony. The image should feel personal and ready: one practical job at the start of a
larger round. Large open navy-coral sky on the left, action right of center.

## 2. Architecture

Target: `public/covers/section-04-two-courses-one-blueprint.png`

Kaddy and the Greenkeepers hold one shared course plan between two visible courses. The small local
course uses a sea-green stone gate; the larger cliffside course uses a different sand-colored gate.
The fairways, clubhouse, watchtower, and operating plan visibly correspond, but the entrances are
intentionally not identical. The visual message is shared platform applications with
substrate-specific edges, not a one-click repoint.

## 3. Platform controls

Target: `public/covers/section-08-gatehouse-inspection.png`

At an elegant gatehouse, an attendant checks every bag, applies a sea-green seal to an approved bag,
and gently removes the masked Gopher from another. Low fences divide the course into deliberate
zones; a compact locked key cabinet sits behind the desk. Watchful, calm, and procedural. Use warm
sand light for review and sea green for approved state.

## 4. Operations and delivery

Target: `public/covers/section-09-mulligans-second-chance.png`

The Member sends a ball toward rough ground. Mulligan catches it in motion and returns it to the tee
while the Marshal watches course gauges from a tower. Kaddy calmly points to the safe fairway and
the next release attempt. Show measurement, traffic choice, and recovery in one clean composition;
avoid slapstick or disaster.

## 5. Evidence and next steps

Target: `public/covers/section-12-signed-scorecard.png`

Late-afternoon light on the clubhouse steps. Kaddy hands the Member a clear, stamped scorecard while
the Marshal and Greenkeepers add their marks. The completed front of the course is visible; a few
future stakes remain on the distant holes. The mood is earned and open: evidence for what is done,
and an honest view of what comes next.

## Production checklist

- Render all files at the same dimensions and with the same character references or seed.
- Preserve the exact five filenames above.
- Keep title-safe space on the left and attribution-safe space at bottom-right.
- Check the image under the deck's navy overlay before accepting contrast.
- Keep `CoverArt.vue` attribution enabled for every generated cover.

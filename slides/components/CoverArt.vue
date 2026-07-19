<script setup lang="ts">
/**
 * Full-bleed AI section-cover for the kaddy deck (E12b).
 *
 * - `src` always points at the FINAL artwork filename under `public/covers/`
 *   (see ../image-prompts.md); until the PNG is generated and dropped in, the
 *   `@error` handler falls back to `covers/placeholder-section.svg`, so
 *   `pnpm build` and the rendered deck stay green with zero code changes later.
 * - The low-opacity "AI generated" footer is a hard guardrail for every
 *   generated cover and must not be removed.
 */
const props = withDefaults(
  defineProps<{
    /** Final cover artwork path, e.g. "/covers/section-07-marshals-tower.png". */
    src: string
    /** Small kicker above the title, e.g. "§ 07 · The marshal's tower". */
    kicker?: string
    /** Slide title rendered bottom-left over the calm left third. */
    title?: string
    /** Whether the artwork is AI-generated (footer mandatory when true). */
    aiGenerated?: boolean
  }>(),
  { aiGenerated: true },
)

const base = import.meta.env.BASE_URL

function resolveAsset(url: string) {
  return url.startsWith('/') ? base + url.slice(1) : url
}

const placeholder = resolveAsset('/covers/placeholder-section.svg')

function onError(event: Event) {
  const img = event.target as HTMLImageElement
  if (!img.src.endsWith('placeholder-section.svg'))
    img.src = placeholder
}
</script>

<template>
  <div class="kd-cover">
    <img class="kd-cover-image" :src="resolveAsset(props.src)" alt="" @error="onError" />
    <div class="kd-cover-overlay" />
    <div class="kd-cover-body">
      <div v-if="props.kicker" class="kd-cover-kicker">{{ props.kicker }}</div>
      <h1 v-if="props.title" class="kd-cover-title">{{ props.title }}</h1>
      <slot />
    </div>
    <div v-if="props.aiGenerated" class="kd-ai-footer">AI generated</div>
  </div>
</template>

<style scoped>
.kd-cover {
  position: absolute;
  inset: 0;
  overflow: hidden;
  background: #071b28;
}

.kd-cover-image {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.kd-cover-overlay {
  position: absolute;
  inset: 0;
  background:
    linear-gradient(90deg, rgba(7, 27, 40, 0.88), rgba(7, 27, 40, 0.18) 72%),
    linear-gradient(to top, rgba(11, 14, 20, 0.92) 7%, rgba(11, 14, 20, 0.15) 62%);
}

.kd-cover-body {
  position: absolute;
  left: 3.2rem;
  right: 3.2rem;
  bottom: 2.6rem;
  color: #f8fafc;
  text-align: left;
}

.kd-cover-kicker {
  font-size: 0.85rem;
  letter-spacing: 0.18em;
  text-transform: uppercase;
  color: #a9f2dc;
  margin-bottom: 0.5rem;
  font-family: 'JetBrains Mono', ui-monospace, monospace;
  font-weight: 700;
}

.kd-cover-title {
  max-width: 760px;
  font-size: 2.5rem;
  font-weight: 760;
  letter-spacing: -0.035em;
  line-height: 1.08;
  margin: 0;
  text-shadow: 0 2px 20px rgba(0, 0, 0, 0.5);
}

.kd-ai-footer {
  position: absolute;
  right: 0.9rem;
  bottom: 0.7rem;
  font-size: 0.6rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #f7f2e8;
  opacity: 0.7;
}
</style>

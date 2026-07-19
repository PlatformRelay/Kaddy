<script setup lang="ts">
import { Icon } from '@iconify/vue'

withDefaults(
  defineProps<{
    name: string
    label?: string
    size?: string
  }>(),
  {
    label: '',
    size: '1em',
  },
)
</script>

<template>
  <span class="kd-icon" :aria-hidden="label ? undefined : 'true'" :aria-label="label || undefined">
    <Icon :icon="name" :width="size" :height="size" />
  </span>
</template>

<script setup lang="ts">
defineProps<{ settings: Record<string, unknown>; editorMode?: boolean }>();
</script>

<template>
    <div
        class="relative flex items-center justify-center overflow-hidden bg-gray-900"
        :style="{ minHeight: `${settings.height ?? 500}px` }"
    >
        <!-- Background image -->
        <img
            v-if="settings.image"
            :src="settings.image as string"
            alt=""
            class="absolute inset-0 h-full w-full object-cover"
        />
        <!-- Overlay -->
        <div
            v-if="settings.overlay_opacity"
            class="absolute inset-0"
            :style="{
                backgroundColor: settings.overlay_color as string,
                opacity: (settings.overlay_opacity as number) / 100,
            }"
        />
        <!-- Content -->
        <div
            class="relative z-10 w-full max-w-3xl px-6"
            :class="{
                'text-center': settings.text_align === 'center',
                'text-left': settings.text_align === 'left',
                'text-right': settings.text_align === 'right',
            }"
        >
            <h1
                v-if="settings.headline"
                class="mb-4 text-4xl font-bold text-white md:text-5xl"
            >
                {{ settings.headline }}
            </h1>
            <p v-if="settings.subheading" class="mb-8 text-xl text-white/80">
                {{ settings.subheading }}
            </p>
            <a
                v-if="settings.cta_text"
                :href="(settings.cta_url as string) ?? '#'"
                class="inline-block rounded-lg bg-white px-8 py-3 font-semibold text-gray-900 transition-colors hover:bg-gray-100 dark:bg-slate-900 dark:text-slate-100 dark:hover:bg-slate-800"
            >
                {{ settings.cta_text }}
            </a>
        </div>
        <!-- Editor placeholder when no image -->
        <div
            v-if="!settings.image && editorMode"
            class="absolute inset-0 flex items-center justify-center bg-gradient-to-br from-gray-700 to-gray-900"
        >
            <span class="text-sm text-white/50">Hero — click to configure</span>
        </div>
    </div>
</template>

<script setup lang="ts">
defineProps<{ settings: Record<string, unknown>; editorMode?: boolean }>();
</script>

<template>
    <!-- Editor placeholder when content is empty -->
    <div
        v-if="editorMode && !settings.content"
        class="flex items-center justify-center gap-2 rounded-lg border-2 border-dashed border-gray-200 py-6 text-sm text-gray-400 select-none dark:border-gray-700 dark:text-gray-600"
    >
        <svg
            class="h-4 w-4"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
        >
            <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"
            />
        </svg>
        HTML Block — add content in the panel
    </div>

    <!-- Editor preview badge + rendered content -->
    <div v-else class="relative">
        <div
            v-if="editorMode"
            class="pointer-events-none absolute top-1 right-1 z-10 rounded bg-orange-100 px-1.5 py-0.5 text-[10px] font-bold text-orange-600 select-none dark:bg-orange-900/40 dark:text-orange-400"
        >
            HTML
        </div>
        <!-- eslint-disable-next-line vue/no-v-html -->
        <div class="uie-html-output" v-html="settings.content as string" />
    </div>
</template>

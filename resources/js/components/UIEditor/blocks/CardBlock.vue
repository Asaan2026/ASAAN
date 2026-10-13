<script setup lang="ts">
defineProps<{ settings: Record<string, unknown>; editorMode?: boolean }>();
</script>

<template>
    <div
        class="group overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm transition-shadow hover:shadow-md dark:border-gray-700 dark:bg-gray-800"
    >
        <!-- Card image -->
        <div
            v-if="settings.image || editorMode"
            class="h-48 w-full overflow-hidden bg-gray-100 dark:bg-gray-700"
        >
            <img
                v-if="settings.image"
                :src="settings.image as string"
                alt=""
                class="h-full w-full object-cover"
            />
            <div
                v-else
                class="flex h-full w-full items-center justify-center text-sm text-gray-300 dark:text-gray-600"
            >
                Card Image
            </div>
        </div>
        <div class="p-4">
            <span
                v-if="settings.badge"
                class="mb-2 inline-block rounded-full bg-blue-100 px-2 py-0.5 text-xs font-semibold text-blue-700 dark:bg-blue-900/40 dark:text-blue-300"
            >
                {{ settings.badge }}
            </span>
            <h3
                class="mb-1 text-base font-semibold text-gray-900 dark:text-white"
            >
                {{
                    (settings.title as string) ||
                    (editorMode ? 'Card Title' : '')
                }}
            </h3>
            <p class="text-sm leading-relaxed text-gray-600 dark:text-gray-300">
                {{
                    (settings.body as string) ||
                    (editorMode ? 'Card description goes here.' : '')
                }}
            </p>
            <div
                v-if="settings.footer || settings.link"
                class="mt-3 flex items-center justify-between"
            >
                <span v-if="settings.footer" class="text-xs text-gray-400">{{
                    settings.footer
                }}</span>
                <a
                    v-if="settings.link"
                    :href="settings.link as string"
                    class="text-sm font-medium text-blue-600 hover:underline dark:text-blue-400"
                >
                    Learn more →
                </a>
            </div>
        </div>
    </div>
</template>

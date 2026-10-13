<script setup lang="ts">
defineProps<{ settings: Record<string, unknown>; editorMode?: boolean }>();
</script>

<template>
    <div class="py-1">
        <a v-if="settings.link" :href="settings.link as string">
            <img
                v-if="settings.image"
                :src="settings.image as string"
                :alt="(settings.alt as string) || ''"
                class="block"
                :style="{
                    borderRadius: settings.border_radius
                        ? `${settings.border_radius}px`
                        : undefined,
                    width: (settings.width as string) || '100%',
                }"
            />
        </a>
        <img
            v-else-if="settings.image"
            :src="settings.image as string"
            :alt="(settings.alt as string) || ''"
            class="block"
            :style="{
                borderRadius: settings.border_radius
                    ? `${settings.border_radius}px`
                    : undefined,
                width: (settings.width as string) || '100%',
            }"
        />
        <div
            v-else-if="editorMode"
            class="flex h-40 w-full items-center justify-center rounded-lg border-2 border-dashed border-gray-300 bg-gray-100 text-sm text-gray-400 dark:border-gray-600 dark:bg-gray-800"
        >
            Click to add image
        </div>
        <p
            v-if="settings.caption"
            class="mt-1 text-center text-xs text-gray-500 dark:text-gray-400"
        >
            {{ settings.caption }}
        </p>
    </div>
</template>

<script setup lang="ts">
const props = defineProps<{ settings: Record<string, unknown> }>();
const emit = defineEmits<{ 'update:settings': [v: Record<string, unknown>] }>();
function update(key: string, value: unknown) {
    emit('update:settings', { ...props.settings, [key]: value });
}
</script>

<template>
    <div class="space-y-4 p-4">
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Headline</label
            >
            <input
                type="text"
                :value="settings.headline as string"
                class="uie-input"
                @input="
                    update(
                        'headline',
                        ($event.target as HTMLInputElement).value,
                    )
                "
            />
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Subheading</label
            >
            <input
                type="text"
                :value="settings.subheading as string"
                class="uie-input"
                @input="
                    update(
                        'subheading',
                        ($event.target as HTMLInputElement).value,
                    )
                "
            />
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >CTA Label</label
            >
            <input
                type="text"
                :value="settings.cta_text as string"
                class="uie-input"
                @input="
                    update(
                        'cta_text',
                        ($event.target as HTMLInputElement).value,
                    )
                "
            />
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >CTA URL</label
            >
            <input
                type="text"
                :value="settings.cta_url as string"
                class="uie-input"
                @input="
                    update('cta_url', ($event.target as HTMLInputElement).value)
                "
            />
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Image URL</label
            >
            <input
                type="text"
                :value="settings.image as string"
                class="uie-input"
                @input="
                    update('image', ($event.target as HTMLInputElement).value)
                "
                placeholder="https://… or /storage/…"
            />
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Height (px)</label
            >
            <input
                type="number"
                :value="settings.height as number"
                min="200"
                max="1000"
                class="uie-input"
                @change="
                    update(
                        'height',
                        Number(($event.target as HTMLInputElement).value),
                    )
                "
            />
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Text Align</label
            >
            <select
                :value="settings.text_align as string"
                class="uie-input"
                @change="
                    update(
                        'text_align',
                        ($event.target as HTMLSelectElement).value,
                    )
                "
            >
                <option value="left">Left</option>
                <option value="center">Center</option>
                <option value="right">Right</option>
            </select>
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Overlay Color</label
            >
            <div class="flex items-center gap-2">
                <input
                    type="color"
                    :value="settings.overlay_color as string"
                    class="h-8 w-8 cursor-pointer rounded border"
                    @input="
                        update(
                            'overlay_color',
                            ($event.target as HTMLInputElement).value,
                        )
                    "
                />
                <input
                    type="text"
                    :value="settings.overlay_color as string"
                    class="uie-input flex-1"
                    @change="
                        update(
                            'overlay_color',
                            ($event.target as HTMLInputElement).value,
                        )
                    "
                />
            </div>
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Overlay Opacity ({{ settings.overlay_opacity ?? 40 }}%)</label
            >
            <input
                type="range"
                :value="settings.overlay_opacity as number"
                min="0"
                max="100"
                class="w-full"
                @input="
                    update(
                        'overlay_opacity',
                        Number(($event.target as HTMLInputElement).value),
                    )
                "
            />
        </div>
    </div>
</template>

<style scoped>
@reference "tailwindcss";
.uie-input {
    @apply w-full rounded-lg border border-gray-300 bg-white px-2 py-1.5 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white;
}
</style>

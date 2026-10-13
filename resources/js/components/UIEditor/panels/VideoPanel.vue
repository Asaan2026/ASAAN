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
                >Video URL (YouTube or Vimeo)</label
            >
            <input
                type="text"
                :value="settings.url as string"
                class="uie-input"
                placeholder="https://youtube.com/watch?v=…"
                @input="
                    update('url', ($event.target as HTMLInputElement).value)
                "
            />
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Aspect Ratio</label
            >
            <select
                :value="settings.ratio as string"
                class="uie-input"
                @change="
                    update('ratio', ($event.target as HTMLSelectElement).value)
                "
            >
                <option value="16:9">16:9 (Widescreen)</option>
                <option value="4:3">4:3</option>
                <option value="1:1">1:1 (Square)</option>
            </select>
        </div>
        <div class="flex items-center gap-2">
            <input
                id="vid_controls"
                type="checkbox"
                :checked="settings.controls as boolean"
                class="rounded text-blue-600"
                @change="
                    update(
                        'controls',
                        ($event.target as HTMLInputElement).checked,
                    )
                "
            />
            <label
                for="vid_controls"
                class="text-sm text-gray-700 dark:text-gray-300"
                >Show controls</label
            >
        </div>
    </div>
</template>

<style scoped>
@reference "tailwindcss";
.uie-input {
    @apply w-full rounded-lg border border-gray-300 bg-white px-2 py-1.5 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white;
}
</style>

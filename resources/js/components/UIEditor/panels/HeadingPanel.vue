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
                >Text</label
            >
            <input
                type="text"
                :value="settings.text as string"
                class="uie-input"
                @input="
                    update('text', ($event.target as HTMLInputElement).value)
                "
            />
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Level</label
            >
            <select
                :value="settings.level as string"
                class="uie-input"
                @change="
                    update('level', ($event.target as HTMLSelectElement).value)
                "
            >
                <option
                    v-for="h in ['h1', 'h2', 'h3', 'h4', 'h5', 'h6']"
                    :key="h"
                    :value="h"
                >
                    {{ h.toUpperCase() }}
                </option>
            </select>
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Align</label
            >
            <select
                :value="settings.align as string"
                class="uie-input"
                @change="
                    update('align', ($event.target as HTMLSelectElement).value)
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
                >Color</label
            >
            <div class="flex items-center gap-2">
                <input
                    type="color"
                    :value="(settings.color as string) || '#111827'"
                    class="h-8 w-8 cursor-pointer rounded border"
                    @input="
                        update(
                            'color',
                            ($event.target as HTMLInputElement).value,
                        )
                    "
                />
                <input
                    type="text"
                    :value="settings.color as string"
                    class="uie-input flex-1"
                    @change="
                        update(
                            'color',
                            ($event.target as HTMLInputElement).value,
                        )
                    "
                />
            </div>
        </div>
    </div>
</template>

<style scoped>
@reference "tailwindcss";
.uie-input {
    @apply w-full rounded-lg border border-gray-300 bg-white px-2 py-1.5 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white;
}
</style>

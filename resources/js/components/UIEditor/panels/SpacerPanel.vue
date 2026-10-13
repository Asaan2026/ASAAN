<script setup lang="ts">
const props = defineProps<{ settings: Record<string, unknown> }>();
const emit = defineEmits<{ 'update:settings': [v: Record<string, unknown>] }>();
function update(key: string, value: unknown) {
    emit('update:settings', { ...props.settings, [key]: value });
}
</script>

<template>
    <div class="p-4">
        <label
            class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
            >Height (px)</label
        >
        <input
            type="number"
            :value="settings.height as number"
            min="8"
            max="400"
            class="w-full rounded-lg border border-gray-300 bg-white px-2 py-1.5 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white"
            @change="
                update(
                    'height',
                    Number(($event.target as HTMLInputElement).value),
                )
            "
        />
    </div>
</template>

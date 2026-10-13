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
                >Label</label
            >
            <input
                type="text"
                :value="settings.label as string"
                class="uie-input"
                @input="
                    update('label', ($event.target as HTMLInputElement).value)
                "
            />
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >URL</label
            >
            <input
                type="text"
                :value="settings.url as string"
                class="uie-input"
                @input="
                    update('url', ($event.target as HTMLInputElement).value)
                "
            />
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Variant</label
            >
            <select
                :value="settings.variant as string"
                class="uie-input"
                @change="
                    update(
                        'variant',
                        ($event.target as HTMLSelectElement).value,
                    )
                "
            >
                <option value="primary">Primary</option>
                <option value="secondary">Secondary</option>
                <option value="outline">Outline</option>
            </select>
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Size</label
            >
            <select
                :value="settings.size as string"
                class="uie-input"
                @change="
                    update('size', ($event.target as HTMLSelectElement).value)
                "
            >
                <option value="sm">Small</option>
                <option value="md">Medium</option>
                <option value="lg">Large</option>
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
    </div>
</template>

<style scoped>
@reference "tailwindcss";
.uie-input {
    @apply w-full rounded-lg border border-gray-300 bg-white px-2 py-1.5 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white;
}
</style>

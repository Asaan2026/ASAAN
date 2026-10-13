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
                >Number</label
            >
            <input
                type="number"
                :value="settings.number as number"
                class="uie-input"
                @input="
                    update(
                        'number',
                        Number(($event.target as HTMLInputElement).value),
                    )
                "
            />
        </div>
        <div class="grid grid-cols-2 gap-3">
            <div>
                <label
                    class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                    >Prefix</label
                >
                <input
                    type="text"
                    :value="settings.prefix as string"
                    placeholder="$"
                    class="uie-input"
                    @input="
                        update(
                            'prefix',
                            ($event.target as HTMLInputElement).value,
                        )
                    "
                />
            </div>
            <div>
                <label
                    class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                    >Suffix</label
                >
                <input
                    type="text"
                    :value="settings.suffix as string"
                    placeholder="+"
                    class="uie-input"
                    @input="
                        update(
                            'suffix',
                            ($event.target as HTMLInputElement).value,
                        )
                    "
                />
            </div>
        </div>
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
                >Animation Duration (ms)</label
            >
            <input
                type="number"
                min="200"
                max="8000"
                step="100"
                :value="settings.duration as number"
                class="uie-input"
                @input="
                    update(
                        'duration',
                        Number(($event.target as HTMLInputElement).value),
                    )
                "
            />
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Color</label
            >
            <div class="flex items-center gap-2">
                <input
                    type="color"
                    :value="settings.color as string"
                    class="h-8 w-10 cursor-pointer rounded border border-gray-300"
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
                    @input="
                        update(
                            'color',
                            ($event.target as HTMLInputElement).value,
                        )
                    "
                />
            </div>
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Alignment</label
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

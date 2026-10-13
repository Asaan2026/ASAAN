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
                >Section Title</label
            >
            <input
                type="text"
                :value="settings.section_title as string"
                class="uie-input"
                placeholder="Featured Post"
                @input="
                    update(
                        'section_title',
                        ($event.target as HTMLInputElement).value,
                    )
                "
            />
        </div>

        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Category ID (optional)</label
            >
            <input
                type="number"
                :value="(settings.category_id as number) ?? ''"
                class="uie-input"
                placeholder="Leave blank for any category"
                min="1"
                @input="
                    update(
                        'category_id',
                        ($event.target as HTMLInputElement).value
                            ? Number(($event.target as HTMLInputElement).value)
                            : null,
                    )
                "
            />
            <p class="mt-1 text-xs text-gray-400 dark:text-gray-500">
                Filter posts by category ID
            </p>
        </div>

        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Min Height (px)</label
            >
            <input
                type="number"
                :value="(settings.min_height as number) ?? 400"
                class="uie-input"
                min="200"
                max="800"
                step="50"
                @change="
                    update(
                        'min_height',
                        Number(($event.target as HTMLInputElement).value),
                    )
                "
            />
        </div>

        <div class="flex items-center gap-2">
            <input
                id="pf-show-excerpt"
                type="checkbox"
                :checked="(settings.show_excerpt as boolean) ?? true"
                class="rounded text-blue-600"
                @change="
                    update(
                        'show_excerpt',
                        ($event.target as HTMLInputElement).checked,
                    )
                "
            />
            <label
                for="pf-show-excerpt"
                class="text-sm text-gray-700 dark:text-gray-300"
                >Show excerpt</label
            >
        </div>
    </div>
</template>

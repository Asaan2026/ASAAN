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
                >Image URL</label
            >
            <input
                type="text"
                :value="settings.image as string"
                class="uie-input"
                placeholder="/storage/…"
                @input="
                    update('image', ($event.target as HTMLInputElement).value)
                "
            />
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Title</label
            >
            <input
                type="text"
                :value="settings.title as string"
                class="uie-input"
                @input="
                    update('title', ($event.target as HTMLInputElement).value)
                "
            />
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Body</label
            >
            <textarea
                :value="settings.body as string"
                rows="3"
                class="uie-input resize-none"
                @input="
                    update('body', ($event.target as HTMLTextAreaElement).value)
                "
            />
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Badge</label
            >
            <input
                type="text"
                :value="settings.badge as string"
                class="uie-input"
                placeholder="e.g. New"
                @input="
                    update('badge', ($event.target as HTMLInputElement).value)
                "
            />
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Footer Text</label
            >
            <input
                type="text"
                :value="settings.footer as string"
                class="uie-input"
                @input="
                    update('footer', ($event.target as HTMLInputElement).value)
                "
            />
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Link URL</label
            >
            <input
                type="text"
                :value="settings.link as string"
                class="uie-input"
                @input="
                    update('link', ($event.target as HTMLInputElement).value)
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

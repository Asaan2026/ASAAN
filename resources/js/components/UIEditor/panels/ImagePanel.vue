<script setup lang="ts">
import { ref } from 'vue';
import MediaPickerModal from '../MediaPickerModal.vue';

const props = defineProps<{ settings: Record<string, unknown> }>();
const emit = defineEmits<{ 'update:settings': [v: Record<string, unknown>] }>();
function update(key: string, value: unknown) {
    emit('update:settings', { ...props.settings, [key]: value });
}

const showPicker = ref(false);

function onImageSelected(url: string, alt: string) {
    emit('update:settings', {
        ...props.settings,
        image: url,
        alt: props.settings.alt || alt,
    });
}
</script>

<template>
    <div class="space-y-4 p-4">
        <!-- Image preview + browse button -->
        <div>
            <label
                class="mb-2 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Image</label
            >

            <!-- Preview -->
            <div
                v-if="settings.image"
                class="relative mb-2 overflow-hidden rounded-lg border border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-800"
            >
                <img
                    :src="settings.image as string"
                    class="max-h-32 w-full object-contain"
                />
                <button
                    type="button"
                    class="absolute top-1.5 right-1.5 flex h-6 w-6 items-center justify-center rounded-full bg-red-500/90 text-sm leading-none text-white shadow hover:bg-red-600"
                    title="Remove image"
                    @click="update('image', '')"
                >
                    ×
                </button>
            </div>

            <!-- Media picker button -->
            <button
                type="button"
                class="flex w-full items-center justify-center gap-2 rounded-lg border border-blue-300 px-3 py-2 text-sm font-medium text-blue-600 transition-colors hover:bg-blue-50 dark:border-blue-700 dark:text-blue-400 dark:hover:bg-blue-950/30"
                @click="showPicker = true"
            >
                <svg
                    class="h-4 w-4 flex-shrink-0"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                >
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                    />
                </svg>
                {{ settings.image ? 'Change Image' : 'Browse Media Library' }}
            </button>
        </div>

        <!-- Manual URL fallback -->
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Or enter URL directly</label
            >
            <input
                type="text"
                :value="settings.image as string"
                class="uie-input"
                placeholder="/storage/image.jpg or https://…"
                @input="
                    update('image', ($event.target as HTMLInputElement).value)
                "
            />
        </div>

        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Alt Text</label
            >
            <input
                type="text"
                :value="settings.alt as string"
                class="uie-input"
                @input="
                    update('alt', ($event.target as HTMLInputElement).value)
                "
            />
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Caption</label
            >
            <input
                type="text"
                :value="settings.caption as string"
                class="uie-input"
                @input="
                    update('caption', ($event.target as HTMLInputElement).value)
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
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Border Radius (px)</label
            >
            <input
                type="number"
                :value="settings.border_radius as number"
                min="0"
                max="100"
                class="uie-input"
                @change="
                    update(
                        'border_radius',
                        Number(($event.target as HTMLInputElement).value),
                    )
                "
            />
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Width</label
            >
            <input
                type="text"
                :value="settings.width as string"
                placeholder="100% or 400px"
                class="uie-input"
                @input="
                    update('width', ($event.target as HTMLInputElement).value)
                "
            />
        </div>

        <MediaPickerModal v-model="showPicker" @select="onImageSelected" />
    </div>
</template>

<style scoped>
@reference "tailwindcss";
.uie-input {
    @apply w-full rounded-lg border border-gray-300 bg-white px-2 py-1.5 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white;
}
</style>

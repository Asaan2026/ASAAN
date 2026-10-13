<script setup lang="ts">
import { ref } from 'vue';
const props = defineProps<{ settings: Record<string, unknown> }>();
const emit = defineEmits<{ 'update:settings': [v: Record<string, unknown>] }>();
function update(key: string, value: unknown) {
    emit('update:settings', { ...props.settings, [key]: value });
}

const newImageUrl = ref('');
function addImage() {
    if (!newImageUrl.value.trim()) return;
    const imgs = [
        ...((props.settings.images as string[]) ?? []),
        newImageUrl.value.trim(),
    ];
    update('images', imgs);
    newImageUrl.value = '';
}
function removeImage(i: number) {
    const imgs = [...((props.settings.images as string[]) ?? [])];
    imgs.splice(i, 1);
    update('images', imgs);
}
</script>

<template>
    <div class="space-y-4 p-4">
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Layout</label
            >
            <select
                :value="settings.layout as string"
                class="uie-input"
                @change="
                    update('layout', ($event.target as HTMLSelectElement).value)
                "
            >
                <option value="grid">Grid</option>
                <option value="masonry">Masonry</option>
                <option value="carousel">Carousel</option>
            </select>
        </div>
        <div>
            <label
                class="mb-1 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Columns</label
            >
            <input
                type="number"
                :value="settings.columns as number"
                min="1"
                max="6"
                class="uie-input"
                @change="
                    update(
                        'columns',
                        Number(($event.target as HTMLInputElement).value),
                    )
                "
            />
        </div>
        <div>
            <label
                class="mb-2 block text-xs font-medium text-gray-600 dark:text-gray-400"
                >Images</label
            >
            <div class="mb-2 space-y-1.5">
                <div
                    v-for="(img, i) in (settings.images as string[]) ?? []"
                    :key="i"
                    class="flex items-center gap-2"
                >
                    <span
                        class="flex-1 truncate text-xs text-gray-600 dark:text-gray-400"
                        >{{ img }}</span
                    >
                    <button
                        type="button"
                        class="text-xs text-red-500 hover:text-red-700"
                        @click="removeImage(i)"
                    >
                        Remove
                    </button>
                </div>
            </div>
            <div class="flex gap-2">
                <input
                    v-model="newImageUrl"
                    type="text"
                    placeholder="Image URL"
                    class="uie-input flex-1"
                    @keydown.enter.prevent="addImage"
                />
                <button
                    type="button"
                    class="rounded-lg bg-blue-600 px-2 py-1.5 text-xs text-white hover:bg-blue-700"
                    @click="addImage"
                >
                    Add
                </button>
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

<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{ settings: Record<string, unknown> }>();
const emit = defineEmits<{ 'update:settings': [v: Record<string, unknown>] }>();

type Tab = { label: string; content: string };
const tabs = computed(() => (props.settings.tabs as Tab[]) ?? []);

function update(key: string, value: unknown) {
    emit('update:settings', { ...props.settings, [key]: value });
}

function addTab() {
    update('tabs', [
        ...tabs.value,
        {
            label: `Tab ${tabs.value.length + 1}`,
            content: '<p>Tab content here.</p>',
        },
    ]);
}

function removeTab(i: number) {
    const copy = [...tabs.value];
    copy.splice(i, 1);
    update('tabs', copy);
}

function updateTab(i: number, key: string, value: unknown) {
    const copy = tabs.value.map((t, idx) =>
        idx === i ? { ...t, [key]: value } : t,
    );
    update('tabs', copy);
}
</script>

<template>
    <div class="space-y-4 p-4">
        <div class="space-y-3">
            <div
                v-for="(tab, i) in tabs"
                :key="i"
                class="space-y-2 rounded-lg border border-gray-200 p-3 dark:border-gray-700"
            >
                <div class="flex items-center gap-2">
                    <span
                        class="flex-1 text-xs font-semibold text-gray-500 dark:text-gray-400"
                        >Tab {{ i + 1 }}</span
                    >
                    <button
                        type="button"
                        class="text-xs text-red-500 hover:text-red-700"
                        @click="removeTab(i)"
                    >
                        Remove
                    </button>
                </div>
                <div>
                    <label
                        class="mb-1 block text-xs text-gray-500 dark:text-gray-400"
                        >Label</label
                    >
                    <input
                        type="text"
                        :value="tab.label"
                        class="uie-input"
                        @input="
                            updateTab(
                                i,
                                'label',
                                ($event.target as HTMLInputElement).value,
                            )
                        "
                    />
                </div>
                <div>
                    <label
                        class="mb-1 block text-xs text-gray-500 dark:text-gray-400"
                        >Content (HTML)</label
                    >
                    <textarea
                        :value="tab.content"
                        rows="3"
                        class="uie-input resize-none"
                        @input="
                            updateTab(
                                i,
                                'content',
                                ($event.target as HTMLTextAreaElement).value,
                            )
                        "
                    />
                </div>
            </div>
        </div>

        <button
            type="button"
            class="w-full rounded-lg border border-dashed border-blue-300 py-2 text-sm text-blue-600 transition-colors hover:bg-blue-50 dark:border-blue-600 dark:text-blue-400 dark:hover:bg-blue-900/20"
            @click="addTab"
        >
            + Add Tab
        </button>
    </div>
</template>

<style scoped>
@reference "tailwindcss";
.uie-input {
    @apply w-full rounded-lg border border-gray-300 bg-white px-2 py-1.5 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white;
}
</style>

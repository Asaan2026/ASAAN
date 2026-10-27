<script setup lang="ts">
import { ref } from 'vue';

const props = defineProps<{
    settings: Record<string, unknown>;
    editorMode?: boolean;
}>();

type AccordionItem = { title: string; content: string; open?: boolean };

const items = (props.settings.items as AccordionItem[] | undefined) ?? [];

const openStates = ref<Record<number, boolean>>(
    Object.fromEntries(items.map((item, i) => [i, !!item.open])),
);

function toggle(index: number) {
    if (props.editorMode) {
        // In editor: just toggle visually without affecting settings
        if (!props.settings.allow_multiple) {
            const wasOpen = openStates.value[index];
            Object.keys(openStates.value).forEach((k) => {
                openStates.value[+k] = false;
            });
            openStates.value[index] = !wasOpen;
        } else {
            openStates.value[index] = !openStates.value[index];
        }
    }
}
</script>

<template>
    <div
        class="w-full divide-y divide-gray-200 overflow-hidden rounded-lg border border-gray-200 dark:divide-gray-700 dark:border-gray-700"
    >
        <div v-for="(item, index) in items" :key="index">
            <button
                type="button"
                class="dark:hover:bg-gray-750 flex w-full items-center justify-between bg-white px-4 py-3 text-left text-sm font-medium text-gray-800 transition-colors hover:bg-gray-50 dark:bg-gray-800 dark:text-gray-200"
                @click="toggle(index)"
            >
                <span>{{ item.title }}</span>
                <svg
                    class="h-4 w-4 flex-shrink-0 text-gray-400 transition-transform"
                    :class="openStates[index] ? 'rotate-180' : ''"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                >
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M19 9l-7 7-7-7"
                    />
                </svg>
            </button>
            <div
                v-show="openStates[index]"
                class="dark:bg-gray-850 rich-text rich-text-tight bg-gray-50 px-4 py-3 text-sm text-gray-600 dark:text-gray-400"
                v-html="item.content"
            />
        </div>
        <div
            v-if="!(settings.items as unknown[])?.length"
            class="px-4 py-3 text-center text-sm text-gray-400 dark:text-gray-500"
        >
            No accordion items yet
        </div>
    </div>
</template>

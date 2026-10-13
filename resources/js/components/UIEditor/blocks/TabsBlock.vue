<script setup lang="ts">
import { ref } from 'vue';

const props = defineProps<{
    settings: Record<string, unknown>;
    editorMode?: boolean;
}>();

type Tab = { label: string; content: string };

const active = ref((props.settings.active_tab as number) ?? 0);
</script>

<template>
    <div class="w-full">
        <!-- Tab buttons -->
        <div
            class="flex overflow-x-auto border-b border-gray-200 dark:border-gray-700"
        >
            <button
                v-for="(tab, i) in settings.tabs as Tab[]"
                :key="i"
                type="button"
                class="flex-shrink-0 px-4 py-2.5 text-sm font-medium whitespace-nowrap transition-colors"
                :class="
                    active === i
                        ? '-mb-px border-b-2 border-blue-600 bg-white text-blue-600 dark:border-blue-400 dark:bg-gray-900 dark:text-blue-400'
                        : 'text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-100'
                "
                @click="active = i"
            >
                {{ tab.label }}
            </button>
        </div>

        <!-- Tab content -->
        <div
            v-for="(tab, i) in settings.tabs as Tab[]"
            :key="i"
            v-show="active === i"
            class="rounded-b-lg border border-t-0 border-gray-200 bg-white p-4 text-sm text-gray-700 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-300"
            v-html="tab.content"
        />

        <div
            v-if="!(settings.tabs as unknown[])?.length"
            class="rounded-b-lg border border-gray-200 p-4 text-center text-sm text-gray-400 dark:border-gray-700"
        >
            No tabs yet
        </div>
    </div>
</template>

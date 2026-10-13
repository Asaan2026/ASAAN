<script setup lang="ts">
import { useUiEditorStore } from '@/Stores/uiEditorStore';
import { computed, ref } from 'vue';
import draggable from 'vuedraggable';
import SectionWrapper from './SectionWrapper.vue';

const store = useUiEditorStore();

const sections = computed({
    get: () => store.layout.sections,
    set: (val) => {
        store.layout.sections = val;
    },
});

// ── Section structure picker ──────────────────────────────────────────────────
const showPicker = ref(false);
const pickerAfter = ref<number | undefined>(undefined);

const columnLayouts = [
    { label: '1 Column', visual: [1], widths: [12] },
    { label: '2 Columns', visual: [1, 1], widths: [6, 6] },
    { label: '3 Columns', visual: [1, 1, 1], widths: [4, 4, 4] },
    { label: '4 Columns', visual: [1, 1, 1, 1], widths: [3, 3, 3, 3] },
    { label: '2/3 + 1/3', visual: [2, 1], widths: [8, 4] },
    { label: '1/3 + 2/3', visual: [1, 2], widths: [4, 8] },
];

function openPicker(afterIndex?: number) {
    pickerAfter.value = afterIndex;
    showPicker.value = true;
}

function closePicker() {
    showPicker.value = false;
}

function selectLayout(layout: (typeof columnLayouts)[0]) {
    store.addSectionCustom(layout.widths, pickerAfter.value);
    closePicker();
}
</script>

<template>
    <div class="min-h-full pb-20">
        <!-- Sections list -->
        <draggable
            v-model="sections"
            item-key="id"
            handle=".sec-drag-handle"
            ghost-class="opacity-40"
            animation="180"
            class="flex flex-col"
        >
            <template #item="{ element: section, index }">
                <div class="group/insert relative">
                    <SectionWrapper :section="section" :index="index" />

                    <!-- Insert-after divider — appears on section hover -->
                    <div
                        class="relative z-40 flex h-0 items-center justify-center overflow-visible opacity-0 transition-opacity group-hover/insert:opacity-100"
                    >
                        <button
                            type="button"
                            class="flex items-center gap-1 rounded-full bg-blue-500 px-3 py-0.5 text-xs font-medium text-white shadow-md transition-colors hover:bg-blue-600"
                            title="Add section here"
                            @click.stop="openPicker(index)"
                        >
                            <svg
                                class="h-3 w-3"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2.5"
                                    d="M12 4v16m8-8H4"
                                />
                            </svg>
                            Add section
                        </button>
                    </div>
                </div>
            </template>
        </draggable>

        <!-- Add Section at bottom -->
        <div class="mt-8 flex justify-center">
            <button
                type="button"
                class="flex items-center gap-2 rounded-full border-2 border-dashed border-gray-300 px-6 py-2.5 text-sm font-medium text-gray-500 transition-all hover:border-blue-400 hover:text-blue-600 hover:shadow-sm dark:border-gray-600 dark:text-gray-400 dark:hover:text-blue-400"
                @click="openPicker()"
            >
                <svg
                    class="h-4 w-4"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                >
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 4v16m8-8H4"
                    />
                </svg>
                Add Section
            </button>
        </div>

        <!-- ── Section Structure Picker Modal ──────────────────────────────────── -->
        <Teleport to="body">
            <Transition name="picker">
                <div
                    v-if="showPicker"
                    class="fixed inset-0 z-[9999] flex items-center justify-center p-4"
                    @click.self="closePicker"
                >
                    <!-- Backdrop -->
                    <div
                        class="absolute inset-0 bg-black/50 backdrop-blur-sm"
                        @click="closePicker"
                    />

                    <!-- Picker card -->
                    <div
                        class="relative w-[480px] max-w-full overflow-hidden rounded-2xl bg-white shadow-2xl dark:bg-gray-900"
                    >
                        <!-- Header -->
                        <div
                            class="flex items-center justify-between border-b border-gray-100 px-5 py-4 dark:border-gray-800"
                        >
                            <div>
                                <h3
                                    class="text-sm font-semibold text-gray-900 dark:text-white"
                                >
                                    Choose section structure
                                </h3>
                                <p
                                    class="mt-0.5 text-xs text-gray-500 dark:text-gray-400"
                                >
                                    Select a column layout for the new section
                                </p>
                            </div>
                            <button
                                type="button"
                                class="rounded-lg p-1.5 text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600 dark:hover:bg-gray-800"
                                @click="closePicker"
                            >
                                <svg
                                    class="h-4 w-4"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="2"
                                        d="M6 18L18 6M6 6l12 12"
                                    />
                                </svg>
                            </button>
                        </div>

                        <!-- Layout grid -->
                        <div class="grid grid-cols-3 gap-3 p-5">
                            <button
                                v-for="layout in columnLayouts"
                                :key="layout.label"
                                type="button"
                                class="group flex flex-col items-center gap-2.5 rounded-xl border-2 border-gray-200 p-4 transition-all hover:border-blue-400 hover:bg-blue-50 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-700 dark:hover:border-blue-500 dark:hover:bg-blue-900/20"
                                @click="selectLayout(layout)"
                            >
                                <!-- Column preview bars -->
                                <div
                                    class="flex h-10 w-full items-stretch gap-1.5"
                                >
                                    <div
                                        v-for="(w, i) in layout.visual"
                                        :key="i"
                                        class="rounded-md bg-gray-200 transition-colors group-hover:bg-blue-300 dark:bg-gray-700 dark:group-hover:bg-blue-700"
                                        :style="{ flex: w }"
                                    />
                                </div>
                                <span
                                    class="text-xs font-medium text-gray-500 transition-colors group-hover:text-blue-600 dark:text-gray-400 dark:group-hover:text-blue-400"
                                >
                                    {{ layout.label }}
                                </span>
                            </button>
                        </div>
                    </div>
                </div>
            </Transition>
        </Teleport>
    </div>
</template>

<style scoped>
.picker-enter-active,
.picker-leave-active {
    transition:
        opacity 0.15s ease,
        transform 0.15s ease;
}
.picker-enter-from,
.picker-leave-to {
    opacity: 0;
    transform: scale(0.96);
}
</style>

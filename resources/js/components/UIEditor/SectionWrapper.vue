<script setup lang="ts">
import type { Section } from '@/Stores/uiEditorStore';
import { useUiEditorStore } from '@/Stores/uiEditorStore';
import { computed, ref } from 'vue';
import ColumnWrapper from './ColumnWrapper.vue';

const props = defineProps<{ section: Section; index: number }>();
const store = useUiEditorStore();
const hover = ref(false);

const isSelected = computed(() => store.selectedId === props.section.id);

const columnOptions = [
    { label: '1', cols: 1 },
    { label: '2', cols: 2 },
    { label: '3', cols: 3 },
    { label: '4', cols: 4 },
    { label: '2/3 + 1/3', widths: [8, 4] },
    { label: '1/3 + 2/3', widths: [4, 8] },
];

function select() {
    store.selectNode(props.section.id, 'section');
}

function removeSection() {
    store.removeSection(props.section.id);
}

function setColumns(option: { cols?: number; widths?: number[] }) {
    if (option.widths) {
        const section = store.findSection(props.section.id);
        if (!section) return;
        section.columns = option.widths.map((w) => ({
            id: `col_${Math.random().toString(36).slice(2, 9)}`,
            width: w,
            settings: { padding: 16, align: 'left' },
            blocks: [],
        }));
    } else {
        store.setSectionColumns(props.section.id, option.cols!);
    }
}

const sectionStyle = computed(() => ({
    backgroundColor: props.section.settings.background_color ?? '#ffffff',
    paddingTop: `${props.section.settings.padding_top ?? 60}px`,
    paddingBottom: `${props.section.settings.padding_bottom ?? 60}px`,
    ...(props.section.settings.background_image
        ? {
              backgroundImage: `url(${props.section.settings.background_image})`,
              backgroundSize: 'cover',
              backgroundPosition: 'center',
          }
        : {}),
}));

const gridStyle = computed(() => ({
    display: 'grid',
    gridTemplateColumns: props.section.columns
        .map((c) => `${c.width}fr`)
        .join(' '),
    gap: '16px',
}));

// ── Save-as-template modal ──────────────────────────────────────────────────

const showSaveModal = ref(false);
const saveName = ref('');
const saveDesc = ref('');
const isSavingTpl = ref(false);
const saveSuccess = ref(false);

function openSaveModal() {
    saveName.value = `Section ${store.layout.sections.indexOf(props.section) + 1}`;
    saveDesc.value = '';
    saveSuccess.value = false;
    showSaveModal.value = true;
}

async function confirmSave() {
    if (!saveName.value.trim()) return;
    isSavingTpl.value = true;
    try {
        await store.saveToLibrary(
            saveName.value.trim(),
            'section',
            { ...JSON.parse(JSON.stringify(props.section)) } as Record<
                string,
                unknown
            >,
            saveDesc.value.trim() || undefined,
        );
        saveSuccess.value = true;
        setTimeout(() => {
            showSaveModal.value = false;
        }, 1200);
    } finally {
        isSavingTpl.value = false;
    }
}
</script>

<template>
    <div
        class="group/section relative transition-all"
        :class="[
            isSelected
                ? 'ring-2 ring-blue-500 ring-inset'
                : 'hover:ring-1 hover:ring-blue-300 hover:ring-inset',
        ]"
        :style="sectionStyle"
        @mouseenter="hover = true"
        @mouseleave="hover = false"
        @click.self="select"
    >
        <!-- Section toolbar — top-left corner, block toolbar lives at top-right so no overlap -->
        <div
            v-show="hover || isSelected"
            class="absolute top-0 left-0 z-40 flex items-center gap-0.5 rounded-br bg-blue-600 px-1.5 py-0.5 select-none"
        >
            <!-- Drag handle + label -->
            <div
                class="sec-drag-handle flex cursor-grab items-center gap-1 border-r border-white/20 pr-1.5 text-white/80 hover:text-white"
            >
                <svg
                    class="h-3.5 w-3.5"
                    fill="currentColor"
                    viewBox="0 0 24 24"
                >
                    <path
                        d="M9 5a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm6-14a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z"
                    />
                </svg>
                <span class="text-xs leading-none font-medium">Section</span>
            </div>

            <!-- Column layout switcher -->
            <button
                v-for="opt in columnOptions"
                :key="opt.label"
                type="button"
                class="rounded px-1 py-0.5 text-[11px] leading-none text-white/70 transition-colors hover:bg-white/20 hover:text-white"
                :title="`Layout: ${opt.label}`"
                @click.stop="setColumns(opt)"
            >
                {{ opt.label }}
            </button>

            <!-- Divider -->
            <span class="mx-0.5 h-3.5 w-px bg-white/20"></span>

            <!-- Save as template -->
            <button
                type="button"
                class="rounded p-0.5 text-white/70 transition-colors hover:text-yellow-300"
                title="Save as reusable template"
                @click.stop="openSaveModal"
            >
                <svg
                    class="h-3.5 w-3.5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                >
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"
                    />
                </svg>
            </button>

            <!-- Delete -->
            <button
                type="button"
                class="rounded p-0.5 text-white/70 transition-colors hover:text-red-300"
                title="Remove section"
                @click.stop="removeSection"
            >
                <svg
                    class="h-3.5 w-3.5"
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

        <!-- Columns grid -->
        <div
            :style="gridStyle"
            class="w-full"
            :class="section.settings.full_width ? '' : 'mx-auto max-w-7xl px-4'"
            @click.stop="select"
        >
            <ColumnWrapper
                v-for="column in section.columns"
                :key="column.id"
                :section="section"
                :column="column"
            />
        </div>

        <!-- Save-as-template modal -->
        <Teleport to="body">
            <Transition name="fade">
                <div
                    v-if="showSaveModal"
                    class="fixed inset-0 z-[9999] flex items-center justify-center bg-black/50 backdrop-blur-sm"
                    @click.self="showSaveModal = false"
                >
                    <div
                        class="mx-4 w-full max-w-sm rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-900"
                    >
                        <!-- Success state -->
                        <div
                            v-if="saveSuccess"
                            class="flex flex-col items-center gap-3 py-4"
                        >
                            <div
                                class="flex h-12 w-12 items-center justify-center rounded-full bg-green-100 dark:bg-green-900/30"
                            >
                                <svg
                                    class="h-6 w-6 text-green-600 dark:text-green-400"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="2"
                                        d="M5 13l4 4L19 7"
                                    />
                                </svg>
                            </div>
                            <p
                                class="text-sm font-semibold text-gray-900 dark:text-white"
                            >
                                Saved to library!
                            </p>
                        </div>

                        <!-- Form state -->
                        <template v-else>
                            <div class="mb-4 flex items-center gap-3">
                                <div
                                    class="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-lg bg-yellow-100 dark:bg-yellow-900/30"
                                >
                                    <svg
                                        class="h-5 w-5 text-yellow-600 dark:text-yellow-400"
                                        fill="none"
                                        stroke="currentColor"
                                        viewBox="0 0 24 24"
                                    >
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            stroke-width="2"
                                            d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"
                                        />
                                    </svg>
                                </div>
                                <div>
                                    <h3
                                        class="text-sm font-semibold text-gray-900 dark:text-white"
                                    >
                                        Save as Template
                                    </h3>
                                    <p
                                        class="text-xs text-gray-500 dark:text-gray-400"
                                    >
                                        Reuse this section on any page
                                    </p>
                                </div>
                            </div>

                            <div class="space-y-3">
                                <div>
                                    <label
                                        class="mb-1 block text-xs font-medium text-gray-700 dark:text-gray-300"
                                        >Template name
                                        <span class="text-red-500"
                                            >*</span
                                        ></label
                                    >
                                    <input
                                        v-model="saveName"
                                        type="text"
                                        placeholder="e.g. Hero Section, Contact Form…"
                                        class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                                        @keydown.enter="confirmSave"
                                    />
                                </div>
                                <div>
                                    <label
                                        class="mb-1 block text-xs font-medium text-gray-700 dark:text-gray-300"
                                        >Description
                                        <span class="text-gray-400"
                                            >(optional)</span
                                        ></label
                                    >
                                    <input
                                        v-model="saveDesc"
                                        type="text"
                                        placeholder="Brief description…"
                                        class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                                    />
                                </div>
                            </div>

                            <div class="mt-5 flex justify-end gap-2">
                                <button
                                    type="button"
                                    class="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                                    @click="showSaveModal = false"
                                >
                                    Cancel
                                </button>
                                <button
                                    type="button"
                                    :disabled="!saveName.trim() || isSavingTpl"
                                    class="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-40"
                                    @click="confirmSave"
                                >
                                    <span
                                        v-if="isSavingTpl"
                                        class="flex items-center gap-1.5"
                                    >
                                        <svg
                                            class="h-3.5 w-3.5 animate-spin"
                                            fill="none"
                                            viewBox="0 0 24 24"
                                        >
                                            <circle
                                                class="opacity-25"
                                                cx="12"
                                                cy="12"
                                                r="10"
                                                stroke="currentColor"
                                                stroke-width="4"
                                            />
                                            <path
                                                class="opacity-75"
                                                fill="currentColor"
                                                d="M4 12a8 8 0 018-8v8z"
                                            />
                                        </svg>
                                        Saving…
                                    </span>
                                    <span v-else>Save Template</span>
                                </button>
                            </div>
                        </template>
                    </div>
                </div>
            </Transition>
        </Teleport>
    </div>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
    transition: opacity 0.15s ease;
}
.fade-enter-from,
.fade-leave-to {
    opacity: 0;
}
</style>

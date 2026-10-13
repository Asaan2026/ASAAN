<script setup lang="ts">
import type { PageSettingsData } from '@/Stores/uiEditorStore';
import { useUiEditorStore } from '@/Stores/uiEditorStore';
import axios from 'axios';
import { onBeforeUnmount, onMounted, ref, watch } from 'vue';

const store = useUiEditorStore();

// ── Local form state (clone of store.pageSettings) ──────────────────────────
const form = ref<PageSettingsData>({
    id: 0,
    title: '',
    url_key: '',
    status: 'draft',
    is_homepage: false,
    meta_title: null,
    meta_description: null,
    meta_keywords: null,
});
const saveSuccess = ref(false);
const fieldErrors = ref<Record<string, string>>({});

// Sync form whenever store.pageSettings changes (e.g. after save)
watch(
    () => store.pageSettings,
    (val) => {
        if (val) form.value = { ...val };
    },
    { immediate: true, deep: true },
);

// ── Slug availability check ──────────────────────────────────────────────────
const slugAvailable = ref<boolean | null>(null);
const slugChecking = ref(false);
let slugTimer: ReturnType<typeof setTimeout> | null = null;

function onUrlKeyInput() {
    slugAvailable.value = null;
    if (slugTimer) clearTimeout(slugTimer);
    slugTimer = setTimeout(checkSlug, 450);
}

async function checkSlug() {
    if (!form.value.url_key || form.value.is_homepage) return;
    slugChecking.value = true;
    try {
        const res = await axios.post('/admin/content/pages/check-slug', {
            slug: form.value.url_key,
            exclude_id: form.value.id,
        });
        slugAvailable.value = res.data.available;
    } catch {
        slugAvailable.value = null;
    } finally {
        slugChecking.value = false;
    }
}

// ── Save ─────────────────────────────────────────────────────────────────────
async function save() {
    fieldErrors.value = {};
    saveSuccess.value = false;
    try {
        await store.savePageSettings({ ...form.value });
        saveSuccess.value = true;
        setTimeout(() => (saveSuccess.value = false), 3000);
    } catch {
        // settingsError is set inside the store action
    }
}

// ── ESC to close ─────────────────────────────────────────────────────────────
function onKeyDown(e: KeyboardEvent) {
    if (e.key === 'Escape') store.isPageSettingsOpen = false;
}

onMounted(() => window.addEventListener('keydown', onKeyDown));
onBeforeUnmount(() => {
    window.removeEventListener('keydown', onKeyDown);
    if (slugTimer) clearTimeout(slugTimer);
});
</script>

<template>
    <Teleport to="body">
        <!-- Backdrop -->
        <Transition
            enter-active-class="transition-opacity duration-200"
            enter-from-class="opacity-0"
            enter-to-class="opacity-100"
            leave-active-class="transition-opacity duration-200"
            leave-from-class="opacity-100"
            leave-to-class="opacity-0"
        >
            <div
                v-if="store.isPageSettingsOpen"
                class="fixed inset-0 z-[9980] bg-black/30"
                @click="store.isPageSettingsOpen = false"
            />
        </Transition>

        <!-- Slide-over panel -->
        <Transition
            enter-active-class="transition-transform duration-250 ease-out"
            enter-from-class="translate-x-full"
            enter-to-class="translate-x-0"
            leave-active-class="transition-transform duration-200 ease-in"
            leave-from-class="translate-x-0"
            leave-to-class="translate-x-full"
        >
            <div
                v-if="store.isPageSettingsOpen"
                class="fixed top-0 right-0 z-[9990] flex h-full w-96 flex-col overflow-hidden bg-white shadow-2xl dark:bg-gray-900"
            >
                <!-- Header -->
                <div
                    class="flex flex-shrink-0 items-center justify-between border-b border-gray-200 bg-gray-50 px-5 py-4 dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="flex items-center gap-2">
                        <!-- Settings gear icon -->
                        <svg
                            class="h-4 w-4 text-gray-500"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
                            />
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                            />
                        </svg>
                        <h2
                            class="text-sm font-semibold text-gray-800 dark:text-white"
                        >
                            Page Settings
                        </h2>
                    </div>
                    <button
                        type="button"
                        class="flex h-7 w-7 items-center justify-center rounded-md text-gray-400 transition-colors hover:bg-gray-200 hover:text-gray-600 dark:hover:bg-gray-700 dark:hover:text-gray-300"
                        @click="store.isPageSettingsOpen = false"
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

                <!-- Scrollable body -->
                <div class="flex-1 space-y-5 overflow-y-auto p-5">
                    <!-- Success flash -->
                    <Transition
                        enter-active-class="transition-all duration-200"
                        enter-from-class="opacity-0 -translate-y-1"
                        enter-to-class="opacity-100 translate-y-0"
                        leave-active-class="transition-all duration-150"
                        leave-from-class="opacity-100"
                        leave-to-class="opacity-0"
                    >
                        <div
                            v-if="saveSuccess"
                            class="flex items-center gap-2 rounded-lg border border-green-200 bg-green-50 px-3 py-2 text-sm text-green-700"
                        >
                            <svg
                                class="h-4 w-4 flex-shrink-0"
                                fill="currentColor"
                                viewBox="0 0 20 20"
                            >
                                <path
                                    fill-rule="evenodd"
                                    d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                                    clip-rule="evenodd"
                                />
                            </svg>
                            Settings saved successfully.
                        </div>
                    </Transition>

                    <!-- Error flash -->
                    <div
                        v-if="store.settingsError"
                        class="flex items-center gap-2 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700"
                    >
                        <svg
                            class="h-4 w-4 flex-shrink-0"
                            fill="currentColor"
                            viewBox="0 0 20 20"
                        >
                            <path
                                fill-rule="evenodd"
                                d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                                clip-rule="evenodd"
                            />
                        </svg>
                        {{ store.settingsError }}
                    </div>

                    <!-- ── Page Info ──────────────────────────────────────────────── -->
                    <div>
                        <h3
                            class="mb-3 text-xs font-semibold tracking-wider text-gray-400 uppercase dark:text-gray-500"
                        >
                            Page Info
                        </h3>

                        <!-- Title -->
                        <div class="mb-4">
                            <label
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                Title <span class="text-red-500">*</span>
                            </label>
                            <input
                                v-model="form.title"
                                type="text"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                                placeholder="Page title"
                            />
                        </div>

                        <!-- URL Key -->
                        <div class="mb-4">
                            <label
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >URL Key</label
                            >
                            <div class="relative">
                                <span
                                    class="absolute top-1/2 left-3 -translate-y-1/2 text-sm text-gray-400"
                                    >/</span
                                >
                                <input
                                    v-model="form.url_key"
                                    type="text"
                                    :disabled="form.is_homepage"
                                    class="w-full rounded-lg border border-gray-300 bg-white py-2 pr-8 pl-6 font-mono text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 disabled:cursor-not-allowed disabled:opacity-50 dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                                    placeholder="page-url-key"
                                    @input="onUrlKeyInput"
                                />
                                <!-- Availability indicator -->
                                <div
                                    class="absolute top-1/2 right-2.5 -translate-y-1/2"
                                >
                                    <svg
                                        v-if="slugChecking"
                                        class="h-3.5 w-3.5 animate-spin text-gray-400"
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
                                            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
                                        />
                                    </svg>
                                    <svg
                                        v-else-if="slugAvailable === true"
                                        class="h-3.5 w-3.5 text-green-500"
                                        fill="currentColor"
                                        viewBox="0 0 20 20"
                                    >
                                        <path
                                            fill-rule="evenodd"
                                            d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                                            clip-rule="evenodd"
                                        />
                                    </svg>
                                    <svg
                                        v-else-if="slugAvailable === false"
                                        class="h-3.5 w-3.5 text-red-500"
                                        fill="currentColor"
                                        viewBox="0 0 20 20"
                                    >
                                        <path
                                            fill-rule="evenodd"
                                            d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                                            clip-rule="evenodd"
                                        />
                                    </svg>
                                </div>
                            </div>
                            <p
                                v-if="slugAvailable === false"
                                class="mt-1 text-xs text-red-600"
                            >
                                This URL key is already taken.
                            </p>
                            <p
                                v-else-if="form.is_homepage"
                                class="mt-1 text-xs text-gray-400"
                            >
                                Homepage URL is fixed.
                            </p>
                        </div>

                        <!-- Status -->
                        <div v-if="!form.is_homepage">
                            <label
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >Status</label
                            >
                            <select
                                v-model="form.status"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                            >
                                <option value="draft">Draft</option>
                                <option value="published">Published</option>
                                <option value="disabled">Disabled</option>
                            </select>
                            <p class="mt-1 text-xs text-gray-500">
                                Draft pages are not visible on storefront.
                            </p>
                        </div>
                        <div v-else>
                            <label
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >Status</label
                            >
                            <div
                                class="flex items-center gap-2 rounded-lg border border-green-200 bg-green-50 px-3 py-2 dark:border-green-800 dark:bg-green-900/20"
                            >
                                <span
                                    class="h-2 w-2 flex-shrink-0 rounded-full bg-green-500"
                                ></span>
                                <span
                                    class="text-sm font-medium text-green-700 dark:text-green-400"
                                    >Always Published</span
                                >
                            </div>
                        </div>
                    </div>

                    <!-- ── SEO ────────────────────────────────────────────────────── -->
                    <div
                        class="border-t border-gray-100 pt-5 dark:border-gray-700"
                    >
                        <h3
                            class="mb-3 text-xs font-semibold tracking-wider text-gray-400 uppercase dark:text-gray-500"
                        >
                            SEO
                        </h3>

                        <!-- Meta Title -->
                        <div class="mb-4">
                            <div class="mb-1 flex items-center justify-between">
                                <label
                                    class="text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >Meta Title</label
                                >
                                <span
                                    class="text-xs"
                                    :class="
                                        (form.meta_title?.length ?? 0) > 60
                                            ? 'text-amber-500'
                                            : 'text-gray-400'
                                    "
                                >
                                    {{ form.meta_title?.length ?? 0 }}/60
                                </span>
                            </div>
                            <input
                                v-model="form.meta_title"
                                type="text"
                                maxlength="255"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                                placeholder="Leave empty to use page title"
                            />
                        </div>

                        <!-- Meta Description -->
                        <div class="mb-4">
                            <div class="mb-1 flex items-center justify-between">
                                <label
                                    class="text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >Meta Description</label
                                >
                                <span
                                    class="text-xs"
                                    :class="
                                        (form.meta_description?.length ?? 0) >
                                        160
                                            ? 'text-amber-500'
                                            : 'text-gray-400'
                                    "
                                >
                                    {{ form.meta_description?.length ?? 0 }}/160
                                </span>
                            </div>
                            <textarea
                                v-model="form.meta_description"
                                rows="3"
                                maxlength="500"
                                class="w-full resize-none rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                                placeholder="Brief description for search results (150–160 chars recommended)"
                            />
                        </div>

                        <!-- Meta Keywords -->
                        <div>
                            <label
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >Meta Keywords</label
                            >
                            <input
                                v-model="form.meta_keywords"
                                type="text"
                                maxlength="500"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                                placeholder="keyword1, keyword2, keyword3"
                            />
                            <p class="mt-1 text-xs text-gray-400">
                                Comma-separated
                            </p>
                        </div>
                    </div>
                </div>

                <!-- Footer / Save button -->
                <div
                    class="flex-shrink-0 border-t border-gray-200 bg-gray-50 px-5 py-4 dark:border-gray-700 dark:bg-gray-800"
                >
                    <button
                        type="button"
                        class="flex w-full items-center justify-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
                        :disabled="
                            store.isSettingsSaving || slugAvailable === false
                        "
                        @click="save"
                    >
                        <svg
                            v-if="store.isSettingsSaving"
                            class="h-4 w-4 animate-spin"
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
                                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
                            />
                        </svg>
                        <span>{{
                            store.isSettingsSaving
                                ? 'Saving...'
                                : 'Save Settings'
                        }}</span>
                    </button>
                </div>
            </div>
        </Transition>
    </Teleport>
</template>

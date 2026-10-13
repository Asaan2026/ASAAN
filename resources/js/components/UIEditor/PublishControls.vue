<script setup lang="ts">
import { useUiEditorStore } from '@/Stores/uiEditorStore';
import { computed, ref } from 'vue';

const store = useUiEditorStore();

const showUnpublishDialog = ref(false);

const statusLabel = computed(() => {
    if (store.isDirty) return 'Unsaved changes';
    if (store.isSaving) return 'Saving…';
    if (!store.layoutStatus) return 'No layout';
    return store.layoutStatus === 'published' ? 'Published' : 'Draft';
});

const statusColor = computed(() => {
    if (store.isDirty)
        return 'bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-300';
    if (store.isSaving)
        return 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/40 dark:text-yellow-300';
    if (store.layoutStatus === 'published')
        return 'bg-green-100 text-green-700 dark:bg-green-900/40 dark:text-green-300';
    return 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400';
});

const publishedAtFormatted = computed(() => {
    if (!store.publishedAt) return null;
    return new Date(store.publishedAt).toLocaleString(undefined, {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
    });
});

async function handleSaveDraft() {
    await store.triggerSave();
}

async function handlePublish() {
    await store.triggerPublish();
}

async function handleUnpublish() {
    showUnpublishDialog.value = false;
    await store.triggerUnpublish();
}
</script>

<template>
    <div class="flex items-center gap-2">
        <!-- Status badge -->
        <span
            :class="[
                'rounded-full px-2.5 py-1 text-xs font-semibold whitespace-nowrap transition-colors',
                statusColor,
            ]"
            :title="
                publishedAtFormatted
                    ? `Published: ${publishedAtFormatted}`
                    : undefined
            "
        >
            {{ statusLabel }}
        </span>

        <!-- Preview / Edit toggle -->
        <button
            type="button"
            :class="[
                'flex items-center gap-1.5 rounded-lg border px-3 py-1.5 text-sm font-medium transition-colors',
                store.isPreviewIframe
                    ? 'border-indigo-400 bg-indigo-50 text-indigo-700 hover:bg-indigo-100 dark:border-indigo-500 dark:bg-indigo-900/30 dark:text-indigo-300 dark:hover:bg-indigo-900/50'
                    : 'border-gray-300 bg-white text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700',
            ]"
            :title="store.isPreviewIframe ? 'Back to editor' : 'Preview page'"
            @click="store.togglePreviewIframe()"
        >
            <!-- Eye icon (preview) -->
            <svg
                v-if="!store.isPreviewIframe"
                class="h-4 w-4"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
            >
                <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                />
                <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                />
            </svg>
            <!-- Pencil icon (back to edit) -->
            <svg
                v-else
                class="h-4 w-4"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
            >
                <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                />
            </svg>
            {{ store.isPreviewIframe ? 'Edit' : 'Preview' }}
        </button>

        <!-- Save Draft -->
        <button
            type="button"
            :disabled="!store.isDirty || store.isSaving"
            class="rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-40 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
            @click="handleSaveDraft"
        >
            <span v-if="store.isSaving" class="flex items-center gap-1.5">
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
            <span v-else>Save Draft</span>
        </button>

        <!-- Publish (shown when not published) -->
        <button
            v-if="store.layoutStatus !== 'published'"
            type="button"
            :disabled="store.isSaving"
            class="rounded-lg bg-green-600 px-4 py-1.5 text-sm font-medium text-white transition-colors hover:bg-green-700 disabled:cursor-not-allowed disabled:opacity-40"
            @click="handlePublish"
        >
            Publish
        </button>

        <!-- Unpublish (shown when published) -->
        <button
            v-if="store.layoutStatus === 'published'"
            type="button"
            :disabled="store.isSaving"
            class="rounded-lg border border-red-300 bg-white px-3 py-1.5 text-sm font-medium text-red-600 transition-colors hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-40 dark:border-red-700 dark:bg-gray-800 dark:text-red-400 dark:hover:bg-red-900/20"
            @click="showUnpublishDialog = true"
        >
            Unpublish
        </button>

        <!-- Unpublish confirmation dialog -->
        <Teleport to="body">
            <div
                v-if="showUnpublishDialog"
                class="fixed inset-0 z-[9999] flex items-center justify-center bg-black/50 backdrop-blur-sm"
                @click.self="showUnpublishDialog = false"
            >
                <div
                    class="mx-4 w-full max-w-sm rounded-xl bg-white p-6 shadow-2xl dark:bg-gray-900"
                >
                    <div class="mb-4 flex items-start gap-3">
                        <div
                            class="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full bg-red-100 dark:bg-red-900/30"
                        >
                            <svg
                                class="h-5 w-5 text-red-600 dark:text-red-400"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M12 9v4m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"
                                />
                            </svg>
                        </div>
                        <div>
                            <h3
                                class="text-base font-semibold text-gray-900 dark:text-white"
                            >
                                Unpublish page?
                            </h3>
                            <p
                                class="mt-1 text-sm text-gray-600 dark:text-gray-400"
                            >
                                This will take the page offline. Visitors will
                                see the raw HTML content instead. You can
                                republish at any time.
                            </p>
                        </div>
                    </div>
                    <div class="flex justify-end gap-2">
                        <button
                            type="button"
                            class="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                            @click="showUnpublishDialog = false"
                        >
                            Cancel
                        </button>
                        <button
                            type="button"
                            class="rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-red-700"
                            @click="handleUnpublish"
                        >
                            Yes, Unpublish
                        </button>
                    </div>
                </div>
            </div>
        </Teleport>
    </div>
</template>

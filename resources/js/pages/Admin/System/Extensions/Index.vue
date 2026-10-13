<script setup lang="ts">
import ConfirmDeleteModal from '@/components/Admin/ConfirmDeleteModal.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { useI18nStore } from '@/Stores/i18n';
import { Head, router } from '@inertiajs/vue3';
import {
    Box,
    Download,
    Pause,
    Play,
    Puzzle,
    RefreshCcw,
    Trash2,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

type ExtensionSource = 'bundled' | 'filesystem' | null;

interface ExtensionItem {
    code: string;
    name: string;
    description?: string | null;
    version: string;
    author?: string | null;
    author_url?: string | null;
    source: ExtensionSource;
    path?: string | null;
    installed: boolean;
    active: boolean;
    installed_at?: string | null;
    has_db_row: boolean;
}

interface Props {
    extensions: ExtensionItem[];
}

const props = defineProps<Props>();

const { t } = useI18nStore();

const isSyncing = ref(false);
const showDeleteModal = ref(false);
const deleting = ref<ExtensionItem | null>(null);

const isBundled = (ext: ExtensionItem) => ext.source === 'bundled';

const canUninstall = (ext: ExtensionItem) => {
    // Avoid removing first-party bundled extensions from DB via UI.
    // (They would re-appear on next sync anyway.)
    return ext.installed && !isBundled(ext);
};

const hasAnyExtensions = computed(() => (props.extensions?.length ?? 0) > 0);

const sync = () => {
    isSyncing.value = true;
    router.post(
        '/admin/system/extensions/sync',
        {},
        {
            preserveScroll: true,
            onFinish: () => {
                isSyncing.value = false;
            },
        },
    );
};

const install = (code: string) => {
    router.post(
        `/admin/system/extensions/${encodeURIComponent(code)}/install`,
        {},
        { preserveScroll: true },
    );
};

const activate = (code: string) => {
    router.post(
        `/admin/system/extensions/${encodeURIComponent(code)}/activate`,
        {},
        { preserveScroll: true },
    );
};

const deactivate = (code: string) => {
    router.post(
        `/admin/system/extensions/${encodeURIComponent(code)}/deactivate`,
        {},
        { preserveScroll: true },
    );
};

const askUninstall = (ext: ExtensionItem) => {
    deleting.value = ext;
    showDeleteModal.value = true;
};

const confirmUninstall = () => {
    if (!deleting.value) return;

    router.delete(
        `/admin/system/extensions/${encodeURIComponent(deleting.value.code)}`,
        {
            preserveScroll: true,
            onSuccess: () => {
                showDeleteModal.value = false;
                deleting.value = null;
            },
        },
    );
};
</script>

<template>
    <Head :title="$t('Extensions')" />

    <AdminLayout :title="$t('Extensions')">
        <div class="space-y-6">
            <!-- Header -->
            <div
                class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between"
            >
                <div>
                    <h1
                        class="flex items-center gap-2 text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Extensions') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                        {{
                            $t(
                                'Manage and synchronize system extensions and plugins',
                            )
                        }}
                    </p>
                </div>

                <button
                    @click="sync"
                    :disabled="isSyncing"
                    class="inline-flex items-center gap-2 rounded-xl border border-transparent bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition-all duration-200 hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50"
                >
                    <RefreshCcw
                        class="h-4 w-4"
                        :class="isSyncing ? 'animate-spin' : ''"
                    />
                    {{ $t('Sync Extensions') }}
                </button>
            </div>

            <!-- Content -->
            <div class="overflow-auto rounded-xl">
                <!-- Info Banner -->
                <div
                    class="mb-6 flex items-start gap-3 rounded-xl border border-blue-200 bg-blue-50 p-4 dark:border-blue-800 dark:bg-blue-900/20"
                >
                    <div
                        class="shrink-0 rounded-full bg-blue-100 p-2 dark:bg-blue-800"
                    >
                        <Box class="h-5 w-5 text-blue-600 dark:text-blue-400" />
                    </div>
                    <div>
                        <p
                            class="text-sm font-medium text-blue-900 dark:text-blue-100"
                        >
                            {{ $t('Extension Synchronization') }}
                        </p>
                        <p
                            class="mt-1 text-sm text-blue-700 dark:text-blue-300"
                        >
                            {{
                                $t(
                                    'Use the "Sync" button to refresh extension manifests from the file system. Bundled extensions are automatically discovered.',
                                )
                            }}
                        </p>
                    </div>
                </div>

                <div
                    v-if="!hasAnyExtensions"
                    class="flex flex-col items-center justify-center rounded-lg border border-gray-200 bg-white p-12 text-center shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <Puzzle
                        class="mb-4 h-16 w-16 text-gray-300 dark:text-gray-600"
                    />
                    <h3
                        class="mb-2 text-lg font-medium text-gray-900 dark:text-white"
                    >
                        {{ $t('No extensions found') }}
                    </h3>
                    <p class="text-gray-500 dark:text-gray-400">
                        {{ $t('Run sync to discover available extensions.') }}
                    </p>
                </div>

                <div
                    v-else
                    class="overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <table
                        class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                    >
                        <thead class="bg-gray-50 dark:bg-gray-700/50">
                            <tr>
                                <th
                                    class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Name') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Code') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Version') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Source') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Status') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-right text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Actions') }}
                                </th>
                            </tr>
                        </thead>
                        <tbody
                            class="divide-y divide-gray-200 dark:divide-gray-700"
                        >
                            <tr
                                v-for="ext in props.extensions"
                                :key="ext.code"
                                class="group transition-colors hover:bg-gray-50 dark:hover:bg-gray-800/60"
                            >
                                <td class="px-6 py-4">
                                    <div
                                        class="font-medium text-gray-900 dark:text-white"
                                    >
                                        {{ ext.name }}
                                    </div>
                                    <div
                                        v-if="ext.description"
                                        class="mt-1 line-clamp-2 text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ ext.description }}
                                    </div>
                                </td>

                                <td class="px-6 py-4">
                                    <code
                                        class="rounded border border-gray-200 bg-gray-100 px-2 py-1 font-mono text-xs text-gray-700 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300"
                                        >{{ ext.code }}</code
                                    >
                                </td>

                                <td class="px-6 py-4">
                                    <div
                                        class="text-sm text-gray-700 dark:text-gray-300"
                                    >
                                        {{ ext.version }}
                                    </div>
                                </td>

                                <td class="px-6 py-4">
                                    <span
                                        class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium"
                                        :class="
                                            isBundled(ext)
                                                ? 'border-purple-200 bg-purple-50 text-purple-700 dark:border-purple-800 dark:bg-purple-900/20 dark:text-purple-300'
                                                : 'border-gray-200 bg-gray-50 text-gray-700 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300'
                                        "
                                    >
                                        {{
                                            isBundled(ext)
                                                ? $t('Bundled')
                                                : $t('Filesystem')
                                        }}
                                    </span>
                                </td>

                                <td class="px-6 py-4">
                                    <div class="flex items-center gap-2">
                                        <span
                                            class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium"
                                            :class="
                                                ext.installed
                                                    ? 'border-green-200 bg-green-50 text-green-700 dark:border-green-800 dark:bg-green-900/20 dark:text-green-300'
                                                    : 'border-yellow-200 bg-yellow-50 text-yellow-700 dark:border-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-300'
                                            "
                                        >
                                            {{
                                                ext.installed
                                                    ? $t('Installed')
                                                    : $t('Not installed')
                                            }}
                                        </span>

                                        <span
                                            v-if="ext.installed"
                                            class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium"
                                            :class="
                                                ext.active
                                                    ? 'border-blue-200 bg-blue-50 text-blue-700 dark:border-blue-800 dark:bg-blue-900/20 dark:text-blue-300'
                                                    : 'border-gray-200 bg-gray-50 text-gray-700 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300'
                                            "
                                        >
                                            {{
                                                ext.active
                                                    ? $t('Active')
                                                    : $t('Inactive')
                                            }}
                                        </span>
                                    </div>
                                </td>

                                <td
                                    class="px-6 py-4 text-right text-sm whitespace-nowrap"
                                >
                                    <div
                                        class="flex items-center justify-end gap-2 opacity-60 transition-opacity group-hover:opacity-100"
                                    >
                                        <button
                                            v-if="!ext.installed"
                                            @click="install(ext.code)"
                                            class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-green-50 hover:text-green-600 dark:hover:bg-green-900/20"
                                            :title="$t('Install')"
                                        >
                                            <Download class="h-4 w-4" />
                                        </button>

                                        <button
                                            v-else-if="ext.active"
                                            @click="deactivate(ext.code)"
                                            class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-orange-50 hover:text-orange-600 dark:hover:bg-orange-900/20"
                                            :title="$t('Deactivate')"
                                        >
                                            <Pause class="h-4 w-4" />
                                        </button>

                                        <button
                                            v-else
                                            @click="activate(ext.code)"
                                            class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-900/20"
                                            :title="$t('Activate')"
                                        >
                                            <Play class="h-4 w-4" />
                                        </button>

                                        <button
                                            v-if="canUninstall(ext)"
                                            @click="askUninstall(ext)"
                                            class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-900/20"
                                            :title="$t('Uninstall')"
                                        >
                                            <Trash2 class="h-4 w-4" />
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <ConfirmDeleteModal
                    v-model:show="showDeleteModal"
                    :title="deleting?.name || deleting?.code || $t('Extension')"
                    :message="
                        $t(
                            'This will remove the extension from the database and run its uninstall hook (if implemented).',
                        )
                    "
                    @confirm="confirmUninstall"
                />
            </div>
        </div>
    </AdminLayout>
</template>

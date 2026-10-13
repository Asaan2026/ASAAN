<script setup lang="ts">
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import * as backupRoutes from '@/routes/admin/system/backups/index';
import { useI18nStore } from '@/Stores/i18n';
import { Head, router } from '@inertiajs/vue3';
import {
    Download,
    FileArchive,
    HardDrive,
    Plus,
    Trash2,
} from 'lucide-vue-next';
import { ref } from 'vue';

interface Backup {
    path: string;
    date: string;
    size: string;
    disk: string;
}

interface Props {
    backups: Backup[];
}

const props = defineProps<Props>();

const { t } = useI18nStore();

const isLoading = ref(false);
const showCreateModal = ref(false);
const backupOption = ref('only-db'); // Default to DB only as it's faster and common

const createBackup = () => {
    isLoading.value = true;
    showCreateModal.value = false;

    router.post(
        backupRoutes.create().url,
        {
            option: backupOption.value,
        },
        {
            onFinish: () => {
                isLoading.value = false;
            },
            onError: () => {
                isLoading.value = false;
            },
        },
    );
};

const deleteBackup = (backup: Backup) => {
    if (!confirm('Are you sure you want to delete this backup?')) return;

    router.delete(backupRoutes.destroy().url, {
        data: {
            disk: backup.disk,
            path: backup.path,
        },
    });
};

const downloadBackup = (backup: Backup) => {
    // We use window.location for download to avoid Inertia handling the file stream as a page visit
    const url = backupRoutes.download({
        query: {
            disk: backup.disk,
            path: backup.path,
        },
    }).url;
    window.location.href = url;
};
</script>

<template>
    <Head :title="$t('System Backups')" />

    <AdminLayout :title="$t('System Backups')">
        <div class="space-y-6">
            <!-- Header -->
            <div
                class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between"
            >
                <div>
                    <h1
                        class="flex items-center gap-2 text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('System Backups') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                        {{ $t('Create, download, and manage system backups') }}
                    </p>
                </div>
                <button
                    @click="showCreateModal = true"
                    :disabled="isLoading"
                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900 disabled:cursor-not-allowed disabled:opacity-50"
                >
                    <Plus v-if="!isLoading" class="mr-2 h-4 w-4" />
                    <svg
                        v-else
                        class="mr-2 h-4 w-4 animate-spin text-white"
                        xmlns="http://www.w3.org/2000/svg"
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
                        ></circle>
                        <path
                            class="opacity-75"
                            fill="currentColor"
                            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                        ></path>
                    </svg>
                    <span>{{
                        isLoading ? $t('Creating...') : $t('Create Backup')
                    }}</span>
                </button>
            </div>

            <!-- Content -->
            <div class="overflow-auto rounded-xl">
                <!-- Progress Banner -->
                <div
                    v-if="isLoading"
                    class="mb-6 rounded-lg border border-blue-200 bg-blue-50 p-4 dark:border-blue-800 dark:bg-blue-900/20"
                >
                    <div class="flex items-center gap-3">
                        <svg
                            class="h-5 w-5 animate-spin text-blue-600 dark:text-blue-400"
                            xmlns="http://www.w3.org/2000/svg"
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
                            ></circle>
                            <path
                                class="opacity-75"
                                fill="currentColor"
                                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                            ></path>
                        </svg>
                        <div class="flex-1">
                            <p
                                class="text-sm font-medium text-blue-900 dark:text-blue-100"
                            >
                                {{ $t('Creating backup...') }}
                            </p>
                            <p
                                class="mt-1 text-xs text-blue-700 dark:text-blue-300"
                            >
                                {{
                                    $t(
                                        'Please wait while your backup is being created. This may take a few moments depending on the size of your data.',
                                    )
                                }}
                            </p>
                        </div>
                    </div>
                    <!-- Progress bar -->
                    <div
                        class="mt-3 h-2 overflow-hidden rounded-full bg-blue-200 dark:bg-blue-800"
                    >
                        <div
                            class="h-full animate-pulse rounded-full bg-blue-600 dark:bg-blue-400"
                            style="width: 100%"
                        ></div>
                    </div>
                </div>

                <div
                    class="overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <table
                        class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                    >
                        <thead class="bg-gray-50 dark:bg-gray-700/50">
                            <tr>
                                <th
                                    scope="col"
                                    class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('File Name') }}
                                </th>
                                <th
                                    scope="col"
                                    class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Size') }}
                                </th>
                                <th
                                    scope="col"
                                    class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Date') }}
                                </th>
                                <th
                                    scope="col"
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
                                v-for="(backup, index) in backups"
                                :key="index"
                                class="group transition-colors hover:bg-gray-50 dark:hover:bg-gray-700/50"
                            >
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="flex items-center gap-3">
                                        <div
                                            class="rounded-lg bg-gray-100 p-2 dark:bg-gray-700"
                                        >
                                            <FileArchive
                                                class="h-4 w-4 text-gray-500 dark:text-gray-400"
                                            />
                                        </div>
                                        <span
                                            class="text-sm font-medium text-gray-900 dark:text-white"
                                        >
                                            {{ backup.path.split('/').pop() }}
                                        </span>
                                    </div>
                                </td>
                                <td
                                    class="px-6 py-4 text-sm whitespace-nowrap text-gray-500 dark:text-gray-400"
                                >
                                    {{ backup.size }}
                                </td>
                                <td
                                    class="px-6 py-4 text-sm whitespace-nowrap text-gray-500 dark:text-gray-400"
                                >
                                    <DateDisplay :value="backup.date" time />
                                </td>
                                <td
                                    class="px-6 py-4 text-right text-sm whitespace-nowrap"
                                >
                                    <div
                                        class="flex items-center justify-end gap-2"
                                    >
                                        <button
                                            @click="downloadBackup(backup)"
                                            class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-900/20"
                                            :title="$t('Download')"
                                        >
                                            <Download class="h-4 w-4" />
                                        </button>
                                        <button
                                            @click="deleteBackup(backup)"
                                            class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-900/20"
                                            :title="$t('Delete')"
                                        >
                                            <Trash2 class="h-4 w-4" />
                                        </button>
                                    </div>
                                </td>
                            </tr>
                            <tr v-if="backups.length === 0">
                                <td colspan="4" class="px-6 py-12 text-center">
                                    <div
                                        class="flex flex-col items-center justify-center text-gray-500 dark:text-gray-400"
                                    >
                                        <HardDrive
                                            class="mb-4 h-12 w-12 opacity-50"
                                        />
                                        <p class="text-lg font-medium">
                                            {{ $t('No backups found') }}
                                        </p>
                                        <p class="mt-1 text-sm">
                                            {{
                                                $t(
                                                    'Create your first backup to keep your data safe.',
                                                )
                                            }}
                                        </p>
                                    </div>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!-- Create Backup Modal -->
        <Teleport to="body">
            <Transition
                enter-active-class="transition duration-200 ease-out"
                enter-from-class="opacity-0"
                enter-to-class="opacity-100"
                leave-active-class="transition duration-200 ease-in"
                leave-from-class="opacity-100"
                leave-to-class="opacity-0"
            >
                <div
                    v-if="showCreateModal"
                    class="fixed inset-0 z-50 flex items-center justify-center bg-gray-500/75 p-4 dark:bg-gray-900/75"
                    @click="showCreateModal = false"
                >
                    <Transition
                        enter-active-class="transition duration-200 ease-out"
                        enter-from-class="scale-95 opacity-0"
                        enter-to-class="scale-100 opacity-100"
                        leave-active-class="transition duration-200 ease-in"
                        leave-from-class="scale-100 opacity-100"
                        leave-to-class="scale-95 opacity-0"
                    >
                        <div
                            v-if="showCreateModal"
                            class="relative w-full max-w-lg rounded-lg bg-white shadow-xl dark:bg-gray-800"
                            @click.stop
                        >
                            <!-- Header -->
                            <div
                                class="flex items-center justify-between border-b border-gray-200 px-6 py-4 dark:border-gray-700"
                            >
                                <h3
                                    class="text-xl font-semibold text-gray-900 dark:text-white"
                                >
                                    {{ $t('Create New Backup') }}
                                </h3>
                            </div>

                            <!-- Content -->
                            <div class="px-6 py-4">
                                <p
                                    class="mb-4 text-sm text-gray-500 dark:text-gray-400"
                                >
                                    {{
                                        $t(
                                            'Choose what you want to backup. Creating a full backup may take several minutes.',
                                        )
                                    }}
                                </p>

                                <div class="space-y-3">
                                    <div class="flex items-center">
                                        <input
                                            id="only-db"
                                            name="backup-option"
                                            type="radio"
                                            value="only-db"
                                            v-model="backupOption"
                                            class="h-4 w-4 border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                        />
                                        <label
                                            for="only-db"
                                            class="ml-3 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >
                                            {{ $t('Database Only (Fastest)') }}
                                        </label>
                                    </div>
                                    <div class="flex items-center">
                                        <input
                                            id="only-files"
                                            name="backup-option"
                                            type="radio"
                                            value="only-files"
                                            v-model="backupOption"
                                            class="h-4 w-4 border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                        />
                                        <label
                                            for="only-files"
                                            class="ml-3 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >
                                            {{
                                                $t(
                                                    'Files Only (Media & Uploads)',
                                                )
                                            }}
                                        </label>
                                    </div>
                                    <div class="flex items-center">
                                        <input
                                            id="full"
                                            name="backup-option"
                                            type="radio"
                                            value=""
                                            v-model="backupOption"
                                            class="h-4 w-4 border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                        />
                                        <label
                                            for="full"
                                            class="ml-3 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >
                                            {{
                                                $t(
                                                    'Full Backup (Database + Files)',
                                                )
                                            }}
                                        </label>
                                    </div>
                                </div>
                            </div>

                            <!-- Footer -->
                            <div
                                class="flex items-center justify-end gap-3 border-t border-gray-200 px-6 py-4 dark:border-gray-700"
                            >
                                <button
                                    type="button"
                                    @click="showCreateModal = false"
                                    class="rounded-lg px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-700"
                                >
                                    {{ $t('Cancel') }}
                                </button>
                                <button
                                    type="button"
                                    @click="createBackup"
                                    class="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none"
                                >
                                    {{ $t('Create') }}
                                </button>
                            </div>
                        </div>
                    </Transition>
                </div>
            </Transition>
        </Teleport>
    </AdminLayout>
</template>

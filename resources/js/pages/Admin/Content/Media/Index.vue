<script setup lang="ts">
import ConfirmDeleteModal from '@/components/Admin/ConfirmDeleteModal.vue';
import FolderTreeItem from '@/components/Admin/Media/FolderTreeItem.vue';
import UploadDropzone from '@/components/Admin/Media/UploadDropzone.vue';
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import * as folderRoutes from '@/routes/admin/content/folders/index';
import * as mediaRoutes from '@/routes/admin/content/media/index';
import { useI18nStore } from '@/Stores/i18n';
import type {
    MediaFile,
    MediaFilters,
    MediaFolder,
    MediaStatistics,
    MediaViewMode,
    PaginatedMedia,
} from '@/types/media';
import { Head, Link, router, usePage } from '@inertiajs/vue3';
import {
    ArrowUpDown,
    ChevronDown,
    ChevronRight,
    Copy,
    ExternalLink,
    File,
    FileImage,
    FileVideo,
    Filter,
    Folder,
    FolderPlus,
    Grid3x3,
    Home,
    Image,
    Info,
    List,
    Search,
    Upload,
    X,
} from 'lucide-vue-next';
import { computed, ref, watch } from 'vue';

const { t } = useI18nStore();

// Simple debounce function
const debounce = <T extends (...args: any[]) => any>(
    func: T,
    wait: number,
): ((...args: Parameters<T>) => void) => {
    let timeout: ReturnType<typeof setTimeout> | null = null;
    return (...args: Parameters<T>) => {
        if (timeout) clearTimeout(timeout);
        timeout = setTimeout(() => func(...args), wait);
    };
};

interface Props {
    media: PaginatedMedia;
    folders: MediaFolder[];
    currentFolder: MediaFolder | null;
    statistics: MediaStatistics;
    filters: MediaFilters;
}

const props = defineProps<Props>();

const page = usePage();

// View mode state
const viewMode = ref<MediaViewMode>('grid');

// Form state for filters
const form = ref<MediaFilters>({
    folder_id: props.filters.folder_id || null,
    type: props.filters.type || 'all',
    search: props.filters.search || '',
    sort_by: props.filters.sort_by || 'created_at',
    sort_order: props.filters.sort_order || 'desc',
});

// Selection state
const selectedFiles = ref<number[]>([]);
const selectAll = ref(false);

// Folder tree state
const expandedFolders = ref<number[]>([]);
const showNewFolderModal = ref(false);
const showUploadModal = ref(false);
const showDeleteModal = ref(false);
const showFileDetailsModal = ref(false);
const selectedFileDetails = ref<MediaFile | null>(null);
const deleteTarget = ref<{
    type: 'single' | 'bulk';
    file?: MediaFile;
    count?: number;
} | null>(null);
const newFolderName = ref('');
const newFolderParentId = ref<number | null>(null);
const copyUrlFeedback = ref(false);

// Computed properties for delete modal
const deleteModalTitle = computed(() => {
    if (deleteTarget.value?.type === 'bulk') {
        return t('Delete Multiple Files');
    }
    return deleteTarget.value?.file?.original_filename ?? '';
});

const deleteModalMessage = computed(() => {
    if (deleteTarget.value?.type === 'bulk') {
        return t(
            'Are you sure you want to delete {count} file(s)? This action cannot be undone.',
            {
                count: deleteTarget.value.count ?? 0,
            },
        );
    }
    return t(
        "Are you sure you want to delete '{filename}'? This action cannot be undone.",
        {
            filename: deleteTarget.value?.file?.original_filename ?? '',
        },
    );
});

// Toggle folder expansion
const toggleFolder = (folderId: number) => {
    const index = expandedFolders.value.indexOf(folderId);
    if (index > -1) {
        expandedFolders.value.splice(index, 1);
    } else {
        expandedFolders.value.push(folderId);
    }
};

// Navigate to folder
const navigateToFolder = (folderId: number | null) => {
    form.value.folder_id = folderId;
    applyFilters();
};

// Create folder
const createFolder = () => {
    if (!newFolderName.value.trim()) {
        return;
    }

    router.post(
        folderRoutes.store().url,
        {
            name: newFolderName.value,
            parent_id: newFolderParentId.value,
        },
        {
            preserveScroll: true,
            onSuccess: () => {
                showNewFolderModal.value = false;
                newFolderName.value = '';
                newFolderParentId.value = null;
            },
        },
    );
};

const cancelCreateFolder = () => {
    showNewFolderModal.value = false;
    newFolderName.value = '';
    newFolderParentId.value = null;
};

// Build folder tree recursively
const buildFolderTree = (
    folders: MediaFolder[],
    parentId: number | null = null,
): MediaFolder[] => {
    return folders
        .filter((folder) => folder.parent_id === parentId)
        .map((folder) => ({
            ...folder,
            children: buildFolderTree(folders, folder.id),
        }));
};

const folderTree = computed(() => buildFolderTree(props.folders));

// Watch for select all toggle
watch(selectAll, (value) => {
    if (value) {
        selectedFiles.value = props.media.data.map((file) => file.id);
    } else {
        selectedFiles.value = [];
    }
});

// Debounced filter application
const applyFilters = debounce(() => {
    router.get(
        mediaRoutes.index().url,
        {
            folder_id: form.value.folder_id || undefined,
            type: form.value.type !== 'all' ? form.value.type : undefined,
            search: form.value.search || undefined,
            sort_by: form.value.sort_by,
            sort_order: form.value.sort_order,
        },
        {
            preserveState: true,
            preserveScroll: true,
        },
    );
}, 500);

// Watch form changes
watch(() => form.value.search, applyFilters);
watch(() => form.value.type, applyFilters);
watch(() => form.value.folder_id, applyFilters);

// Format file size
const formatSize = (bytes: number | string | null | undefined): string => {
    // If already a string (formatted), return it
    if (typeof bytes === 'string') return bytes;

    // Convert to number if needed
    const numBytes = Number(bytes);

    if (!numBytes || isNaN(numBytes) || numBytes === 0) return '0.00 B';

    const units = ['B', 'KB', 'MB', 'GB'];
    let size = numBytes;
    let unitIndex = 0;

    while (size > 1024 && unitIndex < units.length - 1) {
        size /= 1024;
        unitIndex++;
    }

    return `${size.toFixed(2)} ${units[unitIndex]}`;
};

// Get file icon based on type
const getFileIcon = (file: MediaFile) => {
    if (file.is_image) return FileImage;
    if (file.is_video) return FileVideo;
    return File;
};

// Toggle file selection
const toggleSelection = (fileId: number) => {
    const index = selectedFiles.value.indexOf(fileId);
    if (index > -1) {
        selectedFiles.value.splice(index, 1);
    } else {
        selectedFiles.value.push(fileId);
    }
};

// Clear selection
const clearSelection = () => {
    selectedFiles.value = [];
    selectAll.value = false;
};

// Bulk delete
const bulkDelete = () => {
    deleteTarget.value = {
        type: 'bulk',
        count: selectedFiles.value.length,
    };
    showDeleteModal.value = true;
};

const confirmDelete = () => {
    if (!deleteTarget.value) return;

    if (deleteTarget.value.type === 'bulk') {
        router.post(
            mediaRoutes.bulkAction().url,
            {
                action: 'delete',
                ids: selectedFiles.value,
            },
            {
                preserveScroll: true,
                onSuccess: () => {
                    clearSelection();
                    showDeleteModal.value = false;
                    deleteTarget.value = null;
                },
            },
        );
    } else if (
        deleteTarget.value.type === 'single' &&
        deleteTarget.value.file
    ) {
        router.delete(mediaRoutes.destroy(deleteTarget.value.file.id).url, {
            preserveScroll: true,
            onSuccess: () => {
                showDeleteModal.value = false;
                deleteTarget.value = null;
            },
        });
    }
};

// Watch for modal close to reset deleteTarget
watch(showDeleteModal, (newValue) => {
    if (!newValue) {
        deleteTarget.value = null;
    }
});

// Delete single file
const deleteFile = (file: MediaFile) => {
    deleteTarget.value = {
        type: 'single',
        file: file,
    };
    showDeleteModal.value = true;
};

// Upload handlers
const handleUploadSuccess = (files: File[]) => {
    showUploadModal.value = false;
    // Refresh the page to show uploaded files
    router.reload({ only: ['media', 'statistics'] });
};

const handleUploadError = (message: string) => {
    console.error('Upload error:', message);
    // You could also show a toast notification here
};

// View file details
const viewFileDetails = (file: MediaFile) => {
    selectedFileDetails.value = file;
    showFileDetailsModal.value = true;
};

// Copy URL to clipboard
const copyUrlToClipboard = async (url: string) => {
    try {
        await navigator.clipboard.writeText(url);
        copyUrlFeedback.value = true;
        setTimeout(() => {
            copyUrlFeedback.value = false;
        }, 2000);
    } catch (err) {
        console.error('Failed to copy URL:', err);
        alert('Failed to copy URL to clipboard');
    }
};
</script>

<template>
    <Head :title="$t('Media Library')" />

    <AdminLayout :title="$t('Media Library')">
        <div class="space-y-6 p-6">
            <!-- Header -->
            <div
                class="flex flex-col justify-between gap-4 md:flex-row md:items-center"
            >
                <div>
                    <h1
                        class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white"
                    >
                        {{ $t('Media Library') }}
                    </h1>
                    <div
                        class="mt-1 flex items-center gap-2 text-sm text-gray-500"
                    >
                        <Link
                            href="/admin/dashboard"
                            class="transition-colors hover:text-blue-600"
                            >{{ $t('Dashboard') }}</Link
                        >
                        <ChevronRight :size="14" />
                        <span
                            class="font-medium text-gray-900 dark:text-gray-300"
                            >{{ $t('Media') }}</span
                        >
                    </div>
                </div>
                <div class="flex items-center gap-3">
                    <div
                        class="flex items-center gap-1 rounded-lg border border-gray-100 bg-white p-1 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <button
                            @click="viewMode = 'grid'"
                            :class="[
                                'rounded-md p-2 transition-all',
                                viewMode === 'grid'
                                    ? 'bg-blue-50 text-blue-600 shadow-sm dark:bg-blue-900/20 dark:text-blue-400'
                                    : 'text-gray-400 hover:text-gray-600 dark:hover:text-gray-300',
                            ]"
                            :title="$t('Grid view')"
                        >
                            <Grid3x3 :size="18" />
                        </button>
                        <button
                            @click="viewMode = 'list'"
                            :class="[
                                'rounded-md p-2 transition-all',
                                viewMode === 'list'
                                    ? 'bg-blue-50 text-blue-600 shadow-sm dark:bg-blue-900/20 dark:text-blue-400'
                                    : 'text-gray-400 hover:text-gray-600 dark:hover:text-gray-300',
                            ]"
                            :title="$t('List view')"
                        >
                            <List :size="18" />
                        </button>
                    </div>

                    <button
                        @click="showUploadModal"
                        class="flex items-center rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-all hover:bg-blue-700 focus:ring-4 focus:ring-blue-100"
                    >
                        <Upload :size="16" class="mr-2" />
                        {{ $t('Upload Files') }}
                    </button>
                </div>
            </div>

            <!-- Main Layout -->
            <div class="flex flex-col gap-6 lg:flex-row">
                <!-- Sidebar -->
                <div class="w-full flex-shrink-0 space-y-6 lg:w-64">
                    <!-- All Files -->
                    <div
                        class="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <button
                            @click="navigateToFolder(null)"
                            :class="[
                                'flex w-full items-center gap-3 px-4 py-3 text-left transition-colors',
                                form.folder_id === null
                                    ? 'bg-blue-50 text-blue-600 dark:bg-blue-900/20 dark:text-blue-400'
                                    : 'text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-700/50',
                            ]"
                        >
                            <Home :size="18" />
                            <span class="font-medium">{{
                                $t('All Files')
                            }}</span>
                        </button>
                    </div>

                    <!-- Folders -->
                    <div
                        class="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <div
                            class="flex items-center justify-between border-b border-gray-100 bg-gray-50/50 px-4 py-3 dark:border-gray-700 dark:bg-gray-700/20"
                        >
                            <h3
                                class="font-medium text-gray-900 dark:text-white"
                            >
                                {{ $t('Folders') }}
                            </h3>
                            <button
                                @click="showNewFolderModal = true"
                                class="rounded-lg border border-transparent p-1.5 shadow-sm transition-colors hover:border-gray-200 hover:bg-white dark:hover:bg-gray-600"
                                :title="$t('Create Folder')"
                            >
                                <FolderPlus
                                    :size="16"
                                    class="text-gray-600 dark:text-gray-400"
                                />
                            </button>
                        </div>

                        <div class="p-2">
                            <!-- Folder tree component -->
                            <div v-for="folder in folderTree" :key="folder.id">
                                <FolderTreeItem
                                    :folder="folder"
                                    :current-folder-id="form.folder_id ?? null"
                                    :expanded-folders="expandedFolders"
                                    @toggle="toggleFolder"
                                    @navigate="navigateToFolder"
                                />
                            </div>

                            <!-- Empty state -->
                            <div
                                v-if="folderTree.length === 0"
                                class="py-8 text-center"
                            >
                                <Folder
                                    :size="32"
                                    class="mx-auto mb-2 text-gray-300 dark:text-gray-600"
                                />
                                <p
                                    class="text-sm text-gray-500 dark:text-gray-400"
                                >
                                    {{ $t('No folders yet') }}
                                </p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Main Content -->
                <div class="flex-1 space-y-6">
                    <!-- Stats Grid -->
                    <div class="grid grid-cols-1 gap-4 md:grid-cols-4">
                        <div
                            class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                        >
                            <div class="flex items-center justify-between">
                                <div>
                                    <p
                                        class="text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Total Files') }}
                                    </p>
                                    <p
                                        class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                                    >
                                        {{ statistics.total_files }}
                                    </p>
                                </div>
                                <div
                                    class="rounded-lg border border-blue-100 bg-blue-50 p-3 dark:border-blue-800 dark:bg-blue-900/20"
                                >
                                    <File
                                        :size="24"
                                        class="text-blue-600 dark:text-blue-400"
                                    />
                                </div>
                            </div>
                        </div>

                        <div
                            class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                        >
                            <div class="flex items-center justify-between">
                                <div>
                                    <p
                                        class="text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Images') }}
                                    </p>
                                    <p
                                        class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                                    >
                                        {{ statistics.total_images }}
                                    </p>
                                </div>
                                <div
                                    class="rounded-lg border border-green-100 bg-green-50 p-3 dark:border-green-800 dark:bg-green-900/20"
                                >
                                    <FileImage
                                        :size="24"
                                        class="text-green-600 dark:text-green-400"
                                    />
                                </div>
                            </div>
                        </div>

                        <div
                            class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                        >
                            <div class="flex items-center justify-between">
                                <div>
                                    <p
                                        class="text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Videos') }}
                                    </p>
                                    <p
                                        class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                                    >
                                        {{ statistics.total_videos }}
                                    </p>
                                </div>
                                <div
                                    class="rounded-lg border border-purple-100 bg-purple-50 p-3 dark:border-purple-800 dark:bg-purple-900/20"
                                >
                                    <FileVideo
                                        :size="24"
                                        class="text-purple-600 dark:text-purple-400"
                                    />
                                </div>
                            </div>
                        </div>

                        <div
                            class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                        >
                            <div class="flex items-center justify-between">
                                <div>
                                    <p
                                        class="text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Storage') }}
                                    </p>
                                    <p
                                        class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                                    >
                                        {{ formatSize(statistics.total_size) }}
                                    </p>
                                </div>
                                <div
                                    class="rounded-lg border border-orange-100 bg-orange-50 p-3 dark:border-orange-800 dark:bg-orange-900/20"
                                >
                                    <Image
                                        :size="24"
                                        class="text-orange-600 dark:text-orange-400"
                                    />
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Filter Bar -->
                    <div
                        class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <div class="grid grid-cols-1 gap-4 md:grid-cols-12">
                            <!-- Search -->
                            <div class="md:col-span-6">
                                <label
                                    class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >{{ $t('Search') }}</label
                                >
                                <div class="relative">
                                    <Search
                                        :size="18"
                                        class="absolute top-1/2 left-3 -translate-y-1/2 text-gray-400"
                                    />
                                    <input
                                        v-model="form.search"
                                        type="text"
                                        :placeholder="$t('Search files...')"
                                        class="w-full rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-4 pl-10 text-sm transition-colors focus:border-blue-500 focus:ring-2 focus:ring-blue-100 dark:border-gray-600 dark:bg-gray-700/50"
                                    />
                                </div>
                            </div>

                            <!-- Type filter -->
                            <div class="md:col-span-3">
                                <label
                                    class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >{{ $t('File Type') }}</label
                                >
                                <div class="relative">
                                    <Filter
                                        :size="18"
                                        class="absolute top-1/2 left-3 -translate-y-1/2 text-gray-400"
                                    />
                                    <select
                                        v-model="form.type"
                                        class="w-full appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-4 pl-10 text-sm transition-colors focus:border-blue-500 focus:ring-2 focus:ring-blue-100 dark:border-gray-600 dark:bg-gray-700/50"
                                    >
                                        <option value="all">
                                            {{ $t('All Files') }}
                                        </option>
                                        <option value="images">
                                            {{ $t('Images') }}
                                        </option>
                                        <option value="videos">
                                            {{ $t('Videos') }}
                                        </option>
                                        <option value="documents">
                                            {{ $t('Documents') }}
                                        </option>
                                    </select>
                                    <ChevronDown
                                        :size="16"
                                        class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2 text-gray-400"
                                    />
                                </div>
                            </div>

                            <!-- Sort -->
                            <div class="md:col-span-3">
                                <label
                                    class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >{{ $t('Sort By') }}</label
                                >
                                <div class="relative">
                                    <ArrowUpDown
                                        :size="18"
                                        class="absolute top-1/2 left-3 -translate-y-1/2 text-gray-400"
                                    />
                                    <select
                                        v-model="form.sort_by"
                                        @change="applyFilters"
                                        class="w-full appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-4 pl-10 text-sm transition-colors focus:border-blue-500 focus:ring-2 focus:ring-blue-100 dark:border-gray-600 dark:bg-gray-700/50"
                                    >
                                        <option value="created_at">
                                            {{ $t('Date Added') }}
                                        </option>
                                        <option value="original_filename">
                                            {{ $t('Name') }}
                                        </option>
                                        <option value="size">
                                            {{ $t('Size') }}
                                        </option>
                                    </select>
                                    <ChevronDown
                                        :size="16"
                                        class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2 text-gray-400"
                                    />
                                </div>
                            </div>
                        </div>

                        <!-- Selection toolbar -->
                        <div
                            v-if="selectedFiles.length > 0"
                            class="mt-4 flex items-center justify-between rounded-lg border border-blue-100 bg-blue-50 p-3 dark:border-blue-800 dark:bg-blue-900/20"
                        >
                            <span
                                class="flex items-center gap-2 text-sm font-medium text-blue-900 dark:text-blue-100"
                            >
                                <div
                                    class="h-1.5 w-1.5 rounded-full bg-blue-500"
                                ></div>
                                {{
                                    $t('{count} file(s) selected', {
                                        count: selectedFiles.length,
                                    })
                                }}
                            </span>
                            <div class="flex items-center gap-2">
                                <button
                                    @click="bulkDelete"
                                    class="rounded-md px-3 py-1.5 text-sm font-medium text-red-600 transition-colors hover:bg-red-50 hover:text-red-700"
                                >
                                    {{ $t('Delete Selected') }}
                                </button>
                                <button
                                    @click="clearSelection"
                                    class="rounded-md px-3 py-1.5 text-sm font-medium text-gray-500 transition-colors hover:bg-gray-100 hover:text-gray-700"
                                >
                                    {{ $t('Clear') }}
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Content Grid -->
                    <div
                        class="min-h-[400px] rounded-xl border border-gray-100 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <!-- Empty state -->
                        <div
                            v-if="media.data.length === 0"
                            class="py-12 text-center"
                        >
                            <Image
                                :size="48"
                                class="mx-auto mb-4 text-gray-300 dark:text-gray-600"
                            />
                            <h3
                                class="mb-2 text-lg font-medium text-gray-900 dark:text-white"
                            >
                                {{ $t('No files found') }}
                            </h3>
                            <p class="text-sm text-gray-500 dark:text-gray-400">
                                {{ $t('Upload files to get started') }}
                            </p>
                        </div>

                        <!-- Grid view -->
                        <div
                            v-else-if="viewMode === 'grid'"
                            class="grid grid-cols-2 gap-4 md:grid-cols-4 lg:grid-cols-6"
                        >
                            <div
                                v-for="file in media.data"
                                :key="file.id"
                                :class="[
                                    'group relative aspect-square overflow-hidden rounded-lg border-2 transition-all',
                                    selectedFiles.includes(file.id)
                                        ? 'border-blue-500 ring-2 ring-blue-500 ring-offset-2'
                                        : 'border-gray-200 hover:border-gray-300 dark:border-gray-700 dark:hover:border-gray-600',
                                ]"
                            >
                                <!-- Checkbox -->
                                <div class="absolute top-2 left-2 z-10">
                                    <input
                                        type="checkbox"
                                        :checked="
                                            selectedFiles.includes(file.id)
                                        "
                                        class="h-5 w-5 rounded border-gray-300 bg-white text-blue-600 focus:ring-blue-500"
                                        @click.stop
                                        @change="toggleSelection(file.id)"
                                    />
                                </div>

                                <!-- View Details Button -->
                                <button
                                    @click="viewFileDetails(file)"
                                    class="absolute top-2 right-2 z-10 rounded-lg bg-white p-1.5 opacity-0 shadow-md transition-opacity group-hover:opacity-100 hover:bg-gray-100 dark:bg-gray-800 dark:hover:bg-gray-700"
                                    :title="$t('View details')"
                                >
                                    <Info
                                        :size="16"
                                        class="text-gray-600 dark:text-gray-400"
                                    />
                                </button>

                                <!-- Image preview -->
                                <div
                                    v-if="file.is_image"
                                    class="h-full w-full cursor-pointer"
                                    @click="viewFileDetails(file)"
                                >
                                    <img
                                        :src="file.thumbnail_url || file.url"
                                        :alt="
                                            file.alt_text ||
                                            file.original_filename
                                        "
                                        class="h-full w-full object-cover"
                                    />
                                </div>

                                <!-- Non-image file icon -->
                                <div
                                    v-else
                                    class="flex h-full w-full cursor-pointer items-center justify-center bg-gray-50 dark:bg-gray-700"
                                    @click="viewFileDetails(file)"
                                >
                                    <component
                                        :is="getFileIcon(file)"
                                        :size="48"
                                        class="text-gray-400"
                                    />
                                </div>

                                <!-- Overlay on hover -->
                                <div
                                    class="pointer-events-none absolute inset-0 flex items-center justify-center bg-black/0 opacity-0 transition-all group-hover:bg-black/50 group-hover:opacity-100"
                                >
                                    <p
                                        class="w-full truncate px-2 text-center text-xs font-medium text-white"
                                    >
                                        {{ file.original_filename }}
                                    </p>
                                </div>
                            </div>
                        </div>

                        <!-- List view -->
                        <div v-else class="overflow-x-auto">
                            <table
                                class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                            >
                                <thead class="bg-gray-50 dark:bg-gray-700">
                                    <tr>
                                        <th class="px-6 py-3 text-left">
                                            <input
                                                v-model="selectAll"
                                                type="checkbox"
                                                class="h-4 w-4 rounded border-gray-300 bg-white text-blue-600 focus:ring-blue-500"
                                            />
                                        </th>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Preview') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Name') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Size') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Type') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Uploaded') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Actions') }}
                                        </th>
                                    </tr>
                                </thead>
                                <tbody
                                    class="divide-y divide-gray-200 bg-white dark:divide-gray-700 dark:bg-gray-800"
                                >
                                    <tr
                                        v-for="file in media.data"
                                        :key="file.id"
                                        :class="[
                                            'transition-colors hover:bg-gray-50 dark:hover:bg-gray-700/50',
                                            selectedFiles.includes(file.id)
                                                ? 'bg-blue-50 dark:bg-blue-900/20'
                                                : '',
                                        ]"
                                    >
                                        <td class="px-6 py-4">
                                            <input
                                                type="checkbox"
                                                :checked="
                                                    selectedFiles.includes(
                                                        file.id,
                                                    )
                                                "
                                                @change="
                                                    toggleSelection(file.id)
                                                "
                                                class="h-4 w-4 rounded border-gray-300 bg-white text-blue-600 focus:ring-blue-500"
                                            />
                                        </td>
                                        <td class="px-6 py-4">
                                            <div
                                                class="h-12 w-12 overflow-hidden rounded bg-gray-100 dark:bg-gray-700"
                                            >
                                                <img
                                                    v-if="file.is_image"
                                                    :src="
                                                        file.thumbnail_url ||
                                                        file.url
                                                    "
                                                    :alt="
                                                        file.alt_text ||
                                                        file.original_filename
                                                    "
                                                    class="h-full w-full object-cover"
                                                />
                                                <div
                                                    v-else
                                                    class="flex h-full w-full items-center justify-center"
                                                >
                                                    <component
                                                        :is="getFileIcon(file)"
                                                        :size="24"
                                                        class="text-gray-400"
                                                    />
                                                </div>
                                            </div>
                                        </td>
                                        <td class="px-6 py-4">
                                            <div
                                                class="text-sm font-medium text-gray-900 dark:text-white"
                                            >
                                                {{ file.original_filename }}
                                            </div>
                                            <div
                                                v-if="file.title"
                                                class="text-xs text-gray-500 dark:text-gray-400"
                                            >
                                                {{ file.title }}
                                            </div>
                                        </td>
                                        <td
                                            class="px-6 py-4 text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            {{ file.formatted_size }}
                                        </td>
                                        <td
                                            class="px-6 py-4 text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            {{
                                                file.extension?.toUpperCase() ||
                                                $t('Unknown')
                                            }}
                                        </td>
                                        <td
                                            class="px-6 py-4 text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            <DateDisplay
                                                :value="file.created_at"
                                                time
                                            />
                                        </td>
                                        <td
                                            class="px-6 py-4 text-right text-sm font-medium"
                                        >
                                            <div
                                                class="flex items-center justify-end gap-2"
                                            >
                                                <button
                                                    @click="
                                                        viewFileDetails(file)
                                                    "
                                                    class="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300"
                                                >
                                                    {{ $t('View') }}
                                                </button>
                                                <button
                                                    @click="deleteFile(file)"
                                                    class="text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300"
                                                >
                                                    {{ $t('Delete') }}
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>

                        <!-- Pagination -->
                        <div
                            v-if="media.last_page > 1"
                            class="mt-6 flex items-center justify-between"
                        >
                            <div
                                class="text-sm text-gray-500 dark:text-gray-400"
                            >
                                {{
                                    $t(
                                        'Showing {from} to {to} of {total} files',
                                        {
                                            from: media.from,
                                            to: media.to,
                                            total: media.total,
                                        },
                                    )
                                }}
                            </div>
                            <div class="flex gap-2">
                                <button
                                    v-for="page in media.last_page"
                                    :key="page"
                                    @click="
                                        router.get(
                                            mediaRoutes.index().url +
                                                `?page=${page}`,
                                        )
                                    "
                                    :class="[
                                        'rounded-lg px-3 py-1.5 text-sm font-medium transition-colors',
                                        page === media.current_page
                                            ? 'bg-blue-600 text-white'
                                            : 'border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600',
                                    ]"
                                >
                                    {{ page }}
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <!-- End of flex container -->

        <!-- Upload Modal -->
        <div v-if="showUploadModal" class="fixed inset-0 z-50 overflow-y-auto">
            <div
                class="flex min-h-screen items-center justify-center px-4 pt-4 pb-20 text-center sm:block sm:p-0"
            >
                <!-- Background overlay -->
                <div
                    class="fixed inset-0 bg-gray-500/75 transition-opacity dark:bg-gray-900/75"
                    @click="showUploadModal = false"
                ></div>

                <!-- Modal panel -->
                <div
                    class="relative z-10 inline-block transform overflow-hidden rounded-lg bg-white text-left align-bottom shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-2xl sm:align-middle dark:bg-gray-800"
                >
                    <!-- Header -->
                    <div
                        class="flex items-center justify-between border-b border-gray-200 px-6 py-4 dark:border-gray-700"
                    >
                        <h3
                            class="text-lg font-medium text-gray-900 dark:text-white"
                        >
                            {{ $t('Upload Files') }}
                        </h3>
                        <button
                            @click="showUploadModal = false"
                            type="button"
                            class="text-gray-400 hover:text-gray-500 dark:hover:text-gray-300"
                        >
                            <X :size="20" />
                        </button>
                    </div>

                    <!-- Body -->
                    <div class="px-6 py-4">
                        <UploadDropzone
                            :folder-id="form.folder_id"
                            @success="handleUploadSuccess"
                            @error="handleUploadError"
                        />
                    </div>
                </div>
            </div>
        </div>

        <!-- Delete Confirmation Modal -->
        <ConfirmDeleteModal
            v-model:show="showDeleteModal"
            :title="deleteModalTitle"
            :message="deleteModalMessage"
            @confirm="confirmDelete"
        />

        <!-- File Details Modal -->
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
                    v-if="showFileDetailsModal && selectedFileDetails"
                    class="fixed inset-0 z-50 flex items-center justify-center bg-gray-500/75 p-4 dark:bg-gray-900/75"
                    @click="showFileDetailsModal = false"
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
                            v-if="showFileDetailsModal && selectedFileDetails"
                            class="relative max-h-[90vh] w-full max-w-4xl overflow-y-auto rounded-lg bg-white shadow-xl dark:bg-gray-800"
                            @click.stop
                        >
                            <!-- Header -->
                            <div
                                class="flex items-center justify-between border-b border-gray-200 px-6 py-4 dark:border-gray-700"
                            >
                                <h3
                                    class="text-lg font-medium text-gray-900 dark:text-white"
                                >
                                    {{ $t('File Details') }}
                                </h3>
                                <button
                                    @click="showFileDetailsModal = false"
                                    type="button"
                                    class="text-gray-400 hover:text-gray-500 dark:hover:text-gray-300"
                                >
                                    <X :size="20" />
                                </button>
                            </div>

                            <!-- Body -->
                            <div class="px-6 py-4">
                                <div
                                    class="grid grid-cols-1 gap-6 md:grid-cols-2"
                                >
                                    <!-- Preview -->
                                    <div>
                                        <label
                                            class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >
                                            {{ $t('Preview') }}
                                        </label>
                                        <div
                                            class="overflow-hidden rounded-lg border border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-700"
                                        >
                                            <img
                                                v-if="
                                                    selectedFileDetails.is_image
                                                "
                                                :src="selectedFileDetails.url"
                                                :alt="
                                                    selectedFileDetails.alt_text ||
                                                    selectedFileDetails.original_filename
                                                "
                                                class="h-auto w-full"
                                            />
                                            <div
                                                v-else
                                                class="flex h-64 items-center justify-center"
                                            >
                                                <component
                                                    :is="
                                                        getFileIcon(
                                                            selectedFileDetails,
                                                        )
                                                    "
                                                    :size="64"
                                                    class="text-gray-400"
                                                />
                                            </div>
                                        </div>
                                    </div>

                                    <!-- Details -->
                                    <div class="space-y-4">
                                        <!-- Filename -->
                                        <div>
                                            <label
                                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                            >
                                                {{ $t('Filename') }}
                                            </label>
                                            <p
                                                class="text-sm text-gray-900 dark:text-white"
                                            >
                                                {{
                                                    selectedFileDetails.original_filename
                                                }}
                                            </p>
                                        </div>

                                        <!-- URL with Copy Button -->
                                        <div>
                                            <label
                                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                            >
                                                {{ $t('File URL') }}
                                            </label>
                                            <div
                                                class="flex items-center gap-2"
                                            >
                                                <input
                                                    type="text"
                                                    :value="
                                                        selectedFileDetails.url
                                                    "
                                                    readonly
                                                    class="flex-1 rounded-lg border border-gray-300 bg-gray-50 px-3 py-2 text-sm text-gray-900 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                                />
                                                <button
                                                    @click="
                                                        copyUrlToClipboard(
                                                            selectedFileDetails.url,
                                                        )
                                                    "
                                                    class="flex items-center gap-2 rounded-lg bg-blue-600 px-3 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700"
                                                    :class="{
                                                        'bg-green-600 hover:bg-green-700':
                                                            copyUrlFeedback,
                                                    }"
                                                >
                                                    <Copy :size="16" />
                                                    {{
                                                        copyUrlFeedback
                                                            ? $t('Copied!')
                                                            : $t('Copy')
                                                    }}
                                                </button>
                                            </div>
                                        </div>

                                        <!-- Thumbnail URL (if image) -->
                                        <div
                                            v-if="
                                                selectedFileDetails.is_image &&
                                                selectedFileDetails.thumbnail_url
                                            "
                                        >
                                            <label
                                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                            >
                                                {{ $t('Thumbnail URL') }}
                                            </label>
                                            <div
                                                class="flex items-center gap-2"
                                            >
                                                <input
                                                    type="text"
                                                    :value="
                                                        selectedFileDetails.thumbnail_url
                                                    "
                                                    readonly
                                                    class="flex-1 rounded-lg border border-gray-300 bg-gray-50 px-3 py-2 text-sm text-gray-900 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                                />
                                                <button
                                                    @click="
                                                        copyUrlToClipboard(
                                                            selectedFileDetails.thumbnail_url!,
                                                        )
                                                    "
                                                    class="flex items-center gap-2 rounded-lg bg-blue-600 px-3 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700"
                                                >
                                                    <Copy :size="16" />
                                                    {{ $t('Copy') }}
                                                </button>
                                            </div>
                                        </div>

                                        <!-- File Type -->
                                        <div>
                                            <label
                                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                            >
                                                {{ $t('File Type') }}
                                            </label>
                                            <p
                                                class="text-sm text-gray-900 dark:text-white"
                                            >
                                                {{
                                                    selectedFileDetails.mime_type
                                                }}
                                                ({{
                                                    selectedFileDetails.extension?.toUpperCase()
                                                }})
                                            </p>
                                        </div>

                                        <!-- File Size -->
                                        <div>
                                            <label
                                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                            >
                                                {{ $t('File Size') }}
                                            </label>
                                            <p
                                                class="text-sm text-gray-900 dark:text-white"
                                            >
                                                {{
                                                    selectedFileDetails.formatted_size
                                                }}
                                            </p>
                                        </div>

                                        <!-- Dimensions (if image) -->
                                        <div
                                            v-if="
                                                selectedFileDetails.width &&
                                                selectedFileDetails.height
                                            "
                                        >
                                            <label
                                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                            >
                                                {{ $t('Dimensions') }}
                                            </label>
                                            <p
                                                class="text-sm text-gray-900 dark:text-white"
                                            >
                                                {{
                                                    selectedFileDetails.width
                                                }}
                                                ×
                                                {{
                                                    selectedFileDetails.height
                                                }}
                                                px
                                            </p>
                                        </div>

                                        <!-- Alt Text -->
                                        <div
                                            v-if="selectedFileDetails.alt_text"
                                        >
                                            <label
                                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                            >
                                                {{ $t('Alt Text') }}
                                            </label>
                                            <p
                                                class="text-sm text-gray-900 dark:text-white"
                                            >
                                                {{
                                                    selectedFileDetails.alt_text
                                                }}
                                            </p>
                                        </div>

                                        <!-- Title -->
                                        <div v-if="selectedFileDetails.title">
                                            <label
                                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                            >
                                                {{ $t('Title') }}
                                            </label>
                                            <p
                                                class="text-sm text-gray-900 dark:text-white"
                                            >
                                                {{ selectedFileDetails.title }}
                                            </p>
                                        </div>

                                        <!-- Description -->
                                        <div
                                            v-if="
                                                selectedFileDetails.description
                                            "
                                        >
                                            <label
                                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                            >
                                                {{ $t('Description') }}
                                            </label>
                                            <p
                                                class="text-sm text-gray-900 dark:text-white"
                                            >
                                                {{
                                                    selectedFileDetails.description
                                                }}
                                            </p>
                                        </div>

                                        <!-- Uploaded Date -->
                                        <div>
                                            <label
                                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                            >
                                                {{ $t('Uploaded') }}
                                            </label>
                                            <p
                                                class="text-sm text-gray-900 dark:text-white"
                                            >
                                                <DateDisplay
                                                    :value="
                                                        selectedFileDetails.created_at
                                                    "
                                                    time
                                                />
                                            </p>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Footer -->
                            <div
                                class="flex items-center justify-between bg-gray-50 px-6 py-4 dark:bg-gray-700/50"
                            >
                                <a
                                    :href="selectedFileDetails.url"
                                    target="_blank"
                                    class="flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-600"
                                >
                                    <ExternalLink :size="16" />
                                    {{ $t('Open in New Tab') }}
                                </a>
                                <button
                                    @click="showFileDetailsModal = false"
                                    type="button"
                                    class="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700"
                                >
                                    {{ $t('Close') }}
                                </button>
                            </div>
                        </div>
                    </Transition>
                </div>
            </Transition>
        </Teleport>

        <!-- New Folder Modal -->
        <div
            v-if="showNewFolderModal"
            class="fixed inset-0 z-50 overflow-y-auto"
        >
            <div
                class="flex min-h-screen items-center justify-center px-4 pt-4 pb-20 text-center sm:block sm:p-0"
            >
                <!-- Background overlay -->
                <div
                    class="fixed inset-0 bg-gray-500/75 transition-opacity dark:bg-gray-900/75"
                    @click="cancelCreateFolder"
                ></div>

                <!-- Modal panel -->
                <div
                    class="relative z-10 inline-block transform overflow-hidden rounded-lg bg-white text-left align-bottom shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-md sm:align-middle dark:bg-gray-800"
                >
                    <!-- Header -->
                    <div
                        class="border-b border-gray-200 px-6 py-4 dark:border-gray-700"
                    >
                        <div class="flex items-center justify-between">
                            <h3
                                class="text-lg font-medium text-gray-900 dark:text-white"
                            >
                                {{ $t('Create New Folder') }}
                            </h3>
                            <button
                                @click="cancelCreateFolder"
                                type="button"
                                class="text-gray-400 hover:text-gray-500 dark:hover:text-gray-300"
                            >
                                <X :size="20" />
                            </button>
                        </div>
                    </div>

                    <!-- Body -->
                    <div class="px-6 py-4">
                        <div>
                            <label
                                for="folder-name"
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Folder Name') }}
                            </label>
                            <input
                                id="folder-name"
                                v-model="newFolderName"
                                type="text"
                                :placeholder="$t('Enter folder name')"
                                class="w-full rounded-lg border border-gray-300 px-4 py-2 focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                @keyup.enter="createFolder"
                            />
                        </div>
                    </div>

                    <!-- Footer -->
                    <div
                        class="flex items-center justify-end gap-3 bg-gray-50 px-6 py-4 dark:bg-gray-700/50"
                    >
                        <button
                            @click="cancelCreateFolder"
                            type="button"
                            class="rounded-lg px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-600"
                        >
                            {{ $t('Cancel') }}
                        </button>
                        <button
                            @click="createFolder"
                            type="button"
                            :disabled="!newFolderName.trim()"
                            class="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
                        >
                            {{ $t('Create Folder') }}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

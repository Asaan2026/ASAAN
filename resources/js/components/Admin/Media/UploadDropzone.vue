<script setup lang="ts">
import * as mediaRoutes from '@/routes/admin/content/media/index';
import { router } from '@inertiajs/vue3';
import { AlertCircle, FileIcon, Upload, X } from 'lucide-vue-next';
import { computed, ref } from 'vue';

interface Props {
    folderId?: number | null;
    maxFileSize?: number; // in MB
    acceptedTypes?: string[];
}

const props = withDefaults(defineProps<Props>(), {
    folderId: null,
    maxFileSize: 10,
    acceptedTypes: () => ['image/*', 'video/*', 'application/pdf'],
});

const emit = defineEmits<{
    success: [files: File[]];
    error: [message: string];
}>();

const isDragging = ref(false);
const isUploading = ref(false);
const uploadProgress = ref(0);
const selectedFiles = ref<File[]>([]);
const errors = ref<string[]>([]);

const fileInput = ref<HTMLInputElement | null>(null);

// Computed
const acceptString = computed(() => props.acceptedTypes.join(','));

// Methods
const openFileDialog = () => {
    fileInput.value?.click();
};

const handleFileSelect = (event: Event) => {
    const target = event.target as HTMLInputElement;
    if (target.files) {
        addFiles(Array.from(target.files));
    }
    // Reset input so same file can be selected again
    target.value = '';
};

const handleDrop = (event: DragEvent) => {
    isDragging.value = false;
    if (event.dataTransfer?.files) {
        addFiles(Array.from(event.dataTransfer.files));
    }
};

const handleDragOver = (event: DragEvent) => {
    event.preventDefault();
    isDragging.value = true;
};

const handleDragLeave = () => {
    isDragging.value = false;
};

const addFiles = (files: File[]) => {
    errors.value = [];
    const validFiles: File[] = [];

    files.forEach((file) => {
        // Check file size
        const maxSize = props.maxFileSize * 1024 * 1024; // Convert to bytes
        if (file.size > maxSize) {
            errors.value.push(
                `${file.name} exceeds maximum size of ${props.maxFileSize}MB`,
            );
            return;
        }

        // Check file type
        const isTypeAccepted = props.acceptedTypes.some((type) => {
            if (type.endsWith('/*')) {
                const category = type.split('/')[0];
                return file.type.startsWith(category + '/');
            }
            return file.type === type;
        });

        if (!isTypeAccepted) {
            errors.value.push(`${file.name} is not an accepted file type`);
            return;
        }

        validFiles.push(file);
    });

    selectedFiles.value = [...selectedFiles.value, ...validFiles];
};

const removeFile = (index: number) => {
    selectedFiles.value.splice(index, 1);
};

const clearFiles = () => {
    selectedFiles.value = [];
    errors.value = [];
    uploadProgress.value = 0;
};

const uploadFiles = async () => {
    if (selectedFiles.value.length === 0) return;

    isUploading.value = true;
    errors.value = [];

    const formData = new FormData();

    selectedFiles.value.forEach((file, index) => {
        formData.append(`files[${index}]`, file);
    });

    if (props.folderId) {
        formData.append('folder_id', props.folderId.toString());
    }

    try {
        router.post(mediaRoutes.upload().url, formData, {
            forceFormData: true,
            preserveScroll: true,
            onProgress: (progress) => {
                if (progress) {
                    uploadProgress.value = progress.percentage || 0;
                }
            },
            onSuccess: () => {
                emit('success', selectedFiles.value);
                clearFiles();
                isUploading.value = false;
            },
            onError: (errors) => {
                const errorMessages = Object.values(errors).flat() as string[];
                emit('error', errorMessages.join(', '));
                isUploading.value = false;
            },
        });
    } catch {
        errors.value.push('Upload failed. Please try again.');
        emit('error', 'Upload failed');
        isUploading.value = false;
    }
};

const formatFileSize = (bytes: number): string => {
    const units = ['B', 'KB', 'MB', 'GB'];
    let size = bytes;
    let unitIndex = 0;

    while (size > 1024 && unitIndex < units.length - 1) {
        size /= 1024;
        unitIndex++;
    }

    return `${size.toFixed(2)} ${units[unitIndex]}`;
};
</script>

<template>
    <div class="space-y-4">
        <!-- Dropzone -->
        <div
            @drop.prevent="handleDrop"
            @dragover.prevent="handleDragOver"
            @dragleave="handleDragLeave"
            @click="openFileDialog"
            :class="[
                'relative cursor-pointer rounded-lg border-2 border-dashed p-8 text-center transition-all',
                isDragging
                    ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                    : 'border-gray-300 bg-gray-50 hover:border-gray-400 dark:border-gray-600 dark:bg-gray-800/50 dark:hover:border-gray-500',
            ]"
        >
            <input
                ref="fileInput"
                type="file"
                multiple
                :accept="acceptString"
                @change="handleFileSelect"
                class="hidden"
            />

            <Upload :size="48" class="mx-auto mb-4 text-gray-400" />

            <h3 class="mb-2 text-lg font-medium text-gray-900 dark:text-white">
                {{ $t('Drop files here or click to browse') }}
            </h3>

            <p class="text-sm text-gray-500 dark:text-gray-400">
                {{ $t('Maximum file size: {size}MB', { size: maxFileSize }) }}
            </p>
        </div>

        <!-- Errors -->
        <div v-if="errors.length > 0" class="space-y-2">
            <div
                v-for="(error, index) in errors"
                :key="index"
                class="flex items-start gap-2 rounded-lg border border-red-200 bg-red-50 p-3 dark:border-red-800 dark:bg-red-900/20"
            >
                <AlertCircle
                    :size="18"
                    class="mt-0.5 flex-shrink-0 text-red-600 dark:text-red-400"
                />
                <p class="text-sm text-red-600 dark:text-red-400">
                    {{ error }}
                </p>
            </div>
        </div>

        <!-- Selected Files List -->
        <div v-if="selectedFiles.length > 0" class="space-y-3">
            <div class="flex items-center justify-between">
                <h4 class="text-sm font-medium text-gray-900 dark:text-white">
                    {{
                        $t('{count} file(s) selected', {
                            count: selectedFiles.length,
                        })
                    }}
                </h4>
                <button
                    @click="clearFiles"
                    type="button"
                    class="text-sm text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-white"
                >
                    {{ $t('Clear all') }}
                </button>
            </div>

            <div class="space-y-2">
                <div
                    v-for="(file, index) in selectedFiles"
                    :key="index"
                    class="flex items-center justify-between rounded-lg border border-gray-200 bg-white p-3 dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="flex min-w-0 flex-1 items-center gap-3">
                        <FileIcon
                            :size="18"
                            class="flex-shrink-0 text-gray-400"
                        />
                        <div class="min-w-0 flex-1">
                            <p
                                class="truncate text-sm font-medium text-gray-900 dark:text-white"
                            >
                                {{ file.name }}
                            </p>
                            <p class="text-xs text-gray-500 dark:text-gray-400">
                                {{ formatFileSize(file.size) }}
                            </p>
                        </div>
                    </div>
                    <button
                        @click="removeFile(index)"
                        type="button"
                        class="rounded p-1 transition-colors hover:bg-gray-100 dark:hover:bg-gray-700"
                    >
                        <X :size="16" class="text-gray-400" />
                    </button>
                </div>
            </div>

            <!-- Upload Progress -->
            <div v-if="isUploading" class="space-y-2">
                <div class="flex items-center justify-between text-sm">
                    <span class="text-gray-600 dark:text-gray-400">{{
                        $t('Uploading...')
                    }}</span>
                    <span class="font-medium text-gray-900 dark:text-white"
                        >{{ Math.round(uploadProgress) }}%</span
                    >
                </div>
                <div
                    class="h-2 w-full rounded-full bg-gray-200 dark:bg-gray-700"
                >
                    <div
                        class="h-2 rounded-full bg-blue-600 transition-all duration-300"
                        :style="{ width: `${uploadProgress}%` }"
                    />
                </div>
            </div>

            <!-- Upload Button -->
            <button
                @click="uploadFiles"
                :disabled="isUploading"
                type="button"
                class="inline-flex w-full items-center justify-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900 disabled:cursor-not-allowed disabled:opacity-50 dark:focus:ring-offset-gray-800"
            >
                <Upload :size="16" class="mr-2" />
                {{ $t(isUploading ? 'Uploading...' : 'Upload Files') }}
            </button>
        </div>
    </div>
</template>

<script setup lang="ts">
import type { MediaFolder } from '@/types/media';
import { ChevronDown, ChevronRight, Folder, FolderOpen } from 'lucide-vue-next';
import { computed } from 'vue';

interface Props {
    folder: MediaFolder;
    currentFolderId: number | null;
    expandedFolders: number[];
    level?: number;
}

const props = withDefaults(defineProps<Props>(), {
    level: 0,
});

const emit = defineEmits<{
    toggle: [folderId: number];
    navigate: [folderId: number];
}>();

const isExpanded = computed(() =>
    props.expandedFolders.includes(props.folder.id),
);
const isActive = computed(() => props.currentFolderId === props.folder.id);
const hasChildren = computed(
    () => props.folder.children && props.folder.children.length > 0,
);

const toggleFolder = (e: Event) => {
    e.stopPropagation();
    emit('toggle', props.folder.id);
};

const navigateToFolder = () => {
    emit('navigate', props.folder.id);
};
</script>

<template>
    <div>
        <button
            @click="navigateToFolder"
            :class="[
                'group flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm transition-colors',
                isActive
                    ? 'bg-blue-50 text-blue-600 dark:bg-blue-900/20 dark:text-blue-400'
                    : 'text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-700/50',
            ]"
            :style="{ paddingLeft: `${level * 16 + 12}px` }"
        >
            <!-- Expand/collapse chevron -->
            <button
                v-if="hasChildren"
                @click="toggleFolder"
                class="rounded p-0.5 transition-colors hover:bg-gray-200 dark:hover:bg-gray-600"
            >
                <ChevronDown v-if="isExpanded" :size="14" />
                <ChevronRight v-else :size="14" />
            </button>
            <div v-else class="w-4" />
            <!-- Spacer for alignment -->

            <!-- Folder icon -->
            <component
                :is="isExpanded ? FolderOpen : Folder"
                :size="16"
                :class="[
                    'flex-shrink-0',
                    isActive
                        ? 'text-blue-600 dark:text-blue-400'
                        : 'text-gray-400',
                ]"
            />

            <!-- Folder name -->
            <span class="flex-1 truncate text-left font-medium">
                {{ folder.name }}
            </span>

            <!-- File count badge -->
            <span
                v-if="
                    folder.files_count !== undefined && folder.files_count > 0
                "
                :class="[
                    'rounded-full px-1.5 py-0.5 text-xs',
                    isActive
                        ? 'bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-300'
                        : 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400',
                ]"
            >
                {{ folder.files_count }}
            </span>
        </button>

        <!-- Child folders (recursive) -->
        <div v-if="hasChildren && isExpanded" class="mt-1">
            <FolderTreeItem
                v-for="child in folder.children"
                :key="child.id"
                :folder="child"
                :current-folder-id="currentFolderId"
                :expanded-folders="expandedFolders"
                :level="level + 1"
                @toggle="(id) => emit('toggle', id)"
                @navigate="(id) => emit('navigate', id)"
            />
        </div>
    </div>
</template>

<script setup lang="ts">
import ConfirmDeleteModal from '@/components/Admin/ConfirmDeleteModal.vue';
import MenuFormModal from '@/components/Admin/System/Menu/MenuFormModal.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import * as menuRoutes from '@/routes/admin/system/menus/index';
import { useI18nStore } from '@/Stores/i18n';
import type { MenuItem } from '@/types/admin-menu';
import { Head, router } from '@inertiajs/vue3';
import {
    Edit,
    Eye,
    EyeOff,
    GripVertical,
    Plug,
    Plus,
    Trash2,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

interface Props {
    menuItems: MenuItem[];
}

const props = defineProps<Props>();

const { t } = useI18nStore();

// State
const showFormModal = ref(false);
const editingItem = ref<MenuItem | null>(null);
const showDeleteModal = ref(false);
const deletingItem = ref<MenuItem | null>(null);

// Computed properties for menu organization
const parentItems = computed(() =>
    props.menuItems.filter((item) => !item.parent_id),
);

const getChildren = (parentId: number): MenuItem[] => {
    return props.menuItems.filter((item) => item.parent_id === parentId);
};

// Drag and drop state
const draggedItem = ref<MenuItem | null>(null);
const dragOverItem = ref<MenuItem | null>(null);

// Drag handlers
const handleDragStart = (event: DragEvent, item: MenuItem) => {
    draggedItem.value = item;
    if (event.dataTransfer) {
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData(
            'text/html',
            (event.target as HTMLElement).innerHTML,
        );
    }
};

const handleDragOver = (event: DragEvent, item: MenuItem) => {
    event.preventDefault();
    if (event.dataTransfer) {
        event.dataTransfer.dropEffect = 'move';
    }

    // Only allow reordering within same parent level
    if (draggedItem.value && draggedItem.value.parent_id === item.parent_id) {
        dragOverItem.value = item;
    }
};

const handleDragLeave = () => {
    dragOverItem.value = null;
};

const handleDrop = (event: DragEvent, targetItem: MenuItem) => {
    event.preventDefault();

    if (!draggedItem.value || draggedItem.value.id === targetItem.id) {
        draggedItem.value = null;
        dragOverItem.value = null;
        return;
    }

    // Only allow reordering within same parent level
    if (draggedItem.value.parent_id !== targetItem.parent_id) {
        draggedItem.value = null;
        dragOverItem.value = null;
        return;
    }

    // Get all items at the same level
    const siblings = props.menuItems.filter(
        (item) => item.parent_id === draggedItem.value!.parent_id,
    );
    const draggedIndex = siblings.findIndex(
        (item) => item.id === draggedItem.value!.id,
    );
    const targetIndex = siblings.findIndex((item) => item.id === targetItem.id);

    if (draggedIndex === -1 || targetIndex === -1) {
        draggedItem.value = null;
        dragOverItem.value = null;
        return;
    }

    // Reorder the items
    const items = siblings.map((item, index) => {
        let newOrder = index;

        if (draggedIndex < targetIndex) {
            // Moving down
            if (index === draggedIndex) {
                newOrder = targetIndex;
            } else if (index > draggedIndex && index <= targetIndex) {
                newOrder = index - 1;
            }
        } else {
            // Moving up
            if (index === draggedIndex) {
                newOrder = targetIndex;
            } else if (index >= targetIndex && index < draggedIndex) {
                newOrder = index + 1;
            }
        }

        return {
            id: item.id,
            order: newOrder,
            parent_id: item.parent_id,
        };
    });

    // Send to backend
    router.post(
        menuRoutes.reorder(),
        { items },
        {
            preserveScroll: true,
        },
    );

    draggedItem.value = null;
    dragOverItem.value = null;
};

const handleDragEnd = () => {
    draggedItem.value = null;
    dragOverItem.value = null;
};

// Handlers
const handleCreate = () => {
    editingItem.value = null;
    showFormModal.value = true;
};

const handleEdit = (item: MenuItem) => {
    editingItem.value = item;
    showFormModal.value = true;
};

const handleDelete = (item: MenuItem) => {
    deletingItem.value = item;
    showDeleteModal.value = true;
};

const confirmDelete = () => {
    if (!deletingItem.value) return;

    router.delete(menuRoutes.destroy(deletingItem.value.id), {
        onSuccess: () => {
            showDeleteModal.value = false;
            deletingItem.value = null;
        },
    });
};

const toggleActive = (item: MenuItem) => {
    router.post(menuRoutes.toggle(item.id));
};
</script>

<template>
    <Head :title="$t('Menu Management')" />

    <AdminLayout :title="$t('Menu Management')">
        <div class="space-y-6">
            <!-- Header -->
            <div
                class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between"
            >
                <div>
                    <h1
                        class="flex items-center gap-2 text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Menu Management') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                        {{
                            $t(
                                'Manage and customize your admin sidebar navigation hierarchy.',
                            )
                        }}
                    </p>
                </div>
                <button
                    @click="handleCreate"
                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                >
                    <Plus class="mr-2 h-4 w-4" />
                    {{ $t('Add Menu Item') }}
                </button>
            </div>

            <!-- Content -->
            <div class="overflow-auto rounded-xl">
                <!-- Info Card -->
                <div
                    class="mb-6 rounded-lg border border-blue-200 bg-blue-50 p-4 dark:border-blue-800 dark:bg-blue-900/20"
                >
                    <p
                        class="flex items-start gap-2 text-sm text-blue-800 dark:text-blue-200"
                    >
                        <span class="mt-0.5">•</span>
                        <span
                            ><strong>{{ $t('Admin Menu Structure:') }}</strong>
                            {{
                                $t(
                                    'Drag and drop items to reorder the sidebar navigation. Parent items act as collapsible sections when they contain child menu links.',
                                )
                            }}</span
                        >
                    </p>
                </div>

                <!-- Menu Tree -->
                <div
                    class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="overflow-x-auto">
                        <table
                            class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                        >
                            <thead class="bg-gray-50/50 dark:bg-gray-900/50">
                                <tr>
                                    <th class="w-12 px-6 py-4"></th>
                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Title') }}
                                    </th>
                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Icon') }}
                                    </th>
                                    <th
                                        class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase sm:table-cell dark:text-gray-400"
                                    >
                                        {{ $t('Route / URL') }}
                                    </th>
                                    <th
                                        class="px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Status') }}
                                    </th>
                                    <th
                                        class="px-6 py-4 text-right text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Actions') }}
                                    </th>
                                </tr>
                            </thead>
                            <tbody
                                class="divide-y divide-gray-200 bg-white dark:divide-gray-700 dark:bg-gray-800"
                            >
                                <template
                                    v-for="item in parentItems"
                                    :key="item.id"
                                >
                                    <tr
                                        draggable="true"
                                        @dragstart="
                                            handleDragStart($event, item)
                                        "
                                        @dragover="handleDragOver($event, item)"
                                        @dragleave="handleDragLeave"
                                        @drop="handleDrop($event, item)"
                                        @dragend="handleDragEnd"
                                        :class="[
                                            'group transition-colors hover:bg-gray-50 dark:hover:bg-gray-700/50',
                                            draggedItem?.id === item.id
                                                ? 'bg-gray-50 opacity-50 dark:bg-gray-700'
                                                : '',
                                            dragOverItem?.id === item.id
                                                ? 'border-t-2 border-blue-500'
                                                : '',
                                        ]"
                                    >
                                        <!-- Drag Handle -->
                                        <td
                                            class="px-6 py-4 pl-4 text-center sm:pl-6"
                                        >
                                            <div
                                                class="inline-block cursor-move rounded p-1 text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600 dark:hover:bg-gray-700 dark:hover:text-gray-200"
                                            >
                                                <GripVertical class="h-4 w-4" />
                                            </div>
                                        </td>

                                        <!-- Title -->
                                        <td class="px-6 py-4">
                                            <div
                                                class="flex flex-col gap-1 sm:flex-row sm:items-center sm:gap-3"
                                            >
                                                <span
                                                    class="font-medium text-gray-900 dark:text-white"
                                                    >{{ item.title }}</span
                                                >
                                                <span
                                                    v-if="
                                                        getChildren(item.id)
                                                            .length > 0
                                                    "
                                                    class="inline-flex w-fit rounded-full bg-blue-50 px-2 py-0.5 text-xs font-medium text-blue-700 dark:bg-blue-900/30 dark:text-blue-300"
                                                >
                                                    {{
                                                        $t('{count} children', {
                                                            count: getChildren(
                                                                item.id,
                                                            ).length,
                                                        })
                                                    }}
                                                </span>
                                                <!-- Mobile-only URL view -->
                                                <span
                                                    v-if="
                                                        item.route || item.url
                                                    "
                                                    class="max-w-[150px] truncate font-mono text-xs text-gray-500 sm:hidden"
                                                >
                                                    {{
                                                        item.route
                                                            ? `route: ${item.route}`
                                                            : item.url
                                                    }}
                                                </span>
                                            </div>
                                        </td>

                                        <!-- Icon -->
                                        <td class="px-6 py-4">
                                            <div
                                                v-if="item.icon"
                                                class="flex w-fit items-center gap-2 rounded bg-gray-100 px-2 py-1 font-mono text-sm text-xs text-gray-600 dark:bg-gray-700 dark:text-gray-300"
                                            >
                                                <Plug class="h-3 w-3" />
                                                {{ item.icon }}
                                            </div>
                                            <span
                                                v-else
                                                class="text-sm text-gray-400"
                                                >—</span
                                            >
                                        </td>

                                        <!-- Route / URL -->
                                        <td
                                            class="hidden px-6 py-4 sm:table-cell"
                                        >
                                            <span
                                                v-if="item.route"
                                                class="rounded bg-blue-50 px-2 py-0.5 font-mono text-xs text-blue-600 dark:bg-blue-900/20 dark:text-blue-400"
                                                >{{ item.route }}</span
                                            >
                                            <span
                                                v-else-if="item.url"
                                                class="font-mono text-xs text-gray-600 dark:text-gray-400"
                                                >{{ item.url }}</span
                                            >
                                            <span
                                                v-else
                                                class="text-sm text-gray-400"
                                                >#</span
                                            >
                                        </td>

                                        <!-- Status -->
                                        <td class="px-6 py-4">
                                            <button
                                                @click="toggleActive(item)"
                                                :class="[
                                                    'inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-medium',
                                                    item.active
                                                        ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400'
                                                        : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300',
                                                ]"
                                            >
                                                <Eye
                                                    v-if="item.active"
                                                    class="h-3 w-3"
                                                />
                                                <EyeOff
                                                    v-else
                                                    class="h-3 w-3"
                                                />
                                                {{
                                                    item.active
                                                        ? $t('Active')
                                                        : $t('Inactive')
                                                }}
                                            </button>
                                        </td>

                                        <!-- Actions -->
                                        <td class="px-6 py-4 text-right">
                                            <div
                                                class="flex items-center justify-end gap-2 opacity-60 transition-opacity group-hover:opacity-100"
                                            >
                                                <button
                                                    @click="handleEdit(item)"
                                                    class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-900/20"
                                                    :title="$t('Edit')"
                                                >
                                                    <Edit class="h-4 w-4" />
                                                </button>
                                                <button
                                                    @click="handleDelete(item)"
                                                    class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-900/20"
                                                    :title="$t('Delete')"
                                                >
                                                    <Trash2 class="h-4 w-4" />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>

                                    <!-- Children -->
                                    <tr
                                        v-for="child in getChildren(item.id)"
                                        :key="child.id"
                                        draggable="true"
                                        @dragstart="
                                            handleDragStart($event, child)
                                        "
                                        @dragover="
                                            handleDragOver($event, child)
                                        "
                                        @dragleave="handleDragLeave"
                                        @drop="handleDrop($event, child)"
                                        @dragend="handleDragEnd"
                                        :class="[
                                            'group bg-gray-50/50 transition-colors hover:bg-gray-100 dark:bg-gray-900/30 dark:hover:bg-gray-800',
                                            draggedItem?.id === child.id
                                                ? 'opacity-50'
                                                : '',
                                            dragOverItem?.id === child.id
                                                ? 'border-t-2 border-blue-500'
                                                : '',
                                        ]"
                                    >
                                        <td
                                            class="border-l-2 border-transparent px-6 py-4 pl-8 text-center sm:pl-12"
                                        >
                                            <div
                                                class="inline-block cursor-move rounded p-1 text-gray-400 transition-colors hover:bg-gray-200 hover:text-gray-600 dark:hover:bg-gray-700 dark:hover:text-gray-200"
                                            >
                                                <GripVertical class="h-4 w-4" />
                                            </div>
                                        </td>
                                        <td class="px-6 py-4">
                                            <div
                                                class="flex flex-col gap-1 sm:flex-row sm:items-center sm:gap-2"
                                            >
                                                <div
                                                    class="flex items-center gap-2"
                                                >
                                                    <span
                                                        class="hidden text-gray-300 sm:inline dark:text-gray-600"
                                                        >{{ $t('SUB') }}</span
                                                    >
                                                    <span
                                                        class="text-sm font-medium text-gray-700 dark:text-gray-300"
                                                        >{{ child.title }}</span
                                                    >
                                                </div>
                                                <!-- Mobile-only URL view -->
                                                <span
                                                    v-if="
                                                        child.route || child.url
                                                    "
                                                    class="max-w-[150px] truncate font-mono text-xs text-gray-500 sm:hidden"
                                                >
                                                    {{
                                                        child.route
                                                            ? `route: ${child.route}`
                                                            : child.url
                                                    }}
                                                </span>
                                            </div>
                                        </td>
                                        <td class="px-6 py-4">
                                            <div
                                                v-if="child.icon"
                                                class="flex w-fit origin-left scale-90 items-center gap-2 rounded border border-gray-100 bg-white px-2 py-0.5 font-mono text-sm text-xs text-gray-600 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-300"
                                            >
                                                <Plug class="h-3 w-3" />
                                                {{ child.icon }}
                                            </div>
                                            <span
                                                v-else
                                                class="text-sm text-gray-400"
                                                >—</span
                                            >
                                        </td>
                                        <td
                                            class="hidden px-6 py-4 sm:table-cell"
                                        >
                                            <span
                                                v-if="child.route"
                                                class="rounded bg-blue-50 px-2 py-0.5 font-mono text-xs text-blue-600 dark:bg-blue-900/20 dark:text-blue-400"
                                                >{{ child.route }}</span
                                            >
                                            <span
                                                v-else-if="child.url"
                                                class="font-mono text-xs text-gray-600 dark:text-gray-400"
                                                >{{ child.url }}</span
                                            >
                                            <span
                                                v-else
                                                class="text-sm text-gray-400"
                                                >#</span
                                            >
                                        </td>
                                        <td class="px-6 py-4">
                                            <button
                                                @click="toggleActive(child)"
                                                :class="[
                                                    'inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-medium',
                                                    child.active
                                                        ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400'
                                                        : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300',
                                                ]"
                                            >
                                                <Eye
                                                    v-if="child.active"
                                                    class="h-3 w-3"
                                                />
                                                <EyeOff
                                                    v-else
                                                    class="h-3 w-3"
                                                />
                                                {{
                                                    child.active
                                                        ? $t('Active')
                                                        : $t('Inactive')
                                                }}
                                            </button>
                                        </td>
                                        <td class="px-6 py-4 text-right">
                                            <div
                                                class="flex items-center justify-end gap-2 opacity-60 transition-opacity group-hover:opacity-100"
                                            >
                                                <button
                                                    @click="handleEdit(child)"
                                                    class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-900/20"
                                                    :title="$t('Edit')"
                                                >
                                                    <Edit class="h-4 w-4" />
                                                </button>
                                                <button
                                                    @click="handleDelete(child)"
                                                    class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-900/20"
                                                    :title="$t('Delete')"
                                                >
                                                    <Trash2 class="h-4 w-4" />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                </template>
                            </tbody>
                        </table>
                    </div>

                    <!-- Empty State -->
                    <div
                        v-if="parentItems.length === 0"
                        class="p-12 text-center"
                    >
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                            {{
                                $t(
                                    'No menu items found. Click "Add Menu Item" to create your first item.',
                                )
                            }}
                        </p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Form Modal -->
        <MenuFormModal
            v-model:show="showFormModal"
            :menu-item="editingItem"
            :parent-options="menuItems"
        />

        <!-- Delete Confirmation -->
        <ConfirmDeleteModal
            v-model:show="showDeleteModal"
            :title="deletingItem?.title ?? ''"
            :message="
                $t('Are you sure you want to delete this menu item? {note}', {
                    note:
                        deletingItem && getChildren(deletingItem.id).length > 0
                            ? t('All child items will also be deleted.')
                            : '',
                })
            "
            @confirm="confirmDelete"
        />
    </AdminLayout>
</template>

<script setup lang="ts">
import ConfirmDeleteModal from '@/components/Admin/ConfirmDeleteModal.vue';
import MenuFormModal from '@/components/Admin/Content/StorefrontMenu/MenuFormModal.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, router } from '@inertiajs/vue3';
import {
    Edit,
    GripVertical,
    Info,
    LayoutTemplate,
    Menu,
    Plus,
    Smartphone,
    Trash2,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

interface MenuItem {
    id: number;
    title: string;
    key: string | null;
    icon: string | null;
    route: string | null;
    url: string | null;
    parent_id: number | null;
    location: string;
    menu_type: string;
    order: number;
    active: boolean;
    children?: MenuItem[];
}

interface Props {
    headerMenuItems: MenuItem[];
    footerMenuItems: MenuItem[];
    mobileMenuItems: MenuItem[];
}

const props = defineProps<Props>();

const activeTab = ref<'header' | 'footer' | 'mobile'>('header');
const showFormModal = ref(false);
const editingItem = ref<MenuItem | null>(null);
const showDeleteModal = ref(false);
const deletingItem = ref<MenuItem | null>(null);

const currentMenuItems = computed(() => {
    switch (activeTab.value) {
        case 'header':
            return props.headerMenuItems;
        case 'footer':
            return props.footerMenuItems;
        case 'mobile':
            return props.mobileMenuItems;
        default:
            return [];
    }
});

const parentItems = computed(() =>
    currentMenuItems.value.filter((item) => !item.parent_id),
);

const getChildren = (parentId: number): MenuItem[] => {
    return currentMenuItems.value.filter((item) => item.parent_id === parentId);
};

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
    router.delete(`/admin/content/storefront-menus/${deletingItem.value.id}`, {
        onSuccess: () => {
            showDeleteModal.value = false;
            deletingItem.value = null;
        },
    });
};

const toggleActive = (item: MenuItem) => {
    router.post(
        `/admin/content/storefront-menus/${item.id}/toggle`,
        {},
        {
            preserveScroll: true,
        },
    );
};

const draggedItem = ref<MenuItem | null>(null);
const dragOverItem = ref<MenuItem | null>(null);

const handleDragStart = (event: DragEvent, item: MenuItem) => {
    draggedItem.value = item;
    if (event.dataTransfer) {
        event.dataTransfer.effectAllowed = 'move';
    }
};

const handleDragOver = (event: DragEvent, item: MenuItem) => {
    event.preventDefault();
    if (event.dataTransfer) {
        event.dataTransfer.dropEffect = 'move';
    }
    if (draggedItem.value && draggedItem.value.parent_id === item.parent_id) {
        dragOverItem.value = item;
    }
};

const handleDrop = (event: DragEvent, targetItem: MenuItem) => {
    event.preventDefault();

    if (!draggedItem.value || draggedItem.value.id === targetItem.id) {
        draggedItem.value = null;
        dragOverItem.value = null;
        return;
    }

    if (draggedItem.value.parent_id !== targetItem.parent_id) {
        draggedItem.value = null;
        dragOverItem.value = null;
        return;
    }

    const siblings = currentMenuItems.value.filter(
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

    const items = siblings.map((item, index) => {
        let newOrder = index;

        if (draggedIndex < targetIndex) {
            if (index === draggedIndex) {
                newOrder = targetIndex;
            } else if (index > draggedIndex && index <= targetIndex) {
                newOrder = index - 1;
            }
        } else {
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

    router.post(
        '/admin/content/storefront-menus/reorder',
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
</script>

<template>
    <Head :title="$t('Storefront Menu')" />

    <AdminLayout :title="$t('Storefront Menu')">
        <div class="space-y-6 p-6">
            <div
                class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
            >
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Storefront Menu') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                        {{
                            $t(
                                'Manage header, footer, and mobile navigation menus.',
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

            <div
                class="flex items-start gap-3 rounded-xl border border-blue-200 bg-blue-50 p-4 dark:border-blue-800 dark:bg-blue-900/20"
            >
                <Info
                    class="mt-0.5 h-5 w-5 shrink-0 text-blue-600 dark:text-blue-400"
                />
                <p class="text-sm text-blue-800 dark:text-blue-200">
                    <strong>{{ $t('Storefront Navigation:') }}</strong>
                    {{
                        $t(
                            'Manage header, footer, and mobile navigation menus. Drag and drop to reorder items.',
                        )
                    }}
                </p>
            </div>

            <div
                class="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div class="border-b border-gray-100 px-6 dark:border-gray-700">
                    <nav class="-mb-px flex space-x-8">
                        <button
                            @click="activeTab = 'header'"
                            :class="[
                                activeTab === 'header'
                                    ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300',
                                'flex items-center gap-2 border-b-2 px-1 py-4 text-sm font-medium whitespace-nowrap transition-colors',
                            ]"
                        >
                            <LayoutTemplate class="h-4 w-4" />
                            {{ $t('Header Menu') }}
                            <span
                                :class="[
                                    activeTab === 'header'
                                        ? 'bg-blue-100 text-blue-600 dark:bg-blue-900/40'
                                        : 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400',
                                    'ml-2 rounded-full px-2 py-0.5 text-xs transition-colors',
                                ]"
                            >
                                {{ headerMenuItems.length }}
                            </span>
                        </button>
                        <button
                            @click="activeTab = 'footer'"
                            :class="[
                                activeTab === 'footer'
                                    ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300',
                                'flex items-center gap-2 border-b-2 px-1 py-4 text-sm font-medium whitespace-nowrap transition-colors',
                            ]"
                        >
                            <Menu class="h-4 w-4" />
                            {{ $t('Footer Menu') }}
                            <span
                                :class="[
                                    activeTab === 'footer'
                                        ? 'bg-blue-100 text-blue-600 dark:bg-blue-900/40'
                                        : 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400',
                                    'ml-2 rounded-full px-2 py-0.5 text-xs transition-colors',
                                ]"
                            >
                                {{ footerMenuItems.length }}
                            </span>
                        </button>
                        <button
                            @click="activeTab = 'mobile'"
                            :class="[
                                activeTab === 'mobile'
                                    ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300',
                                'flex items-center gap-2 border-b-2 px-1 py-4 text-sm font-medium whitespace-nowrap transition-colors',
                            ]"
                        >
                            <Smartphone class="h-4 w-4" />
                            {{ $t('Mobile Menu') }}
                            <span
                                :class="[
                                    activeTab === 'mobile'
                                        ? 'bg-blue-100 text-blue-600 dark:bg-blue-900/40'
                                        : 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400',
                                    'ml-2 rounded-full px-2 py-0.5 text-xs transition-colors',
                                ]"
                            >
                                {{ mobileMenuItems.length }}
                            </span>
                        </button>
                    </nav>
                </div>

                <div class="overflow-x-auto">
                    <table
                        class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                    >
                        <thead class="bg-gray-50 dark:bg-gray-700/50">
                            <tr>
                                <th class="w-12 px-6 py-3"></th>
                                <th
                                    class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Title') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('URL/Route') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-center text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Status') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Actions') }}
                                </th>
                            </tr>
                        </thead>
                        <tbody
                            class="divide-y divide-gray-200 dark:divide-gray-700"
                        >
                            <template
                                v-for="item in parentItems"
                                :key="item.id"
                            >
                                <tr
                                    draggable="true"
                                    @dragstart="handleDragStart($event, item)"
                                    @dragover="handleDragOver($event, item)"
                                    @drop="handleDrop($event, item)"
                                    @dragend="handleDragEnd"
                                    :class="{
                                        'bg-blue-50 dark:bg-blue-900/20':
                                            dragOverItem?.id === item.id,
                                    }"
                                    class="group bg-white transition-colors hover:bg-gray-50 dark:bg-gray-800 dark:hover:bg-gray-700/50"
                                >
                                    <td class="px-6 py-4">
                                        <button
                                            class="cursor-move text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
                                        >
                                            <GripVertical class="h-5 w-5" />
                                        </button>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div class="flex items-center">
                                            <span
                                                class="text-sm font-medium text-gray-900 dark:text-white"
                                                >{{ item.title }}</span
                                            >
                                            <span
                                                v-if="
                                                    item.children &&
                                                    item.children.length > 0
                                                "
                                                class="ml-2 font-mono text-xs text-gray-500"
                                            >
                                                {{
                                                    $t('({count} sub-items)', {
                                                        count: item.children
                                                            .length,
                                                    })
                                                }}
                                            </span>
                                        </div>
                                    </td>
                                    <td
                                        class="px-6 py-4 font-mono text-sm whitespace-nowrap text-gray-500 dark:text-gray-400"
                                    >
                                        {{ item.url || item.route || '-' }}
                                    </td>
                                    <td
                                        class="px-6 py-4 text-center whitespace-nowrap"
                                    >
                                        <span
                                            :class="[
                                                item.active
                                                    ? 'border-green-200 bg-green-50 text-green-700 dark:border-green-800 dark:bg-green-900/20 dark:text-green-300'
                                                    : 'border-gray-200 bg-gray-50 text-gray-700 dark:border-gray-800 dark:bg-gray-900/20 dark:text-gray-300',
                                                'inline-flex rounded-full border px-2.5 py-0.5 text-xs font-medium shadow-sm',
                                            ]"
                                        >
                                            {{
                                                item.active
                                                    ? $t('Active')
                                                    : $t('Inactive')
                                            }}
                                        </span>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right text-sm font-medium whitespace-nowrap"
                                    >
                                        <div
                                            class="flex items-center justify-end gap-2 opacity-60 transition-opacity group-hover:opacity-100"
                                        >
                                            <button
                                                @click="handleEdit(item)"
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-indigo-50 hover:text-indigo-600 dark:hover:bg-indigo-900/20"
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

                                <tr
                                    v-for="child in getChildren(item.id)"
                                    :key="child.id"
                                    draggable="true"
                                    @dragstart="handleDragStart($event, child)"
                                    @dragover="handleDragOver($event, child)"
                                    @drop="handleDrop($event, child)"
                                    @dragend="handleDragEnd"
                                    :class="{
                                        'bg-blue-50 dark:bg-blue-900/20':
                                            dragOverItem?.id === child.id,
                                    }"
                                    class="group bg-gray-50/50 transition-colors hover:bg-gray-50 dark:bg-gray-900/20 dark:hover:bg-gray-700/50"
                                >
                                    <td class="px-6 py-3">
                                        <button
                                            class="cursor-move pl-6 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
                                        >
                                            <GripVertical class="h-4 w-4" />
                                        </button>
                                    </td>
                                    <td class="px-6 py-3 whitespace-nowrap">
                                        <div
                                            class="flex items-center pl-8 text-sm text-gray-600 dark:text-gray-300"
                                        >
                                            <div
                                                class="absolute -mt-4 -ml-6 h-4 w-4 rounded-bl border-b border-l border-gray-300 dark:border-gray-600"
                                            ></div>
                                            {{ child.title }}
                                        </div>
                                    </td>
                                    <td
                                        class="px-6 py-3 font-mono text-sm whitespace-nowrap text-gray-500 dark:text-gray-400"
                                    >
                                        {{ child.url || child.route || '-' }}
                                    </td>
                                    <td
                                        class="px-6 py-3 text-center whitespace-nowrap"
                                    >
                                        <span
                                            :class="[
                                                child.active
                                                    ? 'border-green-200 bg-green-50 text-green-700 dark:border-green-800 dark:bg-green-900/20 dark:text-green-300'
                                                    : 'border-gray-200 bg-gray-50 text-gray-700 dark:border-gray-800 dark:bg-gray-900/20 dark:text-gray-300',
                                                'inline-flex rounded-full border px-2.5 py-0.5 text-xs font-medium shadow-sm',
                                            ]"
                                        >
                                            {{
                                                child.active
                                                    ? $t('Active')
                                                    : $t('Inactive')
                                            }}
                                        </span>
                                    </td>
                                    <td
                                        class="px-6 py-3 text-right text-sm font-medium whitespace-nowrap"
                                    >
                                        <div
                                            class="flex items-center justify-end gap-2 opacity-60 transition-opacity group-hover:opacity-100"
                                        >
                                            <button
                                                @click="handleEdit(child)"
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-indigo-50 hover:text-indigo-600 dark:hover:bg-indigo-900/20"
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

                            <tr v-if="currentMenuItems.length === 0">
                                <td colspan="5" class="px-6 py-12 text-center">
                                    <div
                                        class="flex flex-col items-center justify-center"
                                    >
                                        <div
                                            class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-50 text-gray-400 dark:bg-gray-700"
                                        >
                                            <Menu class="h-8 w-8" />
                                        </div>
                                        <h3
                                            class="mb-1 text-lg font-bold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('No menu items found') }}
                                        </h3>
                                        <p
                                            class="mb-4 text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            {{
                                                $t(
                                                    'Starts adding items to your {tab} menu.',
                                                    { tab: activeTab },
                                                )
                                            }}
                                        </p>
                                        <button
                                            @click="handleCreate"
                                            class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                                        >
                                            <Plus class="mr-2 h-4 w-4" />
                                            {{ $t('Add Menu Item') }}
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <MenuFormModal
            :show="showFormModal"
            :menu-item="editingItem"
            :menu-type="activeTab"
            :parent-options="parentItems"
            @update:show="showFormModal = $event"
        />

        <ConfirmDeleteModal
            v-model:show="showDeleteModal"
            :title="$t('Delete Menu Item')"
            :message="
                $t(
                    'Are you sure you want to delete {title}? This action cannot be undone.',
                    { title: deletingItem?.title },
                )
            "
            @confirm="confirmDelete"
        />
    </AdminLayout>
</template>

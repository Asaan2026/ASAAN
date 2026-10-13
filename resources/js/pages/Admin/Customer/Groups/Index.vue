<script setup lang="ts">
import ConfirmDeleteModal from '@/components/Admin/ConfirmDeleteModal.vue';
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, Link, router } from '@inertiajs/vue3';
import { debounce } from 'lodash';
import {
    ArrowUpDown,
    CheckCircle,
    ChevronLeft,
    ChevronRight,
    Edit,
    Filter,
    GripVertical,
    Layers,
    PlusCircle,
    Search,
    Tag,
    Trash2,
    Users,
    X,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

interface Customer {
    id: number;
    first_name: string;
    last_name: string;
    full_name: string;
    email: string;
}

interface CustomerGroup {
    id: number;
    name: string;
    code: string;
    description?: string;
    color: string;
    discount_percentage: number;
    order: number;
    is_default: boolean;
    auto_assignment_rules: {
        min_orders?: number;
        min_spent?: number;
        min_aov?: number;
    };
    status: boolean;
    customers_count: number;
    active_customers_count: number;
    customers?: Customer[];
    created_at: string;
    updated_at: string;
}

interface Props {
    groups: {
        data: CustomerGroup[];
        links: any;
        meta: any;
        current_page: number;
        last_page: number;
        per_page: number;
        total: number;
        from: number;
        to: number;
        prev_page_url: string | null;
        next_page_url: string | null;
    };
    statistics: {
        total: number;
        active: number;
        inactive: number;
        with_customers: number;
    };
    filters: {
        search?: string;
        status?: string;
        sort_by?: string;
        sort_order?: string;
        per_page?: number;
    };
}

const props = defineProps<Props>();

const { formatPrice } = useCurrency();
const selectedGroups = ref<number[]>([]);
const showDeleteModal = ref(false);
const deleteGroupId = ref<number | null>(null);
const deletingGroup = ref<{ id: number; name: string } | null>(null);
const showBulkDeleteModal = ref(false);
const showAutoAssignModal = ref(false);
const autoAssignGroupId = ref<number | null>(null);
const isDragging = ref(false);
const draggedGroup = ref<CustomerGroup | null>(null);

// Local filter state
const search = ref(props.filters.search || '');
const statusFilter = ref(props.filters.status || '');
const sortBy = ref(props.filters.sort_by || 'order');
const sortOrder = ref(props.filters.sort_order || 'asc');
const perPage = ref(props.filters.per_page || 15);

// Computed
const allSelected = computed(() => {
    return (
        props.groups.data.length > 0 &&
        selectedGroups.value.length === props.groups.data.length
    );
});

const someSelected = computed(() => {
    return (
        selectedGroups.value.length > 0 &&
        selectedGroups.value.length < props.groups.data.length
    );
});

const hasActiveFilters = computed(() => {
    return search.value || statusFilter.value;
});

// Debounced search
const performSearch = debounce(() => {
    applyFilters();
}, 300);

// Methods
function toggleSelectAll() {
    if (allSelected.value) {
        selectedGroups.value = [];
    } else {
        selectedGroups.value = props.groups.data.map((g) => g.id);
    }
}

function applyFilters() {
    router.get(
        '/admin/customers/groups',
        {
            search: search.value || undefined,
            status: statusFilter.value || undefined,
            sort_by: sortBy.value,
            sort_order: sortOrder.value,
            per_page: perPage.value,
        },
        {
            preserveState: true,
            preserveScroll: true,
        },
    );
}

function clearFilters() {
    search.value = '';
    statusFilter.value = '';
    applyFilters();
}

function confirmDelete(groupId: number) {
    const group = props.groups.data.find((g) => g.id === groupId);
    if (group) {
        deletingGroup.value = { id: group.id, name: group.name };
        showDeleteModal.value = true;
    }
}

function deleteGroup() {
    if (deletingGroup.value) {
        router.delete(`/admin/customers/groups/${deletingGroup.value.id}`, {
            onSuccess: () => {
                showDeleteModal.value = false;
                deletingGroup.value = null;
            },
        });
    }
}

function confirmBulkDelete() {
    if (selectedGroups.value.length > 0) {
        showBulkDeleteModal.value = true;
    }
}

function bulkDelete() {
    router.post(
        '/admin/customers/groups/bulk-delete',
        {
            ids: selectedGroups.value,
        },
        {
            onSuccess: () => {
                selectedGroups.value = [];
                showBulkDeleteModal.value = false;
            },
        },
    );
}

function bulkUpdateStatus(status: boolean) {
    if (selectedGroups.value.length > 0) {
        router.post(
            '/admin/customers/groups/bulk-update-status',
            {
                ids: selectedGroups.value,
                status: status,
            },
            {
                onSuccess: () => {
                    selectedGroups.value = [];
                },
            },
        );
    }
}

function applyAutoAssignment(groupId: number) {
    autoAssignGroupId.value = groupId;
    showAutoAssignModal.value = true;
}

function confirmAutoAssignment() {
    if (autoAssignGroupId.value) {
        router.post(
            `/admin/customers/groups/${autoAssignGroupId.value}/apply-auto-assignment`,
            {},
            {
                preserveScroll: true,
                onFinish: () => {
                    showAutoAssignModal.value = false;
                    autoAssignGroupId.value = null;
                },
            },
        );
    }
}

// Drag and drop methods
function handleDragStart(event: DragEvent, group: CustomerGroup) {
    isDragging.value = true;
    draggedGroup.value = group;
    if (event.dataTransfer) {
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/html', '');
    }
}

function handleDragOver(event: DragEvent) {
    event.preventDefault();
    if (event.dataTransfer) {
        event.dataTransfer.dropEffect = 'move';
    }
}

function handleDrop(event: DragEvent, targetGroup: CustomerGroup) {
    event.preventDefault();
    isDragging.value = false;

    if (!draggedGroup.value || draggedGroup.value.id === targetGroup.id) {
        return;
    }

    // Reorder groups
    const groups = [...props.groups.data];
    const draggedIndex = groups.findIndex(
        (g) => g.id === draggedGroup.value!.id,
    );
    const targetIndex = groups.findIndex((g) => g.id === targetGroup.id);

    // Remove dragged group
    const [removed] = groups.splice(draggedIndex, 1);

    // Insert at new position
    groups.splice(targetIndex, 0, removed);

    // Update order property for all groups
    const reorderedGroups = groups.map((group, index) => ({
        id: group.id,
        order: index,
    }));

    // Send update to server
    router.post(
        '/admin/customers/groups/reorder',
        {
            groups: reorderedGroups,
        },
        {
            preserveScroll: true,
        },
    );

    draggedGroup.value = null;
}

function handleDragEnd() {
    isDragging.value = false;
    draggedGroup.value = null;
}
</script>

<template>
    <Head :title="$t('Customer Groups')" />

    <AdminLayout :title="$t('Customer Groups')">
        <div class="space-y-6 p-6">
            <!-- Header -->
            <div
                class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
            >
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Customer Groups') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                        {{
                            $t(
                                'Manage customer segmentation and group-based pricing',
                            )
                        }}
                    </p>
                </div>
                <Link
                    :href="'/admin/customers/groups/create'"
                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                >
                    <PlusCircle class="mr-2 h-4 w-4" />
                    {{ $t('New Group') }}
                </Link>
            </div>

            <!-- Statistics Cards -->
            <div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
                <div
                    class="group rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-colors hover:border-blue-200 dark:border-gray-700 dark:bg-gray-800 dark:hover:border-blue-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Total Groups') }}
                            </p>
                            <p
                                class="mt-1 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.total }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-blue-50 p-3 transition-colors group-hover:bg-blue-100 dark:bg-blue-900/20 dark:group-hover:bg-blue-900/40"
                        >
                            <Layers
                                class="h-6 w-6 text-blue-600 dark:text-blue-400"
                            />
                        </div>
                    </div>
                </div>

                <div
                    class="group rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-colors hover:border-green-200 dark:border-gray-700 dark:bg-gray-800 dark:hover:border-green-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Active') }}
                            </p>
                            <p
                                class="mt-1 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.active }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-green-50 p-3 dark:bg-green-900/20"
                        >
                            <CheckCircle
                                class="h-6 w-6 text-green-600 dark:text-green-400"
                            />
                        </div>
                    </div>
                </div>

                <div
                    class="group rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-colors hover:border-red-200 dark:border-gray-700 dark:bg-gray-800 dark:hover:border-red-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Inactive') }}
                            </p>
                            <p
                                class="mt-1 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.inactive }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-red-50 p-3 dark:bg-red-900/20"
                        >
                            <X class="h-6 w-6 text-red-600 dark:text-red-400" />
                        </div>
                    </div>
                </div>

                <div
                    class="group rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-colors hover:border-purple-200 dark:border-gray-700 dark:bg-gray-800 dark:hover:border-purple-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('With Customers') }}
                            </p>
                            <p
                                class="mt-1 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.with_customers }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-purple-50 p-3 dark:bg-purple-900/20"
                        >
                            <Users
                                class="h-6 w-6 text-purple-600 dark:text-purple-400"
                            />
                        </div>
                    </div>
                </div>
            </div>

            <!-- Filters Card -->
            <div
                class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div
                    class="grid grid-cols-1 gap-4 md:grid-cols-4 lg:grid-cols-6"
                >
                    <!-- Search -->
                    <div class="md:col-span-2">
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Search') }}</label
                        >
                        <div class="relative">
                            <Search
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <input
                                v-model="search"
                                @input="applyFilters"
                                type="text"
                                :placeholder="$t('Name, code, description...')"
                                class="w-full rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-4 pl-10 text-sm text-gray-900 transition-all placeholder:text-gray-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            />
                        </div>
                    </div>

                    <!-- Status Filter -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Status') }}</label
                        >
                        <div class="relative">
                            <Filter
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <select
                                v-model="statusFilter"
                                @change="applyFilters"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-8 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            >
                                <option value="">{{ $t('All Status') }}</option>
                                <option value="active">
                                    {{ $t('Active') }}
                                </option>
                                <option value="inactive">
                                    {{ $t('Inactive') }}
                                </option>
                            </select>
                            <div
                                class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2"
                            >
                                <ArrowUpDown class="h-3 w-3 text-gray-400" />
                            </div>
                        </div>
                    </div>

                    <!-- Per Page -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Per Page') }}</label
                        >
                        <div class="relative">
                            <Layers
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <select
                                v-model="perPage"
                                @change="applyFilters"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-8 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            >
                                <option :value="15">15</option>
                                <option :value="25">25</option>
                                <option :value="50">50</option>
                                <option :value="100">100</option>
                            </select>
                            <div
                                class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2"
                            >
                                <ArrowUpDown class="h-3 w-3 text-gray-400" />
                            </div>
                        </div>
                    </div>
                </div>

                <div
                    v-if="hasActiveFilters"
                    class="mt-4 border-t border-gray-200 pt-4 dark:border-gray-700"
                >
                    <button
                        @click="clearFilters"
                        class="flex items-center gap-2 rounded-lg bg-gray-100 px-4 py-2 text-sm font-medium text-gray-600 transition-colors hover:bg-gray-200 hover:text-gray-900 dark:bg-gray-700 dark:text-gray-400 dark:hover:bg-gray-600 dark:hover:text-gray-200"
                    >
                        <X class="h-4 w-4" />
                        {{ $t('Clear Filters') }}
                    </button>
                </div>
            </div>

            <!-- Bulk Actions -->
            <transition
                enter-active-class="transition ease-out duration-200"
                enter-from-class="opacity-0 -translate-y-2"
                enter-to-class="opacity-100 translate-y-0"
                leave-active-class="transition ease-in duration-150"
                leave-from-class="opacity-100 translate-y-0"
                leave-to-class="opacity-0 -translate-y-2"
            >
                <div
                    v-if="selectedGroups.length > 0"
                    class="sticky top-4 z-10 mb-6 flex items-center justify-between rounded-xl bg-blue-600 p-3 px-6 text-white shadow-lg"
                >
                    <div class="flex items-center">
                        <CheckCircle class="mr-2 h-4 w-4" />
                        <span class="text-sm font-semibold">
                            {{
                                $t('{count} group(s) selected', {
                                    count: selectedGroups.length,
                                })
                            }}
                        </span>
                    </div>
                    <div class="flex gap-2">
                        <button
                            @click="bulkUpdateStatus(true)"
                            class="rounded-lg bg-white/20 px-3 py-1.5 text-xs font-semibold transition-colors hover:bg-white/30"
                        >
                            {{ $t('Activate') }}
                        </button>
                        <button
                            @click="bulkUpdateStatus(false)"
                            class="rounded-lg bg-white/20 px-3 py-1.5 text-xs font-semibold transition-colors hover:bg-white/30"
                        >
                            {{ $t('Deactivate') }}
                        </button>
                        <button
                            @click="confirmBulkDelete"
                            class="flex items-center rounded-lg bg-white/20 px-3 py-1.5 text-xs font-semibold transition-colors hover:bg-white/30"
                        >
                            <Trash2 class="mr-1.5 h-3 w-3" />
                            {{ $t('Delete') }}
                        </button>
                    </div>
                </div>
            </transition>

            <!-- Groups Table -->
            <div
                class="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div class="overflow-x-auto">
                    <table
                        class="min-w-full divide-y divide-gray-100 dark:divide-gray-700"
                    >
                        <thead class="bg-gray-50/80 dark:bg-gray-700/50">
                            <tr>
                                <th class="w-12 px-6 py-4">
                                    <input
                                        type="checkbox"
                                        :checked="allSelected"
                                        :indeterminate="someSelected"
                                        @change="toggleSelectAll"
                                        class="h-4 w-4 rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </th>
                                <th
                                    class="w-12 px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Order') }}
                                </th>
                                <th
                                    class="px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Group') }}
                                </th>
                                <th
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase sm:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Discount') }}
                                </th>
                                <th
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase md:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Customers') }}
                                </th>
                                <th
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase lg:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Auto-Assignment') }}
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
                            class="divide-y divide-gray-100 bg-white dark:divide-gray-700 dark:bg-gray-800"
                        >
                            <!-- Empty State -->
                            <tr v-if="groups.data.length === 0">
                                <td
                                    colspan="8"
                                    class="px-6 py-16 text-center text-gray-500 dark:text-gray-400"
                                >
                                    <div
                                        class="flex flex-col items-center justify-center"
                                    >
                                        <div
                                            class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-50 text-gray-400 dark:bg-gray-700"
                                        >
                                            <Layers class="h-8 w-8" />
                                        </div>
                                        <h3
                                            class="mb-1 text-lg font-bold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('No customer groups found') }}
                                        </h3>
                                        <p
                                            class="mb-4 max-w-sm text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            {{
                                                $t(
                                                    'Get started by creating a new customer group.',
                                                )
                                            }}
                                        </p>
                                        <Link
                                            :href="'/admin/customers/groups/create'"
                                            class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                                        >
                                            <PlusCircle class="mr-2 h-4 w-4" />
                                            {{ $t('New Group') }}
                                        </Link>
                                    </div>
                                </td>
                            </tr>

                            <template
                                v-for="group in groups.data"
                                :key="group.id"
                            >
                                <tr
                                    draggable="true"
                                    @dragstart="handleDragStart($event, group)"
                                    @dragover="handleDragOver"
                                    @drop="handleDrop($event, group)"
                                    @dragend="handleDragEnd"
                                    :class="[
                                        'group transition-colors hover:bg-blue-50/50 dark:hover:bg-blue-900/10',
                                        draggedGroup?.id === group.id
                                            ? 'opacity-50'
                                            : '',
                                    ]"
                                >
                                    <td class="px-6 py-4">
                                        <input
                                            type="checkbox"
                                            :value="group.id"
                                            v-model="selectedGroups"
                                            class="h-4 w-4 cursor-pointer rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                        />
                                    </td>
                                    <td
                                        class="px-6 py-4 text-sm whitespace-nowrap text-gray-500 dark:text-gray-400"
                                    >
                                        <div
                                            class="flex cursor-move items-center space-x-2"
                                        >
                                            <GripVertical
                                                class="h-4 w-4 text-gray-400"
                                            />
                                            <span>{{ group.order }}</span>
                                        </div>
                                    </td>
                                    <td class="px-6 py-4">
                                        <div
                                            class="flex items-center space-x-3"
                                        >
                                            <div
                                                class="flex h-10 w-10 items-center justify-center rounded-lg font-bold text-white shadow-sm"
                                                :style="{
                                                    backgroundColor:
                                                        group.color,
                                                }"
                                            >
                                                {{
                                                    group.name
                                                        .charAt(0)
                                                        .toUpperCase()
                                                }}
                                            </div>
                                            <div>
                                                <div
                                                    class="flex items-center space-x-2"
                                                >
                                                    <span
                                                        class="text-sm font-bold text-gray-900 dark:text-white"
                                                        >{{ group.name }}</span
                                                    >
                                                    <span
                                                        v-if="group.is_default"
                                                        class="inline-flex items-center rounded border border-purple-200 bg-purple-100 px-2 py-0.5 text-[10px] font-medium text-purple-800 dark:border-purple-800 dark:bg-purple-900/30 dark:text-purple-300"
                                                    >
                                                        {{ $t('Default') }}
                                                    </span>
                                                </div>
                                                <div
                                                    class="mt-0.5 flex items-center gap-1 text-xs text-gray-500 dark:text-gray-400"
                                                >
                                                    <Tag class="h-3 w-3" />
                                                    {{ group.code }}
                                                </div>
                                                <p
                                                    v-if="group.description"
                                                    class="mt-1 hidden max-w-xs truncate text-xs text-gray-400 sm:block dark:text-gray-500"
                                                >
                                                    {{ group.description }}
                                                </p>
                                            </div>
                                        </div>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap sm:table-cell"
                                    >
                                        <span
                                            class="inline-flex items-center rounded-full bg-gray-100 px-2.5 py-0.5 text-xs font-medium text-gray-800 dark:bg-gray-700 dark:text-gray-300"
                                        >
                                            {{ group.discount_percentage }}%
                                        </span>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap md:table-cell"
                                    >
                                        <div
                                            class="text-sm font-medium text-gray-900 dark:text-white"
                                        >
                                            {{
                                                $t('{count} total', {
                                                    count: group.customers_count,
                                                })
                                            }}
                                        </div>
                                        <div
                                            class="text-xs text-gray-500 dark:text-gray-400"
                                        >
                                            {{
                                                $t('{count} active', {
                                                    count: group.active_customers_count,
                                                })
                                            }}
                                        </div>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap lg:table-cell"
                                    >
                                        <div
                                            v-if="
                                                group.auto_assignment_rules &&
                                                Object.keys(
                                                    group.auto_assignment_rules,
                                                ).length > 0
                                            "
                                            class="space-y-1 text-xs"
                                        >
                                            <div
                                                v-if="
                                                    group.auto_assignment_rules
                                                        .min_orders
                                                "
                                                class="text-gray-600 dark:text-gray-400"
                                            >
                                                {{ $t('Min Orders:') }}
                                                <span
                                                    class="font-medium text-gray-900 dark:text-white"
                                                    >{{
                                                        group
                                                            .auto_assignment_rules
                                                            .min_orders
                                                    }}</span
                                                >
                                            </div>
                                            <div
                                                v-if="
                                                    group.auto_assignment_rules
                                                        .min_spent
                                                "
                                                class="text-gray-600 dark:text-gray-400"
                                            >
                                                {{ $t('Min Spent:') }}
                                                <span
                                                    class="font-medium text-gray-900 dark:text-white"
                                                    >{{
                                                        formatPrice(
                                                            group
                                                                .auto_assignment_rules
                                                                .min_spent,
                                                        )
                                                    }}</span
                                                >
                                            </div>
                                            <div
                                                v-if="
                                                    group.auto_assignment_rules
                                                        .min_aov
                                                "
                                                class="text-gray-600 dark:text-gray-400"
                                            >
                                                {{ $t('Min AOV:') }}
                                                <span
                                                    class="font-medium text-gray-900 dark:text-white"
                                                    >{{
                                                        formatPrice(
                                                            group
                                                                .auto_assignment_rules
                                                                .min_aov,
                                                        )
                                                    }}</span
                                                >
                                            </div>
                                            <button
                                                @click="
                                                    applyAutoAssignment(
                                                        group.id,
                                                    )
                                                "
                                                class="font-medium text-blue-600 hover:text-blue-700 hover:underline dark:text-blue-400 dark:hover:text-blue-300"
                                            >
                                                {{ $t('Apply Now') }}
                                            </button>
                                        </div>
                                        <span
                                            v-else
                                            class="text-xs text-gray-400 italic dark:text-gray-500"
                                            >{{ $t('Not configured') }}</span
                                        >
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <span
                                            :class="[
                                                'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium shadow-sm',
                                                group.status
                                                    ? 'border-green-200 bg-green-50 text-green-700 dark:border-green-800 dark:bg-green-900/20 dark:text-green-300'
                                                    : 'border-red-200 bg-red-50 text-red-700 dark:border-red-800 dark:bg-red-900/20 dark:text-red-300',
                                            ]"
                                        >
                                            {{
                                                group.status
                                                    ? $t('Active')
                                                    : $t('Inactive')
                                            }}
                                        </span>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right text-sm font-medium"
                                    >
                                        <div
                                            class="flex items-center justify-end gap-2 opacity-60 transition-opacity group-hover:opacity-100"
                                        >
                                            <Link
                                                :href="`/admin/customers/groups/${group.id}/edit`"
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-indigo-50 hover:text-indigo-600 dark:hover:bg-indigo-900/20"
                                                :title="$t('Edit')"
                                            >
                                                <Edit class="h-4 w-4" />
                                            </Link>
                                            <button
                                                @click="confirmDelete(group.id)"
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-900/20"
                                                :disabled="group.is_default"
                                                :class="{
                                                    'cursor-not-allowed opacity-50':
                                                        group.is_default,
                                                }"
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

                <!-- Pagination -->
                <div
                    class="flex items-center justify-between border-t border-gray-100 bg-gray-50/50 px-6 py-4 dark:border-gray-700 dark:bg-gray-700/50"
                >
                    <div class="text-xs text-gray-500 dark:text-gray-400">
                        {{
                            $t('Showing {from} to {to} of {total} results', {
                                from: groups.from || 0,
                                to: groups.to || 0,
                                total: groups.total,
                            })
                        }}
                    </div>
                    <div class="flex gap-2">
                        <Link
                            v-if="groups.prev_page_url"
                            :href="groups.prev_page_url"
                            class="flex items-center gap-1 rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-xs font-medium text-gray-600 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                        >
                            <ChevronLeft class="h-3 w-3" />
                            {{ $t('Previous') }}
                        </Link>
                        <button
                            v-else
                            disabled
                            class="flex cursor-not-allowed items-center gap-1 rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-xs font-medium text-gray-400 opacity-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-600"
                        >
                            <ChevronLeft class="h-3 w-3" />
                            {{ $t('Previous') }}
                        </button>
                        <Link
                            v-if="groups.next_page_url"
                            :href="groups.next_page_url"
                            class="flex items-center gap-1 rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-xs font-medium text-gray-600 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                        >
                            {{ $t('Next') }}
                            <ChevronRight class="h-3 w-3" />
                        </Link>
                        <button
                            v-else
                            disabled
                            class="flex cursor-not-allowed items-center gap-1 rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-xs font-medium text-gray-400 opacity-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-600"
                        >
                            {{ $t('Next') }}
                            <ChevronRight class="h-3 w-3" />
                        </button>
                    </div>
                </div>
            </div>

            <!-- Delete Modal -->
            <ConfirmDeleteModal
                v-model:show="showDeleteModal"
                :title="deletingGroup?.name ?? ''"
                :message="
                    $t(
                        'Are you sure you want to delete {name}? This action cannot be undone.',
                        { name: deletingGroup?.name },
                    )
                "
                @confirm="deleteGroup"
            />

            <!-- Bulk Delete Modal -->
            <ConfirmDeleteModal
                v-model:show="showBulkDeleteModal"
                :title="$t('Multiple Customer Groups')"
                :message="
                    $t(
                        'Are you sure you want to delete {count} customer group(s)? Groups with customers or set as default will be skipped.',
                        { count: selectedGroups.length },
                    )
                "
                @confirm="bulkDelete"
            />

            <!-- Auto Assignment Confirmation Modal -->
            <Teleport to="body">
                <div
                    v-if="showAutoAssignModal"
                    class="fixed inset-0 z-50 overflow-y-auto"
                    aria-labelledby="modal-title"
                    role="dialog"
                    aria-modal="true"
                >
                    <div
                        class="flex min-h-screen items-end justify-center px-4 pt-4 pb-20 text-center sm:block sm:p-0"
                    >
                        <div
                            class="fixed inset-0 bg-gray-900/50 backdrop-blur-sm transition-opacity"
                            @click="showAutoAssignModal = false"
                        ></div>

                        <div
                            class="relative inline-block transform overflow-hidden rounded-xl bg-white px-4 pt-5 pb-4 text-left align-bottom shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg sm:p-6 sm:align-middle dark:bg-gray-800"
                        >
                            <div class="sm:flex sm:items-start">
                                <div
                                    class="mx-auto flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-blue-100 sm:mx-0 sm:h-10 sm:w-10 dark:bg-blue-900/30"
                                >
                                    <Users
                                        class="h-6 w-6 text-blue-600 dark:text-blue-400"
                                    />
                                </div>
                                <div
                                    class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left"
                                >
                                    <h3
                                        class="text-lg leading-6 font-medium text-gray-900 dark:text-white"
                                        id="modal-title"
                                    >
                                        {{ $t('Apply Auto-Assignment Rules') }}
                                    </h3>
                                    <div class="mt-2">
                                        <p
                                            class="text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            {{
                                                $t(
                                                    'This will assign customers matching the auto-assignment rules to this group. This operation might take a while depending on the number of customers.',
                                                )
                                            }}
                                        </p>
                                    </div>
                                </div>
                            </div>
                            <div
                                class="mt-5 gap-3 sm:mt-4 sm:flex sm:flex-row-reverse"
                            >
                                <button
                                    type="button"
                                    @click="confirmAutoAssignment"
                                    class="inline-flex w-full justify-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-base font-medium text-white shadow-sm hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none sm:w-auto sm:text-sm"
                                >
                                    {{ $t('Continue') }}
                                </button>
                                <button
                                    type="button"
                                    @click="showAutoAssignModal = false"
                                    class="mt-3 inline-flex w-full justify-center rounded-lg border border-gray-300 bg-white px-4 py-2 text-base font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none sm:mt-0 sm:w-auto sm:text-sm dark:border-gray-600 dark:bg-gray-700 dark:text-gray-200 dark:hover:bg-gray-600"
                                >
                                    {{ $t('Cancel') }}
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </Teleport>
        </div>
    </AdminLayout>
</template>

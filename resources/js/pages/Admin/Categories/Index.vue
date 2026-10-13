<script setup lang="ts">
import ConfirmDeleteModal from '@/components/Admin/ConfirmDeleteModal.vue';
import Pagination from '@/components/Admin/Pagination.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import * as categoryRoutes from '@/routes/admin/catalog/categories';
import { Head, Link, router } from '@inertiajs/vue3';
import { debounce } from 'lodash';
import {
    ArrowDown,
    ArrowUp,
    ArrowUpDown,
    CheckCircle,
    ChevronDown,
    Edit,
    Filter,
    Image as ImageIcon,
    Layers,
    MinusCircle,
    Plus,
    PlusCircle,
    Search,
    Trash2,
    X,
    XCircle,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

interface Category {
    id: number;
    name: string;
    slug: string;
    description?: string;
    image?: string;
    status: 'enabled' | 'disabled';
    sort_order: number;
    show_in_menu: boolean;
    parent_id?: number;
    parent?: {
        id: number;
        name: string;
    };
    created_at: string;
    updated_at: string;
}

interface Props {
    categories: {
        data: Category[];
        current_page: number;
        last_page: number;
        per_page: number;
        total: number;
        from: number;
        to: number;
    };
    filters: {
        search?: string;
        status?: string;
        parent_id?: string;
        sort_by?: string;
        sort_order?: string;
    };
    parentCategories: Array<{ id: number; name: string }>;
}

const props = defineProps<Props>();

const selectedCategories = ref<number[]>([]);
const showDeleteModal = ref(false);
const deleteCategoryId = ref<number | null>(null);
const deletingCategory = ref<{ id: number; name: string } | null>(null);
const showBulkDeleteModal = ref(false);

// Local filter state
const search = ref(props.filters.search || '');
const statusFilter = ref(props.filters.status || '');
const parentFilter = ref(props.filters.parent_id || '');
const sortBy = ref(props.filters.sort_by || 'sort_order');
const sortOrder = ref(props.filters.sort_order || 'asc');
const expandedRows = ref<number[]>([]);

// Computed
const allSelected = computed(() => {
    return (
        props.categories.data.length > 0 &&
        selectedCategories.value.length === props.categories.data.length
    );
});

const someSelected = computed(() => {
    return (
        selectedCategories.value.length > 0 &&
        selectedCategories.value.length < props.categories.data.length
    );
});

// Debounced search
const performSearch = debounce(() => {
    applyFilters();
}, 300);

// Methods
function toggleSelectAll() {
    if (allSelected.value) {
        selectedCategories.value = [];
    } else {
        selectedCategories.value = props.categories.data.map((c) => c.id);
    }
}

function applyFilters() {
    router.get(
        categoryRoutes.index().url,
        {
            search: search.value || undefined,
            status: statusFilter.value || undefined,
            parent_id: parentFilter.value || undefined,
            sort_by: sortBy.value,
            sort_order: sortOrder.value,
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
    parentFilter.value = '';
    sortBy.value = 'sort_order';
    sortOrder.value = 'asc';
    applyFilters();
}

function sortTable(column: string) {
    if (sortBy.value === column) {
        sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
    } else {
        sortBy.value = column;
        sortOrder.value = 'asc';
    }
    applyFilters();
}

function confirmDelete(categoryId: number) {
    const category = props.categories.data.find((c) => c.id === categoryId);
    if (category) {
        deletingCategory.value = { id: category.id, name: category.name };
        showDeleteModal.value = true;
    }
}

function deleteCategory() {
    if (deletingCategory.value) {
        router.delete(categoryRoutes.destroy(deletingCategory.value.id).url, {
            onSuccess: () => {
                showDeleteModal.value = false;
                deletingCategory.value = null;
            },
        });
    }
}

function confirmBulkDelete() {
    if (selectedCategories.value.length > 0) {
        showBulkDeleteModal.value = true;
    }
}

function bulkDelete() {
    router.post(
        categoryRoutes.bulkDestroy().url,
        {
            ids: selectedCategories.value,
        },
        {
            onSuccess: () => {
                showBulkDeleteModal.value = false;
                selectedCategories.value = [];
            },
        },
    );
}

function bulkUpdateStatus(status: 'enabled' | 'disabled') {
    if (selectedCategories.value.length > 0) {
        router.post(
            categoryRoutes.bulkStatus().url,
            {
                ids: selectedCategories.value,
                status: status,
            },
            {
                onSuccess: () => {
                    selectedCategories.value = [];
                },
            },
        );
    }
}

function toggleRow(id: number) {
    if (expandedRows.value.includes(id)) {
        expandedRows.value = expandedRows.value.filter((rowId) => rowId !== id);
    } else {
        expandedRows.value.push(id);
    }
}
</script>

<template>
    <Head :title="$t('Categories')" />

    <AdminLayout :title="$t('Categories')">
        <div class="space-y-6">
            <!-- Page Header -->
            <div
                class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
            >
                <div>
                    <h1
                        class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white"
                    >
                        {{ $t('Categories') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                        {{ $t('Manage your product categories structure.') }}
                    </p>
                </div>
                <Link
                    :href="categoryRoutes.create().url"
                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                >
                    <Plus class="mr-2 h-4 w-4" />
                    {{ $t('Add Category') }}
                </Link>
            </div>

            <!-- Filters Card -->
            <div
                class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div
                    class="mb-4 flex items-center gap-2 font-medium text-gray-900 dark:text-white"
                >
                    <Filter class="h-4 w-4 text-gray-500" />
                    {{ $t('Filters & Search') }}
                </div>

                <div class="grid grid-cols-1 gap-4 md:grid-cols-4">
                    <!-- Search -->
                    <div class="group relative md:col-span-1">
                        <div
                            class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3.5"
                        >
                            <Search
                                class="h-4 w-4 text-gray-400 transition-colors group-focus-within:text-blue-500"
                            />
                        </div>
                        <input
                            v-model="search"
                            @input="performSearch"
                            type="text"
                            :placeholder="$t('Search by name or slug...')"
                            class="block w-full rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-3 pl-10 leading-5 text-gray-900 placeholder-gray-400 transition-all focus:border-blue-500 focus:bg-white focus:ring-2 focus:ring-blue-500/20 focus:outline-none sm:text-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white dark:focus:bg-gray-800"
                        />
                    </div>

                    <!-- Status Filter -->
                    <div class="md:col-span-1">
                        <div class="relative">
                            <select
                                v-model="statusFilter"
                                @change="applyFilters"
                                class="block w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-10 pl-3 leading-5 text-gray-700 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 focus:outline-none sm:text-sm dark:border-gray-700 dark:bg-gray-900 dark:text-gray-200"
                            >
                                <option value="">{{ $t('All Status') }}</option>
                                <option value="enabled">
                                    {{ $t('Enabled') }}
                                </option>
                                <option value="disabled">
                                    {{ $t('Disabled') }}
                                </option>
                            </select>
                            <div
                                class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-gray-500"
                            >
                                <ChevronDown class="h-4 w-4" />
                            </div>
                        </div>
                    </div>

                    <!-- Parent Category Filter -->
                    <div class="md:col-span-1">
                        <div class="relative">
                            <select
                                v-model="parentFilter"
                                @change="applyFilters"
                                class="block w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-10 pl-3 leading-5 text-gray-700 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 focus:outline-none sm:text-sm dark:border-gray-700 dark:bg-gray-900 dark:text-gray-200"
                            >
                                <option value="">
                                    {{ $t('All Categories') }}
                                </option>
                                <option value="null">
                                    {{ $t('Root Categories') }}
                                </option>
                                <option
                                    v-for="parent in parentCategories"
                                    :key="parent.id"
                                    :value="parent.id"
                                >
                                    {{ parent.name }}
                                </option>
                            </select>
                            <div
                                class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-gray-500"
                            >
                                <ChevronDown class="h-4 w-4" />
                            </div>
                        </div>
                    </div>

                    <!-- Clear Filters (keeping structure similar but aligned) -->
                    <div class="flex items-end md:col-span-1">
                        <!-- This will be handled by the Active Filters & Clear section below -->
                    </div>
                </div>

                <!-- Active Filters & Clear -->
                <div
                    v-if="search || statusFilter || parentFilter"
                    class="mt-4 flex items-center justify-between border-t border-gray-100 pt-4 dark:border-gray-700"
                >
                    <div class="flex flex-wrap gap-2">
                        <span
                            v-if="search"
                            class="inline-flex items-center rounded-md border border-blue-100 bg-blue-50 px-2.5 py-1 text-xs font-medium text-blue-700 dark:border-blue-800 dark:bg-blue-900/30 dark:text-blue-300"
                        >
                            {{ $t('Search:') }} {{ search }}
                            <button
                                @click="
                                    search = '';
                                    performSearch();
                                "
                                class="ml-1.5 hover:text-blue-900 dark:hover:text-blue-100"
                            >
                                <X class="h-3 w-3" />
                            </button>
                        </span>
                        <span
                            v-if="statusFilter"
                            class="inline-flex items-center rounded-md border border-gray-200 bg-gray-100 px-2.5 py-1 text-xs font-medium text-gray-700 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300"
                        >
                            {{ $t('Status:') }} {{ statusFilter }}
                            <button
                                @click="
                                    statusFilter = '';
                                    applyFilters();
                                "
                                class="ml-1.5 hover:text-gray-900 dark:hover:text-white"
                            >
                                <X class="h-3 w-3" />
                            </button>
                        </span>
                        <span
                            v-if="parentFilter"
                            class="inline-flex items-center rounded-md border border-gray-200 bg-gray-100 px-2.5 py-1 text-xs font-medium text-gray-700 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300"
                        >
                            {{ $t('Parent:') }}
                            {{
                                parentFilter === 'null'
                                    ? $t('Root')
                                    : parentCategories.find(
                                          (p) => p.id == parentFilter,
                                      )?.name || parentFilter
                            }}
                            <button
                                @click="
                                    parentFilter = '';
                                    applyFilters();
                                "
                                class="ml-1.5 hover:text-gray-900 dark:hover:text-white"
                            >
                                <X class="h-3 w-3" />
                            </button>
                        </span>
                    </div>
                    <button
                        @click="clearFilters"
                        class="flex items-center text-sm font-medium text-gray-500 transition-colors hover:text-gray-800 dark:text-gray-400 dark:hover:text-gray-200"
                    >
                        <X class="mr-1 h-4 w-4" />
                        {{ $t('Clear All') }}
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
                    v-if="selectedCategories.length > 0"
                    class="sticky top-4 z-10 flex items-center justify-between rounded-xl bg-blue-600 p-3 px-6 text-white shadow-lg"
                >
                    <span class="flex items-center text-sm font-semibold">
                        <CheckCircle class="mr-2 h-4 w-4" />
                        {{ selectedCategories.length }}
                        {{
                            $t(
                                selectedCategories.length === 1
                                    ? 'category'
                                    : 'categories',
                            )
                        }}
                        {{ $t('selected') }}
                    </span>
                    <div class="flex gap-2">
                        <button
                            @click="bulkUpdateStatus('enabled')"
                            class="rounded-lg bg-white px-3 py-1.5 text-xs font-bold tracking-wide text-blue-600 uppercase transition-colors hover:bg-blue-50"
                        >
                            {{ $t('Enable') }}
                        </button>
                        <button
                            @click="bulkUpdateStatus('disabled')"
                            class="rounded-lg bg-white px-3 py-1.5 text-xs font-bold tracking-wide text-blue-600 uppercase transition-colors hover:bg-blue-50"
                        >
                            {{ $t('Disable') }}
                        </button>
                        <div class="mx-1 h-6 w-px bg-blue-400"></div>
                        <button
                            @click="confirmBulkDelete"
                            class="flex items-center rounded-lg bg-red-500 px-3 py-1.5 text-xs font-bold tracking-wide text-white uppercase transition-colors hover:bg-red-600"
                        >
                            <Trash2 class="mr-1.5 h-3 w-3" />
                            {{ $t('Delete') }}
                        </button>
                    </div>
                </div>
            </transition>

            <!-- Table -->
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
                                        :indeterminate.prop="someSelected"
                                        @change="toggleSelectAll"
                                        class="h-4 w-4 rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </th>
                                <th
                                    class="w-20 px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Image') }}
                                </th>
                                <th
                                    @click="sortTable('name')"
                                    class="group cursor-pointer px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase transition-colors hover:text-blue-600 dark:text-gray-400 dark:hover:text-blue-400"
                                >
                                    <div class="flex items-center gap-1">
                                        {{ $t('Name & Slug') }}
                                        <span
                                            v-if="sortBy === 'name'"
                                            class="text-blue-600 dark:text-blue-400"
                                        >
                                            <ArrowUp
                                                v-if="sortOrder === 'asc'"
                                                class="h-3 w-3"
                                            />
                                            <ArrowDown v-else class="h-3 w-3" />
                                        </span>
                                        <ArrowUpDown
                                            v-else
                                            class="h-3 w-3 opacity-0 group-hover:opacity-50"
                                        />
                                    </div>
                                </th>
                                <th
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase md:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Parent') }}
                                </th>
                                <th
                                    @click="sortTable('status')"
                                    class="group cursor-pointer px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase transition-colors hover:text-blue-600 dark:text-gray-400 dark:hover:text-blue-400"
                                >
                                    <div class="flex items-center gap-1">
                                        {{ $t('Status') }}
                                        <span
                                            v-if="sortBy === 'status'"
                                            class="text-blue-600 dark:text-blue-400"
                                        >
                                            <ArrowUp
                                                v-if="sortOrder === 'asc'"
                                                class="h-3 w-3"
                                            />
                                            <ArrowDown v-else class="h-3 w-3" />
                                        </span>
                                        <ArrowUpDown
                                            v-else
                                            class="h-3 w-3 opacity-0 group-hover:opacity-50"
                                        />
                                    </div>
                                </th>
                                <th
                                    @click="sortTable('sort_order')"
                                    class="group hidden cursor-pointer px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase transition-colors hover:text-blue-600 lg:table-cell dark:text-gray-400 dark:hover:text-blue-400"
                                >
                                    <div class="flex items-center gap-1">
                                        {{ $t('Order') }}
                                        <span
                                            v-if="sortBy === 'sort_order'"
                                            class="text-blue-600 dark:text-blue-400"
                                        >
                                            <ArrowUp
                                                v-if="sortOrder === 'asc'"
                                                class="h-3 w-3"
                                            />
                                            <ArrowDown v-else class="h-3 w-3" />
                                        </span>
                                        <ArrowUpDown
                                            v-else
                                            class="h-3 w-3 opacity-0 group-hover:opacity-50"
                                        />
                                    </div>
                                </th>
                                <th
                                    class="hidden px-6 py-4 text-center text-xs font-semibold tracking-wider text-gray-500 uppercase lg:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Menu') }}
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
                            <tr v-if="categories.data.length === 0">
                                <td
                                    colspan="8"
                                    class="px-6 py-16 text-center text-gray-500 dark:text-gray-400"
                                >
                                    <div class="flex flex-col items-center">
                                        <div
                                            class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-50 text-gray-400 dark:bg-gray-700"
                                        >
                                            <Layers class="h-8 w-8" />
                                        </div>
                                        <p
                                            class="text-lg font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('No categories found') }}
                                        </p>
                                        <p
                                            class="mt-1 max-w-sm text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            {{
                                                $t(
                                                    'No categories matched your search criteria. Try adjusting your filters or add a new category.',
                                                )
                                            }}
                                        </p>
                                        <button
                                            @click="clearFilters"
                                            v-if="
                                                search ||
                                                statusFilter ||
                                                parentFilter
                                            "
                                            class="mt-4 text-sm font-medium text-blue-600 hover:text-blue-700"
                                        >
                                            {{ $t('Clear all filters') }}
                                        </button>
                                    </div>
                                </td>
                            </tr>
                            <template
                                v-for="category in categories.data"
                                :key="category.id"
                            >
                                <tr
                                    class="group transition-colors hover:bg-blue-50/50 dark:hover:bg-blue-900/10"
                                >
                                    <td class="relative px-6 py-4">
                                        <div class="flex items-center">
                                            <button
                                                @click="toggleRow(category.id)"
                                                class="absolute left-2 p-1 text-blue-600 hover:text-blue-800 focus:outline-none lg:hidden"
                                            >
                                                <MinusCircle
                                                    v-if="
                                                        expandedRows.includes(
                                                            category.id,
                                                        )
                                                    "
                                                    class="h-5 w-5 fill-blue-100 dark:fill-blue-900/30"
                                                />
                                                <PlusCircle
                                                    v-else
                                                    class="h-5 w-5 fill-blue-50 dark:fill-blue-900/20"
                                                />
                                            </button>
                                            <input
                                                v-model="selectedCategories"
                                                type="checkbox"
                                                :value="category.id"
                                                class="ml-4 h-4 w-4 cursor-pointer rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 lg:ml-0 dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                    </td>
                                    <td class="px-6 py-4">
                                        <div
                                            v-if="category.image"
                                            class="h-12 w-12 overflow-hidden rounded-lg border border-gray-200 bg-gray-100 shadow-sm dark:border-gray-600 dark:bg-gray-700"
                                        >
                                            <img
                                                :src="`/storage/${category.image}`"
                                                :alt="category.name"
                                                class="h-full w-full object-cover transition-transform duration-300 group-hover:scale-110"
                                            />
                                        </div>
                                        <div
                                            v-else
                                            class="flex h-12 w-12 items-center justify-center rounded-lg border border-gray-200 bg-gray-100 text-gray-400 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-500"
                                        >
                                            <ImageIcon class="h-6 w-6" />
                                        </div>
                                    </td>
                                    <td class="px-6 py-4">
                                        <div class="flex flex-col">
                                            <span
                                                class="text-sm font-bold text-gray-900 transition-colors group-hover:text-blue-600 dark:text-white dark:group-hover:text-blue-400"
                                                >{{ category.name }}</span
                                            >
                                            <span
                                                class="mt-0.5 font-mono text-xs text-gray-500 dark:text-gray-400"
                                                >{{ category.slug }}</span
                                            >
                                        </div>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap md:table-cell"
                                    >
                                        <span
                                            v-if="category.parent"
                                            class="inline-flex items-center rounded-md border border-gray-100 bg-gray-50 px-2 py-1 text-sm text-gray-700 dark:border-gray-700 dark:bg-gray-700/50 dark:text-gray-300"
                                        >
                                            <Layers
                                                class="mr-1.5 h-3 w-3 opacity-70"
                                            />
                                            {{ category.parent.name }}
                                        </span>
                                        <span
                                            v-else
                                            class="text-xs text-gray-400 italic dark:text-gray-500"
                                            >{{ $t('Root Category') }}</span
                                        >
                                    </td>
                                    <td class="px-6 py-4">
                                        <span
                                            class="inline-flex items-center rounded-full border px-2.5 py-1 text-xs font-semibold shadow-sm"
                                            :class="{
                                                'border-green-200 bg-green-50 text-green-700 dark:border-green-800 dark:bg-green-900/20 dark:text-green-300':
                                                    category.status ===
                                                    'enabled',
                                                'border-gray-200 bg-gray-100 text-gray-600 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300':
                                                    category.status ===
                                                    'disabled',
                                            }"
                                        >
                                            <CheckCircle
                                                v-if="
                                                    category.status ===
                                                    'enabled'
                                                "
                                                class="mr-1 h-3 w-3"
                                            />
                                            <XCircle
                                                v-else
                                                class="mr-1 h-3 w-3"
                                            />
                                            {{
                                                $t(
                                                    category.status
                                                        .charAt(0)
                                                        .toUpperCase() +
                                                        category.status.slice(
                                                            1,
                                                        ),
                                                )
                                            }}
                                        </span>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 font-mono text-sm text-gray-500 lg:table-cell dark:text-gray-400"
                                    >
                                        {{ category.sort_order }}
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 text-center lg:table-cell"
                                    >
                                        <div
                                            v-if="category.show_in_menu"
                                            class="inline-flex h-8 w-8 items-center justify-center rounded-full bg-green-50 text-green-600 ring-1 ring-green-600/20 ring-inset dark:bg-green-900/20 dark:text-green-400"
                                        >
                                            <CheckCircle class="h-4 w-4" />
                                        </div>
                                        <div
                                            v-else
                                            class="inline-flex h-8 w-8 items-center justify-center rounded-full bg-gray-50 text-gray-400 ring-1 ring-gray-300/20 ring-inset dark:bg-gray-800 dark:text-gray-500"
                                        >
                                            <X class="h-4 w-4" />
                                        </div>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right align-middle text-sm font-medium"
                                    >
                                        <div
                                            class="flex items-center justify-end gap-2 opacity-60 transition-opacity group-hover:opacity-100"
                                        >
                                            <Link
                                                :href="
                                                    categoryRoutes.edit(
                                                        category.id,
                                                    ).url
                                                "
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-900/20"
                                                :title="$t('Edit')"
                                            >
                                                <Edit class="h-4 w-4" />
                                            </Link>
                                            <button
                                                @click="
                                                    confirmDelete(category.id)
                                                "
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-900/20"
                                                :title="$t('Delete')"
                                            >
                                                <Trash2 class="h-4 w-4" />
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                                <!-- Expanded Mobile Details Row -->
                                <tr
                                    v-if="expandedRows.includes(category.id)"
                                    class="border-t border-gray-100 bg-blue-50/30 lg:hidden dark:border-gray-700 dark:bg-blue-900/10"
                                >
                                    <td colspan="100%" class="px-6 py-4">
                                        <div
                                            class="grid grid-cols-1 gap-6 text-sm sm:grid-cols-3"
                                        >
                                            <div class="md:hidden">
                                                <span
                                                    class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                                    >{{ $t('Parent') }}</span
                                                >
                                                <span
                                                    v-if="category.parent"
                                                    class="inline-flex items-center text-gray-700 dark:text-gray-300"
                                                >
                                                    <Layers
                                                        class="mr-1.5 h-3.5 w-3.5 opacity-70"
                                                    />
                                                    {{ category.parent.name }}
                                                </span>
                                                <span
                                                    v-else
                                                    class="text-gray-400 italic dark:text-gray-500"
                                                    >{{
                                                        $t('Root Category')
                                                    }}</span
                                                >
                                            </div>

                                            <div>
                                                <span
                                                    class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                                    >{{ $t('Order') }}</span
                                                >
                                                <span
                                                    class="font-mono text-gray-700 dark:text-gray-300"
                                                    >{{
                                                        category.sort_order
                                                    }}</span
                                                >
                                            </div>

                                            <div>
                                                <span
                                                    class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                                    >{{
                                                        $t('Show in Menu')
                                                    }}</span
                                                >
                                                <span
                                                    v-if="category.show_in_menu"
                                                    class="inline-flex items-center rounded-md border border-green-200 bg-green-50 px-2 py-0.5 text-xs font-medium text-green-700 dark:border-green-800 dark:bg-green-900/20 dark:text-green-400"
                                                >
                                                    <CheckCircle
                                                        class="mr-1 h-3 w-3"
                                                    />
                                                    {{ $t('Yes') }}
                                                </span>
                                                <span
                                                    v-else
                                                    class="inline-flex items-center rounded-md border border-gray-200 bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-600 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400"
                                                >
                                                    <X class="mr-1 h-3 w-3" />
                                                    {{ $t('No') }}
                                                </span>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                            </template>
                        </tbody>
                    </table>
                </div>

                <!-- Pagination -->
                <Pagination
                    :data="categories"
                    :resource-name="$t('categories')"
                />
            </div>

            <!-- Delete Confirmation Modal -->
            <ConfirmDeleteModal
                v-model:show="showDeleteModal"
                :title="deletingCategory?.name ?? ''"
                :message="
                    $t(
                        'Are you sure you want to delete {name}? This action cannot be undone.',
                        { name: deletingCategory?.name },
                    )
                "
                @confirm="deleteCategory"
            />

            <!-- Bulk Delete Modal -->
            <ConfirmDeleteModal
                v-model:show="showBulkDeleteModal"
                :title="$t('Multiple Categories')"
                :message="
                    $t(
                        'Are you sure you want to delete {count} {noun}? This action cannot be undone.',
                        {
                            count: selectedCategories.length,
                            noun: $t(
                                selectedCategories.length === 1
                                    ? 'category'
                                    : 'categories',
                            ),
                        },
                    )
                "
                @confirm="bulkDelete"
            />
        </div>
    </AdminLayout>
</template>

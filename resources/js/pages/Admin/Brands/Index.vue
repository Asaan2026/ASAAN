<script setup lang="ts">
import ConfirmDeleteModal from '@/components/Admin/ConfirmDeleteModal.vue';
import Pagination from '@/components/Admin/Pagination.vue';
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import * as brandRoutes from '@/routes/admin/catalog/brands';
import { Head, Link, router } from '@inertiajs/vue3';
import { debounce } from 'lodash';
import {
    ArrowDown,
    ArrowUp,
    ArrowUpDown,
    CheckCircle,
    Edit,
    ExternalLink,
    Filter,
    ImageIcon,
    MinusCircle,
    Plus,
    PlusCircle,
    Search,
    Tag,
    Trash2,
    X,
    XCircle,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

interface Brand {
    id: number;
    name: string;
    slug: string;
    description?: string;
    logo?: string;
    website?: string;
    status: boolean;
    is_featured: boolean;
    sort_order: number;
    products_count?: number;
    created_at: string;
    updated_at: string;
}

interface Props {
    brands: {
        data: Brand[];
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
        is_featured?: string;
        sort_by?: string;
        sort_order?: string;
    };
}

const props = defineProps<Props>();

const selectedBrands = ref<number[]>([]);
const showDeleteModal = ref(false);
const deleteBrandId = ref<number | null>(null);
const deletingBrand = ref<{ id: number; name: string } | null>(null);
const showBulkDeleteModal = ref(false);
const expandedRows = ref<number[]>([]);

// Local filter state
const search = ref(props.filters.search || '');
const statusFilter = ref(props.filters.status || '');
const featuredFilter = ref(props.filters.is_featured || '');
const sortBy = ref(props.filters.sort_by || 'name');
const sortOrder = ref(props.filters.sort_order || 'asc');

// Computed
const allSelected = computed(() => {
    return (
        props.brands.data.length > 0 &&
        selectedBrands.value.length === props.brands.data.length
    );
});

const someSelected = computed(() => {
    return (
        selectedBrands.value.length > 0 &&
        selectedBrands.value.length < props.brands.data.length
    );
});

// Debounced search
const performSearch = debounce(() => {
    applyFilters();
}, 300);

const toggleRow = (id: number) => {
    const index = expandedRows.value.indexOf(id);
    if (index === -1) {
        expandedRows.value.push(id);
    } else {
        expandedRows.value.splice(index, 1);
    }
};

// Methods
function toggleSelectAll() {
    if (allSelected.value) {
        selectedBrands.value = [];
    } else {
        selectedBrands.value = props.brands.data.map((b) => b.id);
    }
}

function applyFilters() {
    router.get(
        brandRoutes.index().url,
        {
            search: search.value || undefined,
            status: statusFilter.value || undefined,
            is_featured: featuredFilter.value || undefined,
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
    featuredFilter.value = '';
    sortBy.value = 'name';
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

function confirmDelete(brandId: number) {
    const brand = props.brands.data.find((b) => b.id === brandId);
    if (brand) {
        deletingBrand.value = { id: brand.id, name: brand.name };
        showDeleteModal.value = true;
    }
}

function deleteBrand() {
    if (deletingBrand.value) {
        router.delete(brandRoutes.destroy(deletingBrand.value.id).url, {
            onSuccess: () => {
                showDeleteModal.value = false;
                deletingBrand.value = null;
            },
        });
    }
}

function confirmBulkDelete() {
    if (selectedBrands.value.length > 0) {
        showBulkDeleteModal.value = true;
    }
}

function bulkDelete() {
    router.post(
        brandRoutes.bulkDestroy().url,
        {
            ids: selectedBrands.value,
        },
        {
            onSuccess: () => {
                showBulkDeleteModal.value = false;
                selectedBrands.value = [];
            },
        },
    );
}

function bulkUpdateStatus(status: boolean) {
    if (selectedBrands.value.length > 0) {
        router.post(
            brandRoutes.bulkStatus().url,
            {
                ids: selectedBrands.value,
                status: status,
            },
            {
                onSuccess: () => {
                    selectedBrands.value = [];
                },
            },
        );
    }
}

function changePage(page: number) {
    router.get(
        brandRoutes.index().url,
        {
            ...props.filters,
            page,
        },
        {
            preserveState: true,
            preserveScroll: true,
        },
    );
}
</script>

<template>
    <Head :title="$t('Brands')" />

    <AdminLayout :title="$t('Brands')">
        <div class="space-y-6 p-6">
            <!-- Page Header -->
            <div class="flex items-center justify-between">
                <div>
                    <h1 class="text-2xl font-bold text-gray-900">
                        {{ $t('Brands') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600">
                        {{ $t('Manage your product brands') }}
                    </p>
                </div>
                <Link
                    :href="brandRoutes.create().url"
                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                >
                    <Plus class="mr-2 h-4 w-4" />
                    {{ $t('Add Brand') }}
                </Link>
            </div>

            <!-- Filters Card -->
            <div
                class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div class="grid grid-cols-1 gap-4 md:grid-cols-4">
                    <!-- Search -->
                    <div class="relative">
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
                                @input="performSearch"
                                type="text"
                                :placeholder="$t('Search brands...')"
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
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-10 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            >
                                <option value="">{{ $t('All Status') }}</option>
                                <option value="1">{{ $t('Active') }}</option>
                                <option value="0">{{ $t('Inactive') }}</option>
                            </select>
                            <div
                                class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2"
                            >
                                <svg
                                    class="h-4 w-4 text-gray-400"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="2"
                                        d="M19 9l-7 7-7-7"
                                    ></path>
                                </svg>
                            </div>
                        </div>
                    </div>

                    <!-- Featured Filter -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Featured') }}</label
                        >
                        <div class="relative">
                            <Filter
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <select
                                v-model="featuredFilter"
                                @change="applyFilters"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-10 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            >
                                <option value="">{{ $t('All Brands') }}</option>
                                <option value="1">{{ $t('Featured') }}</option>
                                <option value="0">
                                    {{ $t('Not Featured') }}
                                </option>
                            </select>
                            <div
                                class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2"
                            >
                                <svg
                                    class="h-4 w-4 text-gray-400"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="2"
                                        d="M19 9l-7 7-7-7"
                                    ></path>
                                </svg>
                            </div>
                        </div>
                    </div>

                    <!-- Clear Filters -->
                    <div class="flex items-end">
                        <button
                            @click="clearFilters"
                            class="flex w-full items-center justify-center gap-2 rounded-lg bg-gray-100 py-2.5 text-sm font-medium text-gray-600 transition-colors hover:bg-gray-200 hover:text-gray-900 dark:bg-gray-700 dark:text-gray-400 dark:hover:bg-gray-600 dark:hover:text-gray-200"
                        >
                            <X class="h-4 w-4" />
                            {{ $t('Clear Filters') }}
                        </button>
                    </div>
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
                    v-if="selectedBrands.length > 0"
                    class="sticky top-4 z-10 flex items-center justify-between rounded-xl bg-blue-600 p-3 px-6 text-white shadow-lg"
                >
                    <span class="flex items-center text-sm font-semibold">
                        <CheckCircle class="mr-2 h-4 w-4" />
                        {{ selectedBrands.length }}
                        {{
                            $t(selectedBrands.length === 1 ? 'brand' : 'brands')
                        }}
                        {{ $t('selected') }}
                    </span>
                    <div class="flex gap-2">
                        <button
                            @click="bulkUpdateStatus(true)"
                            class="rounded-lg bg-white px-3 py-1.5 text-xs font-bold tracking-wide text-blue-600 uppercase transition-colors hover:bg-blue-50"
                        >
                            {{ $t('Activate') }}
                        </button>
                        <button
                            @click="bulkUpdateStatus(false)"
                            class="rounded-lg bg-white px-3 py-1.5 text-xs font-bold tracking-wide text-blue-600 uppercase transition-colors hover:bg-blue-50"
                        >
                            {{ $t('Deactivate') }}
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
                                <th scope="col" class="w-12 px-6 py-4">
                                    <input
                                        type="checkbox"
                                        :checked="allSelected"
                                        :indeterminate.prop="someSelected"
                                        @change="toggleSelectAll"
                                        class="h-4 w-4 rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </th>
                                <th
                                    scope="col"
                                    class="group cursor-pointer px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase transition-colors hover:text-blue-600 dark:text-gray-400 dark:hover:text-blue-400"
                                    @click="sortTable('name')"
                                >
                                    <div class="flex items-center gap-1">
                                        {{ $t('Name') }}
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
                                    scope="col"
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase md:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Website') }}
                                </th>
                                <th
                                    scope="col"
                                    class="group cursor-pointer px-6 py-4 text-center text-xs font-semibold tracking-wider text-gray-500 uppercase transition-colors hover:text-blue-600 dark:text-gray-400 dark:hover:text-blue-400"
                                    @click="sortTable('status')"
                                >
                                    <div
                                        class="flex items-center justify-center gap-1"
                                    >
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
                                    scope="col"
                                    class="hidden px-6 py-4 text-center text-xs font-semibold tracking-wider text-gray-500 uppercase sm:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Featured') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-4 text-center text-xs font-semibold tracking-wider text-gray-500 uppercase lg:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Products') }}
                                </th>
                                <th
                                    scope="col"
                                    class="px-6 py-4 text-right text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Actions') }}
                                </th>
                            </tr>
                        </thead>
                        <tbody
                            class="divide-y divide-gray-100 bg-white dark:divide-gray-700 dark:bg-gray-800"
                        >
                            <template
                                v-for="brand in brands.data"
                                :key="brand.id"
                            >
                                <tr
                                    class="group transition-colors hover:bg-blue-50/50 dark:hover:bg-blue-900/10"
                                >
                                    <td class="relative px-6 py-4">
                                        <div class="flex items-center">
                                            <button
                                                @click="toggleRow(brand.id)"
                                                class="absolute left-2 p-1 text-blue-600 hover:text-blue-800 focus:outline-none lg:hidden"
                                            >
                                                <MinusCircle
                                                    v-if="
                                                        expandedRows.includes(
                                                            brand.id,
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
                                                type="checkbox"
                                                :value="brand.id"
                                                v-model="selectedBrands"
                                                class="ml-4 h-4 w-4 cursor-pointer rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 lg:ml-0 dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div class="flex items-center">
                                            <div
                                                class="h-10 w-10 flex-shrink-0"
                                            >
                                                <img
                                                    v-if="brand.logo"
                                                    class="h-10 w-10 rounded-full border border-gray-100 object-cover"
                                                    :src="`/storage/${brand.logo}`"
                                                    :alt="brand.name"
                                                />
                                                <div
                                                    v-else
                                                    class="flex h-10 w-10 items-center justify-center rounded-full bg-gray-100 text-gray-400 dark:bg-gray-700"
                                                >
                                                    <ImageIcon
                                                        class="h-5 w-5"
                                                    />
                                                </div>
                                            </div>
                                            <div class="ml-4">
                                                <div
                                                    class="text-sm font-bold text-gray-900 transition-colors group-hover:text-blue-600 dark:text-white dark:group-hover:text-blue-400"
                                                >
                                                    {{ brand.name }}
                                                </div>
                                                <div
                                                    class="font-mono text-xs text-gray-500 dark:text-gray-400"
                                                >
                                                    {{ brand.slug }}
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap md:table-cell"
                                    >
                                        <a
                                            v-if="brand.website"
                                            :href="brand.website"
                                            target="_blank"
                                            class="flex items-center gap-1 text-sm text-blue-600 hover:text-blue-800 hover:underline"
                                        >
                                            <ExternalLink class="h-3 w-3" />
                                            {{ $t('Visit') }}
                                        </a>
                                        <span
                                            v-else
                                            class="text-sm text-gray-400 dark:text-gray-600"
                                            >-</span
                                        >
                                    </td>
                                    <td
                                        class="px-6 py-4 text-center whitespace-nowrap"
                                    >
                                        <span
                                            :class="[
                                                'inline-flex items-center rounded-full border px-2.5 py-1 text-xs font-medium shadow-sm',
                                                brand.status
                                                    ? 'border-green-200 bg-green-50 text-green-700 dark:border-green-800 dark:bg-green-900/20 dark:text-green-300'
                                                    : 'border-gray-200 bg-gray-100 text-gray-600 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300',
                                            ]"
                                        >
                                            <CheckCircle
                                                v-if="brand.status"
                                                class="mr-1 h-3 w-3"
                                            />
                                            <XCircle
                                                v-else
                                                class="mr-1 h-3 w-3"
                                            />
                                            {{
                                                $t(
                                                    brand.status
                                                        ? 'Active'
                                                        : 'Inactive',
                                                )
                                            }}
                                        </span>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 text-center whitespace-nowrap sm:table-cell"
                                    >
                                        <span
                                            v-if="brand.is_featured"
                                            class="inline-flex h-6 w-6 items-center justify-center rounded-full bg-yellow-50 text-yellow-600 ring-1 ring-yellow-600/20 ring-inset dark:bg-yellow-900/20 dark:text-yellow-400"
                                        >
                                            <svg
                                                class="h-4 w-4 fill-current"
                                                viewBox="0 0 20 20"
                                                xmlns="http://www.w3.org/2000/svg"
                                            >
                                                <path
                                                    d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"
                                                ></path>
                                            </svg>
                                        </span>
                                        <span
                                            v-else
                                            class="text-gray-300 dark:text-gray-600"
                                        >
                                            -
                                        </span>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 text-center text-sm whitespace-nowrap text-gray-500 lg:table-cell dark:text-gray-400"
                                    >
                                        <div
                                            class="inline-flex items-center rounded-full bg-blue-50 px-2.5 py-0.5 text-xs font-medium text-blue-700 dark:bg-blue-900/20 dark:text-blue-300"
                                        >
                                            {{
                                                $t('{count} products', {
                                                    count:
                                                        brand.products_count ||
                                                        0,
                                                })
                                            }}
                                        </div>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right text-sm font-medium whitespace-nowrap"
                                    >
                                        <div
                                            class="flex items-center justify-end gap-2 opacity-60 transition-opacity group-hover:opacity-100"
                                        >
                                            <Link
                                                :href="
                                                    brandRoutes.edit(brand.id)
                                                        .url
                                                "
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-900/20"
                                                :title="$t('Edit')"
                                            >
                                                <Edit class="h-4 w-4" />
                                            </Link>
                                            <button
                                                @click="confirmDelete(brand.id)"
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-900/20"
                                                :title="$t('Delete')"
                                            >
                                                <Trash2 class="h-4 w-4" />
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                                <!-- Expanded Mobile Row -->
                                <tr
                                    v-if="expandedRows.includes(brand.id)"
                                    class="bg-gray-50/50 lg:hidden dark:bg-gray-900/50"
                                >
                                    <td
                                        colspan="7"
                                        class="border-t border-gray-100 px-6 py-4 dark:border-gray-700"
                                    >
                                        <div
                                            class="grid grid-cols-2 gap-4 text-sm"
                                        >
                                            <div
                                                class="col-span-2 flex flex-col gap-1 sm:col-span-1"
                                                v-if="brand.website"
                                            >
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Website') }}</span
                                                >
                                                <a
                                                    :href="brand.website"
                                                    target="_blank"
                                                    class="flex items-center gap-1 text-blue-600 hover:underline"
                                                >
                                                    <ExternalLink
                                                        class="h-3 w-3"
                                                    />
                                                    {{ brand.website }}
                                                </a>
                                            </div>
                                            <div
                                                class="flex flex-col gap-1 sm:hidden"
                                            >
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Featured') }}</span
                                                >
                                                <span
                                                    v-if="brand.is_featured"
                                                    class="inline-flex w-fit items-center rounded bg-yellow-100 px-2 py-0.5 text-xs font-medium text-yellow-800"
                                                    >{{ $t('Featured') }}</span
                                                >
                                                <span
                                                    v-else
                                                    class="text-gray-500"
                                                    >{{ $t('No') }}</span
                                                >
                                            </div>
                                            <div
                                                class="flex flex-col gap-1 lg:hidden"
                                            >
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Products') }}</span
                                                >
                                                <span
                                                    class="text-gray-700 dark:text-gray-300"
                                                    >{{
                                                        $t('{count} products', {
                                                            count:
                                                                brand.products_count ||
                                                                0,
                                                        })
                                                    }}</span
                                                >
                                            </div>
                                            <div class="flex flex-col gap-1">
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Created') }}</span
                                                >
                                                <span
                                                    class="text-gray-700 dark:text-gray-300"
                                                    ><DateDisplay
                                                        :value="
                                                            brand.created_at
                                                        "
                                                /></span>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                            </template>
                            <tr v-if="brands.data.length === 0">
                                <td
                                    colspan="7"
                                    class="px-6 py-16 text-center text-gray-500 dark:text-gray-400"
                                >
                                    <div class="flex flex-col items-center">
                                        <div
                                            class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-50 text-gray-400 dark:bg-gray-700"
                                        >
                                            <Tag class="h-8 w-8" />
                                        </div>
                                        <p
                                            class="text-lg font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('No brands found') }}
                                        </p>
                                        <p
                                            class="mt-1 max-w-sm text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            {{
                                                $t(
                                                    'Get started by creating a new brand.',
                                                )
                                            }}
                                        </p>
                                    </div>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <!-- Pagination -->
                <Pagination :data="brands" :resource-name="$t('brands')" />
            </div>
        </div>

        <!-- Delete Confirmation Modal -->
        <ConfirmDeleteModal
            v-model:show="showDeleteModal"
            :title="deletingBrand?.name ?? ''"
            :message="
                $t(
                    'Are you sure you want to delete {name}? This action cannot be undone.',
                    { name: deletingBrand?.name },
                )
            "
            @confirm="deleteBrand"
        />

        <!-- Bulk Delete Modal -->
        <ConfirmDeleteModal
            v-model:show="showBulkDeleteModal"
            :title="$t('Multiple Brands')"
            :message="
                $t(
                    'Are you sure you want to delete {count} brand(s)? This action cannot be undone.',
                    { count: selectedBrands.length },
                )
            "
            @confirm="bulkDelete"
        />
    </AdminLayout>
</template>

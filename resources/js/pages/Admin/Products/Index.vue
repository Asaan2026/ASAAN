<script setup lang="ts">
import ConfirmDeleteModal from '@/components/Admin/ConfirmDeleteModal.vue';
import Pagination from '@/components/Admin/Pagination.vue';
import ProductQuickView from '@/components/Admin/ProductQuickView.vue';
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import * as productRoutes from '@/routes/admin/catalog/products';
import { Head, Link, router } from '@inertiajs/vue3';
import { debounce } from 'lodash';
import {
    ArrowDown,
    ArrowUp,
    ArrowUpDown,
    CheckCircle,
    ChevronDown,
    Edit,
    Eye,
    Filter,
    Layers,
    MinusCircle,
    Package,
    Plus,
    PlusCircle,
    Search,
    Trash2,
    X,
    XCircle,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

interface Product {
    id: number;
    sku: string;
    name: string;
    slug: string;
    price: number;
    special_price?: number;
    quantity: number;
    status: 'enabled' | 'disabled';
    stock_status: 'in_stock' | 'out_of_stock' | 'on_backorder';
    type: 'simple' | 'configurable' | 'virtual' | 'downloadable';
    featured: boolean;
    new: boolean;
    created_at: string;
    main_image?: {
        id: number;
        path: string;
        url: string;
        thumbnail_path: string;
    };
    categories: Array<{ id: number; name: string }>;
    images_count: number;
}

interface Props {
    products: {
        data: Product[];
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
        category_id?: number;
        stock_status?: string;
        sort_by?: string;
        sort_order?: string;
    };
    categories: Array<{ id: number; name: string }>;
}

const props = defineProps<Props>();

const selectedProducts = ref<number[]>([]);
const showDeleteModal = ref(false);
const deleteProductId = ref<number | null>(null);
const deletingProduct = ref<{ id: number; name: string } | null>(null);
const showBulkDeleteModal = ref(false);
const expandedRows = ref<number[]>([]);

// Quick View
const showQuickView = ref(false);
const selectedProduct = ref<Product | null>(null);

// Local filter state
const search = ref(props.filters.search || '');
const statusFilter = ref(props.filters.status || '');
const categoryFilter = ref(props.filters.category_id || '');
const stockStatusFilter = ref(props.filters.stock_status || '');
const sortBy = ref(props.filters.sort_by || 'created_at');
const sortOrder = ref(props.filters.sort_order || 'desc');

// Computed
const allSelected = computed(() => {
    return (
        props.products.data.length > 0 &&
        selectedProducts.value.length === props.products.data.length
    );
});

const someSelected = computed(() => {
    return (
        selectedProducts.value.length > 0 &&
        selectedProducts.value.length < props.products.data.length
    );
});

// Debounced search
const performSearch = debounce(() => {
    applyFilters();
}, 300);

// Methods
const toggleRow = (id: number) => {
    const index = expandedRows.value.indexOf(id);
    if (index === -1) {
        expandedRows.value.push(id);
    } else {
        expandedRows.value.splice(index, 1);
    }
};

function toggleSelectAll() {
    if (allSelected.value) {
        selectedProducts.value = [];
    } else {
        selectedProducts.value = props.products.data.map((p) => p.id);
    }
}

function applyFilters() {
    router.get(
        productRoutes.index().url,
        {
            search: search.value || undefined,
            status: statusFilter.value || undefined,
            category_id: categoryFilter.value || undefined,
            stock_status: stockStatusFilter.value || undefined,
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
    categoryFilter.value = '';
    stockStatusFilter.value = '';
    sortBy.value = 'created_at';
    sortOrder.value = 'desc';
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

function confirmDelete(productId: number) {
    const product = props.products.data.find((p) => p.id === productId);
    if (product) {
        deletingProduct.value = { id: product.id, name: product.name };
        showDeleteModal.value = true;
    }
}

function deleteProduct() {
    if (deletingProduct.value) {
        router.delete(
            productRoutes.destroy({ product: deletingProduct.value.id }).url,
            {
                onSuccess: () => {
                    showDeleteModal.value = false;
                    deletingProduct.value = null;
                },
            },
        );
    }
}

function confirmBulkDelete() {
    if (selectedProducts.value.length > 0) {
        showBulkDeleteModal.value = true;
    }
}

function bulkDelete() {
    router.post(
        productRoutes.bulkDestroy().url,
        {
            ids: selectedProducts.value,
        },
        {
            onSuccess: () => {
                selectedProducts.value = [];
                showBulkDeleteModal.value = false;
            },
        },
    );
}

function openQuickView(product: Product) {
    selectedProduct.value = product;
    showQuickView.value = true;
}

function editProductFromQuickView(product: Product) {
    router.visit(productRoutes.edit({ product: product.id }).url);
}

function deleteProductFromQuickView(product: Product) {
    showQuickView.value = false;
    confirmDelete(product.id);
}

function bulkUpdateStatus(status: 'enabled' | 'disabled') {
    if (selectedProducts.value.length > 0) {
        router.post(
            productRoutes.bulkStatus().url,
            {
                ids: selectedProducts.value,
                status: status,
            },
            {
                onSuccess: () => {
                    selectedProducts.value = [];
                },
            },
        );
    }
}

const { formatPrice } = useCurrency();
</script>

<template>
    <Head :title="$t('Products')" />

    <AdminLayout :title="$t('Products')">
        <div class="space-y-5">
            <!-- Page Header -->
            <div
                class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
            >
                <div>
                    <h1
                        class="text-xl font-semibold tracking-tight text-gray-900 dark:text-white"
                    >
                        {{ $t('Products') }}
                    </h1>
                    <p class="mt-0.5 text-sm text-gray-500 dark:text-gray-400">
                        {{
                            $t(
                                'Manage your entire product catalog from one place.',
                            )
                        }}
                    </p>
                </div>
                <Link
                    :href="productRoutes.create().url"
                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                >
                    <Plus class="mr-2 h-4 w-4" />
                    {{ $t('Add Product') }}
                </Link>
            </div>

            <!-- Filters Card -->
            <div
                class="rounded-xl border border-gray-100 bg-white p-5 dark:border-gray-700/60 dark:bg-gray-800/80"
            >
                <div
                    class="mb-3.5 flex items-center gap-2 text-sm font-medium text-gray-700 dark:text-gray-300"
                >
                    <Filter class="h-3.5 w-3.5 text-gray-400" />
                    {{ $t('Filters & Search') }}
                </div>

                <div class="grid grid-cols-1 gap-4 md:grid-cols-12">
                    <!-- Search -->
                    <div class="group relative md:col-span-4">
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
                            :placeholder="$t('Search by name, SKU...')"
                            class="block w-full rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-3 pl-10 leading-5 text-gray-900 placeholder-gray-400 transition-all focus:border-blue-500 focus:bg-white focus:ring-2 focus:ring-blue-500/20 focus:outline-none sm:text-sm dark:border-gray-700 dark:bg-gray-900 dark:text-white dark:focus:bg-gray-800"
                        />
                    </div>

                    <!-- Status Filter -->
                    <div class="md:col-span-2">
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

                    <!-- Category Filter -->
                    <div class="md:col-span-3">
                        <div class="relative">
                            <select
                                v-model="categoryFilter"
                                @change="applyFilters"
                                class="block w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-10 pl-3 leading-5 text-gray-700 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 focus:outline-none sm:text-sm dark:border-gray-700 dark:bg-gray-900 dark:text-gray-200"
                            >
                                <option value="">
                                    {{ $t('All Categories') }}
                                </option>
                                <option
                                    v-for="category in categories"
                                    :key="category.id"
                                    :value="category.id"
                                >
                                    {{ category.name }}
                                </option>
                            </select>
                            <div
                                class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-gray-500"
                            >
                                <ChevronDown class="h-4 w-4" />
                            </div>
                        </div>
                    </div>

                    <!-- Stock Status Filter -->
                    <div class="md:col-span-3">
                        <div class="relative">
                            <select
                                v-model="stockStatusFilter"
                                @change="applyFilters"
                                class="block w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-10 pl-3 leading-5 text-gray-700 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 focus:outline-none sm:text-sm dark:border-gray-700 dark:bg-gray-900 dark:text-gray-200"
                            >
                                <option value="">
                                    {{ $t('All Stock Status') }}
                                </option>
                                <option value="in_stock">
                                    {{ $t('In Stock') }}
                                </option>
                                <option value="out_of_stock">
                                    {{ $t('Out of Stock') }}
                                </option>
                                <option value="on_backorder">
                                    {{ $t('On Backorder') }}
                                </option>
                            </select>
                            <div
                                class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-gray-500"
                            >
                                <ChevronDown class="h-4 w-4" />
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Active Filters & Clear -->
                <div
                    v-if="
                        search ||
                        statusFilter ||
                        categoryFilter ||
                        stockStatusFilter
                    "
                    class="mt-4 flex items-center justify-between border-t border-gray-100 pt-4 dark:border-gray-700"
                >
                    <div class="flex flex-wrap gap-2">
                        <span
                            v-if="search"
                            class="inline-flex items-center rounded-md border border-blue-100 bg-blue-50 px-2.5 py-1 text-xs font-medium text-blue-700 dark:border-blue-800 dark:bg-blue-900/30 dark:text-blue-300"
                        >
                            {{ $t('Search: {value}', { value: search }) }}
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
                            {{ $t('Status: {value}', { value: statusFilter }) }}
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
                        <!-- Add more badges as needed -->
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
                    v-if="selectedProducts.length > 0"
                    class="sticky top-4 z-10 flex items-center justify-between rounded-xl bg-blue-600 p-3 px-5 text-white shadow-lg shadow-blue-600/20"
                >
                    <span class="flex items-center text-xs font-semibold">
                        <CheckCircle class="mr-1.5 h-3.5 w-3.5" />
                        {{
                            $t(
                                selectedProducts.length > 1
                                    ? '{count} products selected'
                                    : '{count} product selected',
                                { count: selectedProducts.length },
                            )
                        }}
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

            <!-- Products Table -->
            <div
                class="overflow-hidden rounded-xl border border-gray-100 bg-white dark:border-gray-700/60 dark:bg-gray-800/80"
            >
                <div class="overflow-x-auto">
                    <table
                        class="min-w-full divide-y divide-gray-100 dark:divide-gray-700/60"
                    >
                        <thead class="bg-gray-50/80 dark:bg-gray-800/50">
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
                                        {{ $t('Product Details') }}
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
                                    @click="sortTable('sku')"
                                    class="group hidden cursor-pointer px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase transition-colors hover:text-blue-600 md:table-cell dark:text-gray-400 dark:hover:text-blue-400"
                                >
                                    <div class="flex items-center gap-1">
                                        {{ $t('SKU & Type') }}
                                        <span
                                            v-if="sortBy === 'sku'"
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
                                    @click="sortTable('price')"
                                    class="group hidden cursor-pointer px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase transition-colors hover:text-blue-600 md:table-cell dark:text-gray-400 dark:hover:text-blue-400"
                                >
                                    <div class="flex items-center gap-1">
                                        {{ $t('Price') }}
                                        <span
                                            v-if="sortBy === 'price'"
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
                                    @click="sortTable('quantity')"
                                    class="group hidden cursor-pointer px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase transition-colors hover:text-blue-600 lg:table-cell dark:text-gray-400 dark:hover:text-blue-400"
                                >
                                    <div class="flex items-center gap-1">
                                        {{ $t('Stock') }}
                                        <span
                                            v-if="sortBy === 'quantity'"
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
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase lg:table-cell dark:text-gray-400"
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
                            class="divide-y divide-gray-50 bg-white dark:divide-gray-700/40 dark:bg-gray-800/80"
                        >
                            <tr v-if="products.data.length === 0">
                                <td
                                    colspan="8"
                                    class="px-6 py-16 text-center text-gray-500 dark:text-gray-400"
                                >
                                    <div class="flex flex-col items-center">
                                        <div
                                            class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-50 text-gray-400 dark:bg-gray-700"
                                        >
                                            <Package class="h-8 w-8" />
                                        </div>
                                        <p
                                            class="text-lg font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('No products found') }}
                                        </p>
                                        <p
                                            class="mt-1 max-w-sm text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            {{
                                                $t(
                                                    'No products matched your search criteria. Try adjusting your filters or add a new product.',
                                                )
                                            }}
                                        </p>
                                        <button
                                            @click="clearFilters"
                                            v-if="
                                                search ||
                                                statusFilter ||
                                                categoryFilter
                                            "
                                            class="mt-4 text-sm font-medium text-blue-600 hover:text-blue-700"
                                        >
                                            {{ $t('Clear all filters') }}
                                        </button>
                                    </div>
                                </td>
                            </tr>
                            <template
                                v-for="product in products.data"
                                :key="product.id"
                            >
                                <tr
                                    class="group transition-colors hover:bg-gray-50/80 dark:hover:bg-gray-700/20"
                                >
                                    <td class="relative px-6 py-4">
                                        <div class="flex items-center">
                                            <button
                                                @click="toggleRow(product.id)"
                                                class="absolute left-2 p-1 text-blue-600 hover:text-blue-800 focus:outline-none md:hidden"
                                            >
                                                <MinusCircle
                                                    v-if="
                                                        expandedRows.includes(
                                                            product.id,
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
                                                v-model="selectedProducts"
                                                type="checkbox"
                                                :value="product.id"
                                                class="ml-4 h-4 w-4 cursor-pointer rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 md:ml-0 dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                    </td>
                                    <td class="px-6 py-4">
                                        <div
                                            v-if="product.main_image"
                                            class="group/image relative"
                                        >
                                            <div
                                                class="h-12 w-12 overflow-hidden rounded-lg border border-gray-200 bg-gray-100 shadow-sm dark:border-gray-600 dark:bg-gray-700"
                                            >
                                                <img
                                                    :src="
                                                        product.main_image.url
                                                    "
                                                    :alt="product.name"
                                                    class="h-full w-full object-cover transition-transform duration-300 group-hover/image:scale-110"
                                                />
                                            </div>
                                            <button
                                                @click="openQuickView(product)"
                                                class="absolute inset-0 flex items-center justify-center rounded-lg bg-black/40 opacity-0 transition-opacity group-hover/image:opacity-100"
                                            >
                                                <Eye
                                                    class="h-5 w-5 text-white drop-shadow-md"
                                                />
                                            </button>
                                        </div>
                                        <div
                                            v-else
                                            class="flex h-12 w-12 items-center justify-center rounded-lg border border-gray-200 bg-gray-100 text-gray-400 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-500"
                                        >
                                            <Package class="h-6 w-6" />
                                        </div>
                                    </td>
                                    <td class="px-6 py-4">
                                        <div
                                            class="flex max-w-xs items-start gap-2"
                                        >
                                            <div>
                                                <div
                                                    class="line-clamp-2 text-sm leading-snug font-bold text-gray-900 transition-colors group-hover:text-blue-600 dark:text-white dark:group-hover:text-blue-400"
                                                >
                                                    {{ product.name }}
                                                </div>
                                                <div
                                                    v-if="
                                                        product.categories
                                                            .length > 0
                                                    "
                                                    class="mt-1.5 flex flex-wrap gap-1"
                                                >
                                                    <span
                                                        class="inline-flex items-center rounded bg-gray-100 px-1.5 py-0.5 text-[10px] text-gray-500 dark:bg-gray-700/50 dark:text-gray-400"
                                                    >
                                                        <Layers
                                                            class="mr-1 h-3 w-3 opacity-70"
                                                        />
                                                        {{
                                                            product
                                                                .categories[0]
                                                                .name
                                                        }}
                                                        <span
                                                            v-if="
                                                                product
                                                                    .categories
                                                                    .length > 1
                                                            "
                                                            class="ml-0.5"
                                                            >+{{
                                                                product
                                                                    .categories
                                                                    .length - 1
                                                            }}</span
                                                        >
                                                    </span>
                                                </div>
                                                <div
                                                    class="mt-2 flex gap-1.5"
                                                    v-if="
                                                        product.featured ||
                                                        product.new
                                                    "
                                                >
                                                    <span
                                                        v-if="product.featured"
                                                        class="inline-flex items-center rounded border border-yellow-200 bg-gradient-to-r from-yellow-100 to-yellow-200 px-1.5 py-0.5 text-[10px] font-bold tracking-wide text-yellow-800 uppercase shadow-sm dark:border-yellow-800/50 dark:from-yellow-900/40 dark:to-yellow-800/40 dark:text-yellow-300"
                                                    >
                                                        {{ $t('Featured') }}
                                                    </span>
                                                    <span
                                                        v-if="product.new"
                                                        class="inline-flex items-center rounded border border-green-200 bg-gradient-to-r from-green-100 to-green-200 px-1.5 py-0.5 text-[10px] font-bold tracking-wide text-green-800 uppercase shadow-sm dark:border-green-800/50 dark:from-green-900/40 dark:to-green-800/40 dark:text-green-300"
                                                    >
                                                        {{ $t('New') }}
                                                    </span>
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 pt-5 align-top text-sm md:table-cell"
                                    >
                                        <div class="flex flex-col gap-1.5">
                                            <span
                                                class="w-fit rounded border border-gray-200 bg-gray-50 px-1.5 py-0.5 font-mono text-xs text-gray-500 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400"
                                                >{{
                                                    product.sku || 'NO-SKU'
                                                }}</span
                                            >
                                            <span
                                                class="inline-flex w-fit items-center rounded-full border px-2 py-0.5 text-xs font-medium shadow-sm"
                                                :class="{
                                                    'border-gray-200 bg-gray-50 text-gray-700 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300':
                                                        product.type ===
                                                        'simple',
                                                    'border-purple-200 bg-purple-50 text-purple-700 dark:border-purple-800 dark:bg-purple-900/20 dark:text-purple-300':
                                                        product.type ===
                                                        'configurable',
                                                    'border-blue-200 bg-blue-50 text-blue-700 dark:border-blue-800 dark:bg-blue-900/20 dark:text-blue-300':
                                                        product.type ===
                                                        'virtual',
                                                    'border-cyan-200 bg-cyan-50 text-cyan-700 dark:border-cyan-800 dark:bg-cyan-900/20 dark:text-cyan-300':
                                                        product.type ===
                                                        'downloadable',
                                                }"
                                            >
                                                {{
                                                    $t(
                                                        product.type
                                                            .charAt(0)
                                                            .toUpperCase() +
                                                            product.type.slice(
                                                                1,
                                                            ),
                                                    )
                                                }}
                                            </span>
                                        </div>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 pt-5 align-top text-sm text-gray-900 md:table-cell dark:text-white"
                                    >
                                        <div
                                            v-if="product.special_price"
                                            class="flex flex-col"
                                        >
                                            <span
                                                class="font-bold text-red-600 dark:text-red-400"
                                                >{{
                                                    formatPrice(
                                                        product.special_price,
                                                    )
                                                }}</span
                                            >
                                            <span
                                                class="text-xs text-gray-400 line-through decoration-gray-400 dark:text-gray-500"
                                                >{{
                                                    formatPrice(product.price)
                                                }}</span
                                            >
                                        </div>
                                        <span v-else class="font-bold">{{
                                            formatPrice(product.price)
                                        }}</span>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 pt-5 align-top text-sm lg:table-cell"
                                    >
                                        <div class="flex flex-col gap-1">
                                            <div
                                                class="flex items-center text-xs font-medium"
                                                :class="{
                                                    'text-green-600 dark:text-green-400':
                                                        product.stock_status ===
                                                        'in_stock',
                                                    'text-red-600 dark:text-red-400':
                                                        product.stock_status ===
                                                        'out_of_stock',
                                                    'text-yellow-600 dark:text-yellow-400':
                                                        product.stock_status ===
                                                        'on_backorder',
                                                }"
                                            >
                                                <div
                                                    class="mr-1.5 h-1.5 w-1.5 rounded-full"
                                                    :class="{
                                                        'bg-green-500':
                                                            product.stock_status ===
                                                            'in_stock',
                                                        'bg-red-500':
                                                            product.stock_status ===
                                                            'out_of_stock',
                                                        'bg-yellow-500':
                                                            product.stock_status ===
                                                            'on_backorder',
                                                    }"
                                                ></div>
                                                {{
                                                    $t('{quantity} units', {
                                                        quantity:
                                                            product.quantity,
                                                    })
                                                }}
                                            </div>
                                            <span
                                                class="text-[10px] font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                            >
                                                {{
                                                    $t(
                                                        product.stock_status.replace(
                                                            '_',
                                                            ' ',
                                                        ),
                                                    )
                                                }}
                                            </span>
                                        </div>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 pt-5 align-top lg:table-cell"
                                    >
                                        <span
                                            class="inline-flex items-center rounded-full border px-2.5 py-1 text-xs font-semibold shadow-sm"
                                            :class="{
                                                'border-green-200 bg-green-50 text-green-700 dark:border-green-800 dark:bg-green-900/20 dark:text-green-300':
                                                    product.status ===
                                                    'enabled',
                                                'border-gray-200 bg-gray-100 text-gray-600 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300':
                                                    product.status ===
                                                    'disabled',
                                            }"
                                        >
                                            <CheckCircle
                                                v-if="
                                                    product.status === 'enabled'
                                                "
                                                class="mr-1 h-3 w-3"
                                            />
                                            <XCircle
                                                v-else
                                                class="mr-1 h-3 w-3"
                                            />
                                            {{
                                                $t(
                                                    product.status
                                                        .charAt(0)
                                                        .toUpperCase() +
                                                        product.status.slice(1),
                                                )
                                            }}
                                        </span>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right align-middle text-sm font-medium"
                                    >
                                        <div
                                            class="flex items-center justify-end gap-1 opacity-50 transition-opacity group-hover:opacity-100"
                                        >
                                            <button
                                                @click="openQuickView(product)"
                                                class="rounded-lg p-1.5 text-gray-400 transition-colors hover:bg-purple-50 hover:text-purple-600 dark:hover:bg-purple-500/10"
                                                :title="$t('Quick View')"
                                            >
                                                <Eye class="h-4 w-4" />
                                            </button>
                                            <Link
                                                :href="
                                                    productRoutes.edit({
                                                        product: product.id,
                                                    }).url
                                                "
                                                class="rounded-lg p-1.5 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-500/10"
                                                :title="$t('Edit')"
                                            >
                                                <Edit class="h-4 w-4" />
                                            </Link>
                                            <button
                                                @click="
                                                    confirmDelete(product.id)
                                                "
                                                class="rounded-lg p-1.5 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-500/10"
                                                :title="$t('Delete')"
                                            >
                                                <Trash2 class="h-4 w-4" />
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                                <!-- Expanded Row for Mobile/Tablet -->
                                <tr
                                    v-if="expandedRows.includes(product.id)"
                                    class="bg-gray-50/50 md:hidden dark:bg-gray-900/50"
                                >
                                    <td
                                        colspan="8"
                                        class="border-t border-gray-100 px-6 py-4 dark:border-gray-700"
                                    >
                                        <div
                                            class="grid grid-cols-2 gap-4 text-sm"
                                        >
                                            <div class="flex flex-col gap-1">
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Price') }}</span
                                                >
                                                <div
                                                    v-if="product.special_price"
                                                >
                                                    <span
                                                        class="font-bold text-red-600"
                                                        >{{
                                                            formatPrice(
                                                                product.special_price,
                                                            )
                                                        }}</span
                                                    >
                                                    <span
                                                        class="ml-1 text-xs text-gray-400 line-through"
                                                        >{{
                                                            formatPrice(
                                                                product.price,
                                                            )
                                                        }}</span
                                                    >
                                                </div>
                                                <span
                                                    v-else
                                                    class="font-bold text-gray-900 dark:text-gray-100"
                                                    >{{
                                                        formatPrice(
                                                            product.price,
                                                        )
                                                    }}</span
                                                >
                                            </div>
                                            <div class="flex flex-col gap-1">
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Stock') }}</span
                                                >
                                                <div
                                                    class="flex items-center gap-2"
                                                >
                                                    <span
                                                        class="font-semibold text-gray-900 dark:text-white"
                                                        >{{
                                                            $t(
                                                                '{quantity} units',
                                                                {
                                                                    quantity:
                                                                        product.quantity,
                                                                },
                                                            )
                                                        }}</span
                                                    >
                                                    <span
                                                        class="rounded border px-1.5 py-0.5 text-[10px]"
                                                        :class="{
                                                            'border-green-200 bg-green-50 text-green-700':
                                                                product.stock_status ===
                                                                'in_stock',
                                                            'border-red-200 bg-red-50 text-red-700':
                                                                product.stock_status ===
                                                                'out_of_stock',
                                                            'border-yellow-200 bg-yellow-50 text-yellow-700':
                                                                product.stock_status ===
                                                                'on_backorder',
                                                        }"
                                                        >{{
                                                            $t(
                                                                product.stock_status.replace(
                                                                    '_',
                                                                    ' ',
                                                                ),
                                                            )
                                                        }}</span
                                                    >
                                                </div>
                                            </div>
                                            <div class="flex flex-col gap-1">
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{
                                                        $t('SKU & Type')
                                                    }}</span
                                                >
                                                <div
                                                    class="flex flex-col gap-1"
                                                >
                                                    <span
                                                        class="font-mono text-xs text-gray-600"
                                                        >{{
                                                            product.sku || 'N/A'
                                                        }}</span
                                                    >
                                                    <span
                                                        class="w-fit rounded bg-gray-100 px-1.5 py-0.5 text-xs capitalize dark:bg-gray-800"
                                                        >{{
                                                            product.type
                                                        }}</span
                                                    >
                                                </div>
                                            </div>
                                            <div class="flex flex-col gap-1">
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Status') }}</span
                                                >
                                                <span
                                                    class="inline-flex w-fit items-center rounded-full border px-2 py-0.5 text-xs font-medium"
                                                    :class="{
                                                        'border-green-200 bg-green-50 text-green-700':
                                                            product.status ===
                                                            'enabled',
                                                        'border-gray-200 bg-gray-100 text-gray-600':
                                                            product.status ===
                                                            'disabled',
                                                    }"
                                                >
                                                    {{
                                                        $t(
                                                            product.status
                                                                .charAt(0)
                                                                .toUpperCase() +
                                                                product.status.slice(
                                                                    1,
                                                                ),
                                                        )
                                                    }}
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
                <Pagination :data="products" :resource-name="$t('products')" />
            </div>

            <!-- Delete Confirmation Modal -->
            <ConfirmDeleteModal
                v-model:show="showDeleteModal"
                :title="deletingProduct?.name ?? ''"
                :message="
                    $t(
                        'Are you sure you want to delete {name}? This action cannot be undone.',
                        { name: deletingProduct?.name },
                    )
                "
                @confirm="deleteProduct"
            />

            <!-- Bulk Delete Confirmation Modal -->
            <ConfirmDeleteModal
                v-model:show="showBulkDeleteModal"
                :title="$t('Delete Multiple Products')"
                :message="
                    $t(
                        selectedProducts.length > 1
                            ? 'Are you sure you want to delete {count} products? This action cannot be undone.'
                            : 'Are you sure you want to delete {count} product? This action cannot be undone.',
                        { count: selectedProducts.length },
                    )
                "
                @confirm="bulkDelete"
            />

            <!-- Product Quick View Modal -->
            <ProductQuickView
                :product="selectedProduct"
                :show="showQuickView"
                @close="showQuickView = false"
                @edit="editProductFromQuickView"
                @delete="deleteProductFromQuickView"
            />
        </div>
    </AdminLayout>
</template>

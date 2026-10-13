<script setup lang="ts">
import Pagination from '@/components/Admin/Pagination.vue';
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import * as reviewRoutes from '@/routes/admin/catalog/reviews';
import { Head, Link, router } from '@inertiajs/vue3';
import {
    ArrowUpDown,
    CheckCircle,
    Eye,
    Filter,
    MessageSquare,
    MinusCircle,
    PlusCircle,
    Search,
    Star,
    ThumbsDown,
    ThumbsUp,
    Trash2,
    X,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

interface Review {
    id: number;
    product: {
        id: number;
        name: string;
        slug: string;
        featured_image?: string;
    };
    reviewer: string;
    rating: number;
    title: string;
    comment: string;
    status: string;
    admin_reply: string | null;
    admin_replier: { id: number; name: string } | null;
    admin_replied_at: string | null;
    created_at: string;
}

interface Product {
    id: number;
    name: string;
}

interface Props {
    reviews: {
        data: Review[];
        current_page: number;
        last_page: number;
        per_page: number;
        total: number;
    };
    stats: {
        total: number;
        pending: number;
        approved: number;
        rejected: number;
    };
    products: Product[];
    filters: {
        status?: string;
        rating?: string;
        product_id?: string;
        search?: string;
    };
}

const props = defineProps<Props>();

const selectedReviews = ref<number[]>([]);
const search = ref(props.filters.search || '');
const selectedStatus = ref(props.filters.status || '');
const selectedRating = ref(props.filters.rating || '');
const selectedProduct = ref(props.filters.product_id || '');
const isLoading = ref(false);
const showBulkDeleteModal = ref(false);
const expandedRows = ref<number[]>([]);

const selectAll = computed(() => {
    return (
        props.reviews.data.length > 0 &&
        selectedReviews.value.length === props.reviews.data.length
    );
});

const someSelected = computed(() => {
    return (
        selectedReviews.value.length > 0 &&
        selectedReviews.value.length < props.reviews.data.length
    );
});

function toggleRow(id: number) {
    if (expandedRows.value.includes(id)) {
        expandedRows.value = expandedRows.value.filter((rowId) => rowId !== id);
    } else {
        expandedRows.value.push(id);
    }
}

function toggleSelectAll() {
    if (selectAll.value) {
        selectedReviews.value = [];
    } else {
        selectedReviews.value = props.reviews.data.map((r) => r.id);
    }
}

function applyFilters() {
    router.get(
        reviewRoutes.index().url,
        {
            search: search.value || undefined,
            status: selectedStatus.value || undefined,
            rating: selectedRating.value || undefined,
            product_id: selectedProduct.value || undefined,
        },
        {
            preserveState: true,
            preserveScroll: true,
        },
    );
}

function clearFilters() {
    search.value = '';
    selectedStatus.value = '';
    selectedRating.value = '';
    selectedProduct.value = '';
    applyFilters();
}

function changePage(page: number) {
    if (page < 1 || page > props.reviews.last_page) return;

    router.get(
        reviewRoutes.index().url,
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

function bulkApprove() {
    if (selectedReviews.value.length === 0 || isLoading.value) return;

    isLoading.value = true;
    router.post(
        reviewRoutes.bulkAction().url,
        {
            action: 'approve',
            review_ids: selectedReviews.value,
        },
        {
            onFinish: () => {
                isLoading.value = false;
                selectedReviews.value = [];
            },
        },
    );
}

function bulkReject() {
    if (selectedReviews.value.length === 0 || isLoading.value) return;

    isLoading.value = true;
    router.post(
        reviewRoutes.bulkAction().url,
        {
            action: 'reject',
            review_ids: selectedReviews.value,
        },
        {
            onFinish: () => {
                isLoading.value = false;
                selectedReviews.value = [];
            },
        },
    );
}

function bulkDelete() {
    if (selectedReviews.value.length === 0 || isLoading.value) return;

    showBulkDeleteModal.value = true;
}

function confirmBulkDelete() {
    isLoading.value = true;
    router.post(
        reviewRoutes.bulkAction().url,
        {
            action: 'delete',
            review_ids: selectedReviews.value,
        },
        {
            onFinish: () => {
                isLoading.value = false;
                selectedReviews.value = [];
                showBulkDeleteModal.value = false;
            },
        },
    );
}
</script>

<template>
    <Head :title="$t('Product Reviews')" />

    <AdminLayout :title="$t('Product Reviews')">
        <div class="space-y-6 p-6">
            <!-- Page Header -->
            <div class="flex items-center justify-between">
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Product Reviews') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                        {{ $t('Manage customer reviews and ratings') }}
                    </p>
                </div>
            </div>

            <!-- Stats Cards -->
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
                <!-- Total Reviews -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-sm font-medium text-gray-600 dark:text-gray-400"
                            >
                                {{ $t('Total Reviews') }}
                            </p>
                            <p
                                class="mt-1 text-3xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ stats.total }}
                            </p>
                        </div>
                        <div
                            class="rounded-xl bg-blue-50 p-3 dark:bg-blue-900/20"
                        >
                            <MessageSquare
                                class="h-6 w-6 text-blue-600 dark:text-blue-400"
                            />
                        </div>
                    </div>
                </div>

                <!-- Pending -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-sm font-medium text-gray-600 dark:text-gray-400"
                            >
                                {{ $t('Pending') }}
                            </p>
                            <p
                                class="mt-1 text-3xl font-bold text-yellow-600 dark:text-yellow-400"
                            >
                                {{ stats.pending }}
                            </p>
                        </div>
                        <div
                            class="rounded-xl bg-yellow-50 p-3 dark:bg-yellow-900/20"
                        >
                            <Eye
                                class="h-6 w-6 text-yellow-600 dark:text-yellow-400"
                            />
                        </div>
                    </div>
                </div>

                <!-- Approved -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-sm font-medium text-gray-600 dark:text-gray-400"
                            >
                                {{ $t('Approved') }}
                            </p>
                            <p
                                class="mt-1 text-3xl font-bold text-green-600 dark:text-green-400"
                            >
                                {{ stats.approved }}
                            </p>
                        </div>
                        <div
                            class="rounded-xl bg-green-50 p-3 dark:bg-green-900/20"
                        >
                            <ThumbsUp
                                class="h-6 w-6 text-green-600 dark:text-green-400"
                            />
                        </div>
                    </div>
                </div>

                <!-- Rejected -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-sm font-medium text-gray-600 dark:text-gray-400"
                            >
                                {{ $t('Rejected') }}
                            </p>
                            <p
                                class="mt-1 text-3xl font-bold text-red-600 dark:text-red-400"
                            >
                                {{ stats.rejected }}
                            </p>
                        </div>
                        <div
                            class="rounded-xl bg-red-50 p-3 dark:bg-red-900/20"
                        >
                            <ThumbsDown
                                class="h-6 w-6 text-red-600 dark:text-red-400"
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
                    class="grid grid-cols-1 gap-4 md:grid-cols-4 lg:grid-cols-5"
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
                                @keyup.enter="applyFilters"
                                type="text"
                                :placeholder="$t('Search reviews...')"
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
                                v-model="selectedStatus"
                                @change="applyFilters"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-10 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            >
                                <option value="">{{ $t('All Status') }}</option>
                                <option value="pending">
                                    {{ $t('Pending') }}
                                </option>
                                <option value="approved">
                                    {{ $t('Approved') }}
                                </option>
                                <option value="rejected">
                                    {{ $t('Rejected') }}
                                </option>
                            </select>
                            <div
                                class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2"
                            >
                                <ArrowUpDown class="h-3 w-3 text-gray-400" />
                            </div>
                        </div>
                    </div>

                    <!-- Rating Filter -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Rating') }}</label
                        >
                        <div class="relative">
                            <Star
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <select
                                v-model="selectedRating"
                                @change="applyFilters"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-10 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            >
                                <option value="">
                                    {{ $t('All Ratings') }}
                                </option>
                                <option value="5">{{ $t('5 Stars') }}</option>
                                <option value="4">{{ $t('4 Stars') }}</option>
                                <option value="3">{{ $t('3 Stars') }}</option>
                                <option value="2">{{ $t('2 Stars') }}</option>
                                <option value="1">{{ $t('1 Star') }}</option>
                            </select>
                            <div
                                class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2"
                            >
                                <ArrowUpDown class="h-3 w-3 text-gray-400" />
                            </div>
                        </div>
                    </div>

                    <!-- Product Filter -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Product') }}</label
                        >
                        <div class="relative">
                            <Filter
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <select
                                v-model="selectedProduct"
                                @change="applyFilters"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-10 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            >
                                <option value="">
                                    {{ $t('All Products') }}
                                </option>
                                <option
                                    v-for="product in products"
                                    :key="product.id"
                                    :value="product.id"
                                >
                                    {{ product.name }}
                                </option>
                            </select>
                            <div
                                class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2"
                            >
                                <ArrowUpDown class="h-3 w-3 text-gray-400" />
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Clear Filters Button -->
                <div
                    v-if="
                        search ||
                        selectedStatus ||
                        selectedRating ||
                        selectedProduct
                    "
                    class="mt-4 flex justify-end border-t border-gray-100 pt-4 dark:border-gray-700"
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
                    v-if="selectedReviews.length > 0"
                    class="sticky top-4 z-10 flex items-center justify-between rounded-xl bg-blue-600 p-3 px-6 text-white shadow-lg"
                >
                    <span class="flex items-center text-sm font-semibold">
                        <CheckCircle class="mr-2 h-4 w-4" />
                        {{ selectedReviews.length }}
                        {{
                            $t(
                                selectedReviews.length === 1
                                    ? 'review'
                                    : 'reviews',
                            )
                        }}
                        {{ $t('selected') }}
                    </span>
                    <div class="flex gap-2">
                        <button
                            @click="bulkApprove"
                            :disabled="isLoading"
                            class="rounded-lg bg-white px-3 py-1.5 text-xs font-bold tracking-wide text-green-600 uppercase transition-colors hover:bg-green-50 disabled:opacity-50"
                        >
                            {{ $t('Approve') }}
                        </button>
                        <button
                            @click="bulkReject"
                            :disabled="isLoading"
                            class="rounded-lg bg-white px-3 py-1.5 text-xs font-bold tracking-wide text-yellow-600 uppercase transition-colors hover:bg-yellow-50 disabled:opacity-50"
                        >
                            {{ $t('Reject') }}
                        </button>
                        <div class="mx-1 h-6 w-px bg-blue-400"></div>
                        <button
                            @click="bulkDelete"
                            :disabled="isLoading"
                            class="flex items-center rounded-lg bg-red-500 px-3 py-1.5 text-xs font-bold tracking-wide text-white uppercase transition-colors hover:bg-red-600 disabled:opacity-50"
                        >
                            <Trash2 class="mr-1.5 h-3 w-3" />
                            {{ $t('Delete') }}
                        </button>
                    </div>
                </div>
            </transition>

            <!-- Reviews Table -->
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
                                        :checked="selectAll"
                                        :indeterminate.prop="someSelected"
                                        @change="toggleSelectAll"
                                        class="h-4 w-4 rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </th>
                                <th
                                    scope="col"
                                    class="px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Product') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase md:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Reviewer') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase sm:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Rating') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase lg:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Review') }}
                                </th>
                                <th
                                    scope="col"
                                    class="px-6 py-4 text-center text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Status') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase xl:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Date') }}
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
                                v-for="review in reviews.data"
                                :key="review.id"
                            >
                                <tr
                                    class="group transition-colors hover:bg-blue-50/50 dark:hover:bg-blue-900/10"
                                >
                                    <td class="relative px-6 py-4">
                                        <div class="flex items-center">
                                            <button
                                                @click="toggleRow(review.id)"
                                                class="absolute left-2 p-1 text-blue-600 hover:text-blue-800 focus:outline-none xl:hidden"
                                            >
                                                <MinusCircle
                                                    v-if="
                                                        expandedRows.includes(
                                                            review.id,
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
                                                :value="review.id"
                                                v-model="selectedReviews"
                                                class="ml-4 h-4 w-4 cursor-pointer rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 xl:ml-0 dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                    </td>
                                    <td class="px-6 py-4">
                                        <div class="flex items-center gap-3">
                                            <div
                                                class="flex h-10 w-10 flex-shrink-0 items-center justify-center overflow-hidden rounded-lg border border-gray-200 bg-gray-100 dark:border-gray-600 dark:bg-gray-700"
                                            >
                                                <img
                                                    v-if="
                                                        review.product
                                                            .featured_image
                                                    "
                                                    :src="`/storage/${review.product.featured_image}`"
                                                    :alt="review.product.name"
                                                    class="h-full w-full object-cover"
                                                />
                                                <div
                                                    v-else
                                                    class="p-1 text-center text-xs leading-tight font-semibold text-gray-400"
                                                >
                                                    {{
                                                        review.product.name
                                                            .substring(0, 2)
                                                            .toUpperCase()
                                                    }}
                                                </div>
                                            </div>
                                            <div>
                                                <div
                                                    class="line-clamp-1 text-sm font-bold text-gray-900 transition-colors group-hover:text-blue-600 dark:text-white dark:group-hover:text-blue-400"
                                                >
                                                    {{ review.product.name }}
                                                </div>
                                                <div
                                                    class="font-mono text-xs text-gray-500 dark:text-gray-400"
                                                >
                                                    {{ review.product.slug }}
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                    <td class="hidden px-6 py-4 md:table-cell">
                                        <div class="flex items-center">
                                            <div
                                                class="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full border border-gray-200 bg-gray-100 dark:border-gray-600 dark:bg-gray-700"
                                            >
                                                <span
                                                    class="text-xs font-bold text-gray-500 dark:text-gray-400"
                                                    >{{
                                                        review.reviewer
                                                            .charAt(0)
                                                            .toUpperCase()
                                                    }}</span
                                                >
                                            </div>
                                            <div class="ml-3">
                                                <div
                                                    class="text-sm font-medium text-gray-900 dark:text-white"
                                                >
                                                    {{ review.reviewer }}
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap sm:table-cell"
                                    >
                                        <div
                                            class="flex w-fit items-center rounded-lg bg-yellow-50 px-2 py-1 dark:bg-yellow-900/10"
                                        >
                                            <span
                                                class="mr-1.5 text-sm font-bold text-yellow-700 dark:text-yellow-500"
                                                >{{ review.rating }}.0</span
                                            >
                                            <div class="flex">
                                                <template
                                                    v-for="star in 5"
                                                    :key="star"
                                                >
                                                    <Star
                                                        :class="
                                                            star <=
                                                            review.rating
                                                                ? 'fill-current text-yellow-400'
                                                                : 'text-gray-300 dark:text-gray-600'
                                                        "
                                                        class="h-3.5 w-3.5"
                                                    />
                                                </template>
                                            </div>
                                        </div>
                                    </td>
                                    <td class="hidden px-6 py-4 lg:table-cell">
                                        <div class="max-w-xs">
                                            <div
                                                class="mb-1 line-clamp-1 text-sm font-semibold text-gray-900 dark:text-white"
                                            >
                                                {{ review.title }}
                                            </div>
                                            <div
                                                class="line-clamp-2 text-xs leading-relaxed text-gray-500 dark:text-gray-400"
                                            >
                                                {{ review.comment }}
                                            </div>
                                            <div
                                                v-if="review.admin_reply"
                                                class="mt-2 flex w-fit items-center rounded bg-green-50 px-2 py-1 text-xs font-medium text-green-600 dark:bg-green-900/10 dark:text-green-400"
                                            >
                                                <MessageSquare
                                                    class="mr-1.5 h-3 w-3"
                                                />
                                                {{ $t('Admin replied') }}
                                            </div>
                                        </div>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-center whitespace-nowrap"
                                    >
                                        <span
                                            :class="{
                                                'border-green-200 bg-green-50 text-green-700 dark:border-green-800 dark:bg-green-900/20 dark:text-green-300':
                                                    review.status ===
                                                    'approved',
                                                'border-yellow-200 bg-yellow-50 text-yellow-700 dark:border-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-300':
                                                    review.status === 'pending',
                                                'border-red-200 bg-red-50 text-red-700 dark:border-red-800 dark:bg-red-900/20 dark:text-red-300':
                                                    review.status ===
                                                    'rejected',
                                            }"
                                            class="inline-flex rounded-full border px-2.5 py-1 text-xs leading-5 font-semibold shadow-sm"
                                        >
                                            <template
                                                v-if="
                                                    review.status === 'approved'
                                                "
                                                ><CheckCircle
                                                    class="mr-1 h-3 w-3"
                                                />
                                                {{ $t('Approved') }}</template
                                            >
                                            <template
                                                v-else-if="
                                                    review.status === 'pending'
                                                "
                                                ><Eye class="mr-1 h-3 w-3" />
                                                {{ $t('Pending') }}</template
                                            >
                                            <template v-else
                                                ><X class="mr-1 h-3 w-3" />
                                                {{ $t('Rejected') }}</template
                                            >
                                        </span>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 font-mono text-sm whitespace-nowrap text-gray-500 xl:table-cell dark:text-gray-400"
                                    >
                                        <DateDisplay
                                            :value="review.created_at"
                                        />
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right text-sm font-medium whitespace-nowrap"
                                    >
                                        <div
                                            class="flex items-center justify-end gap-2 opacity-60 transition-opacity group-hover:opacity-100"
                                        >
                                            <Link
                                                :href="
                                                    reviewRoutes.show({
                                                        review: review.id,
                                                    }).url
                                                "
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-900/20"
                                                :title="$t('View Details')"
                                            >
                                                <Eye class="h-4 w-4" />
                                            </Link>
                                        </div>
                                    </td>
                                </tr>
                                <!-- Expanded Mobile Row -->
                                <tr
                                    v-if="expandedRows.includes(review.id)"
                                    class="bg-gray-50/50 xl:hidden dark:bg-gray-900/50"
                                >
                                    <td
                                        colspan="8"
                                        class="border-t border-gray-100 px-6 py-4 dark:border-gray-700"
                                    >
                                        <div
                                            class="grid grid-cols-1 gap-6 text-sm md:grid-cols-2"
                                        >
                                            <div
                                                class="flex flex-col gap-1 md:hidden"
                                            >
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Reviewer') }}</span
                                                >
                                                <div class="flex items-center">
                                                    <div
                                                        class="mr-2 flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-full border border-gray-200 bg-gray-100 dark:border-gray-600 dark:bg-gray-700"
                                                    >
                                                        <span
                                                            class="text-xs font-bold text-gray-500 dark:text-gray-400"
                                                            >{{
                                                                review.reviewer
                                                                    .charAt(0)
                                                                    .toUpperCase()
                                                            }}</span
                                                        >
                                                    </div>
                                                    <span
                                                        class="text-gray-900 dark:text-white"
                                                        >{{
                                                            review.reviewer
                                                        }}</span
                                                    >
                                                </div>
                                            </div>
                                            <div
                                                class="flex flex-col gap-1 sm:hidden"
                                            >
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Rating') }}</span
                                                >
                                                <div class="flex items-center">
                                                    <span
                                                        class="mr-2 text-sm font-bold text-gray-900 dark:text-white"
                                                        >{{
                                                            review.rating
                                                        }}/5</span
                                                    >
                                                    <div class="flex">
                                                        <template
                                                            v-for="star in 5"
                                                            :key="star"
                                                        >
                                                            <Star
                                                                :class="
                                                                    star <=
                                                                    review.rating
                                                                        ? 'fill-current text-yellow-400'
                                                                        : 'text-gray-300 dark:text-gray-600'
                                                                "
                                                                class="h-3.5 w-3.5"
                                                            />
                                                        </template>
                                                    </div>
                                                </div>
                                            </div>
                                            <div
                                                class="col-span-1 flex flex-col gap-2 md:col-span-2 lg:hidden"
                                            >
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{
                                                        $t('Review Content')
                                                    }}</span
                                                >
                                                <div
                                                    class="rounded-lg border border-gray-100 bg-white p-3 dark:border-gray-700 dark:bg-gray-800"
                                                >
                                                    <div
                                                        class="mb-1 font-bold text-gray-900 dark:text-white"
                                                    >
                                                        {{ review.title }}
                                                    </div>
                                                    <div
                                                        class="text-gray-600 italic dark:text-gray-400"
                                                    >
                                                        "{{ review.comment }}"
                                                    </div>
                                                    <div
                                                        v-if="
                                                            review.admin_reply
                                                        "
                                                        class="mt-3 border-l-2 border-green-500 pl-3"
                                                    >
                                                        <div
                                                            class="mb-0.5 text-xs font-semibold text-green-600"
                                                        >
                                                            {{
                                                                $t(
                                                                    'Admin Response',
                                                                )
                                                            }}
                                                        </div>
                                                        <div
                                                            class="text-sm text-gray-600 dark:text-gray-400"
                                                        >
                                                            {{
                                                                review.admin_reply
                                                            }}
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                            <div
                                                class="flex flex-col gap-1 xl:hidden"
                                            >
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Date') }}</span
                                                >
                                                <span
                                                    class="font-mono text-gray-700 dark:text-gray-300"
                                                    ><DateDisplay
                                                        :value="
                                                            review.created_at
                                                        "
                                                        time
                                                /></span>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                            </template>
                            <tr v-if="reviews.data.length === 0">
                                <td
                                    colspan="8"
                                    class="px-6 py-16 text-center text-gray-500 dark:text-gray-400"
                                >
                                    <div class="flex flex-col items-center">
                                        <div
                                            class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-50 text-gray-400 dark:bg-gray-700"
                                        >
                                            <MessageSquare class="h-8 w-8" />
                                        </div>
                                        <p
                                            class="text-lg font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('No reviews found') }}
                                        </p>
                                        <p
                                            class="mt-1 max-w-sm text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            {{
                                                $t(
                                                    'Try adjusting your search or filters.',
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
                <Pagination :data="reviews" :resource-name="$t('reviews')" />
            </div>

            <!-- Bulk Delete Confirmation Modal -->
            <div
                v-if="showBulkDeleteModal"
                class="fixed inset-0 z-50 flex items-center justify-center bg-gray-500/75 dark:bg-gray-900/75"
            >
                <div class="mx-4 w-full max-w-sm rounded-lg bg-white p-6">
                    <h3 class="mb-4 text-lg font-medium text-gray-900">
                        {{ $t('Delete Reviews') }}
                    </h3>
                    <p class="mb-6 text-sm text-gray-500">
                        {{
                            $t(
                                selectedReviews.length === 1
                                    ? 'Are you sure you want to delete {count} review? This action cannot be undone.'
                                    : 'Are you sure you want to delete {count} reviews? This action cannot be undone.',
                                { count: selectedReviews.length },
                            )
                        }}
                    </p>
                    <div class="flex justify-end gap-3">
                        <button
                            @click="showBulkDeleteModal = false"
                            class="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
                        >
                            {{ $t('Cancel') }}
                        </button>
                        <button
                            @click="confirmBulkDelete"
                            class="rounded-md bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700"
                        >
                            {{ $t('Delete') }}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

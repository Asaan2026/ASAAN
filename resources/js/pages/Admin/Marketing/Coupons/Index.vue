<script setup lang="ts">
import { useCalendar } from '@/composables/useCalendar';
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { useI18nStore } from '@/Stores/i18n';
import { Head, Link, router } from '@inertiajs/vue3';
import {
    ArrowUpDown,
    CheckCircle,
    DollarSign,
    Edit,
    Filter,
    MinusCircle,
    PlusCircle,
    Search,
    ShoppingBag,
    Ticket,
    Trash2,
    X,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

const { t } = useI18nStore();
const { formatDate: formatCalendarDate } = useCalendar();

interface Coupon {
    id: number;
    code: string;
    name: string;
    type: string;
    value: number;
    is_active: boolean;
    is_public: boolean;
    usage_count: number;
    usage_limit_total: number | null;
    start_date: string;
    end_date: string | null;
    created_at: string;
}

interface Stats {
    total: number;
    active: number;
    used_today: number;
    total_discount: number;
}

interface Props {
    coupons: {
        data: Coupon[];
        current_page: number;
        last_page: number;
        per_page: number;
        total: number;
        from: number;
        to: number;
        prev_page_url: string | null;
        next_page_url: string | null;
    };
    stats: Stats;
    filters: {
        search?: string;
        status?: string;
        type?: string;
    };
}

const props = defineProps<Props>();

const selectedCoupons = ref<number[]>([]);
const searchQuery = ref(props.filters.search || '');
const statusFilter = ref(props.filters.status || 'all');
const typeFilter = ref(props.filters.type || 'all');
const expandedRows = ref<number[]>([]);

const { formatPrice } = useCurrency();

const allSelected = computed(() => {
    return (
        props.coupons.data.length > 0 &&
        selectedCoupons.value.length === props.coupons.data.length
    );
});

const someSelected = computed(() => {
    return (
        selectedCoupons.value.length > 0 &&
        selectedCoupons.value.length < props.coupons.data.length
    );
});

const toggleSelectAll = () => {
    if (allSelected.value) {
        selectedCoupons.value = [];
    } else {
        selectedCoupons.value = props.coupons.data.map((c) => c.id);
    }
};

const toggleSelect = (id: number) => {
    const index = selectedCoupons.value.indexOf(id);
    if (index > -1) {
        selectedCoupons.value.splice(index, 1);
    } else {
        selectedCoupons.value.push(id);
    }
};

const toggleRow = (id: number) => {
    if (expandedRows.value.includes(id)) {
        expandedRows.value = expandedRows.value.filter((rowId) => rowId !== id);
    } else {
        expandedRows.value.push(id);
    }
};

const applyFilters = () => {
    router.get(
        '/admin/marketing/coupons',
        {
            search: searchQuery.value || undefined,
            status:
                statusFilter.value !== 'all' ? statusFilter.value : undefined,
            type: typeFilter.value !== 'all' ? typeFilter.value : undefined,
        },
        {
            preserveState: true,
            preserveScroll: true,
        },
    );
};

const createCoupon = () => {
    router.visit('/admin/marketing/coupons/create');
};

const deleteCoupon = (id: number) => {
    if (confirm('Are you sure you want to delete this coupon?')) {
        router.delete(`/admin/marketing/coupons/${id}`, {
            preserveScroll: true,
            onSuccess: () => {
                selectedCoupons.value = selectedCoupons.value.filter(
                    (cid) => cid !== id,
                );
            },
        });
    }
};

const bulkActivate = () => {
    if (selectedCoupons.value.length === 0) return;

    router.post(
        '/admin/marketing/coupons/bulk-activate',
        {
            coupon_ids: selectedCoupons.value,
        },
        {
            preserveScroll: true,
            onSuccess: () => {
                selectedCoupons.value = [];
            },
        },
    );
};

const bulkDeactivate = () => {
    if (selectedCoupons.value.length === 0) return;

    router.post(
        '/admin/marketing/coupons/bulk-deactivate',
        {
            coupon_ids: selectedCoupons.value,
        },
        {
            preserveScroll: true,
            onSuccess: () => {
                selectedCoupons.value = [];
            },
        },
    );
};

const bulkDelete = () => {
    if (selectedCoupons.value.length === 0) return;

    if (
        confirm(
            `Are you sure you want to delete ${selectedCoupons.value.length} coupon(s)?`,
        )
    ) {
        router.post(
            '/admin/marketing/coupons/bulk-delete',
            {
                coupon_ids: selectedCoupons.value,
            },
            {
                preserveScroll: true,
                onSuccess: () => {
                    selectedCoupons.value = [];
                },
            },
        );
    }
};

const getTypeLabel = (type: string) => {
    const types: Record<string, string> = {
        percentage: t('Percentage'),
        fixed_amount: t('Fixed Amount'),
        free_shipping: t('Free Shipping'),
        buy_x_get_y: t('Buy X Get Y'),
        fixed_price: t('Fixed Price'),
    };
    return types[type] || type;
};

const getTypeColor = (type: string) => {
    const colors: Record<string, string> = {
        percentage:
            'bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-300',
        fixed_amount:
            'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-300',
        free_shipping:
            'bg-purple-100 dark:bg-purple-900/30 text-purple-800 dark:text-purple-300',
        buy_x_get_y:
            'bg-orange-100 dark:bg-orange-900/30 text-orange-800 dark:text-orange-300',
        fixed_price:
            'bg-pink-100 dark:bg-pink-900/30 text-pink-800 dark:text-pink-300',
    };
    return (
        colors[type] ||
        'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300'
    );
};

const formatDiscount = (coupon: Coupon) => {
    switch (coupon.type) {
        case 'percentage':
            return `${coupon.value}%`;
        case 'fixed_amount':
            return `$${coupon.value}`;
        case 'free_shipping':
            return t('Free');
        case 'fixed_price':
            return `$${coupon.value}`;
        default:
            return coupon.value;
    }
};

const formatDate = (date: string | null) => {
    if (!date) return t('No expiry');
    return formatCalendarDate(date);
};

const clearFilters = () => {
    searchQuery.value = '';
    statusFilter.value = 'all';
    typeFilter.value = 'all';
    applyFilters();
};

const isExpired = (endDate: string | null) => {
    if (!endDate) return false;
    return new Date(endDate) < new Date();
};
</script>

<template>
    <Head :title="$t('Coupons')" />

    <AdminLayout :title="$t('Coupons')">
        <div class="space-y-6 p-6">
            <!-- Header -->
            <div
                class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
            >
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Coupons') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                        {{
                            $t('Manage discount coupons and promotional codes')
                        }}
                    </p>
                </div>
                <Link
                    href="/admin/marketing/coupons/create"
                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                >
                    <PlusCircle class="mr-2 h-4 w-4" />
                    {{ $t('Create Coupon') }}
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
                                class="text-sm font-medium text-gray-500 dark:text-gray-400"
                            >
                                {{ $t('Total Coupons') }}
                            </p>
                            <p
                                class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ stats.total }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-blue-50 p-3 transition-colors group-hover:bg-blue-100 dark:bg-blue-900/20 dark:group-hover:bg-blue-900/40"
                        >
                            <Ticket
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
                                class="text-sm font-medium text-gray-500 dark:text-gray-400"
                            >
                                {{ $t('Active') }}
                            </p>
                            <p
                                class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ stats.active }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-green-50 p-3 transition-colors group-hover:bg-green-100 dark:bg-green-900/20 dark:group-hover:bg-green-900/40"
                        >
                            <CheckCircle
                                class="h-6 w-6 text-green-600 dark:text-green-400"
                            />
                        </div>
                    </div>
                </div>

                <div
                    class="group rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-colors hover:border-purple-200 dark:border-gray-700 dark:bg-gray-800 dark:hover:border-purple-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-sm font-medium text-gray-500 dark:text-gray-400"
                            >
                                {{ $t('Used Today') }}
                            </p>
                            <p
                                class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ stats.used_today }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-purple-50 p-3 transition-colors group-hover:bg-purple-100 dark:bg-purple-900/20 dark:group-hover:bg-purple-900/40"
                        >
                            <ShoppingBag
                                class="h-6 w-6 text-purple-600 dark:text-purple-400"
                            />
                        </div>
                    </div>
                </div>

                <div
                    class="group rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-colors hover:border-orange-200 dark:border-gray-700 dark:bg-gray-800 dark:hover:border-orange-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-sm font-medium text-gray-500 dark:text-gray-400"
                            >
                                {{ $t('Total Discounts') }}
                            </p>
                            <p
                                class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ formatPrice(stats.total_discount) }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-orange-50 p-3 transition-colors group-hover:bg-orange-100 dark:bg-orange-900/20 dark:group-hover:bg-orange-900/40"
                        >
                            <DollarSign
                                class="h-6 w-6 text-orange-600 dark:text-orange-400"
                            />
                        </div>
                    </div>
                </div>
            </div>

            <!-- Filters & Actions -->
            <div class="flex flex-col gap-4">
                <!-- Search & Filter Grid -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="grid grid-cols-1 gap-4 md:grid-cols-12">
                        <!-- Search -->
                        <div class="md:col-span-6 lg:col-span-4">
                            <label
                                class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >{{ $t('Search') }}</label
                            >
                            <div class="relative">
                                <Search
                                    class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                                />
                                <input
                                    type="text"
                                    v-model="searchQuery"
                                    :placeholder="$t('Code, name...')"
                                    class="w-full rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-4 pl-10 text-sm text-gray-900 transition-all placeholder:text-gray-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                    @keyup.enter="applyFilters"
                                />
                            </div>
                        </div>

                        <!-- Status Filter -->
                        <div class="md:col-span-3 lg:col-span-2">
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
                                    <option value="all">
                                        {{ $t('All Status') }}
                                    </option>
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
                                    <ArrowUpDown
                                        class="h-3 w-3 text-gray-400"
                                    />
                                </div>
                            </div>
                        </div>

                        <!-- Type Filter -->
                        <div class="md:col-span-3 lg:col-span-2">
                            <label
                                class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >{{ $t('Type') }}</label
                            >
                            <div class="relative">
                                <Ticket
                                    class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                                />
                                <select
                                    v-model="typeFilter"
                                    @change="applyFilters"
                                    class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-8 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                >
                                    <option value="all">
                                        {{ $t('All Types') }}
                                    </option>
                                    <option value="percentage">
                                        {{ $t('Percentage') }}
                                    </option>
                                    <option value="fixed_amount">
                                        {{ $t('Fixed Amount') }}
                                    </option>
                                    <option value="free_shipping">
                                        {{ $t('Free Shipping') }}
                                    </option>
                                    <option value="buy_x_get_y">
                                        {{ $t('Buy X Get Y') }}
                                    </option>
                                </select>
                                <div
                                    class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2"
                                >
                                    <ArrowUpDown
                                        class="h-3 w-3 text-gray-400"
                                    />
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Filter Actions -->
                    <div
                        v-if="
                            searchQuery ||
                            statusFilter !== 'all' ||
                            typeFilter !== 'all'
                        "
                        class="mt-4 flex justify-end border-t border-gray-200 pt-4 dark:border-gray-700"
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

                <!-- Bulk Actions Bar -->
                <div
                    v-if="someSelected || allSelected"
                    class="flex flex-wrap items-center justify-between gap-4 rounded-lg border border-blue-200 bg-blue-50 p-3 transition-all duration-300 dark:border-blue-800 dark:bg-blue-900/20"
                >
                    <div class="flex items-center gap-2">
                        <span
                            class="text-sm font-medium text-blue-700 dark:text-blue-300"
                        >
                            {{
                                $t('{count} selected', {
                                    count: selectedCoupons.length,
                                })
                            }}
                        </span>
                    </div>
                    <div class="flex items-center gap-2">
                        <button
                            @click="bulkActivate"
                            class="inline-flex items-center rounded border border-transparent bg-blue-100 px-3 py-1.5 text-xs font-medium text-blue-700 hover:bg-blue-200 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none dark:bg-blue-900/40 dark:text-blue-300 dark:hover:bg-blue-900/60"
                        >
                            <CheckCircle class="mr-1.5 h-4 w-4" />
                            {{ $t('Activate') }}
                        </button>
                        <button
                            @click="bulkDeactivate"
                            class="inline-flex items-center rounded border border-transparent bg-orange-100 px-3 py-1.5 text-xs font-medium text-orange-700 hover:bg-orange-200 focus:ring-2 focus:ring-orange-500 focus:ring-offset-2 focus:outline-none dark:bg-orange-900/40 dark:text-orange-300 dark:hover:bg-orange-900/60"
                        >
                            <X class="mr-1.5 h-4 w-4" />
                            {{ $t('Deactivate') }}
                        </button>
                        <button
                            @click="bulkDelete"
                            class="inline-flex items-center rounded border border-transparent bg-red-100 px-3 py-1.5 text-xs font-medium text-red-700 hover:bg-red-200 focus:ring-2 focus:ring-red-500 focus:ring-offset-2 focus:outline-none dark:bg-red-900/40 dark:text-red-300 dark:hover:bg-red-900/60"
                        >
                            <Trash2 class="mr-1.5 h-4 w-4" />
                            {{ $t('Delete Selected') }}
                        </button>
                    </div>
                </div>
            </div>

            <!-- Content Table -->
            <div
                class="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div class="overflow-x-auto">
                    <table
                        class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                    >
                        <thead class="bg-gray-50 dark:bg-gray-700/50">
                            <tr>
                                <th scope="col" class="px-6 py-3 text-left">
                                    <div class="flex items-center">
                                        <input
                                            type="checkbox"
                                            :checked="allSelected"
                                            :indeterminate="someSelected"
                                            @change="toggleSelectAll"
                                            class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                        />
                                    </div>
                                </th>
                                <th
                                    scope="col"
                                    class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Details') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase md:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Type') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase md:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Discount') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase lg:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Usage') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase lg:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Valid Until') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase sm:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Status') }}
                                </th>
                                <th
                                    scope="col"
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
                                v-for="coupon in coupons.data"
                                :key="coupon.id"
                            >
                                <tr
                                    :class="[
                                        'group transition-colors hover:bg-blue-50/50 dark:hover:bg-blue-900/10',
                                        {
                                            'bg-blue-50 dark:bg-blue-900/10':
                                                selectedCoupons.includes(
                                                    coupon.id,
                                                ),
                                        },
                                    ]"
                                >
                                    <td
                                        class="relative px-6 py-4 whitespace-nowrap"
                                    >
                                        <div class="flex items-center">
                                            <button
                                                @click="toggleRow(coupon.id)"
                                                class="absolute left-2 p-1 text-blue-600 hover:text-blue-800 focus:outline-none md:hidden"
                                            >
                                                <MinusCircle
                                                    v-if="
                                                        expandedRows.includes(
                                                            coupon.id,
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
                                                :checked="
                                                    selectedCoupons.includes(
                                                        coupon.id,
                                                    )
                                                "
                                                @change="
                                                    toggleSelect(coupon.id)
                                                "
                                                class="ml-4 h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 md:ml-0 dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                    </td>

                                    <!-- Details -->
                                    <td class="px-6 py-4">
                                        <div class="flex items-center">
                                            <div>
                                                <div
                                                    class="font-medium text-gray-900 dark:text-white"
                                                >
                                                    {{ coupon.code }}
                                                </div>
                                                <div
                                                    class="text-xs text-gray-500 dark:text-gray-400"
                                                >
                                                    {{ coupon.name }}
                                                </div>
                                            </div>
                                        </div>
                                    </td>

                                    <!-- Type -->
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap md:table-cell"
                                    >
                                        <span
                                            class="inline-flex rounded-md px-2 py-1 text-xs font-medium"
                                            :class="getTypeColor(coupon.type)"
                                        >
                                            {{ getTypeLabel(coupon.type) }}
                                        </span>
                                    </td>

                                    <!-- Discount -->
                                    <td
                                        class="hidden px-6 py-4 text-sm font-medium whitespace-nowrap text-gray-900 md:table-cell dark:text-white"
                                    >
                                        {{ formatDiscount(coupon) }}
                                    </td>

                                    <!-- Usage -->
                                    <td
                                        class="hidden px-6 py-4 text-sm whitespace-nowrap text-gray-500 lg:table-cell dark:text-gray-400"
                                    >
                                        <div class="flex flex-col">
                                            <span>{{
                                                $t('{count} used', {
                                                    count: coupon.usage_count,
                                                })
                                            }}</span>
                                            <span
                                                class="text-xs text-gray-400"
                                                v-if="coupon.usage_limit_total"
                                            >
                                                {{
                                                    $t('of {limit} limit', {
                                                        limit: coupon.usage_limit_total,
                                                    })
                                                }}
                                            </span>
                                        </div>
                                    </td>

                                    <!-- Dates -->
                                    <td
                                        class="hidden px-6 py-4 text-sm whitespace-nowrap text-gray-500 lg:table-cell dark:text-gray-400"
                                    >
                                        <div
                                            :class="{
                                                'font-medium text-red-500':
                                                    isExpired(coupon.end_date),
                                            }"
                                        >
                                            {{ formatDate(coupon.end_date) }}
                                            <span
                                                v-if="
                                                    isExpired(coupon.end_date)
                                                "
                                                class="block text-xs text-red-500"
                                                >{{ $t('Expired') }}</span
                                            >
                                        </div>
                                    </td>

                                    <!-- Status -->
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap sm:table-cell"
                                    >
                                        <span
                                            class="inline-flex rounded-full px-2 py-1 text-xs font-medium"
                                            :class="
                                                coupon.is_active
                                                    ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                                                    : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
                                            "
                                        >
                                            {{
                                                coupon.is_active
                                                    ? $t('Active')
                                                    : $t('Inactive')
                                            }}
                                        </span>
                                    </td>

                                    <!-- Actions -->
                                    <td
                                        class="px-6 py-4 text-right text-sm font-medium whitespace-nowrap"
                                    >
                                        <div
                                            class="flex items-center justify-end gap-2 opacity-60 transition-opacity group-hover:opacity-100"
                                        >
                                            <Link
                                                :href="`/admin/marketing/coupons/${coupon.id}/edit`"
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-900/20"
                                            >
                                                <Edit class="h-4 w-4" />
                                            </Link>
                                            <button
                                                @click="deleteCoupon(coupon.id)"
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-900/20"
                                            >
                                                <Trash2 class="h-4 w-4" />
                                            </button>
                                        </div>
                                    </td>
                                </tr>

                                <!-- Mobile Expanded Row -->
                                <tr
                                    v-if="expandedRows.includes(coupon.id)"
                                    class="bg-gray-50 md:hidden dark:bg-gray-700/30"
                                >
                                    <td colspan="7" class="space-y-3 px-6 py-4">
                                        <div
                                            class="grid grid-cols-2 gap-4 text-sm"
                                        >
                                            <div>
                                                <span
                                                    class="block text-xs font-medium text-gray-500 uppercase"
                                                    >{{ $t('Type') }}</span
                                                >
                                                <span
                                                    class="mt-1 inline-flex rounded-md px-2 py-1 text-xs font-medium"
                                                    :class="
                                                        getTypeColor(
                                                            coupon.type,
                                                        )
                                                    "
                                                >
                                                    {{
                                                        getTypeLabel(
                                                            coupon.type,
                                                        )
                                                    }}
                                                </span>
                                            </div>
                                            <div>
                                                <span
                                                    class="block text-xs font-medium text-gray-500 uppercase"
                                                    >{{ $t('Discount') }}</span
                                                >
                                                <span
                                                    class="mt-1 block font-medium text-gray-900 dark:text-white"
                                                    >{{
                                                        formatDiscount(coupon)
                                                    }}</span
                                                >
                                            </div>
                                            <div>
                                                <span
                                                    class="block text-xs font-medium text-gray-500 uppercase"
                                                    >{{ $t('Usage') }}</span
                                                >
                                                <div
                                                    class="mt-1 text-gray-500 dark:text-gray-400"
                                                >
                                                    <span>{{
                                                        $t('{count} used', {
                                                            count: coupon.usage_count,
                                                        })
                                                    }}</span>
                                                    <span
                                                        class="text-xs text-gray-400"
                                                        v-if="
                                                            coupon.usage_limit_total
                                                        "
                                                    >
                                                        {{
                                                            $t(
                                                                'of {limit} limit',
                                                                {
                                                                    limit: coupon.usage_limit_total,
                                                                },
                                                            )
                                                        }}
                                                    </span>
                                                </div>
                                            </div>
                                            <div>
                                                <span
                                                    class="block text-xs font-medium text-gray-500 uppercase"
                                                    >{{ $t('Status') }}</span
                                                >
                                                <span
                                                    class="mt-1 inline-flex rounded-full px-2 py-1 text-xs font-medium"
                                                    :class="
                                                        coupon.is_active
                                                            ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                                                            : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
                                                    "
                                                >
                                                    {{
                                                        coupon.is_active
                                                            ? $t('Active')
                                                            : $t('Inactive')
                                                    }}
                                                </span>
                                            </div>
                                            <div class="col-span-2">
                                                <span
                                                    class="block text-xs font-medium text-gray-500 uppercase"
                                                    >{{
                                                        $t('Valid Until')
                                                    }}</span
                                                >
                                                <div
                                                    class="mt-1"
                                                    :class="{
                                                        'font-medium text-red-500':
                                                            isExpired(
                                                                coupon.end_date,
                                                            ),
                                                    }"
                                                >
                                                    {{
                                                        formatDate(
                                                            coupon.end_date,
                                                        )
                                                    }}
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                            </template>
                        </tbody>
                    </table>
                </div>

                <!-- Pagination -->
                <div
                    class="border-t border-gray-100 px-6 py-4 dark:border-gray-700"
                >
                    <div class="flex items-center justify-between">
                        <div class="text-sm text-gray-500 dark:text-gray-400">
                            {{
                                $t(
                                    'Showing {from} to {to} of {total} results',
                                    {
                                        from: coupons.from,
                                        to: coupons.to,
                                        total: coupons.total,
                                    },
                                )
                            }}
                        </div>
                        <div class="flex gap-2">
                            <Link
                                v-if="coupons.prev_page_url"
                                :href="coupons.prev_page_url"
                                class="rounded-md border border-gray-300 px-3 py-1 text-sm text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                            >
                                {{ $t('Previous') }}
                            </Link>
                            <Link
                                v-if="coupons.next_page_url"
                                :href="coupons.next_page_url"
                                class="rounded-md border border-gray-300 px-3 py-1 text-sm text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                            >
                                {{ $t('Next') }}
                            </Link>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

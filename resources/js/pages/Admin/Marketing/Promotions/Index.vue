<script setup lang="ts">
import { useCalendar } from '@/composables/useCalendar';
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { useI18nStore } from '@/Stores/i18n';
import { Link, router } from '@inertiajs/vue3';
import {
    ArrowUpDown,
    CheckCircle,
    Edit,
    Filter,
    MinusCircle,
    PlusCircle,
    Search,
    ShoppingBag,
    Tag,
    Trash2,
    TrendingUp,
    X,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

interface Promotion {
    id: number;
    name: string;
    description: string | null;
    type: string;
    discount_type: string;
    discount_value: number;
    is_active: boolean;
    show_badge: boolean;
    badge_text: string | null;
    badge_color: string;
    badge_bg_color: string;
    start_date: string | null;
    end_date: string | null;
    usage_count: number;
    usage_limit: number | null;
    total_revenue_generated: number;
    priority: number;
    created_at: string;
}

interface Filters {
    search?: string;
    status?: string;
    type?: string;
    sort_by?: string;
    sort_order?: string;
}

interface Stats {
    total: number;
    active: number;
    usage_count: number;
    revenue_generated: number;
}

const props = defineProps<{
    promotions: {
        data: Promotion[];
        current_page: number;
        last_page: number;
        per_page: number;
        total: number;
        from: number;
        to: number;
        links: any[];
        prev_page_url: string | null;
        next_page_url: string | null;
    };
    filters: Filters;
    stats: Stats;
    promotionTypes: Record<string, string>;
}>();

const filters = ref({
    search: props.filters.search || '',
    status: props.filters.status || '',
    type: props.filters.type || '',
});

const selectedIds = ref<number[]>([]);
const selectAll = ref(false);
const expandedRows = ref<number[]>([]);

const { formatPrice } = useCurrency();
const { t } = useI18nStore();
const { formatDate: formatCalendarDate } = useCalendar();

const someSelected = computed(() => {
    return (
        selectedIds.value.length > 0 &&
        selectedIds.value.length < props.promotions.data.length
    );
});

const allSelected = computed(() => {
    return (
        props.promotions.data.length > 0 &&
        selectedIds.value.length === props.promotions.data.length
    );
});

const search = () => {
    router.get(
        '/admin/marketing/promotions',
        {
            search: filters.value.search || undefined,
            status: filters.value.status || undefined,
            type: filters.value.type || undefined,
        },
        {
            preserveState: true,
            preserveScroll: true,
        },
    );
};

const clearFilters = () => {
    filters.value.search = '';
    filters.value.status = '';
    filters.value.type = '';
    search();
};

const toggleSelectAll = () => {
    if (allSelected.value) {
        selectedIds.value = [];
    } else {
        selectedIds.value = props.promotions.data.map((p) => p.id);
    }
};

const toggleSelect = (id: number) => {
    const index = selectedIds.value.indexOf(id);
    if (index > -1) {
        selectedIds.value.splice(index, 1);
    } else {
        selectedIds.value.push(id);
    }
};

const toggleRow = (id: number) => {
    if (expandedRows.value.includes(id)) {
        expandedRows.value = expandedRows.value.filter((rowId) => rowId !== id);
    } else {
        expandedRows.value.push(id);
    }
};

const deletePromotion = (id: number) => {
    if (confirm('Are you sure you want to delete this promotion?')) {
        router.delete(`/admin/marketing/promotions/${id}`, {
            preserveScroll: true,
            onSuccess: () => {
                selectedIds.value = selectedIds.value.filter(
                    (sid) => sid !== id,
                );
            },
        });
    }
};

const bulkActivate = () => {
    if (selectedIds.value.length === 0) return;

    router.post(
        '/admin/marketing/promotions/bulk-activate',
        {
            ids: selectedIds.value,
        },
        {
            preserveScroll: true,
            onSuccess: () => {
                selectedIds.value = [];
            },
        },
    );
};

const bulkDeactivate = () => {
    if (selectedIds.value.length === 0) return;

    router.post(
        '/admin/marketing/promotions/bulk-deactivate',
        {
            ids: selectedIds.value,
        },
        {
            preserveScroll: true,
            onSuccess: () => {
                selectedIds.value = [];
            },
        },
    );
};

const bulkDelete = () => {
    if (selectedIds.value.length === 0) return;

    if (
        confirm(
            `Are you sure you want to delete ${selectedIds.value.length} promotions?`,
        )
    ) {
        router.post(
            '/admin/marketing/promotions/bulk-delete',
            {
                ids: selectedIds.value,
            },
            {
                preserveScroll: true,
                onSuccess: () => {
                    selectedIds.value = [];
                },
            },
        );
    }
};

const getTypeLabel = (type: string) => {
    return props.promotionTypes[type] || type;
};

const getTypeBadgeColor = (type: string) => {
    const colors: Record<string, string> = {
        catalog_rule:
            'bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-300',
        cart_rule:
            'bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-300',
        bundle: 'bg-purple-100 dark:bg-purple-900/30 text-purple-800 dark:text-purple-300',
        flash_sale:
            'bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-300',
        tiered_pricing:
            'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-300',
    };
    return (
        colors[type] ||
        'bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-300'
    );
};

const formatDiscount = (promotion: Promotion) => {
    if (promotion.discount_type === 'percentage') {
        return `${promotion.discount_value}%`;
    }
    return formatPrice(promotion.discount_value);
};

const formatDate = (date: string | null) => {
    if (!date) return t('No expiry');
    return formatCalendarDate(date);
};

const isExpired = (promotion: Promotion) => {
    if (!promotion.end_date) return false;
    return new Date(promotion.end_date) < new Date();
};

const isScheduled = (promotion: Promotion) => {
    if (!promotion.start_date) return false;
    return new Date(promotion.start_date) > new Date();
};
</script>

<template>
    <AdminLayout :title="$t('Promotions')">
        <div class="space-y-6 p-6">
            <!-- Header -->
            <div
                class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
            >
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Promotions') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                        {{
                            $t(
                                'Manage automatic discounts and promotional offers',
                            )
                        }}
                    </p>
                </div>
                <Link
                    href="/admin/marketing/promotions/create"
                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                >
                    <PlusCircle class="mr-2 h-4 w-4" />
                    {{ $t('Create Promotion') }}
                </Link>
            </div>

            <!-- Stats Cards -->
            <div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
                <div
                    class="group rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-colors hover:border-blue-200 dark:border-gray-700 dark:bg-gray-800 dark:hover:border-blue-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-sm font-medium text-gray-500 dark:text-gray-400"
                            >
                                {{ $t('Total Promotions') }}
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
                            <Tag
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
                                {{ $t('Total Applications') }}
                            </p>
                            <p
                                class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ stats.usage_count }}
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
                    class="group rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-colors hover:border-red-200 dark:border-gray-700 dark:bg-gray-800 dark:hover:border-red-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-sm font-medium text-gray-500 dark:text-gray-400"
                            >
                                {{ $t('Revenue Impact') }}
                            </p>
                            <p
                                class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ formatPrice(stats.revenue_generated) }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-red-50 p-3 transition-colors group-hover:bg-red-100 dark:bg-red-900/20 dark:group-hover:bg-red-900/40"
                        >
                            <TrendingUp
                                class="h-6 w-6 text-red-600 dark:text-red-400"
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
                                    v-model="filters.search"
                                    :placeholder="$t('Search promotions...')"
                                    class="w-full rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-4 pl-10 text-sm text-gray-900 transition-all placeholder:text-gray-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                    @keyup.enter="search"
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
                                    v-model="filters.status"
                                    @change="search"
                                    class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-8 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                >
                                    <option value="">
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
                                <Tag
                                    class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                                />
                                <select
                                    v-model="filters.type"
                                    @change="search"
                                    class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-8 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                >
                                    <option value="">
                                        {{ $t('All Types') }}
                                    </option>
                                    <option
                                        v-for="(label, value) in promotionTypes"
                                        :key="value"
                                        :value="value"
                                    >
                                        {{ label }}
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

                        <!-- Filter Actions -->
                        <div
                            v-if="
                                filters.search || filters.status || filters.type
                            "
                            class="mt-4 flex justify-end border-t border-gray-200 pt-4 md:col-span-12 dark:border-gray-700"
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
                                    count: selectedIds.length,
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
                                    {{ $t('Promotion') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase md:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Discount') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase md:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Badge') }}
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
                                    {{ $t('Schedule') }}
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
                                v-for="promotion in promotions.data"
                                :key="promotion.id"
                            >
                                <tr
                                    :class="[
                                        'group transition-colors hover:bg-blue-50/50 dark:hover:bg-blue-900/10',
                                        {
                                            'bg-blue-50 dark:bg-blue-900/10':
                                                selectedIds.includes(
                                                    promotion.id,
                                                ),
                                        },
                                    ]"
                                >
                                    <td
                                        class="relative px-6 py-4 whitespace-nowrap"
                                    >
                                        <div class="flex items-center">
                                            <button
                                                @click="toggleRow(promotion.id)"
                                                class="absolute left-2 p-1 text-blue-600 hover:text-blue-800 focus:outline-none md:hidden"
                                            >
                                                <MinusCircle
                                                    v-if="
                                                        expandedRows.includes(
                                                            promotion.id,
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
                                                    selectedIds.includes(
                                                        promotion.id,
                                                    )
                                                "
                                                @change="
                                                    toggleSelect(promotion.id)
                                                "
                                                class="ml-4 h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 md:ml-0 dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                    </td>

                                    <!-- Promotion Details -->
                                    <td class="px-6 py-4">
                                        <div class="flex flex-col">
                                            <span
                                                class="font-medium text-gray-900 dark:text-white"
                                                >{{ promotion.name }}</span
                                            >
                                            <span
                                                :class="[
                                                    'mt-1 inline-flex w-fit items-center rounded px-2 py-0.5 text-xs font-medium',
                                                    getTypeBadgeColor(
                                                        promotion.type,
                                                    ),
                                                ]"
                                            >
                                                {{
                                                    getTypeLabel(promotion.type)
                                                }}
                                            </span>
                                        </div>
                                    </td>

                                    <!-- Discount -->
                                    <td
                                        class="hidden px-6 py-4 text-sm font-medium whitespace-nowrap text-gray-900 md:table-cell dark:text-white"
                                    >
                                        {{ formatDiscount(promotion) }}
                                    </td>

                                    <!-- Badge -->
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap md:table-cell"
                                    >
                                        <div
                                            v-if="promotion.show_badge"
                                            class="flex items-center gap-2"
                                        >
                                            <div
                                                class="rounded px-2 py-1 text-xs font-medium"
                                                :style="{
                                                    backgroundColor:
                                                        promotion.badge_bg_color,
                                                    color: promotion.badge_color,
                                                }"
                                            >
                                                {{
                                                    promotion.badge_text ||
                                                    $t('SALE')
                                                }}
                                            </div>
                                        </div>
                                        <span
                                            v-else
                                            class="text-sm text-gray-400"
                                            >{{ $t('No badge') }}</span
                                        >
                                    </td>

                                    <!-- Usage -->
                                    <td
                                        class="hidden px-6 py-4 text-sm whitespace-nowrap text-gray-500 lg:table-cell dark:text-gray-400"
                                    >
                                        <div
                                            class="text-sm text-gray-900 dark:text-white"
                                        >
                                            {{ promotion.usage_count }}
                                            <span
                                                v-if="promotion.usage_limit"
                                                class="text-gray-500 dark:text-gray-400"
                                                >/
                                                {{
                                                    promotion.usage_limit
                                                }}</span
                                            >
                                        </div>
                                    </td>

                                    <!-- Schedule -->
                                    <td
                                        class="hidden px-6 py-4 text-sm whitespace-nowrap text-gray-500 lg:table-cell dark:text-gray-400"
                                    >
                                        <div class="flex flex-col">
                                            <span>{{
                                                formatDate(promotion.start_date)
                                            }}</span>
                                            <span class="text-xs">{{
                                                $t('to {date}', {
                                                    date: formatDate(
                                                        promotion.end_date,
                                                    ),
                                                })
                                            }}</span>
                                        </div>
                                    </td>

                                    <!-- Status -->
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap sm:table-cell"
                                    >
                                        <span
                                            v-if="isExpired(promotion)"
                                            class="inline-flex items-center rounded-full bg-gray-100 px-2.5 py-0.5 text-xs font-medium text-gray-800 dark:bg-gray-700 dark:text-gray-300"
                                        >
                                            {{ $t('Expired') }}
                                        </span>
                                        <span
                                            v-else-if="isScheduled(promotion)"
                                            class="inline-flex items-center rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-800 dark:bg-blue-900/30 dark:text-blue-300"
                                        >
                                            {{ $t('Scheduled') }}
                                        </span>
                                        <span
                                            v-else-if="promotion.is_active"
                                            class="inline-flex items-center rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-medium text-green-800 dark:bg-green-900/30 dark:text-green-300"
                                        >
                                            {{ $t('Active') }}
                                        </span>
                                        <span
                                            v-else
                                            class="inline-flex items-center rounded-full bg-red-100 px-2.5 py-0.5 text-xs font-medium text-red-800 dark:bg-red-900/30 dark:text-red-300"
                                        >
                                            {{ $t('Inactive') }}
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
                                                :href="`/admin/marketing/promotions/${promotion.id}/edit`"
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-900/20"
                                                :title="$t('Edit')"
                                            >
                                                <Edit class="h-4 w-4" />
                                            </Link>
                                            <button
                                                @click="
                                                    deletePromotion(
                                                        promotion.id,
                                                    )
                                                "
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-900/20"
                                                :title="$t('Delete')"
                                            >
                                                <Trash2 class="h-4 w-4" />
                                            </button>
                                        </div>
                                    </td>
                                </tr>

                                <!-- Mobile Expanded Rows -->
                                <tr
                                    v-if="expandedRows.includes(promotion.id)"
                                    class="bg-gray-50 md:hidden dark:bg-gray-700/30"
                                >
                                    <td colspan="8" class="space-y-3 px-6 py-4">
                                        <div
                                            class="grid grid-cols-2 gap-4 text-sm"
                                        >
                                            <div>
                                                <span
                                                    class="block text-xs font-medium text-gray-500 uppercase"
                                                    >{{ $t('Discount') }}</span
                                                >
                                                <span
                                                    class="mt-1 block font-medium text-gray-900 dark:text-white"
                                                    >{{
                                                        formatDiscount(
                                                            promotion,
                                                        )
                                                    }}</span
                                                >
                                            </div>
                                            <div>
                                                <span
                                                    class="block text-xs font-medium text-gray-500 uppercase"
                                                    >{{ $t('Status') }}</span
                                                >
                                                <div class="mt-1">
                                                    <span
                                                        v-if="
                                                            isExpired(promotion)
                                                        "
                                                        class="inline-flex items-center rounded-full bg-gray-100 px-2.5 py-0.5 text-xs font-medium text-gray-800 dark:bg-gray-700 dark:text-gray-300"
                                                    >
                                                        {{ $t('Expired') }}
                                                    </span>
                                                    <span
                                                        v-else-if="
                                                            isScheduled(
                                                                promotion,
                                                            )
                                                        "
                                                        class="inline-flex items-center rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-800 dark:bg-blue-900/30 dark:text-blue-300"
                                                    >
                                                        {{ $t('Scheduled') }}
                                                    </span>
                                                    <span
                                                        v-else-if="
                                                            promotion.is_active
                                                        "
                                                        class="inline-flex items-center rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-medium text-green-800 dark:bg-green-900/30 dark:text-green-300"
                                                    >
                                                        {{ $t('Active') }}
                                                    </span>
                                                    <span
                                                        v-else
                                                        class="inline-flex items-center rounded-full bg-red-100 px-2.5 py-0.5 text-xs font-medium text-red-800 dark:bg-red-900/30 dark:text-red-300"
                                                    >
                                                        {{ $t('Inactive') }}
                                                    </span>
                                                </div>
                                            </div>
                                            <div class="col-span-2">
                                                <span
                                                    class="block text-xs font-medium text-gray-500 uppercase"
                                                    >{{ $t('Schedule') }}</span
                                                >
                                                <span
                                                    class="mt-1 block text-gray-900 dark:text-white"
                                                    >{{
                                                        formatDate(
                                                            promotion.start_date,
                                                        )
                                                    }}
                                                    -
                                                    {{
                                                        formatDate(
                                                            promotion.end_date,
                                                        )
                                                    }}</span
                                                >
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
                                        from: promotions.from,
                                        to: promotions.to,
                                        total: promotions.total,
                                    },
                                )
                            }}
                        </div>
                        <div class="flex gap-2">
                            <Link
                                v-if="promotions.prev_page_url"
                                :href="promotions.prev_page_url"
                                class="rounded-md border border-gray-300 px-3 py-1 text-sm text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                            >
                                {{ $t('Previous') }}
                            </Link>
                            <Link
                                v-if="promotions.next_page_url"
                                :href="promotions.next_page_url"
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

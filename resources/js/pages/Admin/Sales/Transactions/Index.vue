<script setup lang="ts">
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import DatePicker from '@/components/Calendar/DatePicker.vue';
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import type {
    PaginatedResponse,
    StatusOption,
    Transaction,
    TransactionFilters,
    TransactionStatistics,
} from '@/types/sales';
import { Head, Link, router } from '@inertiajs/vue3';
import {
    AlertCircle,
    ArrowUpDown,
    CheckCircle,
    CheckSquare,
    ChevronLeft,
    ChevronRight,
    Clock,
    CreditCard,
    DollarSign,
    Download,
    Eye,
    FileText,
    Filter,
    MinusCircle,
    PlusCircle,
    RefreshCw,
    Search,
    X,
} from 'lucide-vue-next';
import { computed, ref, watch } from 'vue';

const props = defineProps<{
    transactions: PaginatedResponse<Transaction>;
    filters: TransactionFilters;
    statistics: TransactionStatistics;
    types: StatusOption[];
    statuses: StatusOption[];
    gateways: StatusOption[];
}>();

const { formatPrice } = useCurrency();

const search = ref(props.filters.search || '');
const typeFilter = ref(props.filters.type || '');
const statusFilter = ref(props.filters.status || '');
const gatewayFilter = ref(props.filters.gateway || '');
const dateFrom = ref(props.filters.date_from || '');
const dateTo = ref(props.filters.date_to || '');
const amountMin = ref(props.filters.amount_min || '');
const amountMax = ref(props.filters.amount_max || '');
const sortBy = ref(props.filters.sort_by || 'created_at');
const sortOrder = ref(props.filters.sort_order || 'desc');

// Bulk actions state
const selectAll = ref(false);
const selectedIds = ref<number[]>([]);
const expandedRows = ref<number[]>([]);

const applyFilters = () => {
    router.get(
        '/admin/sales/transactions',
        {
            search: search.value,
            type: typeFilter.value,
            status: statusFilter.value,
            gateway: gatewayFilter.value,
            date_from: dateFrom.value,
            date_to: dateTo.value,
            amount_min: amountMin.value || undefined,
            amount_max: amountMax.value || undefined,
            sort_by: sortBy.value,
            sort_order: sortOrder.value,
        },
        {
            preserveState: true,
            preserveScroll: true,
        },
    );
};

const clearFilters = () => {
    search.value = '';
    typeFilter.value = '';
    statusFilter.value = '';
    gatewayFilter.value = '';
    dateFrom.value = '';
    dateTo.value = '';
    amountMin.value = '';
    amountMax.value = '';
    applyFilters();
};

const toggleRow = (id: number) => {
    const index = expandedRows.value.indexOf(id);
    if (index === -1) {
        expandedRows.value.push(id);
    } else {
        expandedRows.value.splice(index, 1);
    }
};

const someSelected = computed(() => {
    return (
        selectedIds.value.length > 0 &&
        selectedIds.value.length < props.transactions.data.length
    );
});

watch(selectAll, (value) => {
    if (value) {
        selectedIds.value = props.transactions.data.map((t) => t.id);
    } else {
        selectedIds.value = [];
    }
});

const getStatusBadge = (status: string) => {
    const badges: Record<string, string> = {
        pending:
            'bg-yellow-50 text-yellow-700 border-yellow-200 dark:bg-yellow-900/20 dark:text-yellow-300 dark:border-yellow-800',
        completed:
            'bg-green-50 text-green-700 border-green-200 dark:bg-green-900/20 dark:text-green-300 dark:border-green-800',
        failed: 'bg-red-50 text-red-700 border-red-200 dark:bg-red-900/20 dark:text-red-300 dark:border-red-800',
        cancelled:
            'bg-gray-50 text-gray-700 border-gray-200 dark:bg-gray-900/20 dark:text-gray-300 dark:border-gray-800',
    };
    return (
        badges[status] ||
        'bg-gray-50 text-gray-700 border-gray-200 dark:bg-gray-700 dark:text-gray-300 dark:border-gray-600'
    );
};

const getTypeBadge = (type: string) => {
    const badges: Record<string, string> = {
        payment:
            'bg-blue-50 text-blue-700 border-blue-200 dark:bg-blue-900/20 dark:text-blue-300 dark:border-blue-800',
        refund: 'bg-purple-50 text-purple-700 border-purple-200 dark:bg-purple-900/20 dark:text-purple-300 dark:border-purple-800',
        authorization:
            'bg-indigo-50 text-indigo-700 border-indigo-200 dark:bg-indigo-900/20 dark:text-indigo-300 dark:border-indigo-800',
        capture:
            'bg-teal-50 text-teal-700 border-teal-200 dark:bg-teal-900/20 dark:text-teal-300 dark:border-teal-800',
    };
    return (
        badges[type] ||
        'bg-gray-50 text-gray-700 border-gray-200 dark:bg-gray-700 dark:text-gray-300 dark:border-gray-600'
    );
};

const viewTransaction = (id: number) => {
    router.visit(`/admin/sales/transactions/${id}`);
};

const exportTransactions = () => {
    // Construct query params manually or use a helper
    const params = new URLSearchParams({
        search: search.value,
        type: typeFilter.value,
        status: statusFilter.value,
        gateway: gatewayFilter.value,
        date_from: dateFrom.value,
        date_to: dateTo.value,
        amount_min: amountMin.value?.toString() || '',
        amount_max: amountMax.value?.toString() || '',
        sort_by: sortBy.value,
        sort_order: sortOrder.value,
    });
    window.location.href = `/admin/sales/transactions/export?${params.toString()}`;
};
</script>

<template>
    <Head :title="$t('Transactions')" />

    <AdminLayout :title="$t('Transactions')">
        <div class="space-y-6 p-6">
            <!-- Page Header -->
            <div
                class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
            >
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Transactions') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                        {{ $t('View and manage payment transactions') }}
                    </p>
                </div>
                <button
                    @click="exportTransactions"
                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                >
                    <Download class="mr-2 h-4 w-4" />
                    {{ $t('Export') }}
                </button>
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
                                {{ $t('Total Transactions') }}
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
                            <FileText
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
                                {{ $t('Completed') }}
                            </p>
                            <p
                                class="mt-1 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.completed }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-green-50 p-3 dark:bg-green-900/20"
                        >
                            <CheckSquare
                                class="h-6 w-6 text-green-600 dark:text-green-400"
                            />
                        </div>
                    </div>
                </div>

                <div
                    class="group rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-colors hover:border-yellow-200 dark:border-gray-700 dark:bg-gray-800 dark:hover:border-yellow-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Pending') }}
                            </p>
                            <p
                                class="mt-1 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.pending }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-yellow-50 p-3 dark:bg-yellow-900/20"
                        >
                            <Clock
                                class="h-6 w-6 text-yellow-600 dark:text-yellow-400"
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
                                {{ $t('Failed') }}
                            </p>
                            <p
                                class="mt-1 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.failed }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-red-50 p-3 dark:bg-red-900/20"
                        >
                            <AlertCircle
                                class="h-6 w-6 text-red-600 dark:text-red-400"
                            />
                        </div>
                    </div>
                </div>
            </div>

            <!-- Payment/Refund Summary -->
            <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="mb-4 flex items-center justify-between">
                        <h3
                            class="text-sm font-medium text-gray-900 dark:text-white"
                        >
                            {{ $t('Payments') }}
                        </h3>
                        <div
                            class="rounded-lg bg-blue-50 p-2 dark:bg-blue-900/20"
                        >
                            <DollarSign
                                class="h-4 w-4 text-blue-600 dark:text-blue-400"
                            />
                        </div>
                    </div>
                    <div class="space-y-3">
                        <div class="flex items-center justify-between">
                            <span
                                class="text-sm text-gray-600 dark:text-gray-400"
                                >{{ $t('Count') }}</span
                            >
                            <span
                                class="text-sm font-bold text-gray-900 dark:text-white"
                                >{{ statistics.payment_count }}</span
                            >
                        </div>
                        <div class="flex items-center justify-between">
                            <span
                                class="text-sm text-gray-600 dark:text-gray-400"
                                >{{ $t('Total Amount') }}</span
                            >
                            <span
                                class="text-sm font-bold text-green-600 dark:text-green-400"
                                >{{
                                    formatPrice(statistics.payment_amount)
                                }}</span
                            >
                        </div>
                    </div>
                </div>

                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="mb-4 flex items-center justify-between">
                        <h3
                            class="text-sm font-medium text-gray-900 dark:text-white"
                        >
                            {{ $t('Refunds') }}
                        </h3>
                        <div
                            class="rounded-lg bg-purple-50 p-2 dark:bg-purple-900/20"
                        >
                            <RefreshCw
                                class="h-4 w-4 text-purple-600 dark:text-purple-400"
                            />
                        </div>
                    </div>
                    <div class="space-y-3">
                        <div class="flex items-center justify-between">
                            <span
                                class="text-sm text-gray-600 dark:text-gray-400"
                                >{{ $t('Count') }}</span
                            >
                            <span
                                class="text-sm font-bold text-gray-900 dark:text-white"
                                >{{ statistics.refund_count }}</span
                            >
                        </div>
                        <div class="flex items-center justify-between">
                            <span
                                class="text-sm text-gray-600 dark:text-gray-400"
                                >{{ $t('Total Amount') }}</span
                            >
                            <span
                                class="text-sm font-bold text-purple-600 dark:text-purple-400"
                                >{{
                                    formatPrice(statistics.refund_amount)
                                }}</span
                            >
                        </div>
                    </div>
                </div>
            </div>

            <!-- Filters Card -->
            <div
                class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div
                    class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4"
                >
                    <!-- Search -->
                    <div class="lg:col-span-1">
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
                                :placeholder="$t('Transaction #, Order #...')"
                                class="w-full rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-4 pl-10 text-sm text-gray-900 transition-all placeholder:text-gray-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            />
                        </div>
                    </div>

                    <!-- Type Filter -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Type') }}</label
                        >
                        <div class="relative">
                            <div
                                class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3"
                            >
                                <Filter class="h-4 w-4 text-gray-400" />
                            </div>
                            <select
                                v-model="typeFilter"
                                @change="applyFilters"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-10 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            >
                                <option value="">{{ $t('All Types') }}</option>
                                <option
                                    v-for="type in types"
                                    :key="type.value"
                                    :value="type.value"
                                >
                                    {{ type.label }}
                                </option>
                            </select>
                            <div
                                class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2"
                            >
                                <ArrowUpDown class="h-3 w-3 text-gray-400" />
                            </div>
                        </div>
                    </div>

                    <!-- Status Filter -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Status') }}</label
                        >
                        <div class="relative">
                            <div
                                class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3"
                            >
                                <CheckCircle class="h-4 w-4 text-gray-400" />
                            </div>
                            <select
                                v-model="statusFilter"
                                @change="applyFilters"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-10 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            >
                                <option value="">
                                    {{ $t('All Statuses') }}
                                </option>
                                <option
                                    v-for="status in statuses"
                                    :key="status.value"
                                    :value="status.value"
                                >
                                    {{ status.label }}
                                </option>
                            </select>
                            <div
                                class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2"
                            >
                                <ArrowUpDown class="h-3 w-3 text-gray-400" />
                            </div>
                        </div>
                    </div>

                    <!-- Gateway Filter -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Gateway') }}</label
                        >
                        <div class="relative">
                            <div
                                class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3"
                            >
                                <CreditCard class="h-4 w-4 text-gray-400" />
                            </div>
                            <select
                                v-model="gatewayFilter"
                                @change="applyFilters"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-10 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            >
                                <option value="">
                                    {{ $t('All Gateways') }}
                                </option>
                                <option
                                    v-for="gateway in gateways"
                                    :key="gateway.value"
                                    :value="gateway.value"
                                >
                                    {{ gateway.label }}
                                </option>
                            </select>
                            <div
                                class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2"
                            >
                                <ArrowUpDown class="h-3 w-3 text-gray-400" />
                            </div>
                        </div>
                    </div>

                    <!-- Date From -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('From Date') }}</label
                        >
                        <DatePicker
                            v-model="dateFrom"
                            @change="applyFilters"
                            class="w-full rounded-lg border border-gray-200 bg-gray-50 px-4 py-2.5 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                        />
                    </div>

                    <!-- Date To -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('To Date') }}</label
                        >
                        <DatePicker
                            v-model="dateTo"
                            @change="applyFilters"
                            class="w-full rounded-lg border border-gray-200 bg-gray-50 px-4 py-2.5 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                        />
                    </div>

                    <!-- Min Amount -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Min Amount') }}</label
                        >
                        <div class="relative">
                            <DollarSign
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <input
                                v-model="amountMin"
                                @change="applyFilters"
                                type="number"
                                step="0.01"
                                :placeholder="$t('0.00')"
                                class="w-full rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-4 pl-10 text-sm text-gray-900 transition-all placeholder:text-gray-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            />
                        </div>
                    </div>

                    <!-- Max Amount -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Max Amount') }}</label
                        >
                        <div class="relative">
                            <DollarSign
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <input
                                v-model="amountMax"
                                @change="applyFilters"
                                type="number"
                                step="0.01"
                                :placeholder="$t('0.00')"
                                class="w-full rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-4 pl-10 text-sm text-gray-900 transition-all placeholder:text-gray-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            />
                        </div>
                    </div>
                </div>

                <!-- Clear filters -->
                <div
                    v-if="
                        search ||
                        typeFilter ||
                        statusFilter ||
                        gatewayFilter ||
                        dateFrom ||
                        dateTo ||
                        amountMin ||
                        amountMax
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
                    v-if="selectedIds.length > 0"
                    class="sticky top-4 z-10 mb-6 flex items-center justify-between rounded-xl bg-blue-600 p-3 px-6 text-white shadow-lg"
                >
                    <span class="flex items-center text-sm font-semibold">
                        <CheckCircle class="mr-2 h-4 w-4" />
                        {{
                            $t('{count} selected', {
                                count: selectedIds.length,
                            })
                        }}
                    </span>
                    <div class="flex gap-2">
                        <!-- Add bulk actions here if needed -->
                    </div>
                </div>
            </transition>

            <!-- Transactions Table -->
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
                                        v-model="selectAll"
                                        :indeterminate.prop="someSelected"
                                        class="h-4 w-4 rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </th>
                                <th
                                    scope="col"
                                    class="px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Transaction #') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase sm:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Order #') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase xl:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Date') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase md:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Type') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase lg:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Gateway') }}
                                </th>
                                <th
                                    scope="col"
                                    class="px-6 py-4 text-right text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Amount') }}
                                </th>
                                <th
                                    scope="col"
                                    class="px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Status') }}
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
                                v-for="transaction in transactions.data"
                                :key="transaction.id"
                            >
                                <tr
                                    class="group transition-colors hover:bg-blue-50/50 dark:hover:bg-blue-900/10"
                                >
                                    <td class="relative px-6 py-4">
                                        <div class="flex items-center">
                                            <button
                                                @click="
                                                    toggleRow(transaction.id)
                                                "
                                                class="absolute left-2 p-1 text-blue-600 hover:text-blue-800 focus:outline-none lg:hidden"
                                            >
                                                <MinusCircle
                                                    v-if="
                                                        expandedRows.includes(
                                                            transaction.id,
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
                                                :value="transaction.id"
                                                v-model="selectedIds"
                                                class="ml-4 h-4 w-4 cursor-pointer rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 lg:ml-0 dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div
                                            class="text-sm font-bold text-blue-600 dark:text-blue-400"
                                        >
                                            {{ transaction.transaction_number }}
                                        </div>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap sm:table-cell"
                                    >
                                        <Link
                                            v-if="transaction.order"
                                            :href="`/admin/sales/orders/${transaction.order.id}`"
                                            class="text-sm text-blue-600 hover:text-blue-800 hover:underline dark:text-blue-400 dark:hover:text-blue-300"
                                        >
                                            {{ transaction.order.order_number }}
                                        </Link>
                                        <span
                                            v-else
                                            class="text-sm text-gray-500 dark:text-gray-400"
                                            >{{ $t('N/A') }}</span
                                        >
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap xl:table-cell"
                                    >
                                        <span
                                            class="text-sm text-gray-500 dark:text-gray-400"
                                            ><DateDisplay
                                                :value="transaction.created_at"
                                                time
                                        /></span>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap md:table-cell"
                                    >
                                        <span
                                            :class="[
                                                'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium shadow-sm',
                                                getTypeBadge(transaction.type),
                                            ]"
                                        >
                                            {{ transaction.type }}
                                        </span>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap lg:table-cell"
                                    >
                                        <span
                                            class="text-sm text-gray-900 capitalize dark:text-white"
                                            >{{ transaction.gateway }}</span
                                        >
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right whitespace-nowrap"
                                    >
                                        <span
                                            class="text-sm font-bold text-gray-900 dark:text-white"
                                            >{{
                                                formatPrice(transaction.amount)
                                            }}</span
                                        >
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <span
                                            :class="[
                                                'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium shadow-sm',
                                                getStatusBadge(
                                                    transaction.status,
                                                ),
                                            ]"
                                        >
                                            {{ transaction.status }}
                                        </span>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right text-sm font-medium whitespace-nowrap"
                                    >
                                        <div
                                            class="flex items-center justify-end gap-2 opacity-60 transition-opacity group-hover:opacity-100"
                                        >
                                            <button
                                                @click="
                                                    viewTransaction(
                                                        transaction.id,
                                                    )
                                                "
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-900/20"
                                                :title="$t('View Details')"
                                            >
                                                <Eye class="h-4 w-4" />
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                                <!-- Expanded Mobile Row -->
                                <tr
                                    v-if="expandedRows.includes(transaction.id)"
                                    class="bg-gray-50/50 lg:hidden dark:bg-gray-900/50"
                                >
                                    <td
                                        colspan="9"
                                        class="border-t border-gray-100 px-6 py-4 dark:border-gray-700"
                                    >
                                        <div
                                            class="grid grid-cols-1 gap-4 text-sm sm:grid-cols-2"
                                        >
                                            <div
                                                class="flex flex-col gap-2 sm:hidden"
                                            >
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{
                                                        $t('Order Reference')
                                                    }}</span
                                                >
                                                <Link
                                                    v-if="transaction.order"
                                                    :href="`/admin/sales/orders/${transaction.order.id}`"
                                                    class="text-sm font-medium text-blue-600 dark:text-blue-400"
                                                >
                                                    {{
                                                        transaction.order
                                                            .order_number
                                                    }}
                                                </Link>
                                                <span
                                                    v-else
                                                    class="text-sm text-gray-500"
                                                    >{{ $t('N/A') }}</span
                                                >
                                            </div>
                                            <div
                                                class="flex flex-col gap-2 md:hidden"
                                            >
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Type') }}</span
                                                >
                                                <span
                                                    :class="[
                                                        'inline-flex w-fit items-center rounded-full border px-2.5 py-0.5 text-xs font-medium shadow-sm',
                                                        getTypeBadge(
                                                            transaction.type,
                                                        ),
                                                    ]"
                                                >
                                                    {{ transaction.type }}
                                                </span>
                                            </div>
                                            <div
                                                class="flex flex-col gap-2 lg:hidden"
                                            >
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Gateway') }}</span
                                                >
                                                <span
                                                    class="text-sm text-gray-900 capitalize dark:text-white"
                                                    >{{
                                                        transaction.gateway
                                                    }}</span
                                                >
                                            </div>
                                            <div
                                                class="flex flex-col gap-2 xl:hidden"
                                            >
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Date') }}</span
                                                >
                                                <span
                                                    class="text-sm text-gray-500 dark:text-gray-400"
                                                    ><DateDisplay
                                                        :value="
                                                            transaction.created_at
                                                        "
                                                        time
                                                /></span>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                            </template>
                            <tr v-if="transactions.data.length === 0">
                                <td
                                    colspan="9"
                                    class="px-6 py-16 text-center text-gray-500 dark:text-gray-400"
                                >
                                    <div class="flex flex-col items-center">
                                        <div
                                            class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-50 text-gray-400 dark:bg-gray-700"
                                        >
                                            <CreditCard class="h-8 w-8" />
                                        </div>
                                        <p
                                            class="text-lg font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('No transactions found') }}
                                        </p>
                                        <p
                                            class="mt-1 max-w-sm text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            {{
                                                $t(
                                                    'Try adjusting your filters.',
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
                <div
                    class="flex items-center justify-between border-t border-gray-100 bg-gray-50/50 px-6 py-4 dark:border-gray-700 dark:bg-gray-700/50"
                >
                    <div class="text-xs text-gray-500 dark:text-gray-400">
                        {{ $t('Showing') }}
                        <span class="font-medium">{{
                            transactions.from || 0
                        }}</span>
                        {{ $t('to') }}
                        <span class="font-medium">{{
                            transactions.to || 0
                        }}</span>
                        {{ $t('of') }}
                        <span class="font-medium">{{
                            transactions.total
                        }}</span>
                        {{ $t('results') }}
                    </div>
                    <div class="flex gap-2">
                        <Link
                            v-if="transactions.prev_page_url"
                            :href="transactions.prev_page_url"
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
                            v-if="transactions.next_page_url"
                            :href="transactions.next_page_url"
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
        </div>
    </AdminLayout>
</template>

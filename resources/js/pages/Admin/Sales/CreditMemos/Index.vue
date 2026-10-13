<script setup lang="ts">
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import DatePicker from '@/components/Calendar/DatePicker.vue';
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import type {
    CreditMemo,
    CreditMemoFilters,
    CreditMemoStatistics,
    PaginatedResponse,
    StatusOption,
} from '@/types/sales';
import { Head, Link, router } from '@inertiajs/vue3';
import { debounce } from 'lodash';
import {
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
    Mail,
    MinusCircle,
    PlusCircle,
    RefreshCw,
    Search,
    User,
    X,
} from 'lucide-vue-next';
import { computed, ref, watch } from 'vue';

interface Props {
    creditMemos: PaginatedResponse<CreditMemo>;
    filters: CreditMemoFilters;
    statistics: CreditMemoStatistics;
    statuses: StatusOption[];
}

const props = defineProps<Props>();
const { formatPrice } = useCurrency();

const search = ref(props.filters.search || '');
const statusFilter = ref(props.filters.status || '');
const refundMethodFilter = ref(props.filters.refund_method || '');
const dateFrom = ref(props.filters.date_from || '');
const dateTo = ref(props.filters.date_to || '');
const minAmount = ref(props.filters.min_amount || '');
const maxAmount = ref(props.filters.max_amount || '');
const sortBy = ref('created_at'); // Assuming default sort, update if props.filters has it
const sortOrder = ref('desc');

// Bulk actions state
const selectAll = ref(false);
const selectedIds = ref<number[]>([]);
const expandedRows = ref<number[]>([]);

const performSearch = debounce(() => {
    applyFilters();
}, 300);

const applyFilters = () => {
    router.get(
        '/admin/sales/credit-memos',
        {
            search: search.value,
            status: statusFilter.value,
            refund_method: refundMethodFilter.value || undefined,
            date_from: dateFrom.value,
            date_to: dateTo.value,
            min_amount: minAmount.value || undefined,
            max_amount: maxAmount.value || undefined,
            // Add sorting params if backend supports it
        },
        {
            preserveState: true,
            preserveScroll: true,
        },
    );
};

const clearFilters = () => {
    search.value = '';
    statusFilter.value = '';
    refundMethodFilter.value = '';
    dateFrom.value = '';
    dateTo.value = '';
    minAmount.value = '';
    maxAmount.value = '';
    applyFilters();
};

const sortTable = (field: string) => {
    // TODO: implement backend sorting
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
        selectedIds.value.length < props.creditMemos.data.length
    );
});

watch(selectAll, (value) => {
    if (value) {
        selectedIds.value = props.creditMemos.data.map((cm) => cm.id);
    } else {
        selectedIds.value = [];
    }
});

const getStatusBadge = (status: string) => {
    const badges: Record<string, string> = {
        pending:
            'bg-yellow-50 text-yellow-700 border-yellow-200 dark:bg-yellow-900/20 dark:text-yellow-300 dark:border-yellow-800',
        refunded:
            'bg-green-50 text-green-700 border-green-200 dark:bg-green-900/20 dark:text-green-300 dark:border-green-800',
        cancelled:
            'bg-red-50 text-red-700 border-red-200 dark:bg-red-900/20 dark:text-red-300 dark:border-red-800',
    };
    return (
        badges[status] ||
        'bg-gray-50 text-gray-700 border-gray-200 dark:bg-gray-700 dark:text-gray-300 dark:border-gray-600'
    );
};

const getRefundMethodBadge = (method: string) => {
    return method === 'online'
        ? 'bg-blue-50 text-blue-700 border-blue-200 dark:bg-blue-900/20 dark:text-blue-300 dark:border-blue-800'
        : 'bg-purple-50 text-purple-700 border-purple-200 dark:bg-purple-900/20 dark:text-purple-300 dark:border-purple-800';
};

const downloadPdf = (id: number) => {
    window.open(`/admin/sales/credit-memos/${id}/download-pdf`, '_blank');
};

const sendEmail = (creditMemoId: number) => {
    router.post(
        `/admin/sales/credit-memos/${creditMemoId}/send-email`,
        {},
        {
            preserveScroll: true,
        },
    );
};

const processRefund = (id: number) => {
    router.post(
        `/admin/sales/credit-memos/${id}/process-refund`,
        {},
        {
            preserveScroll: true,
        },
    );
};

const cancelCreditMemo = (id: number) => {
    router.post(
        `/admin/sales/credit-memos/${id}/cancel`,
        {},
        {
            preserveScroll: true,
        },
    );
};
</script>

<template>
    <Head :title="$t('Credit Memos')" />

    <AdminLayout :title="$t('Credit Memos')">
        <div class="space-y-6 p-6">
            <!-- Page Header -->
            <div
                class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
            >
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Credit Memos') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                        {{ $t('Manage refunds and credit memos') }}
                    </p>
                </div>
                <Link
                    href="/admin/sales/orders"
                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                >
                    <PlusCircle class="mr-2 h-4 w-4" />
                    {{ $t('Create Credit Memo') }}
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
                                {{ $t('Total') }}
                            </p>
                            <p
                                class="mt-1 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.total }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-gray-50 p-3 transition-colors group-hover:bg-blue-50 dark:bg-gray-700 dark:group-hover:bg-blue-900/20"
                        >
                            <FileText
                                class="h-6 w-6 text-gray-500 transition-colors group-hover:text-blue-600 dark:text-gray-400 dark:group-hover:text-blue-400"
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
                    class="group rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-colors hover:border-green-200 dark:border-gray-700 dark:bg-gray-800 dark:hover:border-green-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Refunded') }}
                            </p>
                            <p
                                class="mt-1 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.refunded }}
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
                    class="group rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-colors hover:border-purple-200 dark:border-gray-700 dark:bg-gray-800 dark:hover:border-purple-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Total Amount') }}
                            </p>
                            <p
                                class="mt-1 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ formatPrice(statistics.total_amount) }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-purple-50 p-3 dark:bg-purple-900/20"
                        >
                            <DollarSign
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
                                @input="performSearch"
                                type="text"
                                :placeholder="$t('Credit Memo #, Order #...')"
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
                            <div
                                class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3"
                            >
                                <Filter class="h-4 w-4 text-gray-400" />
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

                    <!-- Refund Method -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Refund Method') }}</label
                        >
                        <div class="relative">
                            <div
                                class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3"
                            >
                                <CreditCard class="h-4 w-4 text-gray-400" />
                            </div>
                            <select
                                v-model="refundMethodFilter"
                                @change="applyFilters"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-10 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            >
                                <option value="">
                                    {{ $t('All Methods') }}
                                </option>
                                <option value="online">
                                    {{ $t('Online') }}
                                </option>
                                <option value="offline">
                                    {{ $t('Offline') }}
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
                </div>

                <!-- Advanced / clear filters -->
                <div
                    v-if="
                        search ||
                        statusFilter ||
                        refundMethodFilter ||
                        dateFrom ||
                        dateTo ||
                        minAmount ||
                        maxAmount
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
                    class="sticky top-4 z-10 flex items-center justify-between rounded-xl bg-blue-600 p-3 px-6 text-white shadow-lg"
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
                        <!-- Add bulk actions here -->
                    </div>
                </div>
            </transition>

            <!-- Credit Memos Table -->
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
                                    {{ $t('Credit Memo') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase sm:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Order') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase md:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Customer') }}
                                </th>
                                <th
                                    scope="col"
                                    class="px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Status') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase lg:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Method') }}
                                </th>
                                <th
                                    scope="col"
                                    class="px-6 py-4 text-right text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Amount') }}
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
                                v-for="creditMemo in creditMemos.data"
                                :key="creditMemo.id"
                            >
                                <tr
                                    class="group transition-colors hover:bg-blue-50/50 dark:hover:bg-blue-900/10"
                                >
                                    <td class="relative px-6 py-4">
                                        <div class="flex items-center">
                                            <button
                                                @click="
                                                    toggleRow(creditMemo.id)
                                                "
                                                class="absolute left-2 p-1 text-blue-600 hover:text-blue-800 focus:outline-none lg:hidden"
                                            >
                                                <MinusCircle
                                                    v-if="
                                                        expandedRows.includes(
                                                            creditMemo.id,
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
                                                :value="creditMemo.id"
                                                v-model="selectedIds"
                                                class="ml-4 h-4 w-4 cursor-pointer rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 lg:ml-0 dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div
                                            class="text-sm font-bold text-blue-600 dark:text-blue-400"
                                        >
                                            {{ creditMemo.credit_memo_number }}
                                        </div>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap sm:table-cell"
                                    >
                                        <div
                                            class="text-sm text-gray-600 dark:text-gray-300"
                                        >
                                            {{
                                                creditMemo.order
                                                    ?.order_number || '-'
                                            }}
                                        </div>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap md:table-cell"
                                    >
                                        <div class="flex items-center">
                                            <div
                                                class="mr-3 flex h-8 w-8 items-center justify-center rounded-full border border-gray-200 bg-gray-100 text-gray-500 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-400"
                                            >
                                                <User class="h-4 w-4" />
                                            </div>
                                            <div>
                                                <div
                                                    class="text-sm font-medium text-gray-900 dark:text-white"
                                                >
                                                    {{
                                                        creditMemo.order?.user
                                                            ?.name ||
                                                        $t('Guest')
                                                    }}
                                                </div>
                                                <div
                                                    class="text-xs text-gray-500 dark:text-gray-400"
                                                >
                                                    {{
                                                        creditMemo.order
                                                            ?.customer_email
                                                    }}
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <span
                                            :class="[
                                                'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium shadow-sm',
                                                getStatusBadge(
                                                    creditMemo.status,
                                                ),
                                            ]"
                                        >
                                            {{ creditMemo.status }}
                                        </span>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap lg:table-cell"
                                    >
                                        <span
                                            :class="[
                                                'inline-flex items-center rounded border px-2 py-0.5 text-xs font-medium shadow-sm',
                                                getRefundMethodBadge(
                                                    creditMemo.refund_method,
                                                ),
                                            ]"
                                        >
                                            {{ creditMemo.refund_method }}
                                        </span>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right whitespace-nowrap"
                                    >
                                        <div
                                            class="text-sm font-bold text-gray-900 dark:text-white"
                                        >
                                            {{
                                                formatPrice(
                                                    creditMemo.grand_total,
                                                )
                                            }}
                                        </div>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap xl:table-cell"
                                    >
                                        <div
                                            class="text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            <DateDisplay
                                                :value="creditMemo.created_at"
                                            />
                                        </div>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right text-sm font-medium whitespace-nowrap"
                                    >
                                        <div
                                            class="flex items-center justify-end gap-2 opacity-60 transition-opacity group-hover:opacity-100"
                                        >
                                            <button
                                                v-if="
                                                    creditMemo.status ===
                                                    'pending'
                                                "
                                                @click="
                                                    processRefund(creditMemo.id)
                                                "
                                                class="rounded-lg p-2 text-green-600 transition-colors hover:bg-green-50 hover:text-green-800 dark:hover:bg-green-900/20"
                                                :title="$t('Process Refund')"
                                            >
                                                <RefreshCw class="h-4 w-4" />
                                            </button>
                                            <button
                                                @click="
                                                    downloadPdf(creditMemo.id)
                                                "
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-900/20"
                                                :title="$t('Download PDF')"
                                            >
                                                <Download class="h-4 w-4" />
                                            </button>
                                            <button
                                                @click="
                                                    sendEmail(creditMemo.id)
                                                "
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-purple-50 hover:text-purple-600 dark:hover:bg-purple-900/20"
                                                :title="$t('Send Email')"
                                            >
                                                <Mail class="h-4 w-4" />
                                            </button>
                                            <Link
                                                :href="`/admin/sales/credit-memos/${creditMemo.id}`"
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-900/20"
                                                :title="$t('View')"
                                            >
                                                <Eye class="h-4 w-4" />
                                            </Link>
                                        </div>
                                    </td>
                                </tr>
                                <!-- Expanded Mobile Row -->
                                <tr
                                    v-if="expandedRows.includes(creditMemo.id)"
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
                                                <span
                                                    class="text-sm text-gray-600 dark:text-gray-300"
                                                >
                                                    {{
                                                        creditMemo.order
                                                            ?.order_number ||
                                                        '-'
                                                    }}
                                                </span>
                                            </div>
                                            <div
                                                class="flex flex-col gap-2 md:hidden"
                                            >
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Customer') }}</span
                                                >
                                                <div class="flex items-center">
                                                    <div
                                                        class="mr-3 flex h-8 w-8 items-center justify-center rounded-full border border-gray-200 bg-gray-100 text-gray-500 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-400"
                                                    >
                                                        <User class="h-4 w-4" />
                                                    </div>
                                                    <div>
                                                        <div
                                                            class="text-sm font-medium text-gray-900 dark:text-white"
                                                        >
                                                            {{
                                                                creditMemo.order
                                                                    ?.user
                                                                    ?.name ||
                                                                $t('Guest')
                                                            }}
                                                        </div>
                                                        <div
                                                            class="text-xs text-gray-500 dark:text-gray-400"
                                                        >
                                                            {{
                                                                creditMemo.order
                                                                    ?.customer_email
                                                            }}
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                            <div
                                                class="flex flex-col gap-2 lg:hidden"
                                            >
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Details') }}</span
                                                >
                                                <div
                                                    class="grid grid-cols-2 gap-4"
                                                >
                                                    <div>
                                                        <span
                                                            class="block text-xs text-gray-500"
                                                            >{{
                                                                $t('Method')
                                                            }}</span
                                                        >
                                                        <span
                                                            :class="[
                                                                'mt-1 inline-flex items-center rounded border px-2 py-0.5 text-xs font-medium shadow-sm',
                                                                getRefundMethodBadge(
                                                                    creditMemo.refund_method,
                                                                ),
                                                            ]"
                                                        >
                                                            {{
                                                                creditMemo.refund_method
                                                            }}
                                                        </span>
                                                    </div>
                                                    <div>
                                                        <span
                                                            class="block text-xs text-gray-500"
                                                            >{{
                                                                $t('Date')
                                                            }}</span
                                                        >
                                                        <span
                                                            class="mt-1 block text-gray-700 dark:text-gray-300"
                                                            ><DateDisplay
                                                                :value="
                                                                    creditMemo.created_at
                                                                "
                                                        /></span>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                            </template>

                            <tr v-if="creditMemos.data.length === 0">
                                <td
                                    colspan="9"
                                    class="px-6 py-16 text-center text-gray-500 dark:text-gray-400"
                                >
                                    <div class="flex flex-col items-center">
                                        <div
                                            class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-50 text-gray-400 dark:bg-gray-700"
                                        >
                                            <FileText class="h-8 w-8" />
                                        </div>
                                        <p
                                            class="text-lg font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('No credit memos found') }}
                                        </p>
                                        <p
                                            class="mt-1 max-w-sm text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            {{
                                                $t(
                                                    'Try adjusting your filters or create a new one.',
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
                            creditMemos.from || 0
                        }}</span>
                        {{ $t('to') }}
                        <span class="font-medium">{{
                            creditMemos.to || 0
                        }}</span>
                        {{ $t('of') }}
                        <span class="font-medium">{{ creditMemos.total }}</span>
                        {{ $t('results') }}
                    </div>
                    <div class="flex gap-2">
                        <Link
                            v-if="creditMemos.prev_page_url"
                            :href="creditMemos.prev_page_url"
                            class="flex items-center gap-1 rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-xs font-medium text-gray-600 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                        >
                            <ChevronLeft class="h-3 w-3" />
                            {{ $t('Previous') }}
                        </Link>
                        <Link
                            v-if="creditMemos.next_page_url"
                            :href="creditMemos.next_page_url"
                            class="flex items-center gap-1 rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-xs font-medium text-gray-600 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                        >
                            {{ $t('Next') }}
                            <ChevronRight class="h-3 w-3" />
                        </Link>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

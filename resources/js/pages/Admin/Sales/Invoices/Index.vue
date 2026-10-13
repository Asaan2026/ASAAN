<script setup lang="ts">
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import DatePicker from '@/components/Calendar/DatePicker.vue';
import { useCalendar } from '@/composables/useCalendar';
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, Link, router } from '@inertiajs/vue3';
import { debounce } from 'lodash';
import {
    ArrowDown,
    ArrowUp,
    ArrowUpDown,
    CheckCircle,
    Download,
    Eye,
    FileText,
    Filter,
    MinusCircle,
    PlusCircle,
    Printer,
    Search,
    User,
    X,
} from 'lucide-vue-next';
import { computed, ref, watch } from 'vue';

interface Invoice {
    id: number;
    invoice_number: string;
    status: string;
    issue_date: string;
    due_date: string | null;
    total: number;
    order: {
        id: number;
        order_number: string;
        customer_email: string;
        user?: {
            name: string;
        };
    };
}

interface Props {
    invoices: {
        data: Invoice[];
        current_page: number;
        last_page: number;
        per_page: number;
        total: number;
    };
    filters: {
        search?: string;
        status?: string;
        date_from?: string;
        date_to?: string;
        min_amount?: number;
        max_amount?: number;
        sort_by?: string;
        sort_order?: 'asc' | 'desc';
    };
    statuses: Array<{ value: string; label: string }>;
}

const props = defineProps<Props>();
const { formatPrice } = useCurrency();
const { formatDate: formatCalendarDate } = useCalendar();

const search = ref(props.filters.search || '');
const statusFilter = ref(props.filters.status || '');
const dateFrom = ref(props.filters.date_from || '');
const dateTo = ref(props.filters.date_to || '');
const sortBy = ref(props.filters.sort_by || 'issue_date');
const sortOrder = ref(props.filters.sort_order || 'desc');

// Bulk actions state
const selectAll = ref(false);
const selectedIds = ref<number[]>([]);
const expandedRows = ref<number[]>([]);

const performSearch = debounce(() => {
    applyFilters();
}, 300);

const applyFilters = () => {
    router.get(
        '/admin/sales/invoices',
        {
            search: search.value,
            status: statusFilter.value,
            date_from: dateFrom.value,
            date_to: dateTo.value,
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
    statusFilter.value = '';
    dateFrom.value = '';
    dateTo.value = '';
    applyFilters();
};

const sortTable = (field: string) => {
    if (sortBy.value === field) {
        sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
    } else {
        sortBy.value = field;
        sortOrder.value = 'asc';
    }
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
        selectedIds.value.length < props.invoices.data.length
    );
});

watch(selectAll, (value) => {
    if (value) {
        selectedIds.value = props.invoices.data.map((i) => i.id);
    } else {
        selectedIds.value = [];
    }
});

const exportInvoices = () => {
    // TODO: implement export
};

const getStatusBadge = (status: string) => {
    const badges: Record<string, string> = {
        pending:
            'bg-yellow-50 text-yellow-700 border-yellow-200 dark:bg-yellow-900/20 dark:text-yellow-300 dark:border-yellow-800',
        sent: 'bg-blue-50 text-blue-700 border-blue-200 dark:bg-blue-900/20 dark:text-blue-300 dark:border-blue-800',
        paid: 'bg-green-50 text-green-700 border-green-200 dark:bg-green-900/20 dark:text-green-300 dark:border-green-800',
        cancelled:
            'bg-red-50 text-red-700 border-red-200 dark:bg-red-900/20 dark:text-red-300 dark:border-red-800',
    };
    return badges[status] || badges.pending;
};
</script>

<template>
    <Head :title="$t('Invoices')" />

    <AdminLayout :title="$t('Invoices')">
        <div class="space-y-6 p-6">
            <!-- Page Header -->
            <div
                class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
            >
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Invoices') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                        {{ $t('Manage customer invoices and payments') }}
                    </p>
                </div>
                <div class="flex gap-2">
                    <button
                        @click="exportInvoices"
                        class="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-200 dark:hover:bg-gray-700"
                    >
                        <Download class="h-4 w-4" />
                        {{ $t('Export') }}
                    </button>
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
                                :placeholder="$t('Invoice #, Order #...')"
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
                </div>

                <!-- Clear Filters -->
                <div
                    v-if="search || statusFilter || dateFrom || dateTo"
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
                        <button
                            class="flex items-center gap-2 rounded-lg bg-white px-3 py-1.5 text-xs font-bold tracking-wide text-blue-600 uppercase transition-colors hover:bg-blue-50"
                        >
                            <Printer class="h-3 w-3" />
                            {{ $t('Print') }}
                        </button>
                        <button
                            class="flex items-center gap-2 rounded-lg bg-white px-3 py-1.5 text-xs font-bold tracking-wide text-blue-600 uppercase transition-colors hover:bg-blue-50"
                        >
                            <Download class="h-3 w-3" />
                            {{ $t('Download PDF') }}
                        </button>
                    </div>
                </div>
            </transition>

            <!-- Invoices Table -->
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
                                    class="group cursor-pointer px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase transition-colors hover:text-blue-600 dark:text-gray-400 dark:hover:text-blue-400"
                                    @click="sortTable('invoice_number')"
                                >
                                    <div class="flex items-center gap-1">
                                        {{ $t('Invoice #') }}
                                        <span
                                            v-if="sortBy === 'invoice_number'"
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
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase sm:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Order #') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase md:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Customer') }}
                                </th>
                                <th
                                    scope="col"
                                    class="group hidden cursor-pointer px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase transition-colors hover:text-blue-600 lg:table-cell dark:text-gray-400 dark:hover:text-blue-400"
                                    @click="sortTable('issue_date')"
                                >
                                    <div class="flex items-center gap-1">
                                        {{ $t('Issue Date') }}
                                        <span
                                            v-if="sortBy === 'issue_date'"
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
                                    class="px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Status') }}
                                </th>
                                <th
                                    scope="col"
                                    class="group cursor-pointer px-6 py-4 text-right text-xs font-semibold tracking-wider text-gray-500 uppercase transition-colors hover:text-blue-600 dark:text-gray-400 dark:hover:text-blue-400"
                                    @click="sortTable('total')"
                                >
                                    <div
                                        class="flex items-center justify-end gap-1"
                                    >
                                        {{ $t('Total') }}
                                        <span
                                            v-if="sortBy === 'total'"
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
                                v-for="invoice in invoices.data"
                                :key="invoice.id"
                            >
                                <tr
                                    class="group transition-colors hover:bg-blue-50/50 dark:hover:bg-blue-900/10"
                                >
                                    <td class="relative px-6 py-4">
                                        <div class="flex items-center">
                                            <button
                                                @click="toggleRow(invoice.id)"
                                                class="absolute left-2 p-1 text-blue-600 hover:text-blue-800 focus:outline-none lg:hidden"
                                            >
                                                <MinusCircle
                                                    v-if="
                                                        expandedRows.includes(
                                                            invoice.id,
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
                                                :value="invoice.id"
                                                v-model="selectedIds"
                                                class="ml-4 h-4 w-4 cursor-pointer rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 lg:ml-0 dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div class="flex flex-col">
                                            <Link
                                                :href="`/admin/sales/invoices/${invoice.id}`"
                                                class="text-sm font-bold text-blue-600 hover:text-blue-800 hover:underline dark:text-blue-400 dark:hover:text-blue-300"
                                            >
                                                {{ invoice.invoice_number }}
                                            </Link>
                                            <span
                                                v-if="invoice.due_date"
                                                class="mt-0.5 text-xs text-gray-500 dark:text-gray-400"
                                                >{{
                                                    $t('Due: {date}', {
                                                        date: formatCalendarDate(
                                                            invoice.due_date,
                                                        ),
                                                    })
                                                }}</span
                                            >
                                        </div>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap sm:table-cell"
                                    >
                                        <Link
                                            :href="`/admin/sales/orders/${invoice.order.id}`"
                                            class="text-sm text-gray-600 hover:text-blue-600 hover:underline dark:text-gray-300"
                                        >
                                            {{ invoice.order.order_number }}
                                        </Link>
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
                                                        invoice.order.user
                                                            ?.name ||
                                                        $t('Guest')
                                                    }}
                                                </div>
                                                <div
                                                    class="text-xs text-gray-500 dark:text-gray-400"
                                                >
                                                    {{
                                                        invoice.order
                                                            .customer_email
                                                    }}
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap lg:table-cell"
                                    >
                                        <div
                                            class="text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            <DateDisplay
                                                :value="invoice.issue_date"
                                            />
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <span
                                            :class="[
                                                'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium shadow-sm',
                                                getStatusBadge(invoice.status),
                                            ]"
                                        >
                                            {{ invoice.status }}
                                        </span>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right whitespace-nowrap"
                                    >
                                        <div
                                            class="text-sm font-bold text-gray-900 dark:text-white"
                                        >
                                            {{ formatPrice(invoice.total) }}
                                        </div>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right text-sm font-medium whitespace-nowrap"
                                    >
                                        <div
                                            class="flex items-center justify-end gap-2 opacity-60 transition-opacity group-hover:opacity-100"
                                        >
                                            <Link
                                                :href="`/admin/sales/invoices/${invoice.id}`"
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-900/20"
                                                :title="$t('View Invoice')"
                                            >
                                                <Eye class="h-4 w-4" />
                                            </Link>
                                        </div>
                                    </td>
                                </tr>
                                <!-- Expanded Mobile Row -->
                                <tr
                                    v-if="expandedRows.includes(invoice.id)"
                                    class="bg-gray-50/50 lg:hidden dark:bg-gray-900/50"
                                >
                                    <td
                                        colspan="8"
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
                                                    :href="`/admin/sales/orders/${invoice.order.id}`"
                                                    class="flex items-center gap-2 text-sm text-gray-600 hover:text-blue-600 hover:underline dark:text-gray-300"
                                                >
                                                    <FileText class="h-4 w-4" />
                                                    {{
                                                        invoice.order
                                                            .order_number
                                                    }}
                                                </Link>
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
                                                                invoice.order
                                                                    .user
                                                                    ?.name ||
                                                                $t('Guest')
                                                            }}
                                                        </div>
                                                        <div
                                                            class="text-xs text-gray-500 dark:text-gray-400"
                                                        >
                                                            {{
                                                                invoice.order
                                                                    .customer_email
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
                                                    >{{ $t('Dates') }}</span
                                                >
                                                <div
                                                    class="grid grid-cols-2 gap-2"
                                                >
                                                    <div>
                                                        <span
                                                            class="block text-xs text-gray-500"
                                                            >{{
                                                                $t('Issued')
                                                            }}</span
                                                        >
                                                        <span
                                                            class="text-gray-700 dark:text-gray-300"
                                                            ><DateDisplay
                                                                :value="
                                                                    invoice.issue_date
                                                                "
                                                        /></span>
                                                    </div>
                                                    <div
                                                        v-if="invoice.due_date"
                                                    >
                                                        <span
                                                            class="block text-xs text-gray-500"
                                                            >{{
                                                                $t('Due')
                                                            }}</span
                                                        >
                                                        <span
                                                            class="text-gray-700 dark:text-gray-300"
                                                            ><DateDisplay
                                                                :value="
                                                                    invoice.due_date
                                                                "
                                                        /></span>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                            </template>

                            <tr v-if="invoices.data.length === 0">
                                <td
                                    colspan="8"
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
                                            {{ $t('No invoices found') }}
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
                    v-if="invoices.data.length > 0"
                    class="border-t border-gray-200 bg-white px-4 py-3 sm:px-6 dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="flex items-center justify-between">
                        <div class="text-sm text-gray-700 dark:text-gray-300">
                            {{ $t('Showing') }}
                            <span class="font-medium">{{
                                (invoices.current_page - 1) *
                                    invoices.per_page +
                                1
                            }}</span>
                            {{ $t('to') }}
                            <span class="font-medium">{{
                                Math.min(
                                    invoices.current_page * invoices.per_page,
                                    invoices.total,
                                )
                            }}</span>
                            {{ $t('of') }}
                            <span class="font-medium">{{
                                invoices.total
                            }}</span>
                            {{ $t('results') }}
                        </div>
                        <div class="flex space-x-2">
                            <button
                                v-if="invoices.current_page > 1"
                                @click="
                                    router.get('/admin/sales/invoices', {
                                        ...filters,
                                        page: invoices.current_page - 1,
                                    })
                                "
                                class="rounded-lg border border-gray-300 bg-white px-3 py-1 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600"
                            >
                                {{ $t('Previous') }}
                            </button>
                            <button
                                v-if="
                                    invoices.current_page < invoices.last_page
                                "
                                @click="
                                    router.get('/admin/sales/invoices', {
                                        ...filters,
                                        page: invoices.current_page + 1,
                                    })
                                "
                                class="rounded-lg border border-gray-300 bg-white px-3 py-1 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600"
                            >
                                {{ $t('Next') }}
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

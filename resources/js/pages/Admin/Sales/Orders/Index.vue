<script setup lang="ts">
import Pagination from '@/components/Admin/Pagination.vue';
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import DatePicker from '@/components/Calendar/DatePicker.vue';
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, Link, router } from '@inertiajs/vue3';
import { debounce } from 'lodash';
import {
    ArrowDown,
    ArrowUp,
    ArrowUpDown,
    Calendar,
    CheckCircle,
    CreditCard,
    Download,
    Eye,
    Filter,
    MinusCircle,
    Plus,
    PlusCircle,
    Search,
    ShoppingBag,
    User,
    X,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

interface Order {
    id: number;
    order_number: string;
    user?: {
        id: number;
        name: string;
        email: string;
    };
    customer_email: string;
    status: string;
    payment_status: string;
    payment_method: string;
    shipping_method: string;
    total: number;
    created_at: string;
    items_count?: number;
}

interface Props {
    orders: {
        data: Order[];
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
        payment_status?: string;
        payment_method?: string;
        date_from?: string;
        date_to?: string;
        sort_by?: string;
        sort_order?: string;
    };
    statuses: Array<{ value: string; label: string }>;
    paymentStatuses: Array<{ value: string; label: string }>;
}

const props = defineProps<Props>();

const { formatPrice } = useCurrency();

const selectedOrders = ref<number[]>([]);
const search = ref(props.filters.search || '');
const statusFilter = ref(props.filters.status || '');
const paymentStatusFilter = ref(props.filters.payment_status || '');
const paymentMethodFilter = ref(props.filters.payment_method || '');
const dateFrom = ref(props.filters.date_from || '');
const dateTo = ref(props.filters.date_to || '');
const sortBy = ref(props.filters.sort_by || 'created_at');
const sortOrder = ref(props.filters.sort_order || 'desc');

const showBulkModal = ref(false);
const bulkStatus = ref('');
const bulkNotifyCustomer = ref(false);
const expandedRows = ref<number[]>([]);

const selectAll = computed({
    get: () =>
        selectedOrders.value.length === props.orders.data.length &&
        props.orders.data.length > 0,
    set: (value: boolean) => {
        selectedOrders.value = value ? props.orders.data.map((o) => o.id) : [];
    },
});

const someSelected = computed(() => {
    return (
        selectedOrders.value.length > 0 &&
        selectedOrders.value.length < props.orders.data.length
    );
});

function toggleRow(id: number) {
    if (expandedRows.value.includes(id)) {
        expandedRows.value = expandedRows.value.filter((rowId) => rowId !== id);
    } else {
        expandedRows.value.push(id);
    }
}

const performSearch = debounce(() => {
    applyFilters();
}, 300);

function applyFilters() {
    router.get(
        '/admin/sales/orders',
        {
            search: search.value || undefined,
            status: statusFilter.value || undefined,
            payment_status: paymentStatusFilter.value || undefined,
            payment_method: paymentMethodFilter.value || undefined,
            date_from: dateFrom.value || undefined,
            date_to: dateTo.value || undefined,
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
    paymentStatusFilter.value = '';
    paymentMethodFilter.value = '';
    dateFrom.value = '';
    dateTo.value = '';
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

function openBulkModal() {
    if (selectedOrders.value.length === 0) return;
    showBulkModal.value = true;
}

function bulkUpdateStatus() {
    if (!bulkStatus.value || selectedOrders.value.length === 0) return;

    router.post(
        '/admin/sales/orders/bulk/status',
        {
            order_ids: selectedOrders.value,
            status: bulkStatus.value,
            notify_customer: bulkNotifyCustomer.value,
        },
        {
            preserveScroll: true,
            onSuccess: () => {
                selectedOrders.value = [];
                showBulkModal.value = false;
                bulkStatus.value = '';
                bulkNotifyCustomer.value = false;
            },
        },
    );
}

function exportOrders() {
    window.location.href = `/admin/sales/orders/export/csv?${new URLSearchParams(
        {
            search: search.value || '',
            status: statusFilter.value || '',
            payment_status: paymentStatusFilter.value || '',
            date_from: dateFrom.value || '',
            date_to: dateTo.value || '',
        },
    ).toString()}`;
}

function getStatusBadge(status: string): string {
    const badges: Record<string, string> = {
        pending:
            'bg-yellow-50 text-yellow-700 border-yellow-200 dark:bg-yellow-900/20 dark:text-yellow-300 dark:border-yellow-800',
        processing:
            'bg-blue-50 text-blue-700 border-blue-200 dark:bg-blue-900/20 dark:text-blue-300 dark:border-blue-800',
        completed:
            'bg-green-50 text-green-700 border-green-200 dark:bg-green-900/20 dark:text-green-300 dark:border-green-800',
        cancelled:
            'bg-red-50 text-red-700 border-red-200 dark:bg-red-900/20 dark:text-red-300 dark:border-red-800',
        refunded:
            'bg-purple-50 text-purple-700 border-purple-200 dark:bg-purple-900/20 dark:text-purple-300 dark:border-purple-800',
        failed: 'bg-gray-50 text-gray-700 border-gray-200 dark:bg-gray-700 dark:text-gray-300 dark:border-gray-600',
    };
    return badges[status] || badges.pending;
}

function getPaymentStatusBadge(status: string): string {
    const badges: Record<string, string> = {
        pending:
            'bg-yellow-50 text-yellow-700 border-yellow-200 dark:bg-yellow-900/20 dark:text-yellow-300 dark:border-yellow-800',
        paid: 'bg-green-50 text-green-700 border-green-200 dark:bg-green-900/20 dark:text-green-300 dark:border-green-800',
        failed: 'bg-red-50 text-red-700 border-red-200 dark:bg-red-900/20 dark:text-red-300 dark:border-red-800',
        refunded:
            'bg-purple-50 text-purple-700 border-purple-200 dark:bg-purple-900/20 dark:text-purple-300 dark:border-purple-800',
    };
    return badges[status] || badges.pending;
}
</script>

<template>
    <Head :title="$t('Orders')" />

    <AdminLayout :title="$t('Orders')">
        <div class="space-y-6 p-6">
            <!-- Page Header -->
            <div
                class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
            >
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Orders') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                        {{ $t('Manage customer orders and shipments') }}
                    </p>
                </div>
                <div class="flex gap-2">
                    <button
                        @click="exportOrders"
                        class="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-200 dark:hover:bg-gray-700"
                    >
                        <Download class="h-4 w-4" />
                        {{ $t('Export') }}
                    </button>
                    <Link
                        href="/admin/sales/orders/create"
                        class="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700"
                    >
                        <Plus class="h-4 w-4" />
                        {{ $t('Create Order') }}
                    </Link>
                </div>
            </div>

            <!-- Filters Card -->
            <div
                class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div
                    class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-6"
                >
                    <!-- Search -->
                    <div class="lg:col-span-2">
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
                                :placeholder="$t('Order #, email, customer...')"
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
                                <option value="">{{ $t('All Status') }}</option>
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

                    <!-- Payment Status Filter -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Payment') }}</label
                        >
                        <div class="relative">
                            <div
                                class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3"
                            >
                                <CreditCard class="h-4 w-4 text-gray-400" />
                            </div>
                            <select
                                v-model="paymentStatusFilter"
                                @change="applyFilters"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-10 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            >
                                <option value="">
                                    {{ $t('All Payments') }}
                                </option>
                                <option
                                    v-for="status in paymentStatuses"
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
                    v-if="
                        search ||
                        statusFilter ||
                        paymentStatusFilter ||
                        dateFrom ||
                        dateTo
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
                    v-if="selectedOrders.length > 0"
                    class="sticky top-4 z-10 flex items-center justify-between rounded-xl bg-blue-600 p-3 px-6 text-white shadow-lg"
                >
                    <span class="flex items-center text-sm font-semibold">
                        <CheckCircle class="mr-2 h-4 w-4" />
                        {{
                            selectedOrders.length === 1
                                ? $t('{count} order selected', {
                                      count: selectedOrders.length,
                                  })
                                : $t('{count} orders selected', {
                                      count: selectedOrders.length,
                                  })
                        }}
                    </span>
                    <div class="flex gap-2">
                        <button
                            @click="openBulkModal"
                            class="rounded-lg bg-white px-3 py-1.5 text-xs font-bold tracking-wide text-blue-600 uppercase transition-colors hover:bg-blue-50"
                        >
                            {{ $t('Update Status') }}
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
                                        v-model="selectAll"
                                        :indeterminate.prop="someSelected"
                                        class="h-4 w-4 rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </th>
                                <th
                                    scope="col"
                                    class="group cursor-pointer px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase transition-colors hover:text-blue-600 dark:text-gray-400 dark:hover:text-blue-400"
                                    @click="sortTable('order_number')"
                                >
                                    <div class="flex items-center gap-1">
                                        {{ $t('Order #') }}
                                        <span
                                            v-if="sortBy === 'order_number'"
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
                                    {{ $t('Payment') }}
                                </th>
                                <th
                                    scope="col"
                                    class="group cursor-pointer px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase transition-colors hover:text-blue-600 dark:text-gray-400 dark:hover:text-blue-400"
                                    @click="sortTable('total')"
                                >
                                    <div class="flex items-center gap-1">
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
                                    class="group hidden cursor-pointer px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase transition-colors hover:text-blue-600 sm:table-cell dark:text-gray-400 dark:hover:text-blue-400"
                                    @click="sortTable('created_at')"
                                >
                                    <div class="flex items-center gap-1">
                                        {{ $t('Date') }}
                                        <span
                                            v-if="sortBy === 'created_at'"
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
                                v-for="order in orders.data"
                                :key="order.id"
                            >
                                <tr
                                    class="group transition-colors hover:bg-blue-50/50 dark:hover:bg-blue-900/10"
                                >
                                    <td class="relative px-6 py-4">
                                        <div class="flex items-center">
                                            <button
                                                @click="toggleRow(order.id)"
                                                class="absolute left-2 p-1 text-blue-600 hover:text-blue-800 focus:outline-none lg:hidden"
                                            >
                                                <MinusCircle
                                                    v-if="
                                                        expandedRows.includes(
                                                            order.id,
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
                                                :value="order.id"
                                                v-model="selectedOrders"
                                                class="ml-4 h-4 w-4 cursor-pointer rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 lg:ml-0 dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div class="flex flex-col">
                                            <Link
                                                :href="`/admin/sales/orders/${order.id}`"
                                                class="text-sm font-bold text-blue-600 hover:text-blue-800 hover:underline dark:text-blue-400 dark:hover:text-blue-300"
                                            >
                                                {{ order.order_number }}
                                            </Link>
                                            <span
                                                class="mt-0.5 text-xs text-gray-500 dark:text-gray-400"
                                                >{{ order.items_count || 1 }}
                                                {{ $t('items') }}</span
                                            >
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
                                                        order.user?.name ||
                                                        $t('Guest')
                                                    }}
                                                </div>
                                                <div
                                                    class="text-xs text-gray-500 dark:text-gray-400"
                                                >
                                                    {{ order.customer_email }}
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <span
                                            :class="[
                                                'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium shadow-sm',
                                                getStatusBadge(order.status),
                                            ]"
                                        >
                                            {{ order.status }}
                                        </span>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap lg:table-cell"
                                    >
                                        <div class="flex flex-col gap-1">
                                            <span
                                                :class="[
                                                    'inline-flex w-fit items-center rounded px-2 py-0.5 text-xs font-medium',
                                                    getPaymentStatusBadge(
                                                        order.payment_status,
                                                    ),
                                                ]"
                                            >
                                                {{ order.payment_status }}
                                            </span>
                                            <span
                                                class="text-xs text-gray-500 dark:text-gray-400"
                                                >{{
                                                    order.payment_method
                                                }}</span
                                            >
                                        </div>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-sm font-bold whitespace-nowrap text-gray-900 dark:text-white"
                                    >
                                        {{ formatPrice(order.total) }}
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 text-sm whitespace-nowrap text-gray-500 sm:table-cell dark:text-gray-400"
                                    >
                                        <div class="flex items-center gap-1.5">
                                            <Calendar
                                                class="h-3.5 w-3.5 text-gray-400"
                                            />
                                            <DateDisplay
                                                :value="order.created_at"
                                            />
                                        </div>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right text-sm font-medium whitespace-nowrap"
                                    >
                                        <div
                                            class="flex items-center justify-end gap-2 opacity-60 transition-opacity group-hover:opacity-100"
                                        >
                                            <Link
                                                :href="`/admin/sales/orders/${order.id}`"
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-900/20"
                                                :title="$t('View Order')"
                                            >
                                                <Eye class="h-4 w-4" />
                                            </Link>
                                        </div>
                                    </td>
                                </tr>
                                <!-- Expanded Mobile Row -->
                                <tr
                                    v-if="expandedRows.includes(order.id)"
                                    class="bg-gray-50/50 lg:hidden dark:bg-gray-900/50"
                                >
                                    <td
                                        colspan="8"
                                        class="border-t border-gray-100 px-6 py-4 dark:border-gray-700"
                                    >
                                        <div
                                            class="grid grid-cols-1 gap-4 text-sm md:grid-cols-2"
                                        >
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
                                                                order.user
                                                                    ?.name ||
                                                                $t('Guest')
                                                            }}
                                                        </div>
                                                        <div
                                                            class="text-xs text-gray-500 dark:text-gray-400"
                                                        >
                                                            {{
                                                                order.customer_email
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
                                                    >{{ $t('Payment') }}</span
                                                >
                                                <div
                                                    class="flex items-center gap-3"
                                                >
                                                    <div class="flex flex-col">
                                                        <span
                                                            class="mb-0.5 text-xs text-gray-500"
                                                            >{{
                                                                $t('Status')
                                                            }}</span
                                                        >
                                                        <span
                                                            :class="[
                                                                'inline-flex w-fit items-center rounded px-2 py-0.5 text-xs font-medium',
                                                                getPaymentStatusBadge(
                                                                    order.payment_status,
                                                                ),
                                                            ]"
                                                        >
                                                            {{
                                                                order.payment_status
                                                            }}
                                                        </span>
                                                    </div>
                                                    <div class="flex flex-col">
                                                        <span
                                                            class="mb-0.5 text-xs text-gray-500"
                                                            >{{
                                                                $t('Method')
                                                            }}</span
                                                        >
                                                        <span
                                                            class="font-medium text-gray-700 dark:text-gray-300"
                                                            >{{
                                                                order.payment_method
                                                            }}</span
                                                        >
                                                    </div>
                                                </div>
                                            </div>
                                            <div
                                                class="flex flex-col gap-1 sm:hidden"
                                            >
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Date') }}</span
                                                >
                                                <div
                                                    class="flex items-center gap-1.5 text-gray-700 dark:text-gray-300"
                                                >
                                                    <Calendar
                                                        class="h-3.5 w-3.5 text-gray-400"
                                                    />
                                                    <DateDisplay
                                                        :value="
                                                            order.created_at
                                                        "
                                                    />
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                            </template>
                            <tr v-if="orders.data.length === 0">
                                <td
                                    colspan="8"
                                    class="px-6 py-16 text-center text-gray-500 dark:text-gray-400"
                                >
                                    <div class="flex flex-col items-center">
                                        <div
                                            class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-50 text-gray-400 dark:bg-gray-700"
                                        >
                                            <ShoppingBag class="h-8 w-8" />
                                        </div>
                                        <p
                                            class="text-lg font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('No orders found') }}
                                        </p>
                                        <p
                                            class="mt-1 max-w-sm text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            {{
                                                $t(
                                                    'Try adjusting your filters or create a new order.',
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
                <Pagination :data="orders" resource-name="orders" />
            </div>
        </div>

        <!-- Bulk Update Modal -->
        <div v-if="showBulkModal" class="fixed inset-0 z-50 overflow-y-auto">
            <div
                class="flex min-h-screen items-center justify-center px-4 pt-4 pb-20 text-center sm:block sm:p-0"
            >
                <div
                    class="fixed inset-0 bg-gray-500/75 transition-opacity dark:bg-gray-900/75"
                    @click="showBulkModal = false"
                ></div>
                <div
                    class="inline-block transform overflow-hidden rounded-lg bg-white text-left align-bottom shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg sm:align-middle dark:bg-gray-800"
                >
                    <div
                        class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4 dark:bg-gray-800"
                    >
                        <h3
                            class="mb-4 text-lg font-medium text-gray-900 dark:text-white"
                        >
                            {{ $t('Bulk Update Status') }}
                        </h3>
                        <div class="space-y-4">
                            <div>
                                <label
                                    class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('New Status') }}</label
                                >
                                <select
                                    v-model="bulkStatus"
                                    class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                >
                                    <option value="">
                                        {{ $t('Select status...') }}
                                    </option>
                                    <option
                                        v-for="status in statuses"
                                        :key="status.value"
                                        :value="status.value"
                                    >
                                        {{ status.label }}
                                    </option>
                                </select>
                            </div>
                            <div class="flex items-center">
                                <input
                                    type="checkbox"
                                    v-model="bulkNotifyCustomer"
                                    class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                />
                                <label
                                    class="ml-2 text-sm text-gray-700 dark:text-gray-300"
                                    >{{ $t('Notify customers') }}</label
                                >
                            </div>
                        </div>
                    </div>
                    <div
                        class="border-t border-gray-200 bg-gray-50 px-4 py-3 sm:flex sm:flex-row-reverse sm:px-6 dark:border-gray-700 dark:bg-gray-700/50"
                    >
                        <button
                            @click="bulkUpdateStatus"
                            :disabled="!bulkStatus"
                            class="inline-flex w-full justify-center rounded-md border border-transparent bg-blue-600 px-4 py-2 text-base font-medium text-white shadow-sm hover:bg-blue-700 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50 sm:ml-3 sm:w-auto sm:text-sm"
                        >
                            {{ $t('Update Orders') }}
                        </button>
                        <button
                            @click="showBulkModal = false"
                            class="mt-3 inline-flex w-full justify-center rounded-md border border-gray-300 bg-white px-4 py-2 text-base font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                        >
                            {{ $t('Cancel') }}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

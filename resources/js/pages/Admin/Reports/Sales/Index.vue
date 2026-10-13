<script setup lang="ts">
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import DatePicker from '@/components/Calendar/DatePicker.vue';
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, router } from '@inertiajs/vue3';
import {
    ArcElement,
    BarElement,
    CategoryScale,
    Chart as ChartJS,
    Filler,
    Legend,
    LinearScale,
    LineElement,
    PointElement,
    Title,
    Tooltip,
} from 'chart.js';
import {
    ChevronDown,
    CreditCard,
    DollarSign,
    Download,
    Filter,
    RefreshCw,
    ShoppingCart,
    TrendingUp,
} from 'lucide-vue-next';
import { ref } from 'vue';
import { Bar, Doughnut, Line } from 'vue-chartjs';

// Register Chart.js components
ChartJS.register(
    CategoryScale,
    LinearScale,
    PointElement,
    LineElement,
    BarElement,
    Title,
    Tooltip,
    Legend,
    ArcElement,
    Filler,
);

interface Statistics {
    total_revenue: number;
    order_count: number;
    avg_order_value: number;
    growth_percentage: number;
}

interface ChartData {
    labels: string[];
    datasets: any[];
}

interface Order {
    id: number;
    increment_id: number | string;
    customer_name: string;
    total: string | number;
    status: string;
    created_at: string;
}

interface Filters {
    start_date: string;
    end_date: string;
    status?: string[];
    payment_method?: string;
}

interface Props {
    statistics: Statistics;
    revenueChart: ChartData;
    ordersChart: ChartData;
    paymentChart: ChartData;
    topOrders: Order[];
    filters: Filters;
}

const props = defineProps<Props>();

// Filters
const startDate = ref(props.filters.start_date);
const endDate = ref(props.filters.end_date);
const statusFilter = ref(props.filters.status?.[0] || '');

// Apply filters
const applyFilters = () => {
    router.get(
        '/admin/reports/sales',
        {
            start_date: startDate.value,
            end_date: endDate.value,
            status: statusFilter.value || undefined,
        },
        {
            preserveState: true,
            preserveScroll: true,
        },
    );
};

// Clear filters
const clearFilters = () => {
    startDate.value = '';
    endDate.value = '';
    statusFilter.value = '';
    applyFilters();
};

// Chart options
const lineChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
        legend: {
            display: true,
            position: 'top' as const,
        },
        tooltip: {
            mode: 'index' as const,
            intersect: false,
        },
    },
    scales: {
        y: {
            beginAtZero: true,
            ticks: {
                callback: function (value: any) {
                    const { formatPrice } = useCurrency();
                    return formatPrice(value);
                },
            },
        },
    },
};

const barChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
        legend: {
            display: false,
        },
    },
};

const doughnutChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
        legend: {
            position: 'right' as const,
        },
    },
};

// Format currency
const { formatPrice: formatCurrency } = useCurrency();

// Status badge classes
const getStatusClass = (status: string) => {
    const classes: Record<string, string> = {
        completed:
            'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300',
        processing:
            'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300',
        pending:
            'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300',
        cancelled:
            'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300',
        refunded: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300',
    };
    return classes[status] || 'bg-gray-100 text-gray-800';
};
</script>

<template>
    <Head :title="$t('Sales Reports')" />
    <AdminLayout :title="$t('Sales Reports')">
        <div class="space-y-6">
            <!-- Header -->
            <div
                class="flex flex-col justify-between gap-4 md:flex-row md:items-center"
            >
                <div>
                    <h1
                        class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white"
                    >
                        {{ $t('Sales Reports') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                        {{
                            $t(
                                'Track revenue, orders, and financial performance',
                            )
                        }}
                    </p>
                </div>
                <div class="flex items-center gap-3">
                    <button
                        class="flex items-center gap-2 rounded-lg border border-gray-200 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm transition-colors hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-200 dark:hover:bg-gray-700"
                    >
                        <Download :size="16" />
                        {{ $t('Export Report') }}
                    </button>
                    <button
                        @click="router.reload()"
                        class="rounded-lg border border-gray-200 bg-white p-2 text-gray-500 shadow-sm transition-colors hover:bg-gray-50 hover:text-gray-700 dark:border-gray-700 dark:bg-gray-800 dark:hover:bg-gray-700 dark:hover:text-gray-300"
                        :title="$t('Refresh')"
                    >
                        <RefreshCw :size="18" />
                    </button>
                </div>
            </div>

            <!-- Filters Bar -->
            <div
                class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div class="grid grid-cols-1 gap-4 md:grid-cols-4">
                    <!-- Start Date -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Start Date') }}</label
                        >
                        <DatePicker
                            v-model="startDate"
                            class="w-full rounded-lg border border-gray-200 bg-gray-50 px-4 py-2.5 text-sm transition-colors focus:border-blue-500 focus:ring-2 focus:ring-blue-100 dark:border-gray-600 dark:bg-gray-700/50"
                        />
                    </div>

                    <!-- End Date -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('End Date') }}</label
                        >
                        <DatePicker
                            v-model="endDate"
                            class="w-full rounded-lg border border-gray-200 bg-gray-50 px-4 py-2.5 text-sm transition-colors focus:border-blue-500 focus:ring-2 focus:ring-blue-100 dark:border-gray-600 dark:bg-gray-700/50"
                        />
                    </div>

                    <!-- Status Filter -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Order Status') }}</label
                        >
                        <div class="relative">
                            <Filter
                                :size="16"
                                class="pointer-events-none absolute top-1/2 left-3 -translate-y-1/2 text-gray-400"
                            />
                            <select
                                v-model="statusFilter"
                                class="w-full appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-4 pl-10 text-sm transition-colors focus:border-blue-500 focus:ring-2 focus:ring-blue-100 dark:border-gray-600 dark:bg-gray-700/50"
                            >
                                <option value="">
                                    {{ $t('All Statuses') }}
                                </option>
                                <option value="completed">
                                    {{ $t('Completed') }}
                                </option>
                                <option value="processing">
                                    {{ $t('Processing') }}
                                </option>
                                <option value="pending">
                                    {{ $t('Pending') }}
                                </option>
                                <option value="cancelled">
                                    {{ $t('Cancelled') }}
                                </option>
                            </select>
                            <ChevronDown
                                :size="16"
                                class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2 text-gray-400"
                            />
                        </div>
                    </div>

                    <!-- Apply Button -->
                    <div class="flex items-end gap-2">
                        <button
                            @click="applyFilters"
                            class="flex-1 rounded-lg bg-blue-600 px-4 py-2.5 font-medium text-white shadow-sm shadow-blue-600/20 transition-all hover:bg-blue-700 focus:ring-4 focus:ring-blue-500/20"
                        >
                            {{ $t('Apply Filters') }}
                        </button>
                        <button
                            v-if="startDate || endDate || statusFilter"
                            @click="clearFilters"
                            class="rounded-lg px-4 py-2.5 text-sm font-medium text-gray-600 transition-colors hover:bg-gray-100 hover:text-gray-900 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-gray-200"
                        >
                            {{ $t('Clear') }}
                        </button>
                    </div>
                </div>
            </div>

            <!-- Statistics Cards -->
            <div
                class="mb-8 grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4"
            >
                <!-- Total Revenue -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-all hover:shadow-md dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="flex items-start justify-between">
                        <div>
                            <p
                                class="mb-1 text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Total Revenue') }}
                            </p>
                            <h3
                                class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white"
                            >
                                {{ formatCurrency(statistics.total_revenue) }}
                            </h3>
                            <div
                                v-if="statistics.growth_percentage !== 0"
                                class="mt-2.5 flex items-center"
                            >
                                <span
                                    :class="[
                                        'flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium',
                                        statistics.growth_percentage > 0
                                            ? 'bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                                            : 'bg-red-50 text-red-700 dark:bg-red-900/30 dark:text-red-400',
                                    ]"
                                >
                                    <TrendingUp
                                        :size="12"
                                        v-if="statistics.growth_percentage > 0"
                                    />
                                    <TrendingUp
                                        :size="12"
                                        class="rotate-180 transform"
                                        v-else
                                    />
                                    {{
                                        statistics.growth_percentage > 0
                                            ? '+'
                                            : ''
                                    }}{{
                                        statistics.growth_percentage.toFixed(1)
                                    }}%
                                </span>
                                <span class="ml-1.5 text-xs text-gray-400">{{
                                    $t('vs last period')
                                }}</span>
                            </div>
                        </div>
                        <div
                            class="rounded-xl bg-blue-50 p-3 dark:bg-blue-900/20"
                        >
                            <DollarSign
                                :size="22"
                                class="text-blue-600 dark:text-blue-400"
                            />
                        </div>
                    </div>
                </div>

                <!-- Total Orders -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-all hover:shadow-md dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="flex items-start justify-between">
                        <div>
                            <p
                                class="mb-1 text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Total Orders') }}
                            </p>
                            <h3
                                class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white"
                            >
                                {{ statistics.order_count }}
                            </h3>
                            <p class="mt-2.5 text-xs text-gray-400">
                                {{ $t('Orders placed in period') }}
                            </p>
                        </div>
                        <div
                            class="rounded-xl bg-green-50 p-3 dark:bg-green-900/20"
                        >
                            <ShoppingCart
                                :size="22"
                                class="text-green-600 dark:text-green-400"
                            />
                        </div>
                    </div>
                </div>

                <!-- Average Order Value -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-all hover:shadow-md dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="flex items-start justify-between">
                        <div>
                            <p
                                class="mb-1 text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Avg. Order Value') }}
                            </p>
                            <h3
                                class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white"
                            >
                                {{ formatCurrency(statistics.avg_order_value) }}
                            </h3>
                            <p class="mt-2.5 text-xs text-gray-400">
                                {{ $t('Revenue per order') }}
                            </p>
                        </div>
                        <div
                            class="rounded-xl bg-yellow-50 p-3 dark:bg-yellow-900/20"
                        >
                            <CreditCard
                                :size="22"
                                class="text-yellow-600 dark:text-yellow-400"
                            />
                        </div>
                    </div>
                </div>

                <!-- Growth -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-all hover:shadow-md dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="flex items-start justify-between">
                        <div>
                            <p
                                class="mb-1 text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Total Growth') }}
                            </p>
                            <h3
                                class="text-2xl font-bold tracking-tight"
                                :class="[
                                    statistics.growth_percentage > 0
                                        ? 'text-green-600 dark:text-green-400'
                                        : 'text-red-600 dark:text-red-400',
                                ]"
                            >
                                {{ statistics.growth_percentage > 0 ? '+' : ''
                                }}{{ statistics.growth_percentage.toFixed(2) }}%
                            </h3>
                            <p class="mt-2.5 text-xs text-gray-400">
                                {{ $t('Overall performance') }}
                            </p>
                        </div>
                        <div
                            class="rounded-xl bg-purple-50 p-3 dark:bg-purple-900/20"
                        >
                            <TrendingUp
                                :size="22"
                                class="text-purple-600 dark:text-purple-400"
                            />
                        </div>
                    </div>
                </div>
            </div>

            <!-- Revenue Chart -->
            <div
                class="mb-6 rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <h2
                    class="mb-6 text-base font-semibold text-gray-900 dark:text-white"
                >
                    {{ $t('Revenue Over Time') }}
                </h2>
                <div class="relative h-80 w-full">
                    <Line :data="revenueChart" :options="lineChartOptions" />
                </div>
            </div>

            <!-- Charts Row -->
            <div class="mb-6 grid grid-cols-1 gap-6 lg:grid-cols-2">
                <!-- Orders by Status -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <h2
                        class="mb-6 text-base font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('Orders by Status') }}
                    </h2>
                    <div class="relative h-72 w-full">
                        <Bar :data="ordersChart" :options="barChartOptions" />
                    </div>
                </div>

                <!-- Payment Methods -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <h2
                        class="mb-6 text-base font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('Payment Methods') }}
                    </h2>
                    <div class="relative flex h-72 w-full justify-center">
                        <Doughnut
                            :data="paymentChart"
                            :options="doughnutChartOptions"
                        />
                    </div>
                </div>
            </div>

            <!-- Top Orders Table -->
            <div
                class="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div
                    class="border-b border-gray-100 bg-gray-50/50 px-5 py-4 dark:border-gray-700 dark:bg-gray-700/20"
                >
                    <h2
                        class="text-base font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('Top 10 Orders') }}
                    </h2>
                </div>
                <div class="overflow-x-auto">
                    <table
                        class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                    >
                        <thead class="bg-gray-50 dark:bg-gray-800">
                            <tr>
                                <th
                                    class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Order ID') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Customer') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Amount') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Date') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Status') }}
                                </th>
                            </tr>
                        </thead>
                        <tbody
                            class="divide-y divide-gray-100 dark:divide-gray-700"
                        >
                            <tr
                                v-for="order in topOrders"
                                :key="order.id"
                                class="transition-colors hover:bg-gray-50 dark:hover:bg-gray-700/50"
                            >
                                <td
                                    class="px-6 py-3.5 text-sm font-medium whitespace-nowrap text-blue-600 dark:text-blue-400"
                                >
                                    #{{ order.increment_id }}
                                </td>
                                <td
                                    class="px-6 py-3.5 text-sm whitespace-nowrap text-gray-700 dark:text-gray-300"
                                >
                                    {{ order.customer_name }}
                                </td>
                                <td
                                    class="px-6 py-3.5 text-sm font-semibold whitespace-nowrap text-gray-900 dark:text-white"
                                >
                                    {{
                                        typeof order.total === 'string'
                                            ? order.total
                                            : formatCurrency(order.total)
                                    }}
                                </td>
                                <td
                                    class="px-6 py-3.5 text-sm whitespace-nowrap text-gray-500 dark:text-gray-400"
                                >
                                    <DateDisplay
                                        :value="order.created_at"
                                        time
                                    />
                                </td>
                                <td class="px-6 py-3.5 whitespace-nowrap">
                                    <span
                                        :class="[
                                            'inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium',
                                            getStatusClass(order.status),
                                        ]"
                                    >
                                        {{ order.status }}
                                    </span>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

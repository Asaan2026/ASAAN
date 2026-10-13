<script setup lang="ts">
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
    ArrowUpRight,
    CreditCard,
    Download,
    Filter,
    Map,
    PieChart,
    RefreshCcw,
    TrendingUp,
    UserPlus,
    Users,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';
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
    total_customers: number;
    new_customers: number;
    repeat_customers: number;
    total_revenue: number;
    avg_order_value: number;
    total_orders: number;
    avg_lifetime_value: number;
    repeat_rate: number;
}

interface Customer {
    customer_id: number;
    customer_name: string;
    customer_email: string;
    order_count: number;
    total_spent: number;
    avg_order_value: number;
}

interface RFMCustomer {
    id: number;
    name: string;
    email: string;
    recency_days: number;
    frequency: number;
    monetary: number;
    recency_score: number;
    frequency_score: number;
    monetary_score: number;
    rfm_score: number;
    segment: string;
}

interface GeographicData {
    country: string;
    customer_count: number;
    order_count: number;
    total_revenue: number;
}

interface ChartData {
    labels: string[];
    datasets: Array<{
        label: string;
        data: number[];
        borderColor?: string;
        backgroundColor?: string | string[];
        tension?: number;
        fill?: boolean;
    }>;
}

interface Filters {
    start_date: string;
    end_date: string;
}

const props = defineProps<{
    statistics: Statistics;
    topCustomers: Customer[];
    acquisitionTrend: Array<any>;
    rfmSegmentation: RFMCustomer[];
    geographicDistribution: GeographicData[];
    lifetimeValueDistribution: Record<string, number>;
    acquisitionChart: ChartData;
    rfmChart: ChartData;
    geographicChart: ChartData;
    ltvChart: ChartData;
    filters: Filters;
}>();

// Filter refs
const startDate = ref(props.filters.start_date);
const endDate = ref(props.filters.end_date);

// Check if filters are active
const hasFilters = computed(() => {
    return (
        startDate.value !== props.filters.start_date ||
        endDate.value !== props.filters.end_date
    );
});

// Apply filters
const applyFilters = () => {
    router.get(
        route('admin.reports.customers'),
        {
            start_date: startDate.value,
            end_date: endDate.value,
        },
        {
            preserveState: true,
            preserveScroll: true,
        },
    );
};

// Clear filters
const clearFilters = () => {
    startDate.value = props.filters.start_date;
    endDate.value = props.filters.end_date;
    router.get(
        route('admin.reports.customers'),
        {},
        {
            preserveState: true,
            preserveScroll: true,
        },
    );
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
        },
    },
};

const barChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
        legend: {
            display: true,
            position: 'top' as const,
        },
    },
    scales: {
        y: {
            beginAtZero: true,
        },
    },
};

const doughnutChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
        legend: {
            display: true,
            position: 'right' as const,
        },
    },
};

// Utility functions
const { formatPrice: formatCurrency } = useCurrency();

const formatNumber = (value: number) => {
    return new Intl.NumberFormat('en-US').format(value);
};

const formatPercentage = (value: number) => {
    return `${value.toFixed(2)}%`;
};

// Get segment badge color
const getSegmentColor = (segment: string) => {
    const colors: Record<string, string> = {
        Champions:
            'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300',
        'Loyal Customers':
            'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300',
        'Recent Customers':
            'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300',
        'Frequent Shoppers':
            'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-300',
        'Big Spenders':
            'bg-pink-100 text-pink-800 dark:bg-pink-900 dark:text-pink-300',
        'At Risk':
            'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300',
        Lost: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300',
        'Potential Loyalists':
            'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300',
    };
    return colors[segment] || 'bg-gray-100 text-gray-800';
};
</script>

<template>
    <Head :title="$t('Customer Reports')" />
    <AdminLayout :title="$t('Customer Reports')">
        <div class="space-y-6">
            <!-- Page Header -->
            <div
                class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between"
            >
                <div>
                    <h1 class="text-2xl font-bold text-gray-900">
                        {{ $t('Customer Reports') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-500">
                        {{
                            $t(
                                'Analyze customer behavior, segments, and lifetime value',
                            )
                        }}
                    </p>
                </div>
                <div class="flex items-center gap-3">
                    <button
                        class="inline-flex items-center gap-2 rounded-xl border border-gray-200 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm transition-all duration-200 hover:bg-gray-50 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none"
                    >
                        <Download class="h-4 w-4" />
                        {{ $t('Export Report') }}
                    </button>
                    <button
                        @click="applyFilters"
                        class="inline-flex items-center gap-2 rounded-xl border border-transparent bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition-all duration-200 hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none"
                    >
                        <Filter class="h-4 w-4" />
                        {{ $t('Apply Filters') }}
                    </button>
                </div>
            </div>

            <!-- Filters Bar -->
            <div
                class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm"
            >
                <div class="grid grid-cols-1 gap-6 md:grid-cols-4">
                    <!-- Date Range -->
                    <div class="col-span-2 grid grid-cols-2 gap-4">
                        <div>
                            <label
                                class="mb-2 block text-xs font-semibold tracking-wider text-gray-500 uppercase"
                            >
                                {{ $t('Start Date') }}
                            </label>
                            <DatePicker
                                v-model="startDate"
                                class="block w-full rounded-lg border border-gray-200 bg-gray-50 px-3 py-2.5 text-sm text-gray-900 transition-colors duration-200 focus:border-transparent focus:ring-2 focus:ring-blue-500"
                            />
                        </div>
                        <div>
                            <label
                                class="mb-2 block text-xs font-semibold tracking-wider text-gray-500 uppercase"
                            >
                                {{ $t('End Date') }}
                            </label>
                            <DatePicker
                                v-model="endDate"
                                class="block w-full rounded-lg border border-gray-200 bg-gray-50 px-3 py-2.5 text-sm text-gray-900 transition-colors duration-200 focus:border-transparent focus:ring-2 focus:ring-blue-500"
                            />
                        </div>
                    </div>
                </div>

                <!-- Active Filters & Clear -->
                <div
                    v-if="hasFilters"
                    class="mt-4 flex justify-end border-t border-gray-100 pt-4"
                >
                    <button
                        @click="clearFilters"
                        class="flex items-center gap-2 text-sm font-medium text-red-600 hover:text-red-700"
                    >
                        <RefreshCcw class="h-4 w-4" />
                        {{ $t('Reset Filters') }}
                    </button>
                </div>
            </div>

            <!-- Statistics Grid -->
            <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
                <!-- Total Customers -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-6 shadow-sm transition-all duration-200 hover:shadow-md"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-xs font-semibold tracking-wider text-gray-500 uppercase"
                            >
                                {{ $t('Total Customers') }}
                            </p>
                            <p class="mt-2 text-2xl font-bold text-gray-900">
                                {{ formatNumber(statistics.total_customers) }}
                            </p>
                            <div
                                class="mt-2 flex w-fit items-center rounded-full bg-green-50 px-2 py-1 text-xs text-green-600"
                            >
                                <ArrowUpRight class="mr-1 h-3 w-3" />
                                <span class="font-medium">{{
                                    $t('Active Base')
                                }}</span>
                            </div>
                        </div>
                        <div
                            class="rounded-xl border border-blue-100 bg-blue-50 p-3"
                        >
                            <Users class="h-6 w-6 text-blue-600" />
                        </div>
                    </div>
                </div>

                <!-- New Customers -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-6 shadow-sm transition-all duration-200 hover:shadow-md"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-xs font-semibold tracking-wider text-gray-500 uppercase"
                            >
                                {{ $t('New Customers') }}
                            </p>
                            <p class="mt-2 text-2xl font-bold text-gray-900">
                                {{ formatNumber(statistics.new_customers) }}
                            </p>
                            <div
                                class="mt-2 flex w-fit items-center rounded-full bg-blue-50 px-2 py-1 text-xs text-blue-600"
                            >
                                <UserPlus class="mr-1 h-3 w-3" />
                                <span class="font-medium">{{
                                    $t('Recently Joined')
                                }}</span>
                            </div>
                        </div>
                        <div
                            class="rounded-xl border border-green-100 bg-green-50 p-3"
                        >
                            <UserPlus class="h-6 w-6 text-green-600" />
                        </div>
                    </div>
                </div>

                <!-- Avg Lifetime Value -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-6 shadow-sm transition-all duration-200 hover:shadow-md"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-xs font-semibold tracking-wider text-gray-500 uppercase"
                            >
                                {{ $t('Avg LTV') }}
                            </p>
                            <p class="mt-2 text-2xl font-bold text-gray-900">
                                {{
                                    formatCurrency(
                                        statistics.avg_lifetime_value,
                                    )
                                }}
                            </p>
                            <div
                                class="mt-2 flex w-fit items-center rounded-full bg-purple-50 px-2 py-1 text-xs text-purple-600"
                            >
                                <TrendingUp class="mr-1 h-3 w-3" />
                                <span class="font-medium">{{
                                    $t('Per Customer')
                                }}</span>
                            </div>
                        </div>
                        <div
                            class="rounded-xl border border-purple-100 bg-purple-50 p-3"
                        >
                            <CreditCard class="h-6 w-6 text-purple-600" />
                        </div>
                    </div>
                </div>

                <!-- Repeat Rate -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-6 shadow-sm transition-all duration-200 hover:shadow-md"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-xs font-semibold tracking-wider text-gray-500 uppercase"
                            >
                                {{ $t('Repeat Rate') }}
                            </p>
                            <p class="mt-2 text-2xl font-bold text-gray-900">
                                {{ formatPercentage(statistics.repeat_rate) }}
                            </p>
                            <div
                                class="mt-2 flex w-fit items-center rounded-full bg-orange-50 px-2 py-1 text-xs text-orange-600"
                            >
                                <RefreshCcw class="mr-1 h-3 w-3" />
                                <span class="font-medium">{{
                                    $t('Retention')
                                }}</span>
                            </div>
                        </div>
                        <div
                            class="rounded-xl border border-orange-100 bg-orange-50 p-3"
                        >
                            <RefreshCcw class="h-6 w-6 text-orange-600" />
                        </div>
                    </div>
                </div>
            </div>

            <!-- Charts Grid -->
            <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
                <!-- Customer Acquisition Trend -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-6 shadow-sm"
                >
                    <div class="mb-6 flex items-center justify-between">
                        <div class="flex items-center gap-3">
                            <div class="rounded-lg bg-blue-50 p-2">
                                <UserPlus class="h-5 w-5 text-blue-600" />
                            </div>
                            <div>
                                <h2 class="text-lg font-bold text-gray-900">
                                    {{ $t('Customer Acquisition') }}
                                </h2>
                                <p class="text-xs text-gray-500">
                                    {{ $t('New customer signups over time') }}
                                </p>
                            </div>
                        </div>
                    </div>
                    <div class="h-80">
                        <Line
                            :data="acquisitionChart"
                            :options="lineChartOptions"
                        />
                    </div>
                </div>

                <!-- RFM Segmentation -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-6 shadow-sm"
                >
                    <div class="mb-6 flex items-center justify-between">
                        <div class="flex items-center gap-3">
                            <div class="rounded-lg bg-purple-50 p-2">
                                <PieChart class="h-5 w-5 text-purple-600" />
                            </div>
                            <div>
                                <h2 class="text-lg font-bold text-gray-900">
                                    {{ $t('Customer Segments') }}
                                </h2>
                                <p class="text-xs text-gray-500">
                                    {{ $t('Distribution by customer type') }}
                                </p>
                            </div>
                        </div>
                    </div>
                    <div class="h-80">
                        <Doughnut
                            :data="rfmChart"
                            :options="doughnutChartOptions"
                        />
                    </div>
                </div>

                <!-- Geographic Distribution -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-6 shadow-sm"
                >
                    <div class="mb-6 flex items-center justify-between">
                        <div class="flex items-center gap-3">
                            <div class="rounded-lg bg-green-50 p-2">
                                <Map class="h-5 w-5 text-green-600" />
                            </div>
                            <div>
                                <h2 class="text-lg font-bold text-gray-900">
                                    {{ $t('Revenue by Country') }}
                                </h2>
                                <p class="text-xs text-gray-500">
                                    {{ $t('Sales performance by location') }}
                                </p>
                            </div>
                        </div>
                    </div>
                    <div class="h-80">
                        <Bar
                            :data="geographicChart"
                            :options="barChartOptions"
                        />
                    </div>
                </div>

                <!-- Lifetime Value Distribution -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-6 shadow-sm"
                >
                    <div class="mb-6 flex items-center justify-between">
                        <div class="flex items-center gap-3">
                            <div class="rounded-lg bg-orange-50 p-2">
                                <CreditCard class="h-5 w-5 text-orange-600" />
                            </div>
                            <div>
                                <h2 class="text-lg font-bold text-gray-900">
                                    {{ $t('LTV Distribution') }}
                                </h2>
                                <p class="text-xs text-gray-500">
                                    {{ $t('Customer value analysis') }}
                                </p>
                            </div>
                        </div>
                    </div>
                    <div class="h-80">
                        <Bar :data="ltvChart" :options="barChartOptions" />
                    </div>
                </div>
            </div>

            <!-- Tables Grid -->
            <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
                <!-- Top Customers -->
                <div
                    class="flex h-full flex-col overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm"
                >
                    <div
                        class="flex items-center justify-between border-b border-gray-100 px-6 py-4"
                    >
                        <div class="flex items-center gap-3">
                            <div class="rounded-lg bg-yellow-50 p-2">
                                <TrendingUp class="h-5 w-5 text-yellow-600" />
                            </div>
                            <div>
                                <h2 class="text-lg font-bold text-gray-900">
                                    {{ $t('Top Customers') }}
                                </h2>
                                <p class="text-xs text-gray-500">
                                    {{
                                        $t(
                                            'Highest spending customers by value',
                                        )
                                    }}
                                </p>
                            </div>
                        </div>
                    </div>

                    <div class="overflow-x-auto">
                        <table class="w-full border-collapse text-left">
                            <thead>
                                <tr class="border-b border-gray-100 bg-gray-50">
                                    <th
                                        class="px-6 py-3 text-xs font-semibold tracking-wider text-gray-500 uppercase"
                                    >
                                        {{ $t('Customer') }}
                                    </th>
                                    <th
                                        class="px-6 py-3 text-center text-xs font-semibold tracking-wider text-gray-500 uppercase"
                                    >
                                        {{ $t('Orders') }}
                                    </th>
                                    <th
                                        class="px-6 py-3 text-right text-xs font-semibold tracking-wider text-gray-500 uppercase"
                                    >
                                        {{ $t('Total Spent') }}
                                    </th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-gray-100">
                                <tr
                                    v-for="customer in topCustomers"
                                    :key="customer.customer_id"
                                    class="transition-colors duration-150 hover:bg-gray-50"
                                >
                                    <td class="px-6 py-4">
                                        <div class="flex flex-col">
                                            <span
                                                class="text-sm font-medium text-gray-900"
                                                >{{
                                                    customer.customer_name
                                                }}</span
                                            >
                                            <span
                                                class="text-xs text-gray-500"
                                                >{{
                                                    customer.customer_email
                                                }}</span
                                            >
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 text-center">
                                        <span
                                            class="inline-flex items-center rounded-full bg-blue-50 px-2.5 py-0.5 text-xs font-medium text-blue-700"
                                        >
                                            {{
                                                $t('{count} orders', {
                                                    count: customer.order_count,
                                                })
                                            }}
                                        </span>
                                    </td>
                                    <td class="px-6 py-4 text-right">
                                        <span class="font-bold text-gray-900">{{
                                            formatCurrency(customer.total_spent)
                                        }}</span>
                                    </td>
                                </tr>
                                <tr v-if="topCustomers.length === 0">
                                    <td
                                        colspan="3"
                                        class="px-6 py-8 text-center text-sm text-gray-500"
                                    >
                                        {{ $t('No customer data available') }}
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- Customer Segments List -->
                <div
                    class="flex h-full flex-col overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm"
                >
                    <div
                        class="flex items-center justify-between border-b border-gray-100 px-6 py-4"
                    >
                        <div class="flex items-center gap-3">
                            <div class="rounded-lg bg-indigo-50 p-2">
                                <Users class="h-5 w-5 text-indigo-600" />
                            </div>
                            <div>
                                <h2 class="text-lg font-bold text-gray-900">
                                    {{ $t('Segment Analysis') }}
                                </h2>
                                <p class="text-xs text-gray-500">
                                    {{ $t('Top 10 customers by RFM score') }}
                                </p>
                            </div>
                        </div>
                    </div>

                    <div class="overflow-x-auto">
                        <table class="w-full border-collapse text-left">
                            <thead>
                                <tr class="border-b border-gray-100 bg-gray-50">
                                    <th
                                        class="px-6 py-3 text-xs font-semibold tracking-wider text-gray-500 uppercase"
                                    >
                                        {{ $t('Customer') }}
                                    </th>
                                    <th
                                        class="px-6 py-3 text-center text-xs font-semibold tracking-wider text-gray-500 uppercase"
                                    >
                                        {{ $t('RFM Score') }}
                                    </th>
                                    <th
                                        class="px-6 py-3 text-right text-xs font-semibold tracking-wider text-gray-500 uppercase"
                                    >
                                        {{ $t('Segment') }}
                                    </th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-gray-100">
                                <tr
                                    v-for="customer in rfmSegmentation.slice(
                                        0,
                                        10,
                                    )"
                                    :key="customer.id"
                                    class="transition-colors duration-150 hover:bg-gray-50"
                                >
                                    <td class="px-6 py-4">
                                        <div class="flex flex-col">
                                            <span
                                                class="text-sm font-medium text-gray-900"
                                                >{{ customer.name }}</span
                                            >
                                            <span
                                                class="text-xs text-gray-500"
                                                >{{ customer.email }}</span
                                            >
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 text-center">
                                        <span class="font-mono text-xs">{{
                                            customer.rfm_score
                                        }}</span>
                                    </td>
                                    <td class="px-6 py-4 text-right">
                                        <span
                                            :class="
                                                getSegmentColor(
                                                    customer.segment,
                                                )
                                            "
                                            class="border-opacity-20 rounded-full border border-gray-300 px-2 py-1 text-xs font-semibold"
                                        >
                                            {{ customer.segment }}
                                        </span>
                                    </td>
                                </tr>
                                <tr v-if="rfmSegmentation.length === 0">
                                    <td
                                        colspan="3"
                                        class="px-6 py-8 text-center text-sm text-gray-500"
                                    >
                                        {{
                                            $t('No segmentation data available')
                                        }}
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

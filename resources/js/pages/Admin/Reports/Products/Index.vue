<script setup lang="ts">
import DatePicker from '@/components/Calendar/DatePicker.vue';
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { useI18nStore } from '@/Stores/i18n';
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
    AlertTriangle,
    BarChart2,
    Box,
    DollarSign,
    Download,
    RefreshCw,
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
    total_quantity_sold: number;
    total_revenue: number;
    unique_products_sold: number;
    total_orders: number;
    total_products: number;
    low_stock_count: number;
    out_of_stock_count: number;
    avg_revenue_per_product: number;
}

interface Product {
    id: number;
    name: string;
    sku: string;
    quantity?: number;
    price?: number;
    total_quantity?: number;
    total_revenue?: number;
    order_count?: number;
    sold_quantity?: number;
}

interface Category {
    category_id: number;
    category_name: string;
    total_quantity: number;
    total_revenue: number;
    product_count: number;
    order_count: number;
}

interface ChartData {
    labels: string[];
    datasets: any[];
}

interface Filters {
    start_date: string;
    end_date: string;
    category_id?: number;
    low_stock_threshold: number;
}

interface Props {
    statistics: Statistics;
    bestSellers: Product[];
    lowStock: Product[];
    outOfStock: Product[];
    categoryPerformance: Category[];
    slowMoving: Product[];
    bestSellersChart: ChartData;
    categoryChart: ChartData;
    salesTrendChart: ChartData;
    filters: Filters;
}

const props = defineProps<Props>();

const { t } = useI18nStore();

// Filters
const startDate = ref(props.filters.start_date);
const endDate = ref(props.filters.end_date);
const categoryFilter = ref(props.filters.category_id || '');
const lowStockThreshold = ref(props.filters.low_stock_threshold);

// Apply filters
const applyFilters = () => {
    router.get(
        '/admin/reports/products',
        {
            start_date: startDate.value,
            end_date: endDate.value,
            category_id: categoryFilter.value || undefined,
            low_stock_threshold: lowStockThreshold.value,
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
    categoryFilter.value = '';
    lowStockThreshold.value = 10;
    applyFilters();
};

// Chart options
const barChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
        legend: {
            display: false,
        },
        tooltip: {
            callbacks: {
                label: (context: any) =>
                    t('Sold: {count} units', { count: context.parsed.y }),
            },
        },
    },
    scales: {
        x: {
            grid: {
                display: false,
            },
        },
        y: {
            beginAtZero: true,
            grid: {
                color: 'rgba(0, 0, 0, 0.05)',
            },
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
        tooltip: {
            callbacks: {
                label: (context: any) => {
                    const { formatPrice } = useCurrency();
                    const label = context.label || '';
                    const value = context.parsed || 0;
                    return t('{label}: {value}', {
                        label,
                        value: formatPrice(value),
                    });
                },
            },
        },
    },
};

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
        x: {
            grid: {
                display: false,
            },
        },
        y: {
            beginAtZero: true,
            grid: {
                color: 'rgba(0, 0, 0, 0.05)',
            },
        },
    },
};

// Format currency
const { formatPrice: formatCurrency } = useCurrency();

// Format number
const formatNumber = (num: number): string => {
    return new Intl.NumberFormat('en-US').format(num);
};
</script>

<template>
    <Head :title="$t('Product Reports')" />
    <AdminLayout :title="$t('Product Reports')">
        <div class="space-y-6">
            <!-- Header -->
            <div
                class="flex flex-col justify-between gap-4 md:flex-row md:items-center"
            >
                <div>
                    <h1
                        class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white"
                    >
                        {{ $t('Product Reports') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                        {{
                            $t(
                                'Track product performance, inventory, and sales trends',
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

                    <!-- Low Stock Threshold -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Low Stock Limit') }}</label
                        >
                        <div class="relative">
                            <AlertTriangle
                                :size="16"
                                class="pointer-events-none absolute top-1/2 left-3 -translate-y-1/2 text-gray-400"
                            />
                            <input
                                v-model.number="lowStockThreshold"
                                type="number"
                                min="1"
                                class="w-full rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-4 pl-10 text-sm transition-colors focus:border-blue-500 focus:ring-2 focus:ring-blue-100 dark:border-gray-600 dark:bg-gray-700/50"
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
                            v-if="startDate || endDate || categoryFilter"
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
                <!-- Total Products Sold -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-all hover:shadow-md dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="flex items-start justify-between">
                        <div>
                            <p
                                class="mb-1 text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Quantity Sold') }}
                            </p>
                            <h3
                                class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white"
                            >
                                {{
                                    formatNumber(statistics.total_quantity_sold)
                                }}
                            </h3>
                            <p class="mt-2.5 text-xs text-gray-400">
                                {{ $t('Units sold in period') }}
                            </p>
                        </div>
                        <div
                            class="rounded-xl bg-blue-50 p-3 dark:bg-blue-900/20"
                        >
                            <Box
                                :size="22"
                                class="text-blue-600 dark:text-blue-400"
                            />
                        </div>
                    </div>
                </div>

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
                            <p class="mt-2.5 text-xs text-gray-400">
                                {{ $t('Revenue generated') }}
                            </p>
                        </div>
                        <div
                            class="rounded-xl bg-green-50 p-3 dark:bg-green-900/20"
                        >
                            <DollarSign
                                :size="22"
                                class="text-green-600 dark:text-green-400"
                            />
                        </div>
                    </div>
                </div>

                <!-- Low Stock Alert -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-all hover:shadow-md dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="flex items-start justify-between">
                        <div>
                            <p
                                class="mb-1 text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Low Stock') }}
                            </p>
                            <h3
                                class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white"
                            >
                                {{ statistics.low_stock_count }}
                            </h3>
                            <p class="mt-2.5 text-xs text-gray-400">
                                {{ $t('Products running low') }}
                            </p>
                        </div>
                        <div
                            class="rounded-xl bg-yellow-50 p-3 dark:bg-yellow-900/20"
                        >
                            <AlertTriangle
                                :size="22"
                                class="text-yellow-600 dark:text-yellow-400"
                            />
                        </div>
                    </div>
                </div>

                <!-- Out of Stock -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-all hover:shadow-md dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="flex items-start justify-between">
                        <div>
                            <p
                                class="mb-1 text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Out of Stock') }}
                            </p>
                            <h3
                                class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white"
                            >
                                {{ statistics.out_of_stock_count }}
                            </h3>
                            <p class="mt-2.5 text-xs text-gray-400">
                                {{ $t('Products unavailable') }}
                            </p>
                        </div>
                        <div
                            class="rounded-xl bg-red-50 p-3 dark:bg-red-900/20"
                        >
                            <BarChart2
                                :size="22"
                                class="text-red-600 dark:text-red-400"
                            />
                        </div>
                    </div>
                </div>
            </div>

            <!-- Charts Row -->
            <div class="mb-6 grid grid-cols-1 gap-6 lg:grid-cols-2">
                <!-- Best Sellers Chart -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <h2
                        class="mb-6 text-base font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('Top 10 Best Sellers') }}
                    </h2>
                    <div class="relative h-80 w-full">
                        <Bar
                            :data="bestSellersChart"
                            :options="barChartOptions"
                        />
                    </div>
                </div>

                <!-- Category Performance -->
                <div
                    class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <h2
                        class="mb-6 text-base font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('Revenue by Category') }}
                    </h2>
                    <div class="relative flex h-80 w-full justify-center">
                        <Doughnut
                            :data="categoryChart"
                            :options="doughnutChartOptions"
                        />
                    </div>
                </div>
            </div>

            <!-- Sales Trend Chart -->
            <div
                class="mb-6 rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <h2
                    class="mb-6 text-base font-semibold text-gray-900 dark:text-white"
                >
                    {{ $t('Sales Trend') }}
                </h2>
                <div class="relative h-80 w-full">
                    <Line :data="salesTrendChart" :options="lineChartOptions" />
                </div>
            </div>

            <!-- Tables Row -->
            <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
                <!-- Low Stock Products -->
                <div
                    class="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <div
                        class="border-b border-gray-100 bg-gray-50/50 px-5 py-4 dark:border-gray-700 dark:bg-gray-700/20"
                    >
                        <h2
                            class="text-base font-semibold text-gray-900 dark:text-white"
                        >
                            {{ $t('Low Stock Products') }}
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
                                        {{ $t('Product') }}
                                    </th>
                                    <th
                                        class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('SKU') }}
                                    </th>
                                    <th
                                        class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Quantity') }}
                                    </th>
                                </tr>
                            </thead>
                            <tbody
                                class="divide-y divide-gray-100 dark:divide-gray-700"
                            >
                                <tr
                                    v-for="product in lowStock"
                                    :key="product.id"
                                    class="transition-colors hover:bg-gray-50 dark:hover:bg-gray-700/50"
                                >
                                    <td
                                        class="px-6 py-3.5 text-sm font-medium whitespace-nowrap text-gray-900 dark:text-white"
                                    >
                                        {{ product.name }}
                                    </td>
                                    <td
                                        class="px-6 py-3.5 text-sm whitespace-nowrap text-gray-500 dark:text-gray-400"
                                    >
                                        {{ product.sku }}
                                    </td>
                                    <td class="px-6 py-3.5 whitespace-nowrap">
                                        <span
                                            class="inline-flex rounded-full border border-yellow-200 bg-yellow-100 px-2.5 py-0.5 text-xs font-semibold text-yellow-800 dark:border-yellow-800 dark:bg-yellow-900/40 dark:text-yellow-300"
                                        >
                                            {{ product.quantity }}
                                        </span>
                                    </td>
                                </tr>
                                <tr v-if="lowStock.length === 0">
                                    <td
                                        colspan="3"
                                        class="px-6 py-4 text-center text-sm text-gray-500 dark:text-gray-400"
                                    >
                                        {{ $t('No low stock products') }}
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- Slow Moving Products -->
                <div
                    class="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <div
                        class="border-b border-gray-100 bg-gray-50/50 px-5 py-4 dark:border-gray-700 dark:bg-gray-700/20"
                    >
                        <h2
                            class="text-base font-semibold text-gray-900 dark:text-white"
                        >
                            {{ $t('Slow Moving Products') }}
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
                                        {{ $t('Product') }}
                                    </th>
                                    <th
                                        class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('SKU') }}
                                    </th>
                                    <th
                                        class="px-6 py-3 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Sold') }}
                                    </th>
                                </tr>
                            </thead>
                            <tbody
                                class="divide-y divide-gray-100 dark:divide-gray-700"
                            >
                                <tr
                                    v-for="product in slowMoving"
                                    :key="product.id"
                                    class="transition-colors hover:bg-gray-50 dark:hover:bg-gray-700/50"
                                >
                                    <td
                                        class="px-6 py-3.5 text-sm font-medium whitespace-nowrap text-gray-900 dark:text-white"
                                    >
                                        {{ product.name }}
                                    </td>
                                    <td
                                        class="px-6 py-3.5 text-sm whitespace-nowrap text-gray-500 dark:text-gray-400"
                                    >
                                        {{ product.sku }}
                                    </td>
                                    <td
                                        class="px-6 py-3.5 text-sm whitespace-nowrap text-gray-500 dark:text-gray-400"
                                    >
                                        {{
                                            $t('{count} units', {
                                                count:
                                                    product.sold_quantity || 0,
                                            })
                                        }}
                                    </td>
                                </tr>
                                <tr v-if="slowMoving.length === 0">
                                    <td
                                        colspan="3"
                                        class="px-6 py-4 text-center text-sm text-gray-500 dark:text-gray-400"
                                    >
                                        {{ $t('No slow moving products') }}
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

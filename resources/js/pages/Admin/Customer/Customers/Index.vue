<script setup lang="ts">
import ConfirmDeleteModal from '@/components/Admin/ConfirmDeleteModal.vue';
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import DatePicker from '@/components/Calendar/DatePicker.vue';
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, Link, router } from '@inertiajs/vue3';
import { debounce } from 'lodash';
import {
    ArrowUpDown,
    Building,
    CheckCircle,
    ChevronLeft,
    ChevronRight,
    Download,
    Edit,
    Eye,
    Filter,
    Mail,
    MinusCircle,
    PlusCircle,
    Search,
    Shield,
    Trash2,
    User,
    UserCheck,
    Users,
    X,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

interface CustomerGroup {
    id: number;
    name: string;
    color: string;
}

interface Customer {
    id: number;
    first_name: string;
    last_name: string;
    full_name: string;
    email: string;
    phone?: string;
    customer_group: {
        id: number;
        name: string;
        color: string;
    };
    company_name?: string;
    is_active: boolean;
    is_verified: boolean;
    is_guest: boolean;
    newsletter_subscribed: boolean;
    total_orders: number;
    total_spent: number;
    created_at: string;
}

interface Props {
    customers: {
        data: Customer[];
        links: any;
        meta: any;
        current_page: number;
        last_page: number;
        per_page: number;
        total: number;
        from: number;
        to: number;
        prev_page_url: string | null;
        next_page_url: string | null;
    };
    customerGroups: CustomerGroup[];
    filters: {
        search?: string;
        customer_group_id?: number;
        status?: string;
        customer_type?: string;
        is_verified?: boolean;
        newsletter_subscribed?: boolean;
        date_from?: string;
        date_to?: string;
    };
    statistics: {
        total_customers: number;
        active_customers: number;
        verified_customers: number;
        newsletter_subscribers: number;
    };
}

const props = defineProps<Props>();

const selectedCustomers = ref<number[]>([]);
const expandedRows = ref<number[]>([]);
const showDeleteModal = ref(false);
const deleteCustomerId = ref<number | null>(null);
const deletingCustomer = ref<{ id: number; name: string } | null>(null);
const showBulkDeleteModal = ref(false);

// Local filter state
const search = ref(props.filters.search || '');
const customerGroupFilter = ref(props.filters.customer_group_id || '');
const statusFilter = ref(props.filters.status || '');
const customerTypeFilter = ref(props.filters.customer_type || '');
const verifiedFilter = ref(props.filters.is_verified?.toString() || '');
const newsletterFilter = ref(
    props.filters.newsletter_subscribed?.toString() || '',
);
const dateFrom = ref(props.filters.date_from || '');
const dateTo = ref(props.filters.date_to || '');

// Computed
const allSelected = computed(() => {
    return (
        props.customers.data.length > 0 &&
        selectedCustomers.value.length === props.customers.data.length
    );
});

const someSelected = computed(() => {
    return (
        selectedCustomers.value.length > 0 &&
        selectedCustomers.value.length < props.customers.data.length
    );
});

// Debounced search
const performSearch = debounce(() => {
    applyFilters();
}, 300);

// Methods
function toggleSelectAll() {
    if (allSelected.value) {
        selectedCustomers.value = [];
    } else {
        selectedCustomers.value = props.customers.data.map((c) => c.id);
    }
}

const toggleRow = (id: number) => {
    const index = expandedRows.value.indexOf(id);
    if (index === -1) {
        expandedRows.value.push(id);
    } else {
        expandedRows.value.splice(index, 1);
    }
};

function applyFilters() {
    router.get(
        '/admin/customers',
        {
            search: search.value || undefined,
            customer_group_id: customerGroupFilter.value || undefined,
            status: statusFilter.value || undefined,
            customer_type: customerTypeFilter.value || undefined,
            is_verified: verifiedFilter.value || undefined,
            newsletter_subscribed: newsletterFilter.value || undefined,
            date_from: dateFrom.value || undefined,
            date_to: dateTo.value || undefined,
        },
        {
            preserveState: true,
            preserveScroll: true,
        },
    );
}

function clearFilters() {
    search.value = '';
    customerGroupFilter.value = '';
    statusFilter.value = '';
    customerTypeFilter.value = '';
    verifiedFilter.value = '';
    newsletterFilter.value = '';
    dateFrom.value = '';
    dateTo.value = '';
    applyFilters();
}

function confirmDelete(customerId: number) {
    const customer = props.customers.data.find((c) => c.id === customerId);
    if (customer) {
        deletingCustomer.value = {
            id: customer.id,
            name: `${customer.first_name} ${customer.last_name}`,
        };
        showDeleteModal.value = true;
    }
}

function deleteCustomer() {
    if (deletingCustomer.value) {
        router.delete(`/admin/customers/${deletingCustomer.value.id}`, {
            onSuccess: () => {
                showDeleteModal.value = false;
                deletingCustomer.value = null;
            },
        });
    }
}

function confirmBulkDelete() {
    if (selectedCustomers.value.length > 0) {
        showBulkDeleteModal.value = true;
    }
}

function bulkDelete() {
    router.post(
        '/admin/customers/bulk-delete',
        {
            customer_ids: selectedCustomers.value,
        },
        {
            onSuccess: () => {
                selectedCustomers.value = [];
                showBulkDeleteModal.value = false;
            },
        },
    );
}

function bulkUpdateStatus(isActive: boolean) {
    if (selectedCustomers.value.length > 0) {
        router.post(
            '/admin/customers/bulk-update-status',
            {
                customer_ids: selectedCustomers.value,
                is_active: isActive,
            },
            {
                onSuccess: () => {
                    selectedCustomers.value = [];
                },
            },
        );
    }
}

function exportCustomers() {
    const params = new URLSearchParams({
        search: search.value || '',
        customer_group_id: customerGroupFilter.value?.toString() || '',
        status: statusFilter.value || '',
    });
    window.location.href = `/admin/customers/export/csv?${params.toString()}`;
}

const { formatPrice } = useCurrency();

function formatCurrency(amount: number): string {
    return formatPrice(amount);
}
</script>

<template>
    <Head :title="$t('Customers')" />

    <AdminLayout :title="$t('Customers')">
        <div class="space-y-6 p-6">
            <!-- Header -->
            <div
                class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
            >
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Customers') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                        {{ $t('Manage your customer database') }}
                    </p>
                </div>
                <Link
                    :href="'/admin/customers/create'"
                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                >
                    <PlusCircle class="mr-2 h-4 w-4" />
                    {{ $t('Add Customer') }}
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
                                {{ $t('Total Customers') }}
                            </p>
                            <p
                                class="mt-1 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.total_customers }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-blue-50 p-3 transition-colors group-hover:bg-blue-100 dark:bg-blue-900/20 dark:group-hover:bg-blue-900/40"
                        >
                            <Users
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
                                {{ $t('Active') }}
                            </p>
                            <p
                                class="mt-1 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.active_customers }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-green-50 p-3 dark:bg-green-900/20"
                        >
                            <UserCheck
                                class="h-6 w-6 text-green-600 dark:text-green-400"
                            />
                        </div>
                    </div>
                </div>

                <div
                    class="group rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-colors hover:border-blue-200 dark:border-gray-700 dark:bg-gray-800 dark:hover:border-blue-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Verified') }}
                            </p>
                            <p
                                class="mt-1 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.verified_customers }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-blue-50 p-3 dark:bg-blue-900/20"
                        >
                            <Shield
                                class="h-6 w-6 text-blue-600 dark:text-blue-400"
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
                                {{ $t('Subscribers') }}
                            </p>
                            <p
                                class="mt-1 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.newsletter_subscribers }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-purple-50 p-3 dark:bg-purple-900/20"
                        >
                            <Mail
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
                    class="grid grid-cols-1 gap-4 md:grid-cols-4 lg:grid-cols-6"
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
                                @input="applyFilters"
                                type="text"
                                :placeholder="$t('Name, email, phone...')"
                                class="w-full rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-4 pl-10 text-sm text-gray-900 transition-all placeholder:text-gray-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            />
                        </div>
                    </div>

                    <!-- Customer Group Filter -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Group') }}</label
                        >
                        <div class="relative">
                            <Users
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <select
                                v-model="customerGroupFilter"
                                @change="applyFilters"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-8 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            >
                                <option value="">{{ $t('All Groups') }}</option>
                                <option
                                    v-for="group in customerGroups"
                                    :key="group.id"
                                    :value="group.id"
                                >
                                    {{ group.name }}
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
                            <Filter
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <select
                                v-model="statusFilter"
                                @change="applyFilters"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-8 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            >
                                <option value="">{{ $t('All Status') }}</option>
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
                                <ArrowUpDown class="h-3 w-3 text-gray-400" />
                            </div>
                        </div>
                    </div>

                    <!-- Customer Type Filter -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Type') }}</label
                        >
                        <div class="relative">
                            <User
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <select
                                v-model="customerTypeFilter"
                                @change="applyFilters"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-8 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            >
                                <option value="">{{ $t('All Types') }}</option>
                                <option value="registered">
                                    {{ $t('Registered') }}
                                </option>
                                <option value="guest">{{ $t('Guest') }}</option>
                            </select>
                            <div
                                class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2"
                            >
                                <ArrowUpDown class="h-3 w-3 text-gray-400" />
                            </div>
                        </div>
                    </div>

                    <!-- Verified Filter -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Verified') }}</label
                        >
                        <div class="relative">
                            <Shield
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <select
                                v-model="verifiedFilter"
                                @change="applyFilters"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-8 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            >
                                <option value="">{{ $t('All') }}</option>
                                <option value="true">
                                    {{ $t('Verified') }}
                                </option>
                                <option value="false">
                                    {{ $t('Not Verified') }}
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

                <!-- Date Range Filters -->
                <div class="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2">
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

                <!-- Filter Actions -->
                <div
                    v-if="
                        search ||
                        customerGroupFilter ||
                        statusFilter ||
                        customerTypeFilter ||
                        verifiedFilter ||
                        newsletterFilter ||
                        dateFrom ||
                        dateTo
                    "
                    class="mt-4 flex items-center justify-between border-t border-gray-200 pt-4 dark:border-gray-700"
                >
                    <button
                        @click="clearFilters"
                        class="flex items-center gap-2 rounded-lg bg-gray-100 px-4 py-2 text-sm font-medium text-gray-600 transition-colors hover:bg-gray-200 hover:text-gray-900 dark:bg-gray-700 dark:text-gray-400 dark:hover:bg-gray-600 dark:hover:text-gray-200"
                    >
                        <X class="h-4 w-4" />
                        {{ $t('Clear Filters') }}
                    </button>

                    <button
                        @click="exportCustomers"
                        class="inline-flex items-center rounded-lg bg-gray-100 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-200 dark:hover:bg-gray-600"
                    >
                        <Download class="mr-2 h-4 w-4" />
                        {{ $t('Export CSV') }}
                    </button>
                </div>
                <div
                    v-else
                    class="mt-4 flex justify-end border-t border-gray-200 pt-4 dark:border-gray-700"
                >
                    <button
                        @click="exportCustomers"
                        class="inline-flex items-center rounded-lg bg-gray-100 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-200 dark:hover:bg-gray-600"
                    >
                        <Download class="mr-2 h-4 w-4" />
                        {{ $t('Export CSV') }}
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
                    v-if="selectedCustomers.length > 0"
                    class="sticky top-4 z-10 mb-6 flex items-center justify-between rounded-xl bg-blue-600 p-3 px-6 text-white shadow-lg"
                >
                    <div class="flex items-center">
                        <CheckCircle class="mr-2 h-4 w-4" />
                        <span class="text-sm font-semibold">
                            {{
                                selectedCustomers.length === 1
                                    ? $t('{count} customer selected', {
                                          count: selectedCustomers.length,
                                      })
                                    : $t('{count} customers selected', {
                                          count: selectedCustomers.length,
                                      })
                            }}
                        </span>
                    </div>
                    <div class="flex gap-2">
                        <button
                            @click="confirmBulkDelete"
                            class="flex items-center rounded-lg bg-white/20 px-3 py-1.5 text-xs font-semibold transition-colors hover:bg-white/30"
                        >
                            <Trash2 class="mr-1.5 h-3 w-3" />
                            {{ $t('Delete Selected') }}
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
                                <th class="w-12 px-6 py-4">
                                    <input
                                        type="checkbox"
                                        :checked="allSelected"
                                        :indeterminate="someSelected"
                                        @change="toggleSelectAll"
                                        class="h-4 w-4 rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </th>
                                <th
                                    class="px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Customer') }}
                                </th>
                                <th
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase md:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Contact') }}
                                </th>
                                <th
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase lg:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Group') }}
                                </th>
                                <th
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase xl:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Orders') }}
                                </th>
                                <th
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase lg:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Total Spent') }}
                                </th>
                                <th
                                    class="px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Status') }}
                                </th>
                                <th
                                    class="hidden px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase xl:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Created') }}
                                </th>
                                <th
                                    class="px-6 py-4 text-right text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Actions') }}
                                </th>
                            </tr>
                        </thead>
                        <tbody
                            class="divide-y divide-gray-100 bg-white dark:divide-gray-700 dark:bg-gray-800"
                        >
                            <!-- Empty State -->
                            <tr v-if="customers.data.length === 0">
                                <td
                                    colspan="9"
                                    class="px-6 py-16 text-center text-gray-500 dark:text-gray-400"
                                >
                                    <div
                                        class="flex flex-col items-center justify-center"
                                    >
                                        <div
                                            class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-50 text-gray-400 dark:bg-gray-700"
                                        >
                                            <User class="h-8 w-8" />
                                        </div>
                                        <h3
                                            class="mb-1 text-lg font-bold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('No customers found') }}
                                        </h3>
                                        <p
                                            class="mb-4 max-w-sm text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            {{
                                                $t(
                                                    'Get started by creating your first customer.',
                                                )
                                            }}
                                        </p>
                                        <Link
                                            href="/admin/customers/create"
                                            class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                                        >
                                            <PlusCircle class="mr-2 h-4 w-4" />
                                            {{ $t('Add Customer') }}
                                        </Link>
                                    </div>
                                </td>
                            </tr>

                            <!-- Customer Rows -->
                            <template
                                v-for="customer in customers.data"
                                :key="customer.id"
                            >
                                <tr
                                    class="group transition-colors hover:bg-blue-50/50 dark:hover:bg-blue-900/10"
                                >
                                    <td class="relative px-6 py-4">
                                        <div class="flex items-center">
                                            <button
                                                @click="toggleRow(customer.id)"
                                                class="absolute left-2 p-1 text-blue-600 hover:text-blue-800 focus:outline-none lg:hidden"
                                            >
                                                <MinusCircle
                                                    v-if="
                                                        expandedRows.includes(
                                                            customer.id,
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
                                                :value="customer.id"
                                                v-model="selectedCustomers"
                                                class="ml-4 h-4 w-4 cursor-pointer rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 lg:ml-0 dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div class="flex items-center">
                                            <div
                                                class="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full border border-gray-200 bg-gray-100 dark:border-gray-600 dark:bg-gray-700"
                                            >
                                                <span
                                                    class="text-sm font-bold text-gray-600 dark:text-gray-300"
                                                >
                                                    {{
                                                        customer.first_name.charAt(
                                                            0,
                                                        )
                                                    }}{{
                                                        customer.last_name.charAt(
                                                            0,
                                                        )
                                                    }}
                                                </span>
                                            </div>
                                            <div class="ml-4">
                                                <div
                                                    class="text-sm font-bold text-gray-900 dark:text-white"
                                                >
                                                    {{ customer.full_name }}
                                                </div>
                                                <div
                                                    v-if="customer.company_name"
                                                    class="flex items-center gap-1 text-xs text-gray-500 dark:text-gray-400"
                                                >
                                                    <Building class="h-3 w-3" />
                                                    {{ customer.company_name }}
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap md:table-cell"
                                    >
                                        <div
                                            class="text-sm text-gray-600 dark:text-gray-300"
                                        >
                                            {{ customer.email }}
                                        </div>
                                        <div
                                            v-if="customer.phone"
                                            class="text-xs text-gray-500 dark:text-gray-400"
                                        >
                                            {{ customer.phone }}
                                        </div>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap lg:table-cell"
                                    >
                                        <span
                                            class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium shadow-sm"
                                            :style="{
                                                backgroundColor:
                                                    customer.customer_group
                                                        .color + '20',
                                                color: customer.customer_group
                                                    .color,
                                                borderColor:
                                                    customer.customer_group
                                                        .color + '40',
                                            }"
                                        >
                                            {{ customer.customer_group.name }}
                                        </span>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 text-sm whitespace-nowrap text-gray-600 xl:table-cell dark:text-gray-300"
                                    >
                                        {{ customer.total_orders }}
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 text-sm font-bold whitespace-nowrap text-gray-900 lg:table-cell dark:text-white"
                                    >
                                        {{
                                            formatCurrency(customer.total_spent)
                                        }}
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div
                                            class="flex flex-col items-start gap-1.5"
                                        >
                                            <span
                                                :class="[
                                                    'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium shadow-sm',
                                                    customer.is_active
                                                        ? 'border-green-200 bg-green-50 text-green-700 dark:border-green-800 dark:bg-green-900/20 dark:text-green-300'
                                                        : 'border-red-200 bg-red-50 text-red-700 dark:border-red-800 dark:bg-red-900/20 dark:text-red-300',
                                                ]"
                                            >
                                                {{
                                                    customer.is_active
                                                        ? $t('Active')
                                                        : $t('Inactive')
                                                }}
                                            </span>
                                            <div class="flex gap-1">
                                                <span
                                                    v-if="customer.is_guest"
                                                    class="inline-flex items-center rounded border border-gray-200 bg-gray-100 px-2 py-0.5 text-[10px] font-medium text-gray-600 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300"
                                                >
                                                    {{ $t('Guest') }}
                                                </span>
                                                <span
                                                    v-if="customer.is_verified"
                                                    class="inline-flex items-center rounded border border-blue-200 bg-blue-50 px-2 py-0.5 text-[10px] font-medium text-blue-600 dark:border-blue-800 dark:bg-blue-900/20 dark:text-blue-300"
                                                >
                                                    {{ $t('Verified') }}
                                                </span>
                                            </div>
                                        </div>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 text-sm whitespace-nowrap text-gray-500 xl:table-cell dark:text-gray-400"
                                    >
                                        <DateDisplay
                                            :value="customer.created_at"
                                        />
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right text-sm font-medium whitespace-nowrap"
                                    >
                                        <div
                                            class="flex items-center justify-end gap-2 opacity-60 transition-opacity group-hover:opacity-100"
                                        >
                                            <Link
                                                :href="`/admin/customers/${customer.id}`"
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-900/20"
                                                :title="$t('View Customer')"
                                            >
                                                <Eye class="h-4 w-4" />
                                            </Link>
                                            <Link
                                                :href="`/admin/customers/${customer.id}/edit`"
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-indigo-50 hover:text-indigo-600 dark:hover:bg-indigo-900/20"
                                                :title="$t('Edit Customer')"
                                            >
                                                <Edit class="h-4 w-4" />
                                            </Link>
                                            <button
                                                @click="
                                                    confirmDelete(customer.id)
                                                "
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-900/20"
                                                :title="$t('Delete Customer')"
                                            >
                                                <Trash2 class="h-4 w-4" />
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                                <!-- Expanded Mobile Row -->
                                <tr
                                    v-if="expandedRows.includes(customer.id)"
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
                                                class="flex flex-col gap-2 md:hidden"
                                            >
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Contact') }}</span
                                                >
                                                <div
                                                    class="text-sm font-medium text-gray-900 dark:text-white"
                                                >
                                                    {{ customer.email }}
                                                </div>
                                                <div
                                                    v-if="customer.phone"
                                                    class="text-xs text-gray-500"
                                                >
                                                    {{ customer.phone }}
                                                </div>
                                            </div>
                                            <div
                                                class="flex flex-col gap-2 lg:hidden"
                                            >
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Group') }}</span
                                                >
                                                <span
                                                    class="inline-flex w-fit items-center rounded-full border px-2.5 py-0.5 text-xs font-medium shadow-sm"
                                                    :style="{
                                                        backgroundColor:
                                                            customer
                                                                .customer_group
                                                                .color + '20',
                                                        color: customer
                                                            .customer_group
                                                            .color,
                                                        borderColor:
                                                            customer
                                                                .customer_group
                                                                .color + '40',
                                                    }"
                                                >
                                                    {{
                                                        customer.customer_group
                                                            .name
                                                    }}
                                                </span>
                                            </div>
                                            <div
                                                class="flex flex-col gap-2 lg:hidden"
                                            >
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{
                                                        $t('Financials')
                                                    }}</span
                                                >
                                                <div
                                                    class="grid grid-cols-2 gap-4"
                                                >
                                                    <div>
                                                        <span
                                                            class="block text-xs text-gray-500"
                                                            >{{
                                                                $t('Orders')
                                                            }}</span
                                                        >
                                                        <span
                                                            class="font-medium text-gray-900 dark:text-white"
                                                            >{{
                                                                customer.total_orders
                                                            }}</span
                                                        >
                                                    </div>
                                                    <div>
                                                        <span
                                                            class="block text-xs text-gray-500"
                                                            >{{
                                                                $t('Spent')
                                                            }}</span
                                                        >
                                                        <span
                                                            class="font-bold text-gray-900 dark:text-white"
                                                            >{{
                                                                formatCurrency(
                                                                    customer.total_spent,
                                                                )
                                                            }}</span
                                                        >
                                                    </div>
                                                </div>
                                            </div>
                                            <div
                                                class="flex flex-col gap-2 xl:hidden"
                                            >
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Joined') }}</span
                                                >
                                                <span
                                                    class="text-sm text-gray-600 dark:text-gray-300"
                                                    ><DateDisplay
                                                        :value="
                                                            customer.created_at
                                                        "
                                                /></span>
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
                    class="flex items-center justify-between border-t border-gray-100 bg-gray-50/50 px-6 py-4 dark:border-gray-700 dark:bg-gray-700/50"
                >
                    <div class="text-xs text-gray-500 dark:text-gray-400">
                        {{ $t('Showing') }}
                        <span class="font-medium">{{
                            customers.from || 0
                        }}</span>
                        {{ $t('to') }}
                        <span class="font-medium">{{ customers.to || 0 }}</span>
                        {{ $t('of') }}
                        <span class="font-medium">{{ customers.total }}</span>
                        {{ $t('results') }}
                    </div>
                    <div class="flex gap-2">
                        <Link
                            v-if="customers.prev_page_url"
                            :href="customers.prev_page_url"
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
                            v-if="customers.next_page_url"
                            :href="customers.next_page_url"
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

            <!-- Delete Modal -->
            <ConfirmDeleteModal
                v-model:show="showDeleteModal"
                :title="deletingCustomer?.name ?? ''"
                :message="
                    $t(
                        'Are you sure you want to delete {name}? This action cannot be undone.',
                        { name: deletingCustomer?.name },
                    )
                "
                @confirm="deleteCustomer"
            />

            <!-- Bulk Delete Modal -->
            <ConfirmDeleteModal
                v-model:show="showBulkDeleteModal"
                :title="$t('Delete Multiple Customers')"
                :message="
                    $t(
                        'Are you sure you want to delete {count} customers? This action cannot be undone.',
                        { count: selectedCustomers.length },
                    )
                "
                @confirm="bulkDelete"
            />
        </div>
    </AdminLayout>
</template>

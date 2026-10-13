<template>
    <Head :title="$t('Shipping Methods')" />

    <AdminLayout :title="$t('Shipment Method')">
        <div class="space-y-6">
            <!-- Header -->
            <div
                class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
            >
                <div>
                    <h2
                        class="bg-gradient-to-r from-gray-900 to-gray-600 bg-clip-text text-2xl font-bold text-transparent dark:from-white dark:to-gray-300"
                    >
                        {{ $t('Shipping Methods') }}
                    </h2>
                    <p
                        class="mt-1 flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400"
                    >
                        <Truck class="h-4 w-4" />
                        {{
                            $t(
                                'Manage your shipping rates and delivery options',
                            )
                        }}
                    </p>
                </div>
                <div class="flex items-center gap-2">
                    <Link
                        href="/admin/settings/shipping-methods/create"
                        class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                    >
                        <Plus class="mr-2 h-4 w-4" />
                        {{ $t('Add Shipping Method') }}
                    </Link>
                </div>
            </div>

            <div
                class="rounded-xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div class="flex items-start justify-between gap-4">
                    <div>
                        <h3
                            class="text-lg font-semibold text-gray-900 dark:text-white"
                        >
                            {{ $t('In-house Delivery') }}
                        </h3>
                        <p
                            class="mt-1 text-sm text-gray-500 dark:text-gray-400"
                        >
                            {{
                                $t(
                                    'Shipments use your own delivery staff. No courier account or API needed.',
                                )
                            }}
                        </p>
                    </div>
                </div>
            </div>

            <!-- Filters & Search -->
            <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
                <!-- Search -->
                <div class="relative">
                    <Search
                        class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                    />
                    <input
                        v-model="search"
                        type="text"
                        :placeholder="$t('Search details...')"
                        class="w-full rounded-xl border border-gray-200 bg-white py-2.5 pr-4 pl-9 text-sm transition-shadow focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-700 dark:bg-gray-800"
                    />
                </div>

                <!-- Type Filter -->
                <div class="relative">
                    <Filter
                        class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                    />
                    <select
                        v-model="typeFilter"
                        class="w-full appearance-none rounded-xl border border-gray-200 bg-white py-2.5 pr-4 pl-9 text-sm transition-shadow focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-700 dark:bg-gray-800"
                    >
                        <option value="">{{ $t('All Types') }}</option>
                        <option value="flat-rate">{{ $t('Flat Rate') }}</option>
                        <option value="calculated">
                            {{ $t('Calculated') }}
                        </option>
                    </select>
                </div>

                <!-- Status Filter -->
                <div class="relative">
                    <div
                        class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3"
                    >
                        <div
                            class="h-1.5 w-1.5 rounded-full"
                            :class="
                                statusFilter === 'active'
                                    ? 'bg-green-500'
                                    : statusFilter === 'inactive'
                                      ? 'bg-red-500'
                                      : 'bg-gray-400'
                            "
                        ></div>
                    </div>
                    <select
                        v-model="statusFilter"
                        class="w-full appearance-none rounded-xl border border-gray-200 bg-white py-2.5 pr-4 pl-9 text-sm transition-shadow focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-700 dark:bg-gray-800"
                    >
                        <option value="">{{ $t('All Statuses') }}</option>
                        <option value="active">{{ $t('Active') }}</option>
                        <option value="inactive">{{ $t('Inactive') }}</option>
                    </select>
                </div>
            </div>

            <!-- Methods Table -->
            <div
                class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div class="overflow-x-auto">
                    <table
                        class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                    >
                        <thead class="bg-gray-50 dark:bg-gray-700/50">
                            <tr>
                                <th
                                    scope="col"
                                    class="px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Method Details') }}
                                </th>
                                <th
                                    scope="col"
                                    class="px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Type') }}
                                </th>
                                <th
                                    scope="col"
                                    class="px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Rates') }}
                                </th>
                                <th
                                    scope="col"
                                    class="px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Status') }}
                                </th>
                                <th
                                    scope="col"
                                    class="px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Default') }}
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
                            class="divide-y divide-gray-200 bg-white dark:divide-gray-700 dark:bg-gray-800"
                        >
                            <tr
                                v-for="method in filteredMethods"
                                :key="method.id"
                                class="transition-colors hover:bg-gray-50 dark:hover:bg-gray-700/50"
                            >
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div class="flex items-start">
                                        <div
                                            class="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-lg bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400"
                                        >
                                            <component
                                                :is="
                                                    method.type === 'flat-rate'
                                                        ? Package
                                                        : Scale
                                                "
                                                class="h-5 w-5"
                                            />
                                        </div>
                                        <div class="ml-4">
                                            <div
                                                class="text-sm font-medium text-gray-900 dark:text-white"
                                            >
                                                {{ method.name }}
                                            </div>
                                            <div
                                                class="text-sm text-gray-500 dark:text-gray-400"
                                            >
                                                {{
                                                    method.description ||
                                                    $t('No description')
                                                }}
                                            </div>
                                        </div>
                                    </div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <span
                                        class="inline-flex items-center rounded-full bg-gray-100 px-2.5 py-0.5 text-xs font-medium text-gray-800 capitalize dark:bg-gray-700 dark:text-gray-300"
                                    >
                                        {{ method.type.replace('-', ' ') }}
                                    </span>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <div
                                        class="text-sm font-medium text-gray-900 dark:text-white"
                                    >
                                        {{ formatPrice(method.base_cost) }}
                                        <span class="mx-1 text-gray-400"
                                            >+</span
                                        >
                                        {{ formatPrice(method.cost_per_kg)
                                        }}<span class="text-xs text-gray-500"
                                            >/kg</span
                                        >
                                    </div>
                                    <div class="mt-0.5 text-xs text-gray-500">
                                        {{
                                            $t('{count} defined tiers', {
                                                count:
                                                    method.rates?.length || 0,
                                            })
                                        }}
                                    </div>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <button
                                        @click="toggleStatus(method)"
                                        class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium capitalize transition-colors focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none"
                                        :class="
                                            method.status === 'active'
                                                ? 'bg-green-100 text-green-800 hover:bg-green-200 dark:bg-green-900/30 dark:text-green-400 dark:hover:bg-green-900/50'
                                                : 'bg-red-100 text-red-800 hover:bg-red-200 dark:bg-red-900/30 dark:text-red-400 dark:hover:bg-red-900/50'
                                        "
                                    >
                                        <span
                                            class="mr-1.5 h-1.5 w-1.5 rounded-full"
                                            :class="
                                                method.status === 'active'
                                                    ? 'bg-green-500'
                                                    : 'bg-red-500'
                                            "
                                        ></span>
                                        {{ method.status }}
                                    </button>
                                </td>
                                <td class="px-6 py-4 whitespace-nowrap">
                                    <button
                                        v-if="!method.is_default"
                                        @click="setDefault(method)"
                                        :title="$t('Set as default')"
                                        class="text-gray-400 transition-colors hover:text-yellow-500 dark:hover:text-yellow-400"
                                    >
                                        <Star class="h-5 w-5" />
                                    </button>
                                    <div
                                        v-else
                                        class="text-yellow-500 dark:text-yellow-400"
                                        :title="$t('Default Method')"
                                    >
                                        <Star class="h-5 w-5 fill-current" />
                                    </div>
                                </td>
                                <td
                                    class="px-6 py-4 text-right text-sm font-medium whitespace-nowrap"
                                >
                                    <div class="flex justify-end gap-3">
                                        <Link
                                            :href="`/admin/settings/shipping-methods/${method.id}/edit`"
                                            class="text-indigo-600 transition-colors hover:text-indigo-900 dark:text-indigo-400 dark:hover:text-indigo-300"
                                        >
                                            <Pencil class="h-4 w-4" />
                                        </Link>
                                        <button
                                            v-if="!method.is_default"
                                            @click="deleteMethod(method)"
                                            class="text-red-600 transition-colors hover:text-red-900 dark:text-red-400 dark:hover:text-red-300"
                                        >
                                            <Trash2 class="h-4 w-4" />
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <!-- Empty State -->
                <div
                    v-if="filteredMethods.length === 0"
                    class="bg-gray-50 px-6 py-12 text-center dark:bg-gray-800/50"
                >
                    <div
                        class="mb-4 inline-flex h-16 w-16 items-center justify-center rounded-full bg-gray-100 text-gray-400 dark:bg-gray-700"
                    >
                        <Truck class="h-8 w-8" />
                    </div>
                    <h3
                        class="text-lg font-medium text-gray-900 dark:text-white"
                    >
                        {{ $t('No shipping methods found') }}
                    </h3>
                    <p
                        class="mx-auto mt-2 max-w-sm text-sm text-gray-500 dark:text-gray-400"
                    >
                        {{
                            $t(
                                'Get started by creating your first shipping method for your store.',
                            )
                        }}
                    </p>
                    <div class="mt-6">
                        <Link
                            href="/admin/settings/shipping-methods/create"
                            class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                        >
                            <Plus class="mr-2 h-4 w-4" />
                            {{ $t('Create Method') }}
                        </Link>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

<script setup lang="ts">
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, Link } from '@inertiajs/vue3';
import axios from 'axios';
import {
    Filter,
    Package,
    Pencil,
    Plus,
    Scale,
    Search,
    Star,
    Trash2,
    Truck,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

interface ShippingMethod {
    id: number;
    name: string;
    slug: string;
    type: string;
    status: string;
    base_cost: number;
    cost_per_kg: number;
    description: string;
    is_default: boolean;
    rates: any[];
    created_at: string;
    updated_at: string;
}

const props = defineProps<{
    methods: {
        data: ShippingMethod[];
    };
}>();

const { formatPrice } = useCurrency();

const methods = ref<ShippingMethod[]>(props.methods?.data || []);

const search = ref('');
const typeFilter = ref('');
const statusFilter = ref('');

const filteredMethods = computed(() => {
    return methods.value.filter((method) => {
        const matchesSearch =
            !search.value ||
            method.name.toLowerCase().includes(search.value.toLowerCase()) ||
            (method.description &&
                method.description
                    .toLowerCase()
                    .includes(search.value.toLowerCase()));

        const matchesType =
            !typeFilter.value || method.type === typeFilter.value;
        const matchesStatus =
            !statusFilter.value || method.status === statusFilter.value;

        return matchesSearch && matchesType && matchesStatus;
    });
});

const toggleStatus = async (method: ShippingMethod) => {
    try {
        const response = await axios.post(
            `/admin/settings/shipping-methods/${method.id}/toggle-status`,
        );
        method.status = response.data.status;
    } catch (error) {
        console.error('Error toggling status:', error);
    }
};

const setDefault = async (method: ShippingMethod) => {
    try {
        await axios.post(
            `/admin/settings/shipping-methods/${method.id}/set-default`,
        );
        // Update local state
        methods.value.forEach((m) => (m.is_default = m.id === method.id));
    } catch (error) {
        console.error('Error setting default:', error);
    }
};

const deleteMethod = async (method: ShippingMethod) => {
    if (!confirm(`Are you sure you want to delete "${method.name}"?`)) {
        return;
    }

    try {
        await axios.delete(`/admin/settings/shipping-methods/${method.id}`);
        methods.value = methods.value.filter((m) => m.id !== method.id);
    } catch (error) {
        console.error('Error deleting method:', error);
    }
};
</script>

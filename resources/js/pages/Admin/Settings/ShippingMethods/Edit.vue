<template>
    <Head :title="$t('Edit Shipping Method')" />

    <AdminLayout :title="$t('Edit Shipping Method')">
        <div class="space-y-6">
            <!-- Header -->
            <div class="flex items-center justify-between">
                <div>
                    <h2
                        class="bg-gradient-to-r from-gray-900 to-gray-600 bg-clip-text text-2xl font-bold text-transparent dark:from-white dark:to-gray-300"
                    >
                        {{ $t('Edit Shipping Method') }}
                    </h2>
                    <p
                        class="mt-1 flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400"
                    >
                        <Truck class="h-4 w-4" />
                        {{ method.name }}
                    </p>
                </div>
                <Link
                    href="/admin/settings/shipping-methods"
                    class="inline-flex items-center rounded-xl border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm transition-colors hover:bg-gray-50 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                >
                    <ChevronLeft class="mr-2 h-4 w-4" />
                    {{ $t('Back to List') }}
                </Link>
            </div>

            <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
                <!-- Main Form -->
                <div class="lg:col-span-2">
                    <div
                        class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <form @submit.prevent="submit" class="space-y-6">
                            <!-- Name -->
                            <div>
                                <label
                                    class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Method Name') }}</label
                                >
                                <input
                                    v-model="form.name"
                                    type="text"
                                    class="block w-full rounded-xl border border-gray-300 bg-white px-3 py-2.5 text-sm placeholder-gray-400 shadow-sm transition-shadow focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                                />
                                <p
                                    v-if="errors.name"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ errors.name }}
                                </p>
                            </div>

                            <!-- Slug -->
                            <div>
                                <label
                                    class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Slug') }}</label
                                >
                                <input
                                    v-model="form.slug"
                                    type="text"
                                    class="block w-full rounded-xl border border-gray-300 bg-white px-3 py-2.5 text-sm placeholder-gray-400 shadow-sm transition-shadow focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                                />
                                <p
                                    v-if="errors.slug"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ errors.slug }}
                                </p>
                            </div>

                            <!-- Type (Read-only) -->
                            <div>
                                <label
                                    class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Shipping Type') }}</label
                                >
                                <div class="relative">
                                    <div
                                        class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3"
                                    >
                                        <component
                                            :is="
                                                form.type === 'flat-rate'
                                                    ? Package
                                                    : Scale
                                            "
                                            class="h-5 w-5 text-gray-400"
                                        />
                                    </div>
                                    <input
                                        :value="
                                            form.type === 'flat-rate'
                                                ? $t('Flat Rate')
                                                : $t('Calculated')
                                        "
                                        type="text"
                                        disabled
                                        class="block w-full cursor-not-allowed rounded-xl border border-gray-200 bg-gray-50 py-2.5 pr-3 pl-10 text-sm text-gray-500 shadow-sm dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-400"
                                    />
                                </div>
                                <p
                                    class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                                >
                                    {{
                                        $t(
                                            'Type cannot be changed after creation',
                                        )
                                    }}
                                </p>
                            </div>

                            <!-- Cost Fields -->
                            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                                <div>
                                    <label
                                        class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Base Cost ($)') }}</label
                                    >
                                    <input
                                        v-model="form.base_cost"
                                        type="number"
                                        step="0.01"
                                        min="0"
                                        class="block w-full rounded-xl border border-gray-300 bg-white px-3 py-2.5 text-sm placeholder-gray-400 shadow-sm transition-shadow focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                                    />
                                    <p
                                        v-if="errors.base_cost"
                                        class="mt-1 text-sm text-red-600"
                                    >
                                        {{ errors.base_cost }}
                                    </p>
                                </div>

                                <div>
                                    <label
                                        class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Cost per Kg ($)') }}</label
                                    >
                                    <input
                                        v-model="form.cost_per_kg"
                                        type="number"
                                        step="0.0001"
                                        min="0"
                                        class="block w-full rounded-xl border border-gray-300 bg-white px-3 py-2.5 text-sm placeholder-gray-400 shadow-sm transition-shadow focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                                    />
                                    <p
                                        v-if="errors.cost_per_kg"
                                        class="mt-1 text-sm text-red-600"
                                    >
                                        {{ errors.cost_per_kg }}
                                    </p>
                                </div>
                            </div>

                            <!-- Description -->
                            <div>
                                <label
                                    class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Description') }}</label
                                >
                                <textarea
                                    v-model="form.description"
                                    rows="4"
                                    class="block w-full rounded-xl border border-gray-300 bg-white px-3 py-2.5 text-sm placeholder-gray-400 shadow-sm transition-shadow focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                                ></textarea>
                                <p
                                    v-if="errors.description"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ errors.description }}
                                </p>
                            </div>

                            <!-- Default -->
                            <div
                                class="rounded-xl border border-gray-200 bg-gray-50 p-4 dark:border-gray-700 dark:bg-gray-700/50"
                            >
                                <label
                                    class="flex cursor-pointer items-center gap-3"
                                >
                                    <input
                                        v-model="form.is_default"
                                        type="checkbox"
                                        class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                    />
                                    <span
                                        class="text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{
                                            $t('Set as default shipping method')
                                        }}</span
                                    >
                                </label>
                            </div>

                            <!-- Actions -->
                            <div
                                class="flex items-center justify-end gap-3 border-t border-gray-200 pt-4 dark:border-gray-700"
                            >
                                <Link
                                    href="/admin/settings/shipping-methods"
                                    class="rounded-xl border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                                >
                                    {{ $t('Cancel') }}
                                </Link>
                                <button
                                    type="submit"
                                    :disabled="loading"
                                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900 disabled:cursor-not-allowed disabled:opacity-50"
                                >
                                    <Save class="mr-2 h-4 w-4" />
                                    {{
                                        loading
                                            ? $t('Saving...')
                                            : $t('Save Changes')
                                    }}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>

                <!-- Sidebar -->
                <div class="space-y-6">
                    <!-- Status Card -->
                    <div
                        class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <h3
                            class="mb-4 flex items-center gap-2 text-lg font-semibold text-gray-900 dark:text-white"
                        >
                            <Activity class="h-5 w-5 text-gray-400" />
                            {{ $t('Status') }}
                        </h3>
                        <div class="space-y-4">
                            <div
                                class="flex items-center justify-between border-b border-gray-100 pb-3 dark:border-gray-700"
                            >
                                <span
                                    class="text-sm text-gray-600 dark:text-gray-400"
                                    >{{ $t('Current Status') }}</span
                                >
                                <span
                                    :class="[
                                        'rounded-full px-2.5 py-0.5 text-xs font-medium capitalize',
                                        method.status === 'active'
                                            ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400'
                                            : 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400',
                                    ]"
                                >
                                    {{ method.status }}
                                </span>
                            </div>
                            <button
                                @click="toggleStatus"
                                :disabled="loading"
                                class="flex w-full items-center justify-center rounded-xl border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 disabled:opacity-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                            >
                                <Power class="mr-2 h-4 w-4" />
                                {{
                                    method.status === 'active'
                                        ? $t('Deactivate Method')
                                        : $t('Activate Method')
                                }}
                            </button>
                        </div>
                    </div>

                    <!-- Info Card -->
                    <div
                        class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <h3
                            class="mb-4 text-lg font-semibold text-gray-900 dark:text-white"
                        >
                            {{ $t('Details') }}
                        </h3>
                        <div class="space-y-3 text-sm">
                            <div class="flex items-center justify-between">
                                <span
                                    class="text-gray-600 dark:text-gray-400"
                                    >{{ $t('Created') }}</span
                                >
                                <div
                                    class="flex items-center gap-1.5 font-medium text-gray-900 dark:text-white"
                                >
                                    <Calendar
                                        class="h-3.5 w-3.5 text-gray-400"
                                    />
                                    <DateDisplay :value="method.created_at" />
                                </div>
                            </div>
                            <div
                                v-if="method.rates && method.rates.length"
                                class="flex items-center justify-between border-t border-gray-100 pt-3 dark:border-gray-700"
                            >
                                <span
                                    class="text-gray-600 dark:text-gray-400"
                                    >{{ $t('Rates') }}</span
                                >
                                <div
                                    class="font-medium text-gray-900 dark:text-white"
                                >
                                    {{
                                        $t('{count} configured', {
                                            count: method.rates.length,
                                        })
                                    }}
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Rates Preview -->
                    <div
                        v-if="
                            method.type === 'calculated' &&
                            method.rates &&
                            method.rates.length
                        "
                        class="rounded-xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <h3
                            class="mb-4 text-lg font-semibold text-gray-900 dark:text-white"
                        >
                            {{ $t('Shipping Rates') }}
                        </h3>
                        <div class="max-h-48 space-y-2 overflow-y-auto text-sm">
                            <div
                                v-for="rate in method.rates"
                                :key="rate.id"
                                class="flex items-center justify-between border-b border-gray-100 pb-2 last:border-0 last:pb-0 dark:border-gray-700"
                            >
                                <div class="flex-1">
                                    <div
                                        class="font-medium text-gray-900 dark:text-white"
                                    >
                                        {{ rate.country }}
                                    </div>
                                    <div class="text-xs text-gray-500">
                                        {{ rate.min_weight }}-{{
                                            rate.max_weight
                                        }}kg
                                    </div>
                                </div>
                                <div class="text-right">
                                    <div
                                        class="font-medium text-gray-900 dark:text-white"
                                    >
                                        {{ formatPrice(rate.base_cost) }}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

<script setup lang="ts">
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, Link, router, usePage } from '@inertiajs/vue3';
import axios from 'axios';
import {
    Activity,
    Calendar,
    ChevronLeft,
    Package,
    Power,
    Save,
    Scale,
    Truck,
} from 'lucide-vue-next';
import { ref } from 'vue';

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

const { formatPrice } = useCurrency();
const page = usePage();
const method = ref<ShippingMethod>(page.props.method as ShippingMethod);

const form = ref({
    name: method.value.name,
    slug: method.value.slug,
    type: method.value.type,
    base_cost: method.value.base_cost,
    cost_per_kg: method.value.cost_per_kg,
    description: method.value.description,
    is_default: method.value.is_default,
});

const errors = ref<Record<string, string>>({});
const loading = ref(false);

const submit = () => {
    loading.value = true;
    errors.value = {};

    router.put(
        `/admin/settings/shipping-methods/${method.value.id}`,
        form.value,
        {
            onSuccess: () => {
                loading.value = false;
            },
            onError: (errs: Record<string, string>) => {
                errors.value = errs;
                loading.value = false;
            },
        },
    );
};

const toggleStatus = async () => {
    loading.value = true;
    try {
        const response = await axios.post(
            `/admin/settings/shipping-methods/${method.value.id}/toggle-status`,
        );
        method.value.status = response.data.status;
    } catch (error) {
        console.error('Error toggling status:', error);
    } finally {
        loading.value = false;
    }
};
</script>

<script setup lang="ts">
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, Link, router } from '@inertiajs/vue3';
import {
    ChevronLeft,
    Info,
    Package,
    Save,
    Scale,
    Truck,
} from 'lucide-vue-next';
import { ref } from 'vue';

const form = ref({
    name: '',
    slug: '',
    type: 'flat-rate',
    base_cost: '0.00',
    cost_per_kg: '0.00',
    description: '',
    is_default: false,
});

const errors = ref<Record<string, string>>({});
const loading = ref(false);

const submit = () => {
    loading.value = true;
    errors.value = {};

    router.post('/admin/settings/shipping-methods', form.value, {
        onSuccess: () => {
            loading.value = false;
        },
        onError: (errs: Record<string, string>) => {
            errors.value = errs;
            loading.value = false;
        },
    });
};
</script>

<template>
    <Head :title="$t('Create Shipping Method')" />

    <AdminLayout :title="$t('Create Shipping Method')">
        <div class="space-y-6">
            <!-- Header -->
            <div class="flex items-center justify-between">
                <div>
                    <h2
                        class="bg-gradient-to-r from-gray-900 to-gray-600 bg-clip-text text-2xl font-bold text-transparent dark:from-white dark:to-gray-300"
                    >
                        {{ $t('Create Shipping Method') }}
                    </h2>
                    <p
                        class="mt-1 flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400"
                    >
                        <Truck class="h-4 w-4" />
                        {{ $t('Add a new shipping method to your store') }}
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
                <div class="space-y-6 lg:col-span-2">
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
                                    :placeholder="$t('e.g., Standard Shipping')"
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
                                    placeholder="e.g., standard-shipping"
                                    class="block w-full rounded-xl border border-gray-300 bg-white px-3 py-2.5 text-sm placeholder-gray-400 shadow-sm transition-shadow focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                                />
                                <p
                                    class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                                >
                                    {{ $t('URL-friendly identifier') }}
                                </p>
                                <p
                                    v-if="errors.slug"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ errors.slug }}
                                </p>
                            </div>

                            <!-- Type -->
                            <div>
                                <label
                                    class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Shipping Type') }}</label
                                >
                                <div
                                    class="grid grid-cols-1 gap-4 sm:grid-cols-2"
                                >
                                    <div
                                        class="relative flex cursor-pointer items-start rounded-xl border p-4 transition-colors hover:bg-gray-50 dark:hover:bg-gray-700/50"
                                        :class="
                                            form.type === 'flat-rate'
                                                ? 'border-blue-500 bg-blue-50/50 ring-1 ring-blue-500 dark:bg-blue-900/20'
                                                : 'border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-800'
                                        "
                                        @click="form.type = 'flat-rate'"
                                    >
                                        <div class="flex h-5 items-center">
                                            <input
                                                v-model="form.type"
                                                value="flat-rate"
                                                type="radio"
                                                class="h-4 w-4 border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600"
                                            />
                                        </div>
                                        <div class="ml-3">
                                            <label
                                                class="flex items-center gap-2 font-medium text-gray-900 dark:text-white"
                                            >
                                                <Package
                                                    class="h-4 w-4 text-gray-500"
                                                />
                                                {{ $t('Flat Rate') }}
                                            </label>
                                            <p
                                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                                            >
                                                {{
                                                    $t(
                                                        'Fixed price regardless of weight',
                                                    )
                                                }}
                                            </p>
                                        </div>
                                    </div>

                                    <div
                                        class="relative flex cursor-pointer items-start rounded-xl border p-4 transition-colors hover:bg-gray-50 dark:hover:bg-gray-700/50"
                                        :class="
                                            form.type === 'calculated'
                                                ? 'border-blue-500 bg-blue-50/50 ring-1 ring-blue-500 dark:bg-blue-900/20'
                                                : 'border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-800'
                                        "
                                        @click="form.type = 'calculated'"
                                    >
                                        <div class="flex h-5 items-center">
                                            <input
                                                v-model="form.type"
                                                value="calculated"
                                                type="radio"
                                                class="h-4 w-4 border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600"
                                            />
                                        </div>
                                        <div class="ml-3">
                                            <label
                                                class="flex items-center gap-2 font-medium text-gray-900 dark:text-white"
                                            >
                                                <Scale
                                                    class="h-4 w-4 text-gray-500"
                                                />
                                                {{ $t('Calculated') }}
                                            </label>
                                            <p
                                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                                            >
                                                {{
                                                    $t(
                                                        'Based on weight and rules',
                                                    )
                                                }}
                                            </p>
                                        </div>
                                    </div>
                                </div>
                                <p
                                    v-if="errors.type"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ errors.type }}
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
                                        placeholder="0.00"
                                        class="block w-full rounded-xl border border-gray-200 bg-white px-3 py-2.5 text-sm placeholder-gray-400 shadow-sm transition-shadow focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-700 dark:bg-gray-800 dark:text-white"
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
                                        placeholder="0.0000"
                                        class="block w-full rounded-xl border border-gray-200 bg-white px-3 py-2.5 text-sm placeholder-gray-400 shadow-sm transition-shadow focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-700 dark:bg-gray-800 dark:text-white"
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
                                    :placeholder="
                                        $t('Describe this shipping method...')
                                    "
                                    rows="4"
                                    class="block w-full rounded-xl border border-gray-200 bg-white px-3 py-2.5 text-sm placeholder-gray-400 shadow-sm transition-shadow focus:border-transparent focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-700 dark:bg-gray-800 dark:text-white"
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
                                            ? $t('Creating...')
                                            : $t('Create Method')
                                    }}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>

                <!-- Sidebar -->
                <div class="space-y-6">
                    <div
                        class="rounded-xl border border-blue-100 bg-blue-50 p-4 dark:border-blue-800 dark:bg-blue-900/20"
                    >
                        <div class="flex">
                            <div class="flex-shrink-0">
                                <Info
                                    class="h-5 w-5 text-blue-400"
                                    aria-hidden="true"
                                />
                            </div>
                            <div class="ml-3">
                                <h3
                                    class="text-sm font-medium text-blue-800 dark:text-blue-300"
                                >
                                    {{ $t('Shipping Configuration') }}
                                </h3>
                                <div
                                    class="mt-2 space-y-3 text-sm text-blue-700 dark:text-blue-400"
                                >
                                    <p>
                                        <span
                                            class="mb-1 block font-semibold"
                                            >{{ $t('Flat Rate:') }}</span
                                        >
                                        {{
                                            $t(
                                                'Charges a fixed base cost regardless of the total weight of the order.',
                                            )
                                        }}
                                    </p>
                                    <p>
                                        <span
                                            class="mb-1 block font-semibold"
                                            >{{ $t('Calculated:') }}</span
                                        >
                                        {{
                                            $t(
                                                'Combines the Base Cost with the Cost per Kg multiplied by the total weight.',
                                            )
                                        }}
                                    </p>
                                    <p class="text-xs opacity-75">
                                        {{
                                            $t(
                                                'Example: Base $5 + ($2/kg * 2kg) = $9 Total',
                                            )
                                        }}
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

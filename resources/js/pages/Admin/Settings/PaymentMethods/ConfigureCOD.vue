<script setup lang="ts">
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, Link, useForm, usePage } from '@inertiajs/vue3';
import { computed } from 'vue';

interface PaymentMethod {
    id: number;
    code: string;
    name: string;
    description: string;
    type: string;
    is_active: boolean;
    is_default: boolean;
    sort_order: number;
    instructions: string;
    configuration: Record<string, any>;
    created_at: string;
    updated_at: string;
}

const props = defineProps<{
    method: PaymentMethod;
}>();

const page = usePage();
const errors = computed(() => page.props.errors as Record<string, string>);

const form = useForm({
    name: props.method.name || 'Cash on Delivery',
    description: props.method.description || '',
    instructions: props.method.instructions || '',
    configuration: {
        min_order_amount: props.method.configuration?.min_order_amount || 0,
        max_order_amount: props.method.configuration?.max_order_amount || 10000,
        min_order_amount_currency:
            props.method.configuration?.min_order_amount_currency || 'USD',
        handling_fee: props.method.configuration?.handling_fee || 0,
        handling_fee_type:
            props.method.configuration?.handling_fee_type || 'fixed',
        handling_fee_minimum:
            props.method.configuration?.handling_fee_minimum || 0,
        handling_fee_maximum:
            props.method.configuration?.handling_fee_maximum || 100,
        enabled_countries: props.method.configuration?.enabled_countries || [],
        enabled_regions: props.method.configuration?.enabled_regions || [],
    },
});

const save = () => {
    form.post(`/admin/settings/payment-methods/cod/save`, {
        preserveScroll: true,
    });
};
</script>

<template>
    <AdminLayout :title="$t('Payment Methods - Cash on Delivery')">
        <Head :title="$t('Configure Cash on Delivery')" />

        <div>
            <!-- Page Header -->
            <div class="mb-6">
                <div class="mb-6 flex items-center justify-between">
                    <div>
                        <h1
                            class="text-2xl font-bold text-gray-800 md:text-3xl dark:text-white"
                        >
                            {{ $t('Cash on Delivery Configuration') }}
                        </h1>
                        <p
                            class="mt-1 text-sm text-gray-600 dark:text-gray-400"
                        >
                            {{
                                $t(
                                    'Configure payment settings for cash on delivery method',
                                )
                            }}
                        </p>
                    </div>
                    <Link
                        href="/admin/settings/payment-methods"
                        class="inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                    >
                        <svg
                            class="mr-2 h-4 w-4"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M10 19l-7-7m0 0l7-7m-7 7h18"
                            />
                        </svg>
                        {{ $t('Back to Payment Methods') }}
                    </Link>
                </div>
            </div>

            <!-- Configuration Form -->
            <form
                @submit.prevent="save"
                class="rounded-lg border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <!-- Basic Information Section -->
                <div class="border-b border-gray-200 p-6 dark:border-gray-700">
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('Basic Information') }}
                    </h2>

                    <div class="space-y-4">
                        <!-- Name -->
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Method Name') }}
                                <span class="text-red-500">*</span>
                            </label>
                            <input
                                v-model="form.name"
                                type="text"
                                :class="[
                                    'w-full rounded-lg border bg-white px-3 py-2 text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500',
                                    errors.name
                                        ? 'border-red-500'
                                        : 'border-gray-300 dark:border-gray-600',
                                ]"
                                :placeholder="$t('Cash on Delivery')"
                            />
                            <p
                                v-if="errors.name"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors.name }}
                            </p>
                        </div>

                        <!-- Description -->
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Description') }}</label
                            >
                            <textarea
                                v-model="form.description"
                                rows="3"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500"
                                :placeholder="
                                    $t('Describe this payment method...')
                                "
                            ></textarea>
                        </div>

                        <!-- Instructions -->
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Customer Instructions') }}</label
                            >
                            <textarea
                                v-model="form.instructions"
                                rows="3"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500"
                                :placeholder="
                                    $t(
                                        'Instructions shown to customers at checkout...',
                                    )
                                "
                            ></textarea>
                        </div>
                    </div>
                </div>

                <!-- Order Amount Limits Section -->
                <div class="border-b border-gray-200 p-6 dark:border-gray-700">
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('Order Amount Limits') }}
                    </h2>

                    <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                        <!-- Minimum Order Amount -->
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Minimum Order Amount') }}</label
                            >
                            <input
                                v-model.number="
                                    form.configuration.min_order_amount
                                "
                                type="number"
                                step="0.01"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500"
                                placeholder="0.00"
                            />
                            <p
                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{ $t('Leave at 0 for no minimum') }}
                            </p>
                        </div>

                        <!-- Maximum Order Amount -->
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Maximum Order Amount') }}</label
                            >
                            <input
                                v-model.number="
                                    form.configuration.max_order_amount
                                "
                                type="number"
                                step="0.01"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500"
                                placeholder="10000.00"
                            />
                            <p
                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{ $t('Leave at 0 for no maximum') }}
                            </p>
                        </div>
                    </div>
                </div>

                <!-- Handling Fee Section -->
                <div class="border-b border-gray-200 p-6 dark:border-gray-700">
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('Handling Fee') }}
                    </h2>

                    <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
                        <!-- Handling Fee Amount -->
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Handling Fee Amount') }}</label
                            >
                            <input
                                v-model.number="form.configuration.handling_fee"
                                type="number"
                                step="0.01"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500"
                                placeholder="0.00"
                            />
                        </div>

                        <!-- Fee Type -->
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Fee Type') }}</label
                            >
                            <select
                                v-model="form.configuration.handling_fee_type"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            >
                                <option value="fixed">
                                    {{ $t('Fixed Amount') }}
                                </option>
                                <option value="percentage">
                                    {{ $t('Percentage') }}
                                </option>
                            </select>
                        </div>

                        <!-- Fee Maximum -->
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Maximum Fee') }}</label
                            >
                            <input
                                v-model.number="
                                    form.configuration.handling_fee_maximum
                                "
                                type="number"
                                step="0.01"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500"
                                placeholder="100.00"
                            />
                        </div>
                    </div>
                </div>

                <!-- Form Actions -->
                <div
                    class="flex justify-end gap-3 border-t border-gray-200 bg-gray-50 px-6 py-4 dark:border-gray-700 dark:bg-gray-900/50"
                >
                    <button
                        type="submit"
                        :disabled="form.processing"
                        class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        {{
                            form.processing
                                ? $t('Saving...')
                                : $t('Save Configuration')
                        }}
                    </button>
                </div>
            </form>
        </div>
    </AdminLayout>
</template>

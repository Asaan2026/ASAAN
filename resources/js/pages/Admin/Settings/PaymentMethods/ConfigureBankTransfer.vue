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
    name: props.method.name || 'Bank Transfer',
    description: props.method.description || '',
    instructions: props.method.instructions || '',
    configuration: {
        bank_name: props.method.configuration?.bank_name || '',
        account_holder_name:
            props.method.configuration?.account_holder_name || '',
        account_number: props.method.configuration?.account_number || '',
        account_type: props.method.configuration?.account_type || 'checking',
        iban: props.method.configuration?.iban || '',
        swift_code: props.method.configuration?.swift_code || '',
        ifsc_code: props.method.configuration?.ifsc_code || '',
        routing_number: props.method.configuration?.routing_number || '',
        bank_address: props.method.configuration?.bank_address || '',
        correspondence_bank:
            props.method.configuration?.correspondence_bank || '',
        correspondent_swift:
            props.method.configuration?.correspondent_swift || '',
        reference_format:
            props.method.configuration?.reference_format || 'order_id',
        verification_required:
            props.method.configuration?.verification_required ?? false,
        verification_days: props.method.configuration?.verification_days || 3,
        min_order_amount: props.method.configuration?.min_order_amount || 0,
        max_order_amount:
            props.method.configuration?.max_order_amount || 100000,
        enabled_countries: props.method.configuration?.enabled_countries || [],
        fees_buyer: props.method.configuration?.fees_buyer ?? false,
        fee_amount: props.method.configuration?.fee_amount || 0,
        fee_type: props.method.configuration?.fee_type || 'fixed',
    },
});

const save = () => {
    form.post(`/admin/settings/payment-methods/bank_transfer/save`, {
        preserveScroll: true,
    });
};
</script>

<template>
    <AdminLayout :title="$t('Payment Methods - Bank Transfer')">
        <Head :title="$t('Configure Bank Transfer')" />

        <div>
            <!-- Page Header -->
            <div class="mb-6">
                <div class="mb-6 flex items-center justify-between">
                    <div>
                        <h1
                            class="text-2xl font-bold text-gray-800 md:text-3xl dark:text-white"
                        >
                            {{ $t('Bank Transfer Configuration') }}
                        </h1>
                        <p
                            class="mt-1 text-sm text-gray-600 dark:text-gray-400"
                        >
                            {{
                                $t(
                                    'Configure bank account details and payment settings for bank transfer method',
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
                                :placeholder="$t('Bank Transfer')"
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

                <!-- Bank Account Details Section -->
                <div class="border-b border-gray-200 p-6 dark:border-gray-700">
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('Bank Account Details') }}
                    </h2>

                    <div class="space-y-4">
                        <!-- Bank Name -->
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Bank Name') }}
                                <span class="text-red-500">*</span>
                            </label>
                            <input
                                v-model="form.configuration.bank_name"
                                type="text"
                                :class="[
                                    'w-full rounded-lg border bg-white px-3 py-2 text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500',
                                    errors['configuration.bank_name']
                                        ? 'border-red-500'
                                        : 'border-gray-300 dark:border-gray-600',
                                ]"
                                :placeholder="$t('e.g., First National Bank')"
                            />
                            <p
                                v-if="errors['configuration.bank_name']"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors['configuration.bank_name'] }}
                            </p>
                        </div>

                        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                            <!-- Account Holder Name -->
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >
                                    {{ $t('Account Holder Name') }}
                                    <span class="text-red-500">*</span>
                                </label>
                                <input
                                    v-model="
                                        form.configuration.account_holder_name
                                    "
                                    type="text"
                                    :class="[
                                        'w-full rounded-lg border bg-white px-3 py-2 text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500',
                                        errors[
                                            'configuration.account_holder_name'
                                        ]
                                            ? 'border-red-500'
                                            : 'border-gray-300 dark:border-gray-600',
                                    ]"
                                    :placeholder="$t('Full name on account')"
                                />
                                <p
                                    v-if="
                                        errors[
                                            'configuration.account_holder_name'
                                        ]
                                    "
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{
                                        errors[
                                            'configuration.account_holder_name'
                                        ]
                                    }}
                                </p>
                            </div>

                            <!-- Account Type -->
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Account Type') }}</label
                                >
                                <select
                                    v-model="form.configuration.account_type"
                                    class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                >
                                    <option value="checking">
                                        {{ $t('Checking') }}
                                    </option>
                                    <option value="savings">
                                        {{ $t('Savings') }}
                                    </option>
                                    <option value="business">
                                        {{ $t('Business') }}
                                    </option>
                                </select>
                            </div>
                        </div>

                        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                            <!-- Account Number -->
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >
                                    {{ $t('Account Number') }}
                                    <span class="text-red-500">*</span>
                                </label>
                                <input
                                    v-model="form.configuration.account_number"
                                    type="text"
                                    :class="[
                                        'w-full rounded-lg border bg-white px-3 py-2 text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500',
                                        errors['configuration.account_number']
                                            ? 'border-red-500'
                                            : 'border-gray-300 dark:border-gray-600',
                                    ]"
                                    placeholder="1234567890"
                                />
                                <p
                                    v-if="
                                        errors['configuration.account_number']
                                    "
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ errors['configuration.account_number'] }}
                                </p>
                            </div>

                            <!-- Routing Number -->
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Routing Number (US)') }}</label
                                >
                                <input
                                    v-model="form.configuration.routing_number"
                                    type="text"
                                    class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500"
                                    placeholder="021000021"
                                />
                            </div>
                        </div>

                        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                            <!-- IBAN -->
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('IBAN (International)') }}</label
                                >
                                <input
                                    v-model="form.configuration.iban"
                                    type="text"
                                    class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500"
                                    placeholder="DE89370400440532013000"
                                />
                            </div>

                            <!-- SWIFT Code -->
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('SWIFT Code') }}</label
                                >
                                <input
                                    v-model="form.configuration.swift_code"
                                    type="text"
                                    class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500"
                                    placeholder="DEUTDEFF"
                                />
                            </div>
                        </div>

                        <!-- IFSC Code (India) -->
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('IFSC Code (India)') }}</label
                            >
                            <input
                                v-model="form.configuration.ifsc_code"
                                type="text"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500"
                                placeholder="SBIN0001234"
                                maxlength="11"
                            />
                            <p
                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{
                                    $t(
                                        'Indian Financial System Code - 11 character code for Indian banks',
                                    )
                                }}
                            </p>
                        </div>
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Bank Address') }}</label
                            >
                            <textarea
                                v-model="form.configuration.bank_address"
                                rows="2"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500"
                                :placeholder="$t('Full address of the bank...')"
                            ></textarea>
                        </div>

                        <!-- Correspondent Bank Details -->
                        <div
                            class="border-t border-gray-200 pt-4 dark:border-gray-700"
                        >
                            <h3
                                class="mb-3 text-sm font-semibold text-gray-900 dark:text-white"
                            >
                                {{ $t('Correspondent Bank (Optional)') }}
                            </h3>

                            <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                                <div>
                                    <label
                                        class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{
                                            $t('Correspondent Bank Name')
                                        }}</label
                                    >
                                    <input
                                        v-model="
                                            form.configuration
                                                .correspondence_bank
                                        "
                                        type="text"
                                        class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500"
                                        :placeholder="
                                            $t('For international transfers')
                                        "
                                    />
                                </div>

                                <div>
                                    <label
                                        class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{
                                            $t('Correspondent SWIFT Code')
                                        }}</label
                                    >
                                    <input
                                        v-model="
                                            form.configuration
                                                .correspondent_swift
                                        "
                                        type="text"
                                        class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500"
                                        :placeholder="
                                            $t('SWIFT code of correspondent')
                                        "
                                    />
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Transfer Settings Section -->
                <div class="border-b border-gray-200 p-6 dark:border-gray-700">
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('Transfer Settings') }}
                    </h2>

                    <div class="space-y-4">
                        <!-- Reference Format -->
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Reference Format') }}</label
                            >
                            <select
                                v-model="form.configuration.reference_format"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            >
                                <option value="order_id">
                                    {{ $t('Order ID') }}
                                </option>
                                <option value="invoice_number">
                                    {{ $t('Invoice Number') }}
                                </option>
                                <option value="custom">
                                    {{ $t('Custom') }}
                                </option>
                            </select>
                            <p
                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{
                                    $t(
                                        'Format for bank transfer reference field',
                                    )
                                }}
                            </p>
                        </div>

                        <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
                            <!-- Verification Required -->
                            <div class="flex items-center">
                                <input
                                    v-model="
                                        form.configuration.verification_required
                                    "
                                    type="checkbox"
                                    class="h-4 w-4 rounded border-gray-300 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                />
                                <label
                                    class="ml-2 text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Verification Required') }}</label
                                >
                            </div>

                            <!-- Verification Days -->
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Verification Days') }}</label
                                >
                                <input
                                    v-model.number="
                                        form.configuration.verification_days
                                    "
                                    type="number"
                                    min="1"
                                    class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500"
                                    placeholder="3"
                                />
                            </div>

                            <!-- Reference Format (Custom) -->
                            <div></div>
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
                                placeholder="100000.00"
                            />
                        </div>
                    </div>
                </div>

                <!-- Fees Section -->
                <div class="border-b border-gray-200 p-6 dark:border-gray-700">
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('Fees') }}
                    </h2>

                    <div class="space-y-4">
                        <div class="flex items-center">
                            <input
                                v-model="form.configuration.fees_buyer"
                                type="checkbox"
                                class="h-4 w-4 rounded border-gray-300 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                            />
                            <label
                                class="ml-2 text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Buyer Pays Transfer Fees') }}</label
                            >
                        </div>

                        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                            <!-- Fee Amount -->
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Fee Amount') }}</label
                                >
                                <input
                                    v-model.number="
                                        form.configuration.fee_amount
                                    "
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
                                    v-model="form.configuration.fee_type"
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

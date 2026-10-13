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
    name: props.method.name || 'Razorpay',
    description: props.method.description || '',
    instructions: props.method.instructions || '',
    configuration: {
        mode: props.method.configuration?.mode || 'test',
        key_id: props.method.configuration?.key_id || '',
        key_secret: props.method.configuration?.key_secret || '',
        test_key_id: props.method.configuration?.test_key_id || '',
        test_key_secret: props.method.configuration?.test_key_secret || '',
        currency: props.method.configuration?.currency || 'INR',
        webhook_secret: props.method.configuration?.webhook_secret || '',
        auto_capture: props.method.configuration?.auto_capture ?? true,
    },
});

const save = () => {
    form.post(`/admin/settings/payment-methods/razorpay/save`, {
        preserveScroll: true,
    });
};
</script>

<template>
    <AdminLayout :title="$t('Payment Methods - Razorpay')">
        <Head :title="$t('Configure Razorpay')" />

        <div>
            <!-- Page Header -->
            <div class="mb-6">
                <div class="mb-6 flex items-center justify-between">
                    <div>
                        <h1
                            class="text-2xl font-bold text-gray-800 md:text-3xl dark:text-white"
                        >
                            {{ $t('Razorpay Configuration') }}
                        </h1>
                        <p
                            class="mt-1 text-sm text-gray-600 dark:text-gray-400"
                        >
                            {{
                                $t(
                                    'Configure Razorpay payment gateway settings',
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
                                placeholder="Razorpay"
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

                <!-- Razorpay API Keys Section -->
                <div class="border-b border-gray-200 p-6 dark:border-gray-700">
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('Environment Mode') }}
                    </h2>

                    <div class="mb-6 flex items-center gap-4">
                        <label
                            class="relative flex cursor-pointer items-center gap-3 rounded-lg border-2 px-4 py-3 transition-all"
                            :class="
                                form.configuration.mode === 'test'
                                    ? 'border-amber-500 bg-amber-50 dark:bg-amber-900/20'
                                    : 'border-gray-200 dark:border-gray-600'
                            "
                        >
                            <input
                                v-model="form.configuration.mode"
                                type="radio"
                                value="test"
                                class="sr-only"
                            />
                            <div
                                class="flex h-4 w-4 items-center justify-center rounded-full border-2"
                                :class="
                                    form.configuration.mode === 'test'
                                        ? 'border-amber-500'
                                        : 'border-gray-300'
                                "
                            >
                                <div
                                    v-if="form.configuration.mode === 'test'"
                                    class="h-2 w-2 rounded-full bg-amber-500"
                                ></div>
                            </div>
                            <div>
                                <div
                                    class="text-sm font-semibold"
                                    :class="
                                        form.configuration.mode === 'test'
                                            ? 'text-amber-700 dark:text-amber-400'
                                            : 'text-gray-700 dark:text-gray-300'
                                    "
                                >
                                    {{ $t('Test Mode') }}
                                </div>
                                <div class="text-xs text-gray-500">
                                    {{
                                        $t('Use test API keys for development')
                                    }}
                                </div>
                            </div>
                        </label>
                        <label
                            class="relative flex cursor-pointer items-center gap-3 rounded-lg border-2 px-4 py-3 transition-all"
                            :class="
                                form.configuration.mode === 'production'
                                    ? 'border-green-500 bg-green-50 dark:bg-green-900/20'
                                    : 'border-gray-200 dark:border-gray-600'
                            "
                        >
                            <input
                                v-model="form.configuration.mode"
                                type="radio"
                                value="production"
                                class="sr-only"
                            />
                            <div
                                class="flex h-4 w-4 items-center justify-center rounded-full border-2"
                                :class="
                                    form.configuration.mode === 'production'
                                        ? 'border-green-500'
                                        : 'border-gray-300'
                                "
                            >
                                <div
                                    v-if="
                                        form.configuration.mode === 'production'
                                    "
                                    class="h-2 w-2 rounded-full bg-green-500"
                                ></div>
                            </div>
                            <div>
                                <div
                                    class="text-sm font-semibold"
                                    :class="
                                        form.configuration.mode === 'production'
                                            ? 'text-green-700 dark:text-green-400'
                                            : 'text-gray-700 dark:text-gray-300'
                                    "
                                >
                                    {{ $t('Production Mode') }}
                                </div>
                                <div class="text-xs text-gray-500">
                                    {{
                                        $t(
                                            'Use live API keys for real transactions',
                                        )
                                    }}
                                </div>
                            </div>
                        </label>
                    </div>

                    <div
                        v-if="form.configuration.mode === 'test'"
                        class="mb-6 rounded-lg border border-amber-200 bg-amber-50 p-4 dark:border-amber-800 dark:bg-amber-900/30"
                    >
                        <p class="text-sm text-amber-800 dark:text-amber-200">
                            <strong>{{ $t('⚠ Test Mode Active:') }}</strong>
                            {{
                                $t(
                                    'No real charges will be made. Use Razorpay test keys (starting with',
                                )
                            }}
                            <code
                                class="rounded bg-amber-100 px-1 dark:bg-amber-800"
                                >rzp_test_</code
                            >{{ $t(').') }}
                        </p>
                    </div>

                    <div
                        v-if="form.configuration.mode === 'production'"
                        class="mb-6 rounded-lg border border-green-200 bg-green-50 p-4 dark:border-green-800 dark:bg-green-900/30"
                    >
                        <p class="text-sm text-green-800 dark:text-green-200">
                            <strong>{{ $t('✓ Production Mode:') }}</strong>
                            {{
                                $t(
                                    'Real charges will be processed. Use live keys (starting with',
                                )
                            }}
                            <code
                                class="rounded bg-green-100 px-1 dark:bg-green-800"
                                >rzp_live_</code
                            >{{ $t(').') }}
                        </p>
                    </div>

                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-white"
                    >
                        {{
                            form.configuration.mode === 'test'
                                ? $t('Test')
                                : $t('Production')
                        }}
                        {{ $t('API Keys') }}
                    </h2>

                    <div
                        class="mb-4 rounded-lg border border-blue-200 bg-blue-50 p-4 dark:border-blue-800 dark:bg-blue-900/30"
                    >
                        <p class="text-sm text-blue-900 dark:text-blue-200">
                            <strong>{{ $t('Get your keys:') }}</strong>
                            {{ $t('Log in to your') }}
                            <a
                                href="https://dashboard.razorpay.com/app/keys"
                                target="_blank"
                                class="underline"
                                >Razorpay Dashboard</a
                            >
                            {{ $t('→ Settings → API Keys') }}
                        </p>
                    </div>

                    <div class="space-y-4">
                        <!-- Test Keys -->
                        <template v-if="form.configuration.mode === 'test'">
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >
                                    {{ $t('Test Key ID') }}
                                    <span class="text-red-500">*</span>
                                </label>
                                <input
                                    v-model="form.configuration.test_key_id"
                                    type="text"
                                    :class="[
                                        'w-full rounded-lg border bg-white px-3 py-2 font-mono text-sm text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500',
                                        errors['configuration.test_key_id']
                                            ? 'border-red-500'
                                            : 'border-gray-300 dark:border-gray-600',
                                    ]"
                                    placeholder="rzp_test_..."
                                />
                                <p
                                    v-if="errors['configuration.test_key_id']"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ errors['configuration.test_key_id'] }}
                                </p>
                            </div>
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >
                                    {{ $t('Test Key Secret') }}
                                    <span class="text-red-500">*</span>
                                </label>
                                <input
                                    v-model="form.configuration.test_key_secret"
                                    type="password"
                                    :class="[
                                        'w-full rounded-lg border bg-white px-3 py-2 font-mono text-sm text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500',
                                        errors['configuration.test_key_secret']
                                            ? 'border-red-500'
                                            : 'border-gray-300 dark:border-gray-600',
                                    ]"
                                    :placeholder="
                                        $t('Enter your Test Key Secret')
                                    "
                                />
                                <p
                                    v-if="
                                        errors['configuration.test_key_secret']
                                    "
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{
                                        errors['configuration.test_key_secret']
                                    }}
                                </p>
                            </div>
                        </template>

                        <!-- Production Keys -->
                        <template v-else>
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >
                                    {{ $t('Live Key ID') }}
                                    <span class="text-red-500">*</span>
                                </label>
                                <input
                                    v-model="form.configuration.key_id"
                                    type="text"
                                    :class="[
                                        'w-full rounded-lg border bg-white px-3 py-2 font-mono text-sm text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500',
                                        errors['configuration.key_id']
                                            ? 'border-red-500'
                                            : 'border-gray-300 dark:border-gray-600',
                                    ]"
                                    placeholder="rzp_live_..."
                                />
                                <p
                                    v-if="errors['configuration.key_id']"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ errors['configuration.key_id'] }}
                                </p>
                            </div>
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >
                                    {{ $t('Live Key Secret') }}
                                    <span class="text-red-500">*</span>
                                </label>
                                <input
                                    v-model="form.configuration.key_secret"
                                    type="password"
                                    :class="[
                                        'w-full rounded-lg border bg-white px-3 py-2 font-mono text-sm text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500',
                                        errors['configuration.key_secret']
                                            ? 'border-red-500'
                                            : 'border-gray-300 dark:border-gray-600',
                                    ]"
                                    :placeholder="
                                        $t('Enter your Live Key Secret')
                                    "
                                />
                                <p
                                    v-if="errors['configuration.key_secret']"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ errors['configuration.key_secret'] }}
                                </p>
                            </div>
                        </template>

                        <!-- Currency -->
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Currency') }}
                                <span class="text-red-500">*</span>
                            </label>
                            <select
                                v-model="form.configuration.currency"
                                :class="[
                                    'w-full rounded-lg border bg-white px-3 py-2 text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white',
                                    errors['configuration.currency']
                                        ? 'border-red-500'
                                        : 'border-gray-300 dark:border-gray-600',
                                ]"
                            >
                                <option value="INR">
                                    {{ $t('Indian Rupee (INR)') }}
                                </option>
                                <option value="USD">
                                    {{ $t('US Dollar (USD)') }}
                                </option>
                                <option value="EUR">
                                    {{ $t('Euro (EUR)') }}
                                </option>
                                <option value="GBP">
                                    {{ $t('British Pound (GBP)') }}
                                </option>
                            </select>
                            <p
                                v-if="errors['configuration.currency']"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors['configuration.currency'] }}
                            </p>
                            <p
                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{
                                    $t(
                                        'Razorpay primarily supports INR for domestic Indian payments',
                                    )
                                }}
                            </p>
                        </div>

                        <!-- Webhook Secret (Optional) -->
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Webhook Secret') }}
                                <span class="text-gray-400 dark:text-gray-500"
                                    >({{ $t('Optional') }})</span
                                >
                            </label>
                            <input
                                v-model="form.configuration.webhook_secret"
                                type="password"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 font-mono text-sm text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500"
                                placeholder="whsec_..."
                            />
                            <p
                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{ $t('Configure webhooks in your') }}
                                <a
                                    href="https://dashboard.razorpay.com/app/webhooks"
                                    target="_blank"
                                    class="text-blue-600 underline dark:text-blue-400"
                                    >Razorpay Dashboard</a
                                >
                            </p>
                        </div>

                        <!-- Auto Capture -->
                        <div>
                            <label class="flex items-center">
                                <input
                                    v-model="form.configuration.auto_capture"
                                    type="checkbox"
                                    class="focus:ring-opacity-50 rounded border-gray-300 text-blue-600 shadow-sm focus:border-blue-300 focus:ring focus:ring-blue-200 dark:border-gray-600 dark:bg-gray-700"
                                />
                                <span
                                    class="ml-2 text-sm text-gray-700 dark:text-gray-300"
                                    >{{ $t('Auto-capture payments') }}</span
                                >
                            </label>
                            <p
                                class="mt-1 ml-6 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{
                                    $t(
                                        'Automatically capture payments after authorization (recommended)',
                                    )
                                }}
                            </p>
                        </div>
                    </div>
                </div>

                <!-- Payment Methods Info -->
                <div class="border-b border-gray-200 p-6 dark:border-gray-700">
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('Supported Payment Methods') }}
                    </h2>
                    <div
                        class="rounded-lg border border-green-200 bg-green-50 p-4 dark:border-green-800 dark:bg-green-900/30"
                    >
                        <p
                            class="mb-2 text-sm text-green-900 dark:text-green-200"
                        >
                            <strong>{{
                                $t(
                                    'Razorpay supports multiple payment methods:',
                                )
                            }}</strong>
                        </p>
                        <ul
                            class="ml-4 list-disc space-y-1 text-sm text-green-800 dark:text-green-300"
                        >
                            <li>
                                {{
                                    $t(
                                        'Credit & Debit Cards (Visa, Mastercard, Maestro, RuPay)',
                                    )
                                }}
                            </li>
                            <li>
                                {{
                                    $t('UPI (Google Pay, PhonePe, Paytm, etc.)')
                                }}
                            </li>
                            <li>
                                {{ $t('Net Banking (All major Indian banks)') }}
                            </li>
                            <li>
                                {{
                                    $t(
                                        'Wallets (Paytm, Mobikwik, Freecharge, etc.)',
                                    )
                                }}
                            </li>
                            <li>{{ $t('EMI (Easy Monthly Installments)') }}</li>
                        </ul>
                    </div>
                </div>

                <!-- Gateway Redirect Notice -->
                <div class="border-b border-gray-200 p-6 dark:border-gray-700">
                    <div
                        class="rounded-lg border border-blue-200 bg-blue-50 p-4 dark:border-blue-800 dark:bg-blue-900/30"
                    >
                        <p class="text-sm text-blue-900 dark:text-blue-200">
                            <strong>{{ $t('Payment Processing:') }}</strong>
                            {{
                                $t(
                                    "Customers will see the Razorpay payment interface to complete their transactions securely. All payments are processed through Razorpay's secure gateway.",
                                )
                            }}
                        </p>
                    </div>
                </div>

                <!-- Submit Button -->
                <div
                    class="flex justify-end border-t border-gray-200 bg-gray-50 p-6 dark:border-gray-700 dark:bg-gray-900/50"
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

<style scoped>
code {
    font-family: 'Courier New', monospace;
    font-size: 12px;
}
</style>

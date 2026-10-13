<script setup lang="ts">
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, useForm, usePage } from '@inertiajs/vue3';
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
    name: props.method.name || 'Stripe',
    description: props.method.description || '',
    instructions: props.method.instructions || '',
    configuration: {
        public_key: props.method.configuration?.public_key || '',
        enable_3d_secure: props.method.configuration?.enable_3d_secure ?? true,
        save_payment_method:
            props.method.configuration?.save_payment_method ?? true,
        payment_methods: {
            card: props.method.configuration?.payment_methods?.card ?? true,
            apple_pay:
                props.method.configuration?.payment_methods?.apple_pay ?? true,
            google_pay:
                props.method.configuration?.payment_methods?.google_pay ?? true,
            ideal: props.method.configuration?.payment_methods?.ideal ?? false,
            bancontact:
                props.method.configuration?.payment_methods?.bancontact ??
                false,
            eps: props.method.configuration?.payment_methods?.eps ?? false,
            giropay:
                props.method.configuration?.payment_methods?.giropay ?? false,
            klarna:
                props.method.configuration?.payment_methods?.klarna ?? false,
            p24: props.method.configuration?.payment_methods?.p24 ?? false,
            alipay:
                props.method.configuration?.payment_methods?.alipay ?? false,
        },
    },
});

const save = () => {
    form.post(`/admin/payment-methods/stripe/save`, {
        preserveScroll: true,
    });
};
</script>

<template>
    <AdminLayout :title="$t('Payment Methods - Stripe')">
        <Head :title="$t('Configure Stripe')" />

        <div class="p-6">
            <!-- Page Header -->
            <div class="mb-6">
                <div class="mb-2 flex items-center gap-3">
                    <a
                        href="/admin/settings/payment-methods"
                        class="font-medium text-blue-600 hover:text-blue-700"
                        >{{ $t('← Payment Methods') }}</a
                    >
                </div>
                <h1 class="text-2xl font-bold text-gray-900 dark:text-gray-100">
                    {{ $t('Stripe Configuration') }}
                </h1>
                <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                    {{ $t('Configure Stripe payment gateway settings') }}
                </p>
            </div>

            <!-- Configuration Form -->
            <form
                @submit.prevent="save"
                class="rounded-lg border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <!-- Basic Information Section -->
                <div class="border-b border-gray-200 p-6 dark:border-gray-700">
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-gray-100"
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
                                    'w-full rounded-lg border px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500',
                                    errors.name
                                        ? 'border-red-500'
                                        : 'border-gray-300 dark:border-gray-600',
                                ]"
                                placeholder="Stripe"
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
                                class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
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
                                class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                :placeholder="
                                    $t(
                                        'Instructions shown to customers at checkout...',
                                    )
                                "
                            ></textarea>
                        </div>
                    </div>
                </div>

                <!-- Stripe API Keys Section -->
                <div class="border-b border-gray-200 p-6 dark:border-gray-700">
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-gray-100"
                    >
                        {{ $t('Stripe API Keys') }}
                    </h2>

                    <div
                        class="mb-4 rounded-lg border border-blue-200 bg-blue-50 p-4"
                    >
                        <p class="text-sm text-blue-900">
                            <strong>{{ $t('Get your keys:') }}</strong>
                            {{ $t('Log in to your') }} Stripe Dashboard
                            {{ $t('→ Settings → API Keys') }}
                        </p>
                    </div>

                    <div class="space-y-4">
                        <!-- Public Key -->
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Publishable Key') }}
                                <span class="text-red-500">*</span>
                            </label>
                            <input
                                v-model="form.configuration.public_key"
                                type="text"
                                :class="[
                                    'w-full rounded-lg border px-3 py-2 font-mono text-sm focus:border-transparent focus:ring-2 focus:ring-blue-500',
                                    errors['configuration.public_key']
                                        ? 'border-red-500'
                                        : 'border-gray-300 dark:border-gray-600',
                                ]"
                                placeholder="pk_live_..."
                            />
                            <p
                                v-if="errors['configuration.public_key']"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors['configuration.public_key'] }}
                            </p>
                            <p
                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{ $t('Starts with') }}
                                <code
                                    class="rounded bg-gray-100 px-1 dark:bg-gray-800/60"
                                    >pk_</code
                                >
                            </p>
                        </div>
                    </div>
                </div>

                <!-- Payment Features Section -->
                <div class="border-b border-gray-200 p-6 dark:border-gray-700">
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-gray-100"
                    >
                        {{ $t('Payment Features') }}
                    </h2>

                    <div class="space-y-4">
                        <!-- Enable 3D Secure -->
                        <div class="flex items-center">
                            <input
                                v-model="form.configuration.enable_3d_secure"
                                type="checkbox"
                                id="enable_3d_secure"
                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                            />
                            <label
                                for="enable_3d_secure"
                                class="ml-3 flex flex-col"
                            >
                                <span
                                    class="block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Enable 3D Secure') }}</span
                                >
                                <span
                                    class="text-xs text-gray-500 dark:text-gray-400"
                                    >{{
                                        $t(
                                            'Adds an extra layer of security to card payments',
                                        )
                                    }}</span
                                >
                            </label>
                        </div>

                        <!-- Save Payment Method -->
                        <div class="flex items-center">
                            <input
                                v-model="form.configuration.save_payment_method"
                                type="checkbox"
                                id="save_payment_method"
                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                            />
                            <label
                                for="save_payment_method"
                                class="ml-3 flex flex-col"
                            >
                                <span
                                    class="block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Save Payment Methods') }}</span
                                >
                                <span
                                    class="text-xs text-gray-500 dark:text-gray-400"
                                    >{{
                                        $t(
                                            'Allow customers to save payment methods for future purchases',
                                        )
                                    }}</span
                                >
                            </label>
                        </div>
                    </div>
                </div>

                <!-- Supported Payment Methods Section -->
                <div class="border-b border-gray-200 p-6 dark:border-gray-700">
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-gray-100"
                    >
                        {{ $t('Supported Payment Methods') }}
                    </h2>

                    <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                        <!-- Card -->
                        <div class="flex items-center">
                            <input
                                v-model="
                                    form.configuration.payment_methods.card
                                "
                                type="checkbox"
                                id="card"
                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                            />
                            <label
                                for="card"
                                class="ml-3 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Credit/Debit Card') }}</label
                            >
                        </div>

                        <!-- Apple Pay -->
                        <div class="flex items-center">
                            <input
                                v-model="
                                    form.configuration.payment_methods.apple_pay
                                "
                                type="checkbox"
                                id="apple_pay"
                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                            />
                            <label
                                for="apple_pay"
                                class="ml-3 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >Apple Pay</label
                            >
                        </div>

                        <!-- Google Pay -->
                        <div class="flex items-center">
                            <input
                                v-model="
                                    form.configuration.payment_methods
                                        .google_pay
                                "
                                type="checkbox"
                                id="google_pay"
                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                            />
                            <label
                                for="google_pay"
                                class="ml-3 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >Google Pay</label
                            >
                        </div>

                        <!-- iDEAL (Netherlands) -->
                        <div class="flex items-center">
                            <input
                                v-model="
                                    form.configuration.payment_methods.ideal
                                "
                                type="checkbox"
                                id="ideal"
                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                            />
                            <label
                                for="ideal"
                                class="ml-3 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >iDEAL (Netherlands)</label
                            >
                        </div>

                        <!-- Bancontact (Belgium) -->
                        <div class="flex items-center">
                            <input
                                v-model="
                                    form.configuration.payment_methods
                                        .bancontact
                                "
                                type="checkbox"
                                id="bancontact"
                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                            />
                            <label
                                for="bancontact"
                                class="ml-3 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >Bancontact (Belgium)</label
                            >
                        </div>

                        <!-- EPS (Austria) -->
                        <div class="flex items-center">
                            <input
                                v-model="form.configuration.payment_methods.eps"
                                type="checkbox"
                                id="eps"
                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                            />
                            <label
                                for="eps"
                                class="ml-3 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >EPS (Austria)</label
                            >
                        </div>

                        <!-- Giropay (Germany) -->
                        <div class="flex items-center">
                            <input
                                v-model="
                                    form.configuration.payment_methods.giropay
                                "
                                type="checkbox"
                                id="giropay"
                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                            />
                            <label
                                for="giropay"
                                class="ml-3 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >Giropay (Germany)</label
                            >
                        </div>

                        <!-- Klarna -->
                        <div class="flex items-center">
                            <input
                                v-model="
                                    form.configuration.payment_methods.klarna
                                "
                                type="checkbox"
                                id="klarna"
                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                            />
                            <label
                                for="klarna"
                                class="ml-3 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >Klarna (Buy Now Pay Later)</label
                            >
                        </div>

                        <!-- Przelewy24 (Poland) -->
                        <div class="flex items-center">
                            <input
                                v-model="form.configuration.payment_methods.p24"
                                type="checkbox"
                                id="p24"
                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                            />
                            <label
                                for="p24"
                                class="ml-3 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >Przelewy24 (Poland)</label
                            >
                        </div>

                        <!-- Alipay (China) -->
                        <div class="flex items-center">
                            <input
                                v-model="
                                    form.configuration.payment_methods.alipay
                                "
                                type="checkbox"
                                id="alipay"
                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                            />
                            <label
                                for="alipay"
                                class="ml-3 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >Alipay (China)</label
                            >
                        </div>
                    </div>
                </div>

                <!-- Submit Button -->
                <div
                    class="flex justify-between border-t border-gray-200 bg-gray-50 p-6 dark:border-gray-700 dark:bg-gray-900"
                >
                    <a
                        href="/admin/settings/payment-methods"
                        class="rounded-lg border border-gray-300 px-4 py-2 text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                    >
                        {{ $t('Cancel') }}
                    </a>
                    <button
                        type="submit"
                        :disabled="form.processing"
                        class="rounded-lg bg-blue-600 px-6 py-2 text-white transition hover:bg-blue-700 disabled:bg-gray-400"
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

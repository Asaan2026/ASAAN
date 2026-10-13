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
    name: props.method.name || 'PayUMoney',
    description: props.method.description || '',
    instructions: props.method.instructions || '',
    configuration: {
        merchant_key: props.method.configuration?.merchant_key || '',
        merchant_salt: props.method.configuration?.merchant_salt || '',
        mode: props.method.configuration?.mode || 'test',
        auth_header: props.method.configuration?.auth_header || '',
    },
});

const save = () => {
    form.post('/admin/settings/payment-methods/payumoney/save', {
        preserveScroll: true,
    });
};
</script>

<template>
    <AdminLayout :title="$t('Payment Methods - PayUMoney')">
        <Head :title="$t('Configure PayUMoney')" />

        <div>
            <div class="mb-6">
                <div class="mb-6 flex items-center justify-between">
                    <div>
                        <h1
                            class="text-2xl font-bold text-gray-800 md:text-3xl dark:text-white"
                        >
                            {{ $t('PayUMoney Configuration') }}
                        </h1>
                        <p
                            class="mt-1 text-sm text-gray-600 dark:text-gray-400"
                        >
                            {{
                                $t(
                                    'Configure PayUMoney payment gateway settings',
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

            <form
                @submit.prevent="save"
                class="rounded-lg border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div class="border-b border-gray-200 p-6 dark:border-gray-700">
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('Basic Information') }}
                    </h2>

                    <div class="space-y-4">
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Method Name') }}
                                <span class="text-red-500">*</span></label
                            >
                            <input
                                v-model="form.name"
                                type="text"
                                :class="[
                                    'w-full rounded-lg border bg-white px-3 py-2 text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500',
                                    errors.name
                                        ? 'border-red-500'
                                        : 'border-gray-300 dark:border-gray-600',
                                ]"
                                placeholder="PayUMoney"
                            />
                            <p
                                v-if="errors.name"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors.name }}
                            </p>
                        </div>

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

                <div class="border-b border-gray-200 p-6 dark:border-gray-700">
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('PayUMoney Credentials') }}
                    </h2>

                    <div
                        class="mb-4 rounded-lg border border-blue-200 bg-blue-50 p-4 dark:border-blue-800 dark:bg-blue-900/30"
                    >
                        <p class="text-sm text-blue-900 dark:text-blue-200">
                            <strong>{{ $t('Get your credentials:') }}</strong>
                            {{
                                $t(
                                    'Log in to your PayUMoney merchant dashboard',
                                )
                            }}
                        </p>
                    </div>

                    <div class="space-y-4">
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Merchant Key') }}
                                <span class="text-red-500">*</span></label
                            >
                            <input
                                v-model="form.configuration.merchant_key"
                                type="text"
                                :class="[
                                    'w-full rounded-lg border bg-white px-3 py-2 font-mono text-sm text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500',
                                    errors['configuration.merchant_key']
                                        ? 'border-red-500'
                                        : 'border-gray-300 dark:border-gray-600',
                                ]"
                                :placeholder="$t('Merchant Key')"
                            />
                            <p
                                v-if="errors['configuration.merchant_key']"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors['configuration.merchant_key'] }}
                            </p>
                        </div>

                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Merchant Salt') }}
                                <span class="text-red-500">*</span></label
                            >
                            <input
                                v-model="form.configuration.merchant_salt"
                                type="password"
                                :class="[
                                    'w-full rounded-lg border bg-white px-3 py-2 font-mono text-sm text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500',
                                    errors['configuration.merchant_salt']
                                        ? 'border-red-500'
                                        : 'border-gray-300 dark:border-gray-600',
                                ]"
                                :placeholder="$t('Merchant Salt')"
                            />
                            <p
                                v-if="errors['configuration.merchant_salt']"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors['configuration.merchant_salt'] }}
                            </p>
                        </div>

                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Mode') }}
                                <span class="text-red-500">*</span></label
                            >
                            <select
                                v-model="form.configuration.mode"
                                :class="[
                                    'w-full rounded-lg border bg-white px-3 py-2 text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white',
                                    errors['configuration.mode']
                                        ? 'border-red-500'
                                        : 'border-gray-300 dark:border-gray-600',
                                ]"
                            >
                                <option value="test">{{ $t('Test') }}</option>
                                <option value="production">
                                    {{ $t('Production') }}
                                </option>
                            </select>
                            <p
                                v-if="errors['configuration.mode']"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors['configuration.mode'] }}
                            </p>
                        </div>

                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Auth Header') }}
                                <span class="text-gray-400 dark:text-gray-500"
                                    >({{ $t('Optional') }})</span
                                ></label
                            >
                            <input
                                v-model="form.configuration.auth_header"
                                type="text"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 font-mono text-sm text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500"
                                :placeholder="$t('Authorization Header')"
                            />
                        </div>
                    </div>
                </div>

                <div
                    class="flex justify-end border-t border-gray-200 bg-gray-50 px-6 py-4 dark:border-gray-700 dark:bg-gray-900/50"
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

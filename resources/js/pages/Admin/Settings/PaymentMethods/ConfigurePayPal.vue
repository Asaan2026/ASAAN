<script setup lang="ts">
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, Link, useForm, usePage } from '@inertiajs/vue3';
import { computed, onMounted, ref } from 'vue';

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

const webhookUrl = ref('/webhooks/paypal');
onMounted(() => {
    if (typeof window !== 'undefined') {
        webhookUrl.value = `${window.location.origin}/webhooks/paypal`;
    }
});

const form = useForm({
    name: props.method.name || 'PayPal',
    description: props.method.description || '',
    instructions: props.method.instructions || '',
    configuration: {
        mode: props.method.configuration?.mode || 'sandbox',
        // Live credentials
        client_id: props.method.configuration?.client_id || '',
        client_secret: props.method.configuration?.client_secret || '',
        webhook_id: props.method.configuration?.webhook_id || '',
        // Sandbox credentials
        sandbox_client_id: props.method.configuration?.sandbox_client_id || '',
        sandbox_client_secret:
            props.method.configuration?.sandbox_client_secret || '',
        sandbox_webhook_id:
            props.method.configuration?.sandbox_webhook_id || '',
    },
});

const save = () => {
    form.post('/admin/settings/payment-methods/paypal/save', {
        preserveScroll: true,
    });
};
</script>

<template>
    <AdminLayout :title="$t('Payment Methods - PayPal')">
        <Head :title="$t('Configure PayPal')" />

        <div>
            <div class="mb-6">
                <div class="mb-6 flex items-center justify-between">
                    <div>
                        <h1
                            class="text-2xl font-bold text-gray-800 md:text-3xl dark:text-white"
                        >
                            {{ $t('PayPal Configuration') }}
                        </h1>
                        <p
                            class="mt-1 text-sm text-gray-600 dark:text-gray-400"
                        >
                            {{
                                $t('Configure PayPal payment gateway settings')
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
                <!-- Basic Information -->
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
                                placeholder="PayPal"
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

                <!-- Environment Mode Toggle -->
                <div class="border-b border-gray-200 p-6 dark:border-gray-700">
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('Environment Mode') }}
                    </h2>

                    <div class="mb-6 flex items-center gap-4">
                        <!-- Sandbox Mode -->
                        <label
                            class="relative flex cursor-pointer items-center gap-3 rounded-lg border-2 px-4 py-3 transition-all"
                            :class="
                                form.configuration.mode === 'sandbox'
                                    ? 'border-amber-500 bg-amber-50 dark:bg-amber-900/20'
                                    : 'border-gray-200 dark:border-gray-600'
                            "
                        >
                            <input
                                v-model="form.configuration.mode"
                                type="radio"
                                value="sandbox"
                                class="sr-only"
                            />
                            <div
                                class="flex h-4 w-4 items-center justify-center rounded-full border-2"
                                :class="
                                    form.configuration.mode === 'sandbox'
                                        ? 'border-amber-500'
                                        : 'border-gray-300'
                                "
                            >
                                <div
                                    v-if="form.configuration.mode === 'sandbox'"
                                    class="h-2 w-2 rounded-full bg-amber-500"
                                ></div>
                            </div>
                            <div>
                                <div
                                    class="text-sm font-semibold"
                                    :class="
                                        form.configuration.mode === 'sandbox'
                                            ? 'text-amber-700 dark:text-amber-400'
                                            : 'text-gray-700 dark:text-gray-300'
                                    "
                                >
                                    {{ $t('Sandbox Mode') }}
                                </div>
                                <div class="text-xs text-gray-500">
                                    {{ $t('No real charges') }}
                                </div>
                            </div>
                        </label>

                        <!-- Live Mode -->
                        <label
                            class="relative flex cursor-pointer items-center gap-3 rounded-lg border-2 px-4 py-3 transition-all"
                            :class="
                                form.configuration.mode === 'live'
                                    ? 'border-green-500 bg-green-50 dark:bg-green-900/20'
                                    : 'border-gray-200 dark:border-gray-600'
                            "
                        >
                            <input
                                v-model="form.configuration.mode"
                                type="radio"
                                value="live"
                                class="sr-only"
                            />
                            <div
                                class="flex h-4 w-4 items-center justify-center rounded-full border-2"
                                :class="
                                    form.configuration.mode === 'live'
                                        ? 'border-green-500'
                                        : 'border-gray-300'
                                "
                            >
                                <div
                                    v-if="form.configuration.mode === 'live'"
                                    class="h-2 w-2 rounded-full bg-green-500"
                                ></div>
                            </div>
                            <div>
                                <div
                                    class="text-sm font-semibold"
                                    :class="
                                        form.configuration.mode === 'live'
                                            ? 'text-green-700 dark:text-green-400'
                                            : 'text-gray-700 dark:text-gray-300'
                                    "
                                >
                                    {{ $t('Live Mode') }}
                                </div>
                                <div class="text-xs text-gray-500">
                                    {{ $t('Real transactions') }}
                                </div>
                            </div>
                        </label>
                    </div>

                    <div
                        v-if="form.configuration.mode === 'sandbox'"
                        class="rounded-lg border border-amber-200 bg-amber-50 p-4 dark:border-amber-800 dark:bg-amber-900/30"
                    >
                        <p class="text-sm text-amber-800 dark:text-amber-200">
                            <strong
                                >&#9888;
                                {{ $t('Sandbox Mode Active:') }}</strong
                            >
                            {{
                                $t(
                                    'No real charges will be made. Use your PayPal sandbox app credentials from the Developer Dashboard.',
                                )
                            }}
                        </p>
                    </div>
                    <div
                        v-if="form.configuration.mode === 'live'"
                        class="rounded-lg border border-green-200 bg-green-50 p-4 dark:border-green-800 dark:bg-green-900/30"
                    >
                        <p class="text-sm text-green-800 dark:text-green-200">
                            <strong>&#10003; {{ $t('Live Mode:') }}</strong>
                            {{
                                $t(
                                    "Real charges will be processed via PayPal's production environment.",
                                )
                            }}
                        </p>
                    </div>
                </div>

                <!-- API Credentials -->
                <div class="border-b border-gray-200 p-6 dark:border-gray-700">
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-white"
                    >
                        {{
                            form.configuration.mode === 'sandbox'
                                ? $t('Sandbox')
                                : $t('Live')
                        }}
                        {{ $t('API Credentials') }}
                    </h2>

                    <div
                        class="mb-4 rounded-lg border border-blue-200 bg-blue-50 p-4 dark:border-blue-800 dark:bg-blue-900/30"
                    >
                        <p class="text-sm text-blue-900 dark:text-blue-200">
                            <strong>{{ $t('Get your credentials:') }}</strong>
                            {{ $t('Log in to your') }}
                            <a
                                href="https://developer.paypal.com/dashboard/applications"
                                target="_blank"
                                class="underline"
                                >PayPal Developer Dashboard</a
                            >
                            {{ $t('→ Apps & Credentials') }}
                        </p>
                    </div>

                    <div class="space-y-4">
                        <!-- Sandbox credentials -->
                        <template v-if="form.configuration.mode === 'sandbox'">
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Sandbox Client ID') }}
                                    <span class="text-red-500">*</span></label
                                >
                                <input
                                    v-model="
                                        form.configuration.sandbox_client_id
                                    "
                                    type="text"
                                    :class="[
                                        'w-full rounded-lg border bg-white px-3 py-2 font-mono text-sm text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500',
                                        errors[
                                            'configuration.sandbox_client_id'
                                        ]
                                            ? 'border-red-500'
                                            : 'border-gray-300 dark:border-gray-600',
                                    ]"
                                    :placeholder="$t('Sandbox Client ID')"
                                />
                                <p
                                    v-if="
                                        errors[
                                            'configuration.sandbox_client_id'
                                        ]
                                    "
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{
                                        errors[
                                            'configuration.sandbox_client_id'
                                        ]
                                    }}
                                </p>
                            </div>
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Sandbox Client Secret') }}
                                    <span class="text-red-500">*</span></label
                                >
                                <input
                                    v-model="
                                        form.configuration.sandbox_client_secret
                                    "
                                    type="password"
                                    :class="[
                                        'w-full rounded-lg border bg-white px-3 py-2 font-mono text-sm text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500',
                                        errors[
                                            'configuration.sandbox_client_secret'
                                        ]
                                            ? 'border-red-500'
                                            : 'border-gray-300 dark:border-gray-600',
                                    ]"
                                    :placeholder="$t('Sandbox Client Secret')"
                                />
                                <p
                                    v-if="
                                        errors[
                                            'configuration.sandbox_client_secret'
                                        ]
                                    "
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{
                                        errors[
                                            'configuration.sandbox_client_secret'
                                        ]
                                    }}
                                </p>
                            </div>
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Sandbox Webhook ID') }}
                                    <span class="text-xs text-gray-400"
                                        >({{ $t('Optional') }})</span
                                    ></label
                                >
                                <input
                                    v-model="
                                        form.configuration.sandbox_webhook_id
                                    "
                                    type="text"
                                    class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 font-mono text-sm text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500"
                                    :placeholder="$t('Sandbox Webhook ID')"
                                />
                            </div>
                        </template>

                        <!-- Live credentials -->
                        <template v-else>
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Live Client ID') }}
                                    <span class="text-red-500">*</span></label
                                >
                                <input
                                    v-model="form.configuration.client_id"
                                    type="text"
                                    :class="[
                                        'w-full rounded-lg border bg-white px-3 py-2 font-mono text-sm text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500',
                                        errors['configuration.client_id']
                                            ? 'border-red-500'
                                            : 'border-gray-300 dark:border-gray-600',
                                    ]"
                                    :placeholder="$t('Live Client ID')"
                                />
                                <p
                                    v-if="errors['configuration.client_id']"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ errors['configuration.client_id'] }}
                                </p>
                            </div>
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Live Client Secret') }}
                                    <span class="text-red-500">*</span></label
                                >
                                <input
                                    v-model="form.configuration.client_secret"
                                    type="password"
                                    :class="[
                                        'w-full rounded-lg border bg-white px-3 py-2 font-mono text-sm text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500',
                                        errors['configuration.client_secret']
                                            ? 'border-red-500'
                                            : 'border-gray-300 dark:border-gray-600',
                                    ]"
                                    :placeholder="$t('Live Client Secret')"
                                />
                                <p
                                    v-if="errors['configuration.client_secret']"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ errors['configuration.client_secret'] }}
                                </p>
                            </div>
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Live Webhook ID') }}
                                    <span class="text-xs text-gray-400"
                                        >({{ $t('Optional') }})</span
                                    ></label
                                >
                                <input
                                    v-model="form.configuration.webhook_id"
                                    type="text"
                                    class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 font-mono text-sm text-gray-900 placeholder-gray-400 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white dark:placeholder-gray-500"
                                    :placeholder="$t('Live Webhook ID')"
                                />
                            </div>
                        </template>
                    </div>
                </div>

                <!-- Webhook URL Info -->
                <div class="border-b border-gray-200 p-6 dark:border-gray-700">
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('Webhook Configuration') }}
                    </h2>
                    <div
                        class="rounded-lg border border-green-200 bg-green-50 p-4 dark:border-green-800 dark:bg-green-900/30"
                    >
                        <p
                            class="mb-2 text-sm text-green-900 dark:text-green-200"
                        >
                            <strong>{{ $t('Webhook URL:') }}</strong>
                            {{
                                $t('Add this URL in your PayPal app → Webhooks')
                            }}
                        </p>
                        <div
                            class="rounded border border-green-300 bg-white px-3 py-2 dark:border-green-700 dark:bg-gray-800"
                        >
                            <code
                                class="text-sm break-all text-green-800 dark:text-green-300"
                                >{{ webhookUrl }}</code
                            >
                        </div>
                        <p
                            class="mt-2 text-xs text-green-700 dark:text-green-400"
                        >
                            {{
                                $t(
                                    'PayPal will send payment events to this URL for real-time order updates.',
                                )
                            }}
                        </p>
                    </div>
                </div>

                <!-- Submit -->
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

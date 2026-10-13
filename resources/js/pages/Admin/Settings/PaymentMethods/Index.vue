<script setup lang="ts">
import AdminLayout from '@/layouts/AdminLayout.vue';
import { useI18nStore } from '@/Stores/i18n';
import { Head, router, usePage } from '@inertiajs/vue3';
import { CreditCard, ShieldCheck, Zap } from 'lucide-vue-next';
import { computed, ref } from 'vue';
import PaymentMethodCard from './Components/PaymentMethodCard.vue';

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
    paymentMethods: PaymentMethod[];
}>();

const { t } = useI18nStore();

const page = usePage();
const errors = computed(() => page.props.errors as Record<string, string>);
const processing = ref(false);

const handleToggle = (method: PaymentMethod) => {
    processing.value = true;
    router.post(
        `/admin/settings/payment-methods/${method.id}/toggle`,
        {},
        {
            preserveScroll: true,
            preserveState: false,
            onFinish: () => {
                processing.value = false;
            },
        },
    );
};

const handleSetDefault = (method: PaymentMethod) => {
    processing.value = true;
    router.post(
        `/admin/settings/payment-methods/${method.id}/set-default`,
        {},
        {
            preserveScroll: true,
            preserveState: false,
            onFinish: () => {
                processing.value = false;
            },
        },
    );
};

const handleConfigure = (method: PaymentMethod) => {
    router.get(`/admin/settings/payment-methods/${method.code}/configure`);
};
</script>

<template>
    <AdminLayout :title="$t('Payment Methods')">
        <Head :title="$t('Payment Methods')" />

        <div class="p-6">
            <!-- Page Header -->
            <div class="mb-8 flex items-start justify-between">
                <div>
                    <div class="mb-2 flex items-center gap-3">
                        <div
                            class="rounded-lg bg-blue-100 p-2 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400"
                        >
                            <CreditCard class="h-6 w-6" />
                        </div>
                        <h1
                            class="text-2xl font-bold text-gray-900 dark:text-white"
                        >
                            {{ $t('Payment Methods') }}
                        </h1>
                    </div>
                    <p
                        class="ml-11 max-w-2xl text-sm leading-relaxed text-gray-500 dark:text-gray-400"
                    >
                        {{
                            $t(
                                'Configure how your customers pay for their orders. Enable multiple gateways to provide flexibility and increase conversion rates.',
                            )
                        }}
                    </p>
                </div>
            </div>

            <!-- Payment Methods Grid -->
            <div
                v-if="props.paymentMethods.length > 0"
                class="mb-8 grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4"
            >
                <PaymentMethodCard
                    v-for="method in props.paymentMethods"
                    :key="method.id"
                    :payment-method="method"
                    :processing="processing"
                    @toggle="handleToggle(method)"
                    @configure="handleConfigure(method)"
                    @set-default="handleSetDefault(method)"
                />
            </div>

            <!-- Empty State -->
            <div
                v-else
                class="mb-8 rounded-xl border border-gray-100 bg-white py-16 text-center shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div
                    class="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-50 text-gray-400 dark:bg-gray-700"
                >
                    <CreditCard class="h-8 w-8" />
                </div>
                <h3
                    class="mb-1 text-lg font-medium text-gray-900 dark:text-white"
                >
                    {{ $t('No payment methods found') }}
                </h3>
                <p class="text-gray-500 dark:text-gray-400">
                    {{
                        $t(
                            'No payment gateways are currently installed or configured.',
                        )
                    }}
                </p>
            </div>

            <!-- Tips Section -->
            <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
                <!-- Help Text -->
                <div
                    class="relative overflow-hidden rounded-xl border border-blue-100 bg-blue-50 p-6 dark:border-blue-800/30 dark:bg-blue-900/10"
                >
                    <div
                        class="absolute top-0 right-0 -mt-4 -mr-4 h-24 w-24 rounded-full bg-blue-100 opacity-50 blur-xl dark:bg-blue-800/20"
                    ></div>

                    <div class="relative z-10 flex items-start gap-4">
                        <div
                            class="mt-1 rounded-lg bg-blue-100 p-2 text-blue-600 dark:bg-blue-800/30 dark:text-blue-400"
                        >
                            <ShieldCheck class="h-5 w-5" />
                        </div>
                        <div>
                            <h3
                                class="mb-2 font-bold text-blue-900 dark:text-blue-100"
                            >
                                {{ $t('Secure Transactions') }}
                            </h3>
                            <p
                                class="mb-3 text-sm leading-relaxed text-blue-800 dark:text-blue-300"
                            >
                                {{
                                    $t(
                                        'Ensure your payment keys are kept secret. Never share your API secrets or private keys. Set up SSL on your domain to ensure customer data is encrypted during checkout.',
                                    )
                                }}
                            </p>
                        </div>
                    </div>
                </div>

                <div
                    class="relative overflow-hidden rounded-xl border border-purple-100 bg-purple-50 p-6 dark:border-purple-800/30 dark:bg-purple-900/10"
                >
                    <div
                        class="absolute top-0 right-0 -mt-4 -mr-4 h-24 w-24 rounded-full bg-purple-100 opacity-50 blur-xl dark:bg-purple-800/20"
                    ></div>

                    <div class="relative z-10 flex items-start gap-4">
                        <div
                            class="mt-1 rounded-lg bg-purple-100 p-2 text-purple-600 dark:bg-purple-800/30 dark:text-purple-400"
                        >
                            <Zap class="h-5 w-5" />
                        </div>
                        <div>
                            <h3
                                class="mb-2 font-bold text-purple-900 dark:text-purple-100"
                            >
                                {{ $t('Checkout Experience') }}
                            </h3>
                            <p
                                class="text-sm leading-relaxed text-purple-800 dark:text-purple-300"
                            >
                                {{
                                    $t(
                                        'Offering a "Default" payment method speeds up checkout. Consider enabling "Guest Checkout" in General Settings to reduce friction for new customers.',
                                    )
                                }}
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

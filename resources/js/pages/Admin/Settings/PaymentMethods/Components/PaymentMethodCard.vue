<script setup lang="ts">
import {
    Banknote,
    Check,
    CreditCard,
    Globe,
    Power,
    Settings,
    Wallet,
} from 'lucide-vue-next';
import { computed } from 'vue';

// Local interface definition to avoid import issues if the composable path is incorrect
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

interface Props {
    paymentMethod: PaymentMethod;
    processing?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
    processing: false,
});

const emit = defineEmits<{
    toggle: [];
    configure: [];
    setDefault: [];
}>();

const statusBadgeClass = computed(() => {
    if (!props.paymentMethod.is_active) {
        return 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400 border border-gray-200 dark:border-gray-600';
    }
    return 'bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800';
});

const defaultBadgeClass = computed(() => {
    return 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400 border border-blue-200 dark:border-blue-800';
});

const iconComponent = computed(() => {
    const code = props.paymentMethod.code.toLowerCase();
    if (code.includes('card') || code.includes('stripe')) return CreditCard;
    if (code.includes('paypal')) return Wallet;
    if (code.includes('bank') || code.includes('transfer')) return Banknote;
    if (code.includes('cod')) return Banknote;
    return Globe;
});
</script>

<template>
    <div
        class="group relative flex h-full flex-col overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm transition-all duration-300 hover:border-blue-100 hover:shadow-lg dark:border-gray-700 dark:bg-gray-800 dark:hover:border-gray-600"
    >
        <!-- Active Indicator Stripe -->
        <div
            class="absolute top-0 left-0 h-full w-1 transition-colors duration-300"
            :class="
                paymentMethod.is_active
                    ? 'bg-green-500'
                    : 'bg-gray-200 dark:bg-gray-700'
            "
        ></div>

        <div class="flex flex-1 flex-col p-6">
            <!-- Header Section -->
            <div class="mb-4 flex items-start justify-between pl-3">
                <div class="flex items-center space-x-3">
                    <div
                        class="rounded-lg bg-gray-50 p-2.5 text-gray-600 transition-colors group-hover:bg-blue-50 group-hover:text-blue-600 dark:bg-gray-700 dark:text-gray-300 dark:group-hover:bg-blue-900/20 dark:group-hover:text-blue-400"
                    >
                        <component :is="iconComponent" class="h-6 w-6" />
                    </div>
                    <div>
                        <h3
                            class="text-lg leading-tight font-bold text-gray-900 dark:text-white"
                        >
                            {{ paymentMethod.name }}
                        </h3>
                        <span
                            class="mt-0.5 block font-mono text-xs text-gray-500 dark:text-gray-400"
                            >{{ paymentMethod.code }}</span
                        >
                    </div>
                </div>
            </div>

            <!-- Description -->
            <p
                class="mb-6 flex-1 pl-3 text-sm text-pretty text-gray-600 transition-colors group-hover:text-gray-900 dark:text-gray-400 dark:group-hover:text-gray-300"
            >
                {{
                    paymentMethod.description || $t('No description provided.')
                }}
            </p>

            <!-- Status Badges -->
            <div class="mb-6 flex flex-wrap gap-2 pl-3">
                <span
                    :class="[
                        'flex items-center space-x-1.5 rounded-full px-2.5 py-1 text-xs font-semibold',
                        statusBadgeClass,
                    ]"
                >
                    <span
                        class="h-1.5 w-1.5 rounded-full"
                        :class="
                            paymentMethod.is_active
                                ? 'bg-green-500'
                                : 'bg-gray-400'
                        "
                    ></span>
                    <span>{{
                        paymentMethod.is_active ? $t('Active') : $t('Inactive')
                    }}</span>
                </span>

                <span
                    v-if="paymentMethod.is_default"
                    :class="[
                        'flex items-center space-x-1.5 rounded-full px-2.5 py-1 text-xs font-semibold',
                        defaultBadgeClass,
                    ]"
                >
                    <Check class="h-3 w-3" />
                    <span>{{ $t('Default Method') }}</span>
                </span>
            </div>

            <!-- Action Buttons -->
            <div
                class="mt-auto flex items-center gap-3 border-t border-gray-50 pt-4 pl-3 dark:border-gray-700/50"
            >
                <button
                    @click="$emit('configure')"
                    :disabled="processing"
                    class="inline-flex flex-1 items-center justify-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900 disabled:cursor-not-allowed disabled:opacity-50"
                >
                    <Settings class="mr-2 h-4 w-4" />
                    {{ $t('Configure') }}
                </button>

                <button
                    @click="$emit('toggle')"
                    :disabled="processing"
                    class="rounded-lg border p-2 transition-all hover:shadow-sm focus:ring-2 focus:ring-offset-2 disabled:opacity-50"
                    :class="[
                        paymentMethod.is_active
                            ? 'border-gray-200 text-gray-500 hover:border-red-100 hover:bg-red-50 hover:text-red-600 dark:border-gray-600 dark:text-gray-400 dark:hover:border-red-900/30 dark:hover:bg-red-900/20 dark:hover:text-red-400'
                            : 'border-green-200 bg-green-50 text-green-600 hover:bg-green-100 dark:border-green-800 dark:bg-green-900/20 dark:text-green-400 dark:hover:bg-green-900/40',
                    ]"
                    :title="
                        paymentMethod.is_active
                            ? $t('Deactivate')
                            : $t('Activate')
                    "
                >
                    <Power class="h-4 w-4" />
                </button>

                <button
                    v-if="!paymentMethod.is_default && paymentMethod.is_active"
                    @click="$emit('setDefault')"
                    :disabled="processing"
                    class="rounded-lg border border-gray-200 p-2 text-gray-500 transition-all hover:border-blue-100 hover:bg-blue-50 hover:text-blue-600 hover:shadow-sm disabled:opacity-50 dark:border-gray-600 dark:text-gray-400 dark:hover:border-blue-900/30 dark:hover:bg-blue-900/20 dark:hover:text-blue-400"
                    :title="$t('Set as Default')"
                >
                    <Check class="h-4 w-4" />
                </button>
            </div>
        </div>
    </div>
</template>

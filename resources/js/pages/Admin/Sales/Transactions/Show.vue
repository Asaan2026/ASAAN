<script setup lang="ts">
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import type { Transaction } from '@/types/sales';
import { router } from '@inertiajs/vue3';
import { ref } from 'vue';

const props = defineProps<{
    transaction: Transaction;
    relatedTransactions: Transaction[];
}>();

const { formatPrice } = useCurrency();

const showRefundModal = ref(false);
const refundAmount = ref(props.transaction.amount);
const refundNotes = ref('');

const openRefundModal = () => {
    showRefundModal.value = true;
    refundAmount.value = props.transaction.amount;
};

const processRefund = () => {
    router.post(
        `/admin/sales/transactions/${props.transaction.id}/refund`,
        {
            amount: refundAmount.value,
            notes: refundNotes.value,
        },
        {
            onSuccess: () => {
                showRefundModal.value = false;
                refundAmount.value = props.transaction.amount;
                refundNotes.value = '';
            },
        },
    );
};

const retryTransaction = () => {
    if (confirm('Are you sure you want to retry this transaction?')) {
        router.post(`/admin/sales/transactions/${props.transaction.id}/retry`);
    }
};

const cancelTransaction = () => {
    if (confirm('Are you sure you want to cancel this transaction?')) {
        router.post(`/admin/sales/transactions/${props.transaction.id}/cancel`);
    }
};

const viewOrder = () => {
    router.visit(`/admin/sales/orders/${props.transaction.order_id}`);
};

const getStatusBadgeClass = (status: string) => {
    const classes = {
        pending: 'bg-yellow-100 text-yellow-800 border-yellow-200',
        completed: 'bg-green-100 text-green-800 border-green-200',
        failed: 'bg-red-100 text-red-800 border-red-200',
        cancelled: 'bg-gray-100 text-gray-800 border-gray-200',
    };
    return (
        classes[status as keyof typeof classes] ||
        'bg-gray-100 text-gray-800 border-gray-200'
    );
};

const getTypeBadgeClass = (type: string) => {
    const classes = {
        payment: 'bg-blue-100 text-blue-800 border-blue-200',
        refund: 'bg-purple-100 text-purple-800 border-purple-200',
        authorization: 'bg-indigo-100 text-indigo-800 border-indigo-200',
        capture: 'bg-teal-100 text-teal-800 border-teal-200',
    };
    return (
        classes[type as keyof typeof classes] ||
        'bg-gray-100 text-gray-800 border-gray-200'
    );
};

const formatJson = (data: any) => {
    return JSON.stringify(data, null, 2);
};
</script>

<template>
    <AdminLayout :title="$t('Transaction Details')">
        <div class="container-fluid">
            <!-- Header -->
            <div class="mb-6 flex items-center justify-between">
                <div>
                    <div class="mb-2 flex items-center gap-2">
                        <button
                            @click="router.visit('/admin/sales/transactions')"
                            class="text-gray-600 hover:text-gray-900"
                        >
                            <svg
                                class="h-6 w-6"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M15 19l-7-7 7-7"
                                />
                            </svg>
                        </button>
                        <h1 class="text-2xl font-bold text-gray-900">
                            {{ $t('Transaction Details') }}
                        </h1>
                    </div>
                    <p class="text-gray-600">
                        {{ transaction.transaction_number }}
                    </p>
                </div>

                <div class="flex items-center gap-2">
                    <button
                        v-if="
                            transaction.status === 'completed' &&
                            transaction.type === 'payment'
                        "
                        @click="openRefundModal"
                        class="flex items-center gap-2 rounded-lg bg-purple-600 px-4 py-2 text-white hover:bg-purple-700"
                    >
                        <svg
                            class="h-5 w-5"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6"
                            />
                        </svg>
                        {{ $t('Process Refund') }}
                    </button>

                    <button
                        v-if="
                            transaction.status === 'failed' &&
                            (transaction.type === 'payment' ||
                                transaction.type === 'capture')
                        "
                        @click="retryTransaction"
                        class="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
                    >
                        <svg
                            class="h-5 w-5"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
                            />
                        </svg>
                        {{ $t('Retry') }}
                    </button>

                    <button
                        v-if="transaction.status === 'pending'"
                        @click="cancelTransaction"
                        class="flex items-center gap-2 rounded-lg bg-red-600 px-4 py-2 text-white hover:bg-red-700"
                    >
                        <svg
                            class="h-5 w-5"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
                            />
                        </svg>
                        {{ $t('Cancel') }}
                    </button>

                    <button
                        @click="viewOrder"
                        class="flex items-center gap-2 rounded-lg border border-gray-300 px-4 py-2 hover:bg-gray-50"
                    >
                        <svg
                            class="h-5 w-5 text-gray-700"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                            />
                        </svg>
                        {{ $t('View Order') }}
                    </button>
                </div>
            </div>

            <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
                <!-- Main Info -->
                <div class="space-y-6 lg:col-span-2">
                    <!-- Transaction Information -->
                    <div
                        class="rounded-lg border border-gray-200 bg-white p-6 shadow-sm"
                    >
                        <h2 class="mb-4 text-lg font-semibold text-gray-900">
                            {{ $t('Transaction Information') }}
                        </h2>

                        <div class="grid grid-cols-2 gap-4">
                            <div>
                                <label class="text-sm text-gray-600">{{
                                    $t('Transaction Number')
                                }}</label>
                                <p class="font-medium text-gray-900">
                                    {{ transaction.transaction_number }}
                                </p>
                            </div>

                            <div>
                                <label class="text-sm text-gray-600">{{
                                    $t('Order Number')
                                }}</label>
                                <p
                                    class="cursor-pointer font-medium text-blue-600 hover:text-blue-800"
                                    @click="viewOrder"
                                >
                                    {{
                                        $t(
                                            transaction.order?.order_number ||
                                                'N/A',
                                        )
                                    }}
                                </p>
                            </div>

                            <div>
                                <label class="text-sm text-gray-600">{{
                                    $t('Type')
                                }}</label>
                                <p>
                                    <span
                                        :class="
                                            getTypeBadgeClass(transaction.type)
                                        "
                                        class="inline-flex rounded-full border px-2 py-1 text-xs leading-5 font-semibold"
                                    >
                                        {{ transaction.type }}
                                    </span>
                                </p>
                            </div>

                            <div>
                                <label class="text-sm text-gray-600">{{
                                    $t('Status')
                                }}</label>
                                <p>
                                    <span
                                        :class="
                                            getStatusBadgeClass(
                                                transaction.status,
                                            )
                                        "
                                        class="inline-flex rounded-full border px-2 py-1 text-xs leading-5 font-semibold"
                                    >
                                        {{ transaction.status }}
                                    </span>
                                </p>
                            </div>

                            <div>
                                <label class="text-sm text-gray-600">{{
                                    $t('Amount')
                                }}</label>
                                <p class="text-lg font-medium text-gray-900">
                                    {{ formatPrice(transaction.amount) }}
                                </p>
                            </div>

                            <div>
                                <label class="text-sm text-gray-600">{{
                                    $t('Payment Method')
                                }}</label>
                                <p class="font-medium text-gray-900">
                                    {{ transaction.payment_method }}
                                </p>
                            </div>

                            <div>
                                <label class="text-sm text-gray-600">{{
                                    $t('Gateway')
                                }}</label>
                                <p class="font-medium text-gray-900 capitalize">
                                    {{ transaction.gateway }}
                                </p>
                            </div>

                            <div>
                                <label class="text-sm text-gray-600">{{
                                    $t('Gateway Transaction ID')
                                }}</label>
                                <p class="font-mono text-sm text-gray-900">
                                    {{
                                        $t(
                                            transaction.gateway_transaction_id ||
                                                'N/A',
                                        )
                                    }}
                                </p>
                            </div>

                            <div>
                                <label class="text-sm text-gray-600">{{
                                    $t('Created At')
                                }}</label>
                                <p class="font-medium text-gray-900">
                                    <DateDisplay
                                        :value="transaction.created_at"
                                        time
                                    />
                                </p>
                            </div>

                            <div>
                                <label class="text-sm text-gray-600">{{
                                    $t('Processed At')
                                }}</label>
                                <p class="font-medium text-gray-900">
                                    <DateDisplay
                                        :value="transaction.processed_at"
                                        time
                                    />
                                </p>
                            </div>
                        </div>

                        <div
                            v-if="transaction.notes"
                            class="mt-4 border-t border-gray-200 pt-4"
                        >
                            <label class="text-sm text-gray-600">{{
                                $t('Notes')
                            }}</label>
                            <p class="mt-1 font-medium text-gray-900">
                                {{ transaction.notes }}
                            </p>
                        </div>
                    </div>

                    <!-- Gateway Response Data -->
                    <div
                        v-if="transaction.response_data"
                        class="rounded-lg border border-gray-200 bg-white p-6 shadow-sm"
                    >
                        <h2 class="mb-4 text-lg font-semibold text-gray-900">
                            {{ $t('Gateway Response') }}
                        </h2>
                        <pre
                            class="overflow-x-auto rounded-lg bg-gray-50 p-4 text-sm"
                            >{{ formatJson(transaction.response_data) }}</pre
                        >
                    </div>

                    <!-- Related Transactions -->
                    <div
                        v-if="relatedTransactions.length > 0"
                        class="rounded-lg border border-gray-200 bg-white p-6 shadow-sm"
                    >
                        <h2 class="mb-4 text-lg font-semibold text-gray-900">
                            {{ $t('Related Transactions') }}
                        </h2>
                        <div class="space-y-3">
                            <div
                                v-for="related in relatedTransactions"
                                :key="related.id"
                                class="flex cursor-pointer items-center justify-between rounded-lg bg-gray-50 p-3 hover:bg-gray-100"
                                @click="
                                    router.visit(
                                        `/admin/sales/transactions/${related.id}`,
                                    )
                                "
                            >
                                <div class="flex-1">
                                    <p class="font-medium text-gray-900">
                                        {{ related.transaction_number }}
                                    </p>
                                    <p class="text-sm text-gray-600">
                                        <DateDisplay
                                            :value="related.created_at"
                                            time
                                        />
                                    </p>
                                </div>
                                <div class="flex items-center gap-3">
                                    <span
                                        :class="getTypeBadgeClass(related.type)"
                                        class="rounded-full border px-2 py-1 text-xs font-semibold"
                                    >
                                        {{ related.type }}
                                    </span>
                                    <span class="font-medium text-gray-900">{{
                                        formatPrice(related.amount)
                                    }}</span>
                                    <span
                                        :class="
                                            getStatusBadgeClass(related.status)
                                        "
                                        class="rounded-full border px-2 py-1 text-xs font-semibold"
                                    >
                                        {{ related.status }}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Sidebar -->
                <div class="space-y-6">
                    <!-- Order Summary -->
                    <div
                        v-if="transaction.order"
                        class="rounded-lg border border-gray-200 bg-white p-6 shadow-sm"
                    >
                        <h2 class="mb-4 text-lg font-semibold text-gray-900">
                            {{ $t('Order Summary') }}
                        </h2>
                        <div class="space-y-3">
                            <div class="flex justify-between">
                                <span class="text-sm text-gray-600">{{
                                    $t('Order Number:')
                                }}</span>
                                <span
                                    class="cursor-pointer text-sm font-medium text-blue-600 hover:text-blue-800"
                                    @click="viewOrder"
                                >
                                    {{ transaction.order.order_number }}
                                </span>
                            </div>
                            <div class="flex justify-between">
                                <span class="text-sm text-gray-600">{{
                                    $t('Customer:')
                                }}</span>
                                <span
                                    class="text-sm font-medium text-gray-900"
                                    >{{
                                        transaction.order.customer_email
                                    }}</span
                                >
                            </div>
                            <div class="flex justify-between">
                                <span class="text-sm text-gray-600">{{
                                    $t('Order Total:')
                                }}</span>
                                <span
                                    class="text-sm font-medium text-gray-900"
                                    >{{
                                        formatPrice(transaction.order.total)
                                    }}</span
                                >
                            </div>
                            <div class="flex justify-between">
                                <span class="text-sm text-gray-600">{{
                                    $t('Order Status:')
                                }}</span>
                                <span
                                    class="text-sm font-medium text-gray-900 capitalize"
                                    >{{ transaction.order.status }}</span
                                >
                            </div>
                            <div class="flex justify-between">
                                <span class="text-sm text-gray-600">{{
                                    $t('Payment Status:')
                                }}</span>
                                <span
                                    class="text-sm font-medium text-gray-900 capitalize"
                                    >{{
                                        transaction.order.payment_status
                                    }}</span
                                >
                            </div>
                        </div>
                    </div>

                    <!-- Invoice Info -->
                    <div
                        v-if="transaction.invoice"
                        class="rounded-lg border border-gray-200 bg-white p-6 shadow-sm"
                    >
                        <h2 class="mb-4 text-lg font-semibold text-gray-900">
                            {{ $t('Invoice') }}
                        </h2>
                        <div class="space-y-3">
                            <div class="flex justify-between">
                                <span class="text-sm text-gray-600">{{
                                    $t('Invoice Number:')
                                }}</span>
                                <span
                                    class="text-sm font-medium text-gray-900"
                                    >{{
                                        transaction.invoice.invoice_number
                                    }}</span
                                >
                            </div>
                            <div class="flex justify-between">
                                <span class="text-sm text-gray-600">{{
                                    $t('Status:')
                                }}</span>
                                <span
                                    class="text-sm font-medium text-gray-900 capitalize"
                                    >{{ transaction.invoice.status }}</span
                                >
                            </div>
                        </div>
                    </div>

                    <!-- Credit Memo Info -->
                    <div
                        v-if="transaction.credit_memo"
                        class="rounded-lg border border-gray-200 bg-white p-6 shadow-sm"
                    >
                        <h2 class="mb-4 text-lg font-semibold text-gray-900">
                            {{ $t('Credit Memo') }}
                        </h2>
                        <div class="space-y-3">
                            <div class="flex justify-between">
                                <span class="text-sm text-gray-600">{{
                                    $t('Credit Memo #:')
                                }}</span>
                                <span
                                    class="text-sm font-medium text-gray-900"
                                    >{{
                                        transaction.credit_memo
                                            .credit_memo_number
                                    }}</span
                                >
                            </div>
                            <div class="flex justify-between">
                                <span class="text-sm text-gray-600">{{
                                    $t('Status:')
                                }}</span>
                                <span
                                    class="text-sm font-medium text-gray-900 capitalize"
                                    >{{ transaction.credit_memo.status }}</span
                                >
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Refund Modal -->
        <div v-if="showRefundModal" class="fixed inset-0 z-50 overflow-y-auto">
            <div class="flex min-h-screen items-center justify-center px-4">
                <div
                    class="fixed inset-0 bg-gray-500/75 transition-opacity dark:bg-gray-900/75"
                    @click="showRefundModal = false"
                ></div>

                <div class="relative w-full max-w-md rounded-lg bg-white p-6">
                    <h3 class="mb-4 text-lg font-medium text-gray-900">
                        {{ $t('Process Refund') }}
                    </h3>

                    <div class="space-y-4">
                        <div>
                            <label
                                class="mb-1 block text-sm font-medium text-gray-700"
                                >{{ $t('Refund Amount') }}</label
                            >
                            <input
                                v-model.number="refundAmount"
                                type="number"
                                step="0.01"
                                :max="transaction.amount"
                                class="w-full rounded-lg border border-gray-300 px-3 py-2"
                            />
                            <p class="mt-1 text-xs text-gray-500">
                                {{
                                    $t('Maximum: {amount}', {
                                        amount: formatPrice(transaction.amount),
                                    })
                                }}
                            </p>
                        </div>

                        <div>
                            <label
                                class="mb-1 block text-sm font-medium text-gray-700"
                                >{{ $t('Notes') }}</label
                            >
                            <textarea
                                v-model="refundNotes"
                                rows="3"
                                class="w-full rounded-lg border border-gray-300 px-3 py-2"
                                :placeholder="$t('Optional refund notes...')"
                            ></textarea>
                        </div>
                    </div>

                    <div class="mt-6 flex justify-end gap-3">
                        <button
                            @click="showRefundModal = false"
                            class="rounded-lg border border-gray-300 px-4 py-2 hover:bg-gray-50"
                        >
                            {{ $t('Cancel') }}
                        </button>
                        <button
                            @click="processRefund"
                            class="rounded-lg bg-purple-600 px-4 py-2 text-white hover:bg-purple-700"
                        >
                            {{ $t('Process Refund') }}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

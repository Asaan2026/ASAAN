<script setup lang="ts">
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import type { CreditMemo } from '@/types/sales';
import { Head, router } from '@inertiajs/vue3';
import { ref } from 'vue';

interface Props {
    creditMemo: CreditMemo;
}

const props = defineProps<Props>();
const { formatPrice } = useCurrency();

const activeTab = ref('overview');

const getStatusBadge = (status: string) => {
    const badges: Record<string, string> = {
        pending: 'bg-yellow-100 text-yellow-800',
        refunded: 'bg-green-100 text-green-800',
        cancelled: 'bg-red-100 text-red-800',
    };
    return badges[status] || 'bg-gray-100 text-gray-800';
};

const downloadPdf = () => {
    window.open(
        `/admin/sales/credit-memos/${props.creditMemo.id}/download-pdf`,
        '_blank',
    );
};

const sendEmail = () => {
    router.post(
        `/admin/sales/credit-memos/${props.creditMemo.id}/send-email`,
        {},
        {
            preserveScroll: true,
        },
    );
};

const processRefund = () => {
    router.post(
        `/admin/sales/credit-memos/${props.creditMemo.id}/process-refund`,
        {},
        {
            preserveScroll: true,
        },
    );
};

const cancelCreditMemo = () => {
    router.post(
        `/admin/sales/credit-memos/${props.creditMemo.id}/cancel`,
        {},
        {
            preserveScroll: true,
        },
    );
};

const viewOrder = () => {
    router.visit(`/admin/sales/orders/${props.creditMemo.order_id}`);
};

const viewInvoice = () => {
    if (props.creditMemo.invoice_id) {
        router.visit(`/admin/sales/invoices/${props.creditMemo.invoice_id}`);
    }
};
</script>

<template>
    <Head
        :title="
            $t('Credit Memo {number}', {
                number: creditMemo.credit_memo_number,
            })
        "
    />

    <AdminLayout
        :title="
            $t('Credit Memo {number}', {
                number: creditMemo.credit_memo_number,
            })
        "
    >
        <div class="space-y-6">
            <!-- Header -->
            <div class="flex items-center justify-between">
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-gray-100"
                    >
                        {{ creditMemo.credit_memo_number }}
                    </h1>
                    <p class="mt-1 text-gray-600 dark:text-gray-400">
                        {{
                            $t('Credit memo for order {number}', {
                                number: creditMemo.order?.order_number,
                            })
                        }}
                    </p>
                </div>

                <div class="flex items-center space-x-3">
                    <button
                        v-if="creditMemo.status === 'pending'"
                        @click="processRefund"
                        class="rounded-lg bg-green-600 px-4 py-2 text-white hover:bg-green-700 focus:ring-2 focus:ring-green-500 focus:ring-offset-2 focus:outline-none"
                    >
                        {{ $t('Process Refund') }}
                    </button>
                    <button
                        @click="downloadPdf"
                        class="rounded-lg bg-blue-600 px-4 py-2 text-white hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none"
                    >
                        {{ $t('Download PDF') }}
                    </button>
                    <button
                        @click="sendEmail"
                        class="rounded-lg bg-purple-600 px-4 py-2 text-white hover:bg-purple-700 focus:ring-2 focus:ring-purple-500 focus:ring-offset-2 focus:outline-none"
                    >
                        {{ $t('Send Email') }}
                    </button>
                    <button
                        v-if="creditMemo.status === 'pending'"
                        @click="cancelCreditMemo"
                        class="rounded-lg bg-red-600 px-4 py-2 text-white hover:bg-red-700 focus:ring-2 focus:ring-red-500 focus:ring-offset-2 focus:outline-none"
                    >
                        {{ $t('Cancel') }}
                    </button>
                </div>
            </div>

            <!-- Status Cards -->
            <div class="grid grid-cols-1 gap-6 md:grid-cols-4">
                <div class="rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800">
                    <div class="text-sm text-gray-600 dark:text-gray-400">
                        {{ $t('Status') }}
                    </div>
                    <div class="mt-2">
                        <span
                            :class="[
                                'inline-flex rounded-full px-3 py-1 text-sm font-semibold',
                                getStatusBadge(creditMemo.status),
                            ]"
                        >
                            {{ creditMemo.status }}
                        </span>
                    </div>
                </div>

                <div class="rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800">
                    <div class="text-sm text-gray-600 dark:text-gray-400">
                        {{ $t('Refund Method') }}
                    </div>
                    <div
                        class="mt-2 text-lg font-semibold text-gray-900 capitalize dark:text-gray-100"
                    >
                        {{ creditMemo.refund_method }}
                    </div>
                </div>

                <div class="rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800">
                    <div class="text-sm text-gray-600 dark:text-gray-400">
                        {{ $t('Total Amount') }}
                    </div>
                    <div
                        class="mt-2 text-2xl font-bold text-gray-900 dark:text-gray-100"
                    >
                        {{ formatPrice(creditMemo.grand_total) }}
                    </div>
                </div>

                <div class="rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800">
                    <div class="text-sm text-gray-600 dark:text-gray-400">
                        {{ $t('Created') }}
                    </div>
                    <div class="mt-2 text-sm text-gray-900 dark:text-gray-100">
                        <DateDisplay :value="creditMemo.created_at" time />
                    </div>
                </div>
            </div>

            <!-- Tabs -->
            <div class="rounded-lg bg-white shadow-sm dark:bg-gray-800">
                <div class="border-b border-gray-200 dark:border-gray-700">
                    <nav class="-mb-px flex space-x-8 px-6">
                        <button
                            v-for="tab in [
                                'overview',
                                'items',
                                'refund-details',
                            ]"
                            :key="tab"
                            @click="activeTab = tab"
                            :class="[
                                'border-b-2 px-1 py-4 text-sm font-medium',
                                activeTab === tab
                                    ? 'border-blue-500 text-blue-600'
                                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                            ]"
                        >
                            {{
                                $t(
                                    tab
                                        .split('-')
                                        .map(
                                            (w) =>
                                                w.charAt(0).toUpperCase() +
                                                w.slice(1),
                                        )
                                        .join(' '),
                                )
                            }}
                        </button>
                    </nav>
                </div>

                <div class="p-6">
                    <!-- Overview Tab -->
                    <div v-if="activeTab === 'overview'" class="space-y-6">
                        <!-- Credit Memo Information -->
                        <div>
                            <h3
                                class="mb-4 text-lg font-semibold text-gray-900 dark:text-gray-100"
                            >
                                {{ $t('Credit Memo Information') }}
                            </h3>
                            <div class="grid grid-cols-2 gap-4">
                                <div>
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Credit Memo Number') }}
                                    </div>
                                    <div
                                        class="mt-1 font-medium text-gray-900 dark:text-gray-100"
                                    >
                                        {{ creditMemo.credit_memo_number }}
                                    </div>
                                </div>
                                <div>
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Status') }}
                                    </div>
                                    <div class="mt-1">
                                        <span
                                            :class="[
                                                'inline-flex rounded-full px-3 py-1 text-sm font-semibold',
                                                getStatusBadge(
                                                    creditMemo.status,
                                                ),
                                            ]"
                                        >
                                            {{ creditMemo.status }}
                                        </span>
                                    </div>
                                </div>
                                <div>
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Order Number') }}
                                    </div>
                                    <div class="mt-1">
                                        <button
                                            @click="viewOrder"
                                            class="font-medium text-blue-600 hover:text-blue-800"
                                        >
                                            {{ creditMemo.order?.order_number }}
                                        </button>
                                    </div>
                                </div>
                                <div v-if="creditMemo.invoice">
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Invoice Number') }}
                                    </div>
                                    <div class="mt-1">
                                        <button
                                            @click="viewInvoice"
                                            class="font-medium text-blue-600 hover:text-blue-800"
                                        >
                                            {{
                                                creditMemo.invoice
                                                    .invoice_number
                                            }}
                                        </button>
                                    </div>
                                </div>
                                <div>
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Created At') }}
                                    </div>
                                    <div
                                        class="mt-1 text-gray-900 dark:text-gray-100"
                                    >
                                        <DateDisplay
                                            :value="creditMemo.created_at"
                                            time
                                        />
                                    </div>
                                </div>
                                <div v-if="creditMemo.refunded_at">
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Refunded At') }}
                                    </div>
                                    <div
                                        class="mt-1 text-gray-900 dark:text-gray-100"
                                    >
                                        <DateDisplay
                                            :value="creditMemo.refunded_at"
                                            time
                                        />
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Customer Information -->
                        <div v-if="creditMemo.order">
                            <h3
                                class="mb-4 text-lg font-semibold text-gray-900 dark:text-gray-100"
                            >
                                {{ $t('Customer Information') }}
                            </h3>
                            <div class="grid grid-cols-2 gap-4">
                                <div>
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Name') }}
                                    </div>
                                    <div
                                        class="mt-1 font-medium text-gray-900 dark:text-gray-100"
                                    >
                                        {{
                                            creditMemo.order.user?.name ||
                                            $t('Guest')
                                        }}
                                    </div>
                                </div>
                                <div>
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Email') }}
                                    </div>
                                    <div
                                        class="mt-1 text-gray-900 dark:text-gray-100"
                                    >
                                        {{ creditMemo.order.customer_email }}
                                    </div>
                                </div>
                                <div v-if="creditMemo.order.customer_phone">
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Phone') }}
                                    </div>
                                    <div
                                        class="mt-1 text-gray-900 dark:text-gray-100"
                                    >
                                        {{ creditMemo.order.customer_phone }}
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Reason & Notes -->
                        <div>
                            <h3
                                class="mb-4 text-lg font-semibold text-gray-900 dark:text-gray-100"
                            >
                                {{ $t('Reason & Notes') }}
                            </h3>
                            <div class="space-y-4">
                                <div v-if="creditMemo.notes">
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Notes') }}
                                    </div>
                                    <div
                                        class="mt-1 text-gray-900 dark:text-gray-100"
                                    >
                                        {{ creditMemo.notes }}
                                    </div>
                                </div>
                                <div v-if="creditMemo.admin_notes">
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Admin Notes') }}
                                    </div>
                                    <div
                                        class="mt-1 text-gray-900 dark:text-gray-100"
                                    >
                                        {{ creditMemo.admin_notes }}
                                    </div>
                                </div>
                                <div
                                    v-if="
                                        !creditMemo.notes &&
                                        !creditMemo.admin_notes
                                    "
                                >
                                    <p
                                        class="text-sm text-gray-500 italic dark:text-gray-400"
                                    >
                                        {{ $t('No reason or notes provided') }}
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Items Tab -->
                    <div v-if="activeTab === 'items'">
                        <div class="overflow-x-auto">
                            <table
                                class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                            >
                                <thead class="bg-gray-50 dark:bg-gray-700/50">
                                    <tr>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Product') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('SKU') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Qty') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Price') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Tax') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Discount') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Row Total') }}
                                        </th>
                                    </tr>
                                </thead>
                                <tbody
                                    class="divide-y divide-gray-200 bg-white dark:divide-gray-700 dark:bg-gray-800"
                                >
                                    <tr
                                        v-for="item in creditMemo.items"
                                        :key="item.id"
                                    >
                                        <td class="px-6 py-4">
                                            <div
                                                class="text-sm font-medium text-gray-900 dark:text-gray-100"
                                            >
                                                {{ item.product_name }}
                                            </div>
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <div
                                                class="text-sm text-gray-500 dark:text-gray-400"
                                            >
                                                {{ item.sku || '-' }}
                                            </div>
                                        </td>
                                        <td
                                            class="px-6 py-4 text-right whitespace-nowrap"
                                        >
                                            <div
                                                class="text-sm text-gray-900 dark:text-gray-100"
                                            >
                                                {{ item.qty }}
                                            </div>
                                        </td>
                                        <td
                                            class="px-6 py-4 text-right whitespace-nowrap"
                                        >
                                            <div
                                                class="text-sm text-gray-900 dark:text-gray-100"
                                            >
                                                {{ formatPrice(item.price) }}
                                            </div>
                                        </td>
                                        <td
                                            class="px-6 py-4 text-right whitespace-nowrap"
                                        >
                                            <div
                                                class="text-sm text-gray-900 dark:text-gray-100"
                                            >
                                                {{
                                                    formatPrice(item.tax_amount)
                                                }}
                                            </div>
                                        </td>
                                        <td
                                            class="px-6 py-4 text-right whitespace-nowrap"
                                        >
                                            <div
                                                class="text-sm text-gray-900 dark:text-gray-100"
                                            >
                                                {{
                                                    formatPrice(
                                                        item.discount_amount,
                                                    )
                                                }}
                                            </div>
                                        </td>
                                        <td
                                            class="px-6 py-4 text-right whitespace-nowrap"
                                        >
                                            <div
                                                class="text-sm font-medium text-gray-900 dark:text-gray-100"
                                            >
                                                {{
                                                    formatPrice(item.row_total)
                                                }}
                                            </div>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>

                        <!-- Totals -->
                        <div class="mt-6 flex justify-end">
                            <div class="w-full max-w-xs space-y-2">
                                <div class="flex justify-between text-sm">
                                    <span
                                        class="text-gray-600 dark:text-gray-400"
                                        >{{ $t('Subtotal:') }}</span
                                    >
                                    <span
                                        class="font-medium text-gray-900 dark:text-gray-100"
                                        >{{
                                            formatPrice(creditMemo.subtotal)
                                        }}</span
                                    >
                                </div>
                                <div
                                    v-if="creditMemo.discount_amount > 0"
                                    class="flex justify-between text-sm"
                                >
                                    <span
                                        class="text-gray-600 dark:text-gray-400"
                                        >{{ $t('Discount:') }}</span
                                    >
                                    <span
                                        class="font-medium text-gray-900 dark:text-gray-100"
                                        >-{{
                                            formatPrice(
                                                creditMemo.discount_amount,
                                            )
                                        }}</span
                                    >
                                </div>
                                <div class="flex justify-between text-sm">
                                    <span
                                        class="text-gray-600 dark:text-gray-400"
                                        >{{ $t('Tax:') }}</span
                                    >
                                    <span
                                        class="font-medium text-gray-900 dark:text-gray-100"
                                        >{{
                                            formatPrice(creditMemo.tax_amount)
                                        }}</span
                                    >
                                </div>
                                <div
                                    v-if="creditMemo.shipping_amount > 0"
                                    class="flex justify-between text-sm"
                                >
                                    <span
                                        class="text-gray-600 dark:text-gray-400"
                                        >{{ $t('Shipping Refund') }}</span
                                    >
                                    <span
                                        class="font-medium text-gray-900 dark:text-gray-100"
                                        >{{
                                            formatPrice(
                                                creditMemo.shipping_amount,
                                            )
                                        }}</span
                                    >
                                </div>
                                <div
                                    v-if="creditMemo.adjustment_positive > 0"
                                    class="flex justify-between text-sm"
                                >
                                    <span
                                        class="text-gray-600 dark:text-gray-400"
                                        >{{ $t('Adjustment (+)') }}</span
                                    >
                                    <span class="font-medium text-green-600">
                                        +{{
                                            formatPrice(
                                                creditMemo.adjustment_positive,
                                            )
                                        }}
                                    </span>
                                </div>
                                <div
                                    v-if="creditMemo.adjustment_negative > 0"
                                    class="flex justify-between text-sm"
                                >
                                    <span
                                        class="text-gray-600 dark:text-gray-400"
                                        >{{ $t('Adjustment (-)') }}</span
                                    >
                                    <span class="font-medium text-red-600">
                                        -{{
                                            formatPrice(
                                                creditMemo.adjustment_negative,
                                            )
                                        }}
                                    </span>
                                </div>
                                <div
                                    class="mt-3 flex justify-between border-t border-gray-200 pt-3 text-lg font-bold dark:border-gray-700"
                                >
                                    <span
                                        class="text-gray-900 dark:text-gray-100"
                                        >{{ $t('Total Refund') }}</span
                                    >
                                    <span
                                        class="text-gray-900 dark:text-gray-100"
                                        >{{
                                            formatPrice(creditMemo.grand_total)
                                        }}</span
                                    >
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Refund Details Tab -->
                    <div
                        v-if="activeTab === 'refund-details'"
                        class="space-y-6"
                    >
                        <!-- Refund Information -->
                        <div>
                            <h3
                                class="mb-4 text-lg font-semibold text-gray-900 dark:text-gray-100"
                            >
                                {{ $t('Refund Information') }}
                            </h3>
                            <div class="grid grid-cols-2 gap-4">
                                <div>
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Refund Method') }}
                                    </div>
                                    <div
                                        class="mt-1 font-medium text-gray-900 capitalize dark:text-gray-100"
                                    >
                                        {{ creditMemo.refund_method }}
                                    </div>
                                </div>
                                <div>
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Status') }}
                                    </div>
                                    <div class="mt-1">
                                        <span
                                            :class="[
                                                'inline-flex rounded-full px-3 py-1 text-sm font-semibold',
                                                getStatusBadge(
                                                    creditMemo.status,
                                                ),
                                            ]"
                                        >
                                            {{ creditMemo.status }}
                                        </span>
                                    </div>
                                </div>
                                <div v-if="creditMemo.notes">
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Transaction Notes') }}
                                    </div>
                                    <div
                                        class="mt-1 text-sm text-gray-900 dark:text-gray-100"
                                    >
                                        {{ creditMemo.notes }}
                                    </div>
                                </div>
                                <div v-if="creditMemo.refunded_at">
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Refunded At') }}
                                    </div>
                                    <div
                                        class="mt-1 text-gray-900 dark:text-gray-100"
                                    >
                                        <DateDisplay
                                            :value="creditMemo.refunded_at"
                                            time
                                        />
                                    </div>
                                </div>
                                <div>
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Refund Amount') }}
                                    </div>
                                    <div
                                        class="mt-1 text-2xl font-bold text-gray-900 dark:text-gray-100"
                                    >
                                        {{
                                            formatPrice(creditMemo.grand_total)
                                        }}
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Inventory Information -->
                        <div>
                            <h3
                                class="mb-4 text-lg font-semibold text-gray-900 dark:text-gray-100"
                            >
                                {{ $t('Inventory Information') }}
                            </h3>
                            <div class="grid grid-cols-2 gap-4">
                                <div>
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Restore Inventory') }}
                                    </div>
                                    <div class="mt-1">
                                        <span
                                            :class="[
                                                'inline-flex rounded-full px-3 py-1 text-sm font-semibold',
                                                creditMemo.restore_inventory
                                                    ? 'bg-green-100 text-green-800 dark:bg-green-900/40 dark:text-green-300'
                                                    : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300',
                                            ]"
                                        >
                                            {{
                                                creditMemo.restore_inventory
                                                    ? $t('Yes')
                                                    : $t('No')
                                            }}
                                        </span>
                                    </div>
                                </div>
                                <div v-if="creditMemo.restore_inventory">
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Inventory Restored') }}
                                    </div>
                                    <div class="mt-1">
                                        <span
                                            :class="[
                                                'inline-flex rounded-full px-3 py-1 text-sm font-semibold',
                                                creditMemo.inventory_restored_at
                                                    ? 'bg-green-100 text-green-800 dark:bg-green-900/40 dark:text-green-300'
                                                    : 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/40 dark:text-yellow-300',
                                            ]"
                                        >
                                            {{
                                                creditMemo.inventory_restored_at
                                                    ? $t('Yes')
                                                    : $t('Pending')
                                            }}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Payment Information -->
                        <div v-if="creditMemo.order">
                            <h3
                                class="mb-4 text-lg font-semibold text-gray-900 dark:text-gray-100"
                            >
                                {{ $t('Original Order Payment') }}
                            </h3>
                            <div class="grid grid-cols-2 gap-4">
                                <div>
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Payment Method') }}
                                    </div>
                                    <div
                                        class="mt-1 font-medium text-gray-900 dark:text-gray-100"
                                    >
                                        {{
                                            creditMemo.order.payment_method ||
                                            '-'
                                        }}
                                    </div>
                                </div>
                                <div>
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Payment Status') }}
                                    </div>
                                    <div
                                        class="mt-1 font-medium text-gray-900 capitalize dark:text-gray-100"
                                    >
                                        {{ creditMemo.order.payment_status }}
                                    </div>
                                </div>
                                <div>
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Order Total') }}
                                    </div>
                                    <div
                                        class="mt-1 font-medium text-gray-900 dark:text-gray-100"
                                    >
                                        {{
                                            formatPrice(creditMemo.order.total)
                                        }}
                                    </div>
                                </div>
                                <div v-if="creditMemo.order.total_refunded">
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        {{ $t('Total Refunded') }}
                                    </div>
                                    <div
                                        class="mt-1 font-medium text-gray-900 dark:text-gray-100"
                                    >
                                        {{
                                            formatPrice(
                                                creditMemo.order.total_refunded,
                                            )
                                        }}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

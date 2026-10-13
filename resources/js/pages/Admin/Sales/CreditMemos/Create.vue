<script setup lang="ts">
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import type { Order, RefundableItem } from '@/types/sales';
import { Head, router, useForm } from '@inertiajs/vue3';
import { computed, ref, watch } from 'vue';

interface Props {
    order?: Order;
    refundableItems?: RefundableItem[];
    orders?: Order[];
}

const props = defineProps<Props>();
const { formatPrice, getSymbol } = useCurrency();

const selectedOrder = ref<Order | undefined>(props.order);
const refundItems = ref<RefundableItem[]>(props.refundableItems || []);

interface FormItem {
    order_item_id: number;
    qty: number;
}

const form = useForm({
    order_id: props.order?.id || null,
    items: [] as FormItem[],
    refund_method: 'online' as 'online' | 'offline',
    reason: '',
    notes: '',
    shipping_refund: 0,
    adjustment_amount: 0,
    restore_inventory: true,
});

// Watch for order selection changes
watch(
    () => form.order_id,
    (newOrderId) => {
        if (newOrderId && !props.order) {
            // Fetch refundable items for the selected order
            router.get(
                `/admin/sales/credit-memos/create`,
                { order_id: newOrderId },
                {
                    preserveState: true,
                    preserveScroll: true,
                    only: ['order', 'refundableItems'],
                    onSuccess: (page) => {
                        selectedOrder.value = (page.props as any).order;
                        refundItems.value =
                            (page.props as any).refundableItems || [];
                    },
                },
            );
        }
    },
);

// Initialize selected quantities
const selectedQuantities = ref<Record<number, number>>({});
refundItems.value.forEach((item) => {
    selectedQuantities.value[item.order_item_id] = 0;
});

// Calculate subtotal for refund items
const subtotal = computed(() => {
    return refundItems.value.reduce((sum, item) => {
        const qty = selectedQuantities.value[item.order_item_id] || 0;
        return sum + qty * item.price;
    }, 0);
});

// Calculate tax (proportional to original order)
const taxAmount = computed(() => {
    if (!selectedOrder.value) return 0;
    const orderSubtotal = selectedOrder.value.subtotal;
    if (orderSubtotal === 0) return 0;
    const taxRate = selectedOrder.value.tax / orderSubtotal;
    return subtotal.value * taxRate;
});

// Calculate discount (proportional to original order)
const discountAmount = computed(() => {
    if (!selectedOrder.value) return 0;
    const orderSubtotal = selectedOrder.value.subtotal;
    if (orderSubtotal === 0) return 0;
    const discountRate = selectedOrder.value.discount / orderSubtotal;
    return subtotal.value * discountRate;
});

// Calculate grand total
const grandTotal = computed(() => {
    return (
        subtotal.value -
        discountAmount.value +
        taxAmount.value +
        form.shipping_refund +
        form.adjustment_amount
    );
});

// Check if at least one item is selected
const hasSelectedItems = computed(() => {
    return Object.values(selectedQuantities.value).some((qty) => qty > 0);
});

const selectAllItems = () => {
    refundItems.value.forEach((item) => {
        selectedQuantities.value[item.order_item_id] = item.qty_refundable;
    });
};

const clearAllItems = () => {
    refundItems.value.forEach((item) => {
        selectedQuantities.value[item.order_item_id] = 0;
    });
};

const submit = () => {
    // Build items array from selected quantities
    form.items = refundItems.value
        .filter((item) => selectedQuantities.value[item.order_item_id] > 0)
        .map((item) => ({
            order_item_id: item.order_item_id,
            qty: selectedQuantities.value[item.order_item_id],
        }));

    if (form.items.length === 0) {
        return;
    }

    form.post('/admin/sales/credit-memos', {
        onSuccess: () => {
            // Redirect handled by controller
        },
        onError: () => {},
    });
};

const cancel = () => {
    router.visit('/admin/sales/credit-memos');
};
</script>

<template>
    <Head :title="$t('Create Credit Memo')" />

    <AdminLayout :title="$t('Create Credit Memo')">
        <div class="space-y-6">
            <!-- Header -->
            <div>
                <h1 class="text-2xl font-bold text-gray-900 dark:text-gray-100">
                    {{ $t('Create Credit Memo') }}
                </h1>
                <p class="mt-1 text-gray-600 dark:text-gray-400">
                    {{ $t('Issue a refund for an order') }}
                </p>
            </div>

            <form @submit.prevent="submit" class="space-y-6">
                <!-- Order Selection -->
                <div
                    v-if="!order"
                    class="rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800"
                >
                    <h3
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-gray-100"
                    >
                        {{ $t('Select Order') }}
                    </h3>
                    <div>
                        <label
                            class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >{{ $t('Order *') }}</label
                        >
                        <select
                            v-model="form.order_id"
                            required
                            class="w-full rounded-lg border border-gray-300 px-4 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                        >
                            <option :value="null">
                                {{ $t('Select an order...') }}
                            </option>
                            <option
                                v-for="o in orders"
                                :key="o.id"
                                :value="o.id"
                            >
                                {{ o.order_number }} - {{ o.customer_email }} -
                                {{ formatPrice(o.total) }}
                            </option>
                        </select>
                        <p
                            class="mt-1 text-sm text-gray-500 dark:text-gray-400"
                        >
                            {{
                                $t(
                                    'Select an order to create a credit memo for',
                                )
                            }}
                        </p>
                    </div>
                </div>

                <!-- Order Information -->
                <div
                    v-if="selectedOrder"
                    class="rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800"
                >
                    <h3
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-gray-100"
                    >
                        {{ $t('Order Information') }}
                    </h3>
                    <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
                        <div>
                            <div
                                class="text-sm text-gray-600 dark:text-gray-400"
                            >
                                {{ $t('Order Number') }}
                            </div>
                            <div
                                class="mt-1 font-medium text-gray-900 dark:text-gray-100"
                            >
                                {{ selectedOrder.order_number }}
                            </div>
                        </div>
                        <div>
                            <div
                                class="text-sm text-gray-600 dark:text-gray-400"
                            >
                                {{ $t('Customer') }}
                            </div>
                            <div
                                class="mt-1 font-medium text-gray-900 dark:text-gray-100"
                            >
                                {{ selectedOrder.user?.name || $t('Guest') }}
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
                                {{ formatPrice(selectedOrder.total) }}
                            </div>
                        </div>
                        <div>
                            <div
                                class="text-sm text-gray-600 dark:text-gray-400"
                            >
                                {{ $t('Order Date') }}
                            </div>
                            <div class="mt-1 text-gray-900 dark:text-gray-100">
                                <DateDisplay
                                    :value="selectedOrder.created_at"
                                />
                            </div>
                        </div>
                        <div>
                            <div
                                class="text-sm text-gray-600 dark:text-gray-400"
                            >
                                {{ $t('Payment Method') }}
                            </div>
                            <div class="mt-1 text-gray-900 dark:text-gray-100">
                                {{ selectedOrder.payment_method || '-' }}
                            </div>
                        </div>
                        <div
                            v-if="
                                selectedOrder.total_refunded &&
                                selectedOrder.total_refunded > 0
                            "
                        >
                            <div
                                class="text-sm text-gray-600 dark:text-gray-400"
                            >
                                {{ $t('Already Refunded') }}
                            </div>
                            <div class="mt-1 font-medium text-red-600">
                                {{ formatPrice(selectedOrder.total_refunded) }}
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Items Selection -->
                <div
                    v-if="refundItems.length > 0"
                    class="rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800"
                >
                    <div class="mb-4 flex items-center justify-between">
                        <h3
                            class="text-lg font-semibold text-gray-900 dark:text-gray-100"
                        >
                            {{ $t('Select Items to Refund') }}
                        </h3>
                        <div class="flex space-x-2">
                            <button
                                type="button"
                                @click="selectAllItems"
                                class="rounded px-3 py-1 text-sm text-blue-600 hover:bg-blue-50 hover:text-blue-800"
                            >
                                {{ $t('Select All') }}
                            </button>
                            <button
                                type="button"
                                @click="clearAllItems"
                                class="rounded px-3 py-1 text-sm text-gray-600 hover:bg-gray-50 hover:text-gray-800 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-gray-200"
                            >
                                {{ $t('Clear All') }}
                            </button>
                        </div>
                    </div>

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
                                        {{ $t('Price') }}
                                    </th>
                                    <th
                                        class="px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Ordered') }}
                                    </th>
                                    <th
                                        class="px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Refunded') }}
                                    </th>
                                    <th
                                        class="px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Available') }}
                                    </th>
                                    <th
                                        class="px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                    >
                                        {{ $t('Refund Qty') }}
                                    </th>
                                </tr>
                            </thead>
                            <tbody
                                class="divide-y divide-gray-200 bg-white dark:divide-gray-700 dark:bg-gray-800"
                            >
                                <tr
                                    v-for="item in refundItems"
                                    :key="item.order_item_id"
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
                                            {{ formatPrice(item.price) }}
                                        </div>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right whitespace-nowrap"
                                    >
                                        <div
                                            class="text-sm text-gray-900 dark:text-gray-100"
                                        >
                                            {{ item.qty_ordered }}
                                        </div>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right whitespace-nowrap"
                                    >
                                        <div
                                            class="text-sm text-gray-900 dark:text-gray-100"
                                        >
                                            {{ item.qty_refunded }}
                                        </div>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right whitespace-nowrap"
                                    >
                                        <div
                                            class="text-sm font-medium text-gray-900 dark:text-gray-100"
                                        >
                                            {{ item.qty_refundable }}
                                        </div>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right whitespace-nowrap"
                                    >
                                        <input
                                            v-model.number="
                                                selectedQuantities[
                                                    item.order_item_id
                                                ]
                                            "
                                            type="number"
                                            min="0"
                                            :max="item.qty_refundable"
                                            :disabled="
                                                item.qty_refundable === 0
                                            "
                                            class="w-20 rounded border border-gray-300 px-3 py-1 text-right focus:border-transparent focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100 dark:disabled:bg-gray-800/60"
                                        />
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- Refund Options -->
                <div
                    v-if="selectedOrder"
                    class="rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800"
                >
                    <h3
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-gray-100"
                    >
                        {{ $t('Refund Options') }}
                    </h3>
                    <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
                        <!-- Refund Method -->
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Refund Method *') }}</label
                            >
                            <select
                                v-model="form.refund_method"
                                required
                                class="w-full rounded-lg border border-gray-300 px-4 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            >
                                <option value="online">
                                    {{ $t('Online (Payment Gateway)') }}
                                </option>
                                <option value="offline">
                                    {{ $t('Offline (Manual Refund)') }}
                                </option>
                            </select>
                            <p
                                class="mt-1 text-sm text-gray-500 dark:text-gray-400"
                            >
                                {{
                                    $t(
                                        'Online: Refund through the original payment method',
                                    )
                                }}<br />
                                {{
                                    $t(
                                        'Offline: Manual refund (cash, check, etc.)',
                                    )
                                }}
                            </p>
                        </div>

                        <!-- Restore Inventory -->
                        <div>
                            <label
                                class="flex cursor-pointer items-center space-x-3"
                            >
                                <input
                                    v-model="form.restore_inventory"
                                    type="checkbox"
                                    class="rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                />
                                <div>
                                    <div
                                        class="text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >
                                        {{ $t('Restore Inventory') }}
                                    </div>
                                    <div
                                        class="text-sm text-gray-500 dark:text-gray-400"
                                    >
                                        {{
                                            $t(
                                                'Add refunded items back to inventory',
                                            )
                                        }}
                                    </div>
                                </div>
                            </label>
                        </div>

                        <!-- Shipping Refund -->
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Shipping Refund') }}</label
                            >
                            <div class="relative">
                                <span
                                    class="absolute top-1/2 left-3 -translate-y-1/2 text-gray-500 dark:text-gray-400"
                                    >{{ getSymbol() }}</span
                                >
                                <input
                                    v-model.number="form.shipping_refund"
                                    type="number"
                                    step="0.01"
                                    min="0"
                                    :max="selectedOrder.shipping_cost"
                                    placeholder="0.00"
                                    class="w-full rounded-lg border border-gray-300 py-2 pr-3 pl-7 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                />
                            </div>
                            <p
                                class="mt-1 text-sm text-gray-500 dark:text-gray-400"
                            >
                                {{
                                    $t('Max: {amount}', {
                                        amount: formatPrice(
                                            selectedOrder.shipping_cost,
                                        ),
                                    })
                                }}
                            </p>
                        </div>

                        <!-- Adjustment Amount -->
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Adjustment Amount') }}</label
                            >
                            <div class="relative">
                                <span
                                    class="absolute top-1/2 left-3 -translate-y-1/2 text-gray-500 dark:text-gray-400"
                                    >{{ getSymbol() }}</span
                                >
                                <input
                                    v-model.number="form.adjustment_amount"
                                    type="number"
                                    step="0.01"
                                    placeholder="0.00"
                                    class="w-full rounded-lg border border-gray-300 py-2 pr-3 pl-7 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                />
                            </div>
                            <p
                                class="mt-1 text-sm text-gray-500 dark:text-gray-400"
                            >
                                {{
                                    $t(
                                        'Positive for additional refund, negative for deduction',
                                    )
                                }}
                            </p>
                        </div>
                    </div>

                    <!-- Reason -->
                    <div class="mt-6">
                        <label
                            class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >{{ $t('Reason for Refund') }}</label
                        >
                        <textarea
                            v-model="form.reason"
                            rows="3"
                            :placeholder="
                                $t('Enter the reason for this refund...')
                            "
                            class="w-full rounded-lg border border-gray-300 px-4 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                        ></textarea>
                    </div>

                    <!-- Notes -->
                    <div class="mt-6">
                        <label
                            class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >{{ $t('Internal Notes') }}</label
                        >
                        <textarea
                            v-model="form.notes"
                            rows="3"
                            :placeholder="
                                $t(
                                    'Internal notes (not visible to customer)...',
                                )
                            "
                            class="w-full rounded-lg border border-gray-300 px-4 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                        ></textarea>
                    </div>
                </div>

                <!-- Totals Summary -->
                <div
                    v-if="selectedOrder"
                    class="rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800"
                >
                    <h3
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-gray-100"
                    >
                        {{ $t('Refund Summary') }}
                    </h3>
                    <div class="ml-auto max-w-md space-y-3">
                        <div class="flex justify-between text-sm">
                            <span class="text-gray-600 dark:text-gray-400">{{
                                $t('Subtotal:')
                            }}</span>
                            <span
                                class="font-medium text-gray-900 dark:text-gray-100"
                                >{{ formatPrice(subtotal) }}</span
                            >
                        </div>
                        <div
                            v-if="discountAmount > 0"
                            class="flex justify-between text-sm"
                        >
                            <span class="text-gray-600 dark:text-gray-400">{{
                                $t('Discount:')
                            }}</span>
                            <span
                                class="font-medium text-gray-900 dark:text-gray-100"
                                >-{{ formatPrice(discountAmount) }}</span
                            >
                        </div>
                        <div class="flex justify-between text-sm">
                            <span class="text-gray-600 dark:text-gray-400">{{
                                $t('Tax:')
                            }}</span>
                            <span
                                class="font-medium text-gray-900 dark:text-gray-100"
                                >{{ formatPrice(taxAmount) }}</span
                            >
                        </div>
                        <div
                            v-if="form.shipping_refund > 0"
                            class="flex justify-between text-sm"
                        >
                            <span class="text-gray-600 dark:text-gray-400">{{
                                $t('Shipping Refund:')
                            }}</span>
                            <span
                                class="font-medium text-gray-900 dark:text-gray-100"
                                >{{ formatPrice(form.shipping_refund) }}</span
                            >
                        </div>
                        <div
                            v-if="form.adjustment_amount !== 0"
                            class="flex justify-between text-sm"
                        >
                            <span class="text-gray-600 dark:text-gray-400">{{
                                $t('Adjustment:')
                            }}</span>
                            <span
                                class="font-medium text-gray-900 dark:text-gray-100"
                            >
                                {{ form.adjustment_amount > 0 ? '+' : ''
                                }}{{ formatPrice(form.adjustment_amount) }}
                            </span>
                        </div>
                        <div
                            class="flex justify-between border-t border-gray-200 pt-3 text-lg font-bold dark:border-gray-700"
                        >
                            <span class="text-gray-900 dark:text-gray-100">{{
                                $t('Total Refund:')
                            }}</span>
                            <span class="text-gray-900 dark:text-gray-100">{{
                                formatPrice(grandTotal)
                            }}</span>
                        </div>
                    </div>
                </div>

                <!-- Actions -->
                <div class="flex items-center justify-end space-x-4">
                    <button
                        type="button"
                        @click="cancel"
                        class="rounded-lg border border-gray-300 px-6 py-2 text-gray-700 hover:bg-gray-50 focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 focus:outline-none dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                    >
                        {{ $t('Cancel') }}
                    </button>
                    <button
                        type="submit"
                        :disabled="form.processing || !hasSelectedItems"
                        class="rounded-lg bg-blue-600 px-6 py-2 text-white hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        {{
                            $t(
                                form.processing
                                    ? 'Creating...'
                                    : 'Create Credit Memo',
                            )
                        }}
                    </button>
                </div>
            </form>
        </div>
    </AdminLayout>
</template>

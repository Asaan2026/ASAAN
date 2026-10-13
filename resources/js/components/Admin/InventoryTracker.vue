<script setup lang="ts">
import { computed, ref } from 'vue';

interface InventoryAdjustment {
    id?: number;
    type: 'addition' | 'subtraction' | 'correction';
    quantity: number;
    reason: string;
    notes: string | null;
    created_at?: string;
    user?: { name: string };
}

interface Warehouse {
    id: number;
    name: string;
    code: string;
    quantity: number;
}

interface Props {
    productId: number;
    currentStock: number;
    minQuantity?: number;
    notifyStockQty?: number;
    manageStock?: boolean;
    warehouses?: Warehouse[];
    adjustmentHistory?: InventoryAdjustment[];
}

const props = withDefaults(defineProps<Props>(), {
    minQuantity: 1,
    notifyStockQty: 5,
    manageStock: true,
    warehouses: () => [],
    adjustmentHistory: () => [],
});

const emit = defineEmits(['update:stock']);

// State
const showAdjustmentForm = ref(false);
const newAdjustment = ref<InventoryAdjustment>({
    type: 'addition',
    quantity: 0,
    reason: '',
    notes: null,
});

const isSubmitting = ref(false);

// Computed
const stockStatus = computed(() => {
    if (!props.manageStock) return 'unmanaged';
    if (props.currentStock === 0) return 'out_of_stock';
    if (props.currentStock <= props.notifyStockQty) return 'low_stock';
    return 'in_stock';
});

const stockStatusColor = computed(() => {
    switch (stockStatus.value) {
        case 'out_of_stock':
            return 'bg-red-100 text-red-800';
        case 'low_stock':
            return 'bg-yellow-100 text-yellow-800';
        case 'in_stock':
            return 'bg-green-100 text-green-800';
        default:
            return 'bg-gray-100 text-gray-800';
    }
});

const stockStatusText = computed(() => {
    switch (stockStatus.value) {
        case 'out_of_stock':
            return 'Out of Stock';
        case 'low_stock':
            return 'Low Stock';
        case 'in_stock':
            return 'In Stock';
        default:
            return 'Not Managed';
    }
});

const totalWarehouseStock = computed(() => {
    return props.warehouses.reduce((sum, wh) => sum + wh.quantity, 0);
});

// Methods
const openAdjustmentForm = () => {
    showAdjustmentForm.value = true;
    newAdjustment.value = {
        type: 'addition',
        quantity: 0,
        reason: '',
        notes: null,
    };
};

const submitAdjustment = async () => {
    if (newAdjustment.value.quantity <= 0) {
        alert('Please enter a valid quantity');
        return;
    }

    if (!newAdjustment.value.reason.trim()) {
        alert('Please provide a reason for the adjustment');
        return;
    }

    isSubmitting.value = true;

    // Calculate new stock
    let newStock = props.currentStock;
    if (newAdjustment.value.type === 'addition') {
        newStock += newAdjustment.value.quantity;
    } else if (newAdjustment.value.type === 'subtraction') {
        newStock = Math.max(0, newStock - newAdjustment.value.quantity);
    } else if (newAdjustment.value.type === 'correction') {
        newStock = newAdjustment.value.quantity;
    }

    // Emit update
    emit('update:stock', {
        quantity: newStock,
        adjustment: newAdjustment.value,
    });

    // Close form
    showAdjustmentForm.value = false;
    isSubmitting.value = false;
};

const getAdjustmentTypeLabel = (type: string) => {
    switch (type) {
        case 'addition':
            return 'Stock Added';
        case 'subtraction':
            return 'Stock Removed';
        case 'correction':
            return 'Stock Correction';
        default:
            return type;
    }
};

const getAdjustmentTypeColor = (type: string) => {
    switch (type) {
        case 'addition':
            return 'text-green-600';
        case 'subtraction':
            return 'text-red-600';
        case 'correction':
            return 'text-blue-600';
        default:
            return 'text-gray-600';
    }
};

const formatDate = (date: string) => {
    return new Date(date).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
    });
};
</script>

<template>
    <div class="rounded-lg bg-white shadow dark:bg-gray-800">
        <!-- Inventory Overview -->
        <div class="border-b border-gray-200 p-6 dark:border-gray-700">
            <div class="mb-6 flex items-center justify-between">
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
                    {{ $t('Inventory Management') }}
                </h3>
                <button
                    @click="openAdjustmentForm"
                    class="cursor-pointer rounded-lg bg-blue-600 px-4 py-2 text-white transition-colors hover:bg-blue-700"
                >
                    {{ $t('Adjust Stock') }}
                </button>
            </div>

            <!-- Stock Summary Cards -->
            <div class="grid grid-cols-1 gap-4 md:grid-cols-4">
                <!-- Current Stock -->
                <div class="rounded-lg bg-gray-50 p-4 dark:bg-gray-700/50">
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="mb-1 text-sm text-gray-600 dark:text-gray-400"
                            >
                                {{ $t('Current Stock') }}
                            </p>
                            <p
                                class="text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ currentStock }}
                            </p>
                        </div>
                        <div
                            class="flex h-12 w-12 items-center justify-center rounded-full bg-blue-100 dark:bg-blue-900/30"
                        >
                            <svg
                                class="h-6 w-6 text-blue-600 dark:text-blue-400"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
                                />
                            </svg>
                        </div>
                    </div>
                    <div class="mt-2">
                        <span
                            :class="`rounded-full px-2 py-1 text-xs font-medium ${stockStatusColor}`"
                        >
                            {{ stockStatusText }}
                        </span>
                    </div>
                </div>

                <!-- Low Stock Threshold -->
                <div class="rounded-lg bg-gray-50 p-4 dark:bg-gray-700/50">
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="mb-1 text-sm text-gray-600 dark:text-gray-400"
                            >
                                {{ $t('Low Stock Alert') }}
                            </p>
                            <p
                                class="text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ notifyStockQty }}
                            </p>
                        </div>
                        <div
                            class="flex h-12 w-12 items-center justify-center rounded-full bg-yellow-100 dark:bg-yellow-900/30"
                        >
                            <svg
                                class="h-6 w-6 text-yellow-600 dark:text-yellow-400"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                                />
                            </svg>
                        </div>
                    </div>
                    <p class="mt-2 text-xs text-gray-500 dark:text-gray-400">
                        {{ $t('Alert when stock falls below this level') }}
                    </p>
                </div>

                <!-- Minimum Quantity -->
                <div class="rounded-lg bg-gray-50 p-4 dark:bg-gray-700/50">
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="mb-1 text-sm text-gray-600 dark:text-gray-400"
                            >
                                {{ $t('Min Quantity') }}
                            </p>
                            <p
                                class="text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ minQuantity }}
                            </p>
                        </div>
                        <div
                            class="flex h-12 w-12 items-center justify-center rounded-full bg-purple-100 dark:bg-purple-900/30"
                        >
                            <svg
                                class="h-6 w-6 text-purple-600 dark:text-purple-400"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M13 17h8m0 0V9m0 8l-8-8-4 4-6-6"
                                />
                            </svg>
                        </div>
                    </div>
                    <p class="mt-2 text-xs text-gray-500 dark:text-gray-400">
                        {{ $t('Minimum purchase quantity') }}
                    </p>
                </div>

                <!-- Stock Status -->
                <div class="rounded-lg bg-gray-50 p-4 dark:bg-gray-700/50">
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="mb-1 text-sm text-gray-600 dark:text-gray-400"
                            >
                                {{ $t('Management') }}
                            </p>
                            <p
                                class="text-lg font-semibold text-gray-900 dark:text-white"
                            >
                                {{ $t(manageStock ? 'Enabled' : 'Disabled') }}
                            </p>
                        </div>
                        <div
                            :class="`flex h-12 w-12 items-center justify-center rounded-full ${manageStock ? 'bg-green-100 dark:bg-green-900/30' : 'bg-gray-200 dark:bg-gray-600'}`"
                        >
                            <svg
                                class="h-6 w-6"
                                :class="
                                    manageStock
                                        ? 'text-green-600 dark:text-green-400'
                                        : 'text-gray-500 dark:text-gray-400'
                                "
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
                                />
                            </svg>
                        </div>
                    </div>
                    <p class="mt-2 text-xs text-gray-500 dark:text-gray-400">
                        {{
                            $t(
                                manageStock
                                    ? 'Stock tracking active'
                                    : 'No stock tracking',
                            )
                        }}
                    </p>
                </div>
            </div>
        </div>

        <!-- Warehouses (if multi-warehouse enabled) -->
        <div
            v-if="warehouses.length > 0"
            class="border-b border-gray-200 p-6 dark:border-gray-700"
        >
            <h4
                class="mb-4 text-sm font-semibold text-gray-900 dark:text-white"
            >
                {{ $t('Stock by Warehouse') }}
            </h4>
            <div class="space-y-3">
                <div
                    v-for="warehouse in warehouses"
                    :key="warehouse.id"
                    class="flex items-center justify-between rounded-lg bg-gray-50 p-3 dark:bg-gray-700/50"
                >
                    <div class="flex items-center gap-3">
                        <div
                            class="flex h-10 w-10 items-center justify-center rounded-lg bg-blue-100 dark:bg-blue-900/30"
                        >
                            <span
                                class="text-sm font-semibold text-blue-600 dark:text-blue-400"
                                >{{ warehouse.code }}</span
                            >
                        </div>
                        <div>
                            <p
                                class="text-sm font-medium text-gray-900 dark:text-white"
                            >
                                {{ warehouse.name }}
                            </p>
                            <p class="text-xs text-gray-500 dark:text-gray-400">
                                {{
                                    $t('Code: {code}', { code: warehouse.code })
                                }}
                            </p>
                        </div>
                    </div>
                    <div class="text-right">
                        <p
                            class="text-lg font-semibold text-gray-900 dark:text-white"
                        >
                            {{ warehouse.quantity }}
                        </p>
                        <p class="text-xs text-gray-500 dark:text-gray-400">
                            {{ $t('units') }}
                        </p>
                    </div>
                </div>

                <div
                    class="flex items-center justify-between rounded-lg border-2 border-blue-200 bg-blue-50 p-3 dark:border-blue-800 dark:bg-blue-900/20"
                >
                    <p
                        class="text-sm font-semibold text-blue-900 dark:text-blue-300"
                    >
                        {{ $t('Total Stock') }}
                    </p>
                    <p
                        class="text-lg font-bold text-blue-900 dark:text-blue-300"
                    >
                        {{
                            $t('{total} units', { total: totalWarehouseStock })
                        }}
                    </p>
                </div>
            </div>
        </div>

        <!-- Adjustment History -->
        <div class="p-6">
            <h4
                class="mb-4 text-sm font-semibold text-gray-900 dark:text-white"
            >
                {{ $t('Stock Adjustment History') }}
            </h4>

            <div
                v-if="adjustmentHistory.length > 0"
                class="max-h-96 space-y-3 overflow-y-auto"
            >
                <div
                    v-for="adjustment in adjustmentHistory"
                    :key="adjustment.id"
                    class="flex items-start gap-4 rounded-lg bg-gray-50 p-4 transition-colors hover:bg-gray-100 dark:bg-gray-700/50 dark:hover:bg-gray-700"
                >
                    <div class="flex-shrink-0">
                        <div
                            :class="`flex h-10 w-10 items-center justify-center rounded-full ${
                                adjustment.type === 'addition'
                                    ? 'bg-green-100 dark:bg-green-900/30'
                                    : adjustment.type === 'subtraction'
                                      ? 'bg-red-100 dark:bg-red-900/30'
                                      : 'bg-blue-100 dark:bg-blue-900/30'
                            }`"
                        >
                            <svg
                                v-if="adjustment.type === 'addition'"
                                class="h-5 w-5 text-green-600 dark:text-green-400"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                                />
                            </svg>
                            <svg
                                v-else-if="adjustment.type === 'subtraction'"
                                class="h-5 w-5 text-red-600 dark:text-red-400"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M18 12H6"
                                />
                            </svg>
                            <svg
                                v-else
                                class="h-5 w-5 text-blue-600 dark:text-blue-400"
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
                        </div>
                    </div>

                    <div class="min-w-0 flex-1">
                        <div class="flex items-start justify-between">
                            <div>
                                <p
                                    :class="`text-sm font-medium ${
                                        adjustment.type === 'addition'
                                            ? 'text-green-600 dark:text-green-400'
                                            : adjustment.type === 'subtraction'
                                              ? 'text-red-600 dark:text-red-400'
                                              : 'text-blue-600 dark:text-blue-400'
                                    }`"
                                >
                                    {{
                                        getAdjustmentTypeLabel(adjustment.type)
                                    }}
                                </p>
                                <p
                                    class="text-sm font-semibold text-gray-900 dark:text-white"
                                >
                                    {{
                                        adjustment.type === 'addition'
                                            ? '+'
                                            : adjustment.type === 'subtraction'
                                              ? '-'
                                              : ''
                                    }}{{
                                        $t('{quantity} units', {
                                            quantity: adjustment.quantity,
                                        })
                                    }}
                                </p>
                            </div>
                            <span
                                class="text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{
                                    adjustment.created_at
                                        ? formatDate(adjustment.created_at)
                                        : $t('Just now')
                                }}
                            </span>
                        </div>

                        <p
                            class="mt-1 text-sm text-gray-700 dark:text-gray-300"
                        >
                            {{ adjustment.reason }}
                        </p>
                        <p
                            v-if="adjustment.notes"
                            class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                        >
                            {{ adjustment.notes }}
                        </p>
                        <p
                            v-if="adjustment.user"
                            class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                        >
                            {{
                                $t('By: {name}', { name: adjustment.user.name })
                            }}
                        </p>
                    </div>
                </div>
            </div>

            <div
                v-else
                class="rounded-lg bg-gray-50 py-8 text-center dark:bg-gray-700/50"
            >
                <svg
                    class="mx-auto h-12 w-12 text-gray-400 dark:text-gray-500"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                >
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                    />
                </svg>
                <p class="mt-2 text-sm text-gray-600 dark:text-gray-400">
                    {{ $t('No stock adjustments recorded yet') }}
                </p>
            </div>
        </div>

        <!-- Stock Adjustment Modal -->
        <div
            v-if="showAdjustmentForm"
            class="fixed inset-0 z-50 flex transform items-center justify-center bg-gray-500/75 transition-all dark:bg-gray-900/75"
            @click.self="showAdjustmentForm = false"
        >
            <div
                class="mx-4 w-full max-w-md rounded-lg bg-white shadow-xl dark:bg-gray-800"
            >
                <div class="p-6">
                    <h3
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-white"
                    >
                        {{ $t('Adjust Inventory') }}
                    </h3>

                    <div class="space-y-4">
                        <div>
                            <label
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Adjustment Type') }}</label
                            >
                            <select
                                v-model="newAdjustment.type"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            >
                                <option value="addition">
                                    {{ $t('Add Stock') }}
                                </option>
                                <option value="subtraction">
                                    {{ $t('Remove Stock') }}
                                </option>
                                <option value="correction">
                                    {{ $t('Stock Correction') }}
                                </option>
                            </select>
                        </div>

                        <div>
                            <label
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{
                                    $t(
                                        newAdjustment.type === 'correction'
                                            ? 'New Stock Level'
                                            : 'Quantity',
                                    )
                                }}
                            </label>
                            <input
                                v-model.number="newAdjustment.quantity"
                                type="number"
                                min="0"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            />
                            <p
                                v-if="newAdjustment.type !== 'correction'"
                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{
                                    $t('Current stock: {stock} units', {
                                        stock: currentStock,
                                    })
                                }}
                            </p>
                        </div>

                        <div>
                            <label
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Reason *') }}</label
                            >
                            <input
                                v-model="newAdjustment.reason"
                                type="text"
                                :placeholder="
                                    $t(
                                        'e.g., New shipment, Damaged goods, Stock count',
                                    )
                                "
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            />
                        </div>

                        <div>
                            <label
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Notes (Optional)') }}</label
                            >
                            <textarea
                                v-model="newAdjustment.notes"
                                rows="3"
                                :placeholder="$t('Additional details...')"
                                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            ></textarea>
                        </div>
                    </div>

                    <div class="mt-6 flex gap-3">
                        <button
                            @click="submitAdjustment"
                            :disabled="isSubmitting"
                            class="flex-1 cursor-pointer rounded-lg bg-blue-600 px-4 py-2 text-white transition-colors hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
                        >
                            {{
                                $t(
                                    isSubmitting
                                        ? 'Adjusting...'
                                        : 'Adjust Stock',
                                )
                            }}
                        </button>
                        <button
                            @click="showAdjustmentForm = false"
                            :disabled="isSubmitting"
                            class="cursor-pointer rounded-lg bg-gray-100 px-4 py-2 text-gray-700 transition-colors hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600"
                        >
                            {{ $t('Cancel') }}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { useCurrency } from '@/composables/useCurrency';
import { computed, ref } from 'vue';

const { formatPrice } = useCurrency();

interface Attribute {
    id: number;
    code: string;
    name: string;
    type: string;
    is_configurable: boolean;
    options: AttributeOption[];
}

interface AttributeOption {
    id: number;
    label: string;
    value: string;
    swatch_value: string | null;
}

interface Variant {
    id?: number;
    sku: string;
    name: string;
    price: string;
    special_price: string | null;
    quantity: number;
    is_enabled: boolean;
    attributes: Record<number, number>; // attribute_id => option_id
    image_id?: number | null;
}

interface Props {
    productId: number;
    basePrice: string;
    baseSku: string;
    configurable_attributes?: Attribute[];
    existing_variants?: Variant[];
}

const props = withDefaults(defineProps<Props>(), {
    configurable_attributes: () => [],
    existing_variants: () => [],
});

const emit = defineEmits(['update:variants']);

// State
const variants = ref<Variant[]>(props.existing_variants || []);
const selectedAttributes = ref<Record<number, number[]>>({});
const showVariantForm = ref(false);
const editingVariant = ref<Variant | null>(null);
const generating = ref(false);

// Initialize selected attributes
props.configurable_attributes.forEach((attr) => {
    selectedAttributes.value[attr.id] = [];
});

// Generate all combinations of selected attribute options
const generateVariants = () => {
    if (Object.keys(selectedAttributes.value).length === 0) {
        alert('Please select at least one configurable attribute');
        return;
    }

    generating.value = true;

    // Get all selected options for each attribute
    const attributeSelections: Array<{
        attributeId: number;
        optionIds: number[];
    }> = [];

    for (const [attrId, optionIds] of Object.entries(
        selectedAttributes.value,
    )) {
        if (optionIds.length > 0) {
            attributeSelections.push({
                attributeId: parseInt(attrId),
                optionIds: optionIds,
            });
        }
    }

    if (attributeSelections.length === 0) {
        alert('Please select attribute options to generate variants');
        generating.value = false;
        return;
    }

    // Generate combinations
    const combinations = cartesianProduct(attributeSelections);

    // Create variant for each combination
    const newVariants: Variant[] = combinations.map((combo, index) => {
        // Build variant name from attribute options
        const variantNameParts: string[] = [];
        const attributes: Record<number, number> = {};

        combo.forEach(({ attributeId, optionId }) => {
            const attr = props.configurable_attributes.find(
                (a) => a.id === attributeId,
            );
            const option = attr?.options.find((o) => o.id === optionId);
            if (option) {
                variantNameParts.push(option.label);
            }
            attributes[attributeId] = optionId;
        });

        // Generate SKU
        const variantSuffix = variantNameParts
            .map((part) => part.substring(0, 3).toUpperCase())
            .join('-');

        return {
            sku: `${props.baseSku}-${variantSuffix}-${Date.now()}-${index}`,
            name: variantNameParts.join(' / '),
            price: props.basePrice,
            special_price: null,
            quantity: 0,
            is_enabled: true,
            attributes: attributes,
        };
    });

    variants.value = [...variants.value, ...newVariants];
    generating.value = false;
    emit('update:variants', variants.value);
};

// Helper function to generate cartesian product
function cartesianProduct(
    selections: Array<{ attributeId: number; optionIds: number[] }>,
): Array<Array<{ attributeId: number; optionId: number }>> {
    if (selections.length === 0) return [[]];

    const [first, ...rest] = selections;
    const restProduct = cartesianProduct(rest);

    const result: Array<Array<{ attributeId: number; optionId: number }>> = [];

    for (const optionId of first.optionIds) {
        for (const combo of restProduct) {
            result.push([
                { attributeId: first.attributeId, optionId },
                ...combo,
            ]);
        }
    }

    return result;
}

// Get attribute option label
const getOptionLabel = (attributeId: number, optionId: number): string => {
    const attr = props.configurable_attributes.find(
        (a) => a.id === attributeId,
    );
    const option = attr?.options.find((o) => o.id === optionId);
    return option?.label || 'Unknown';
};

// Get attribute name
const getAttributeName = (attributeId: number): string => {
    const attr = props.configurable_attributes.find(
        (a) => a.id === attributeId,
    );
    return attr?.name || 'Unknown';
};

// Remove variant
const removeVariant = (index: number) => {
    if (confirm('Are you sure you want to remove this variant?')) {
        variants.value.splice(index, 1);
        emit('update:variants', variants.value);
    }
};

// Edit variant
const editVariant = (variant: Variant) => {
    editingVariant.value = { ...variant };
    showVariantForm.value = true;
};

// Save edited variant
const saveVariant = () => {
    if (!editingVariant.value) return;

    const index = variants.value.findIndex(
        (v) => v.sku === editingVariant.value!.sku,
    );
    if (index !== -1) {
        variants.value[index] = editingVariant.value;
        emit('update:variants', variants.value);
    }

    showVariantForm.value = false;
    editingVariant.value = null;
};

// Bulk update prices
const bulkUpdatePrices = () => {
    const newPrice = prompt(
        'Enter new price for all variants:',
        props.basePrice,
    );
    if (newPrice && !isNaN(parseFloat(newPrice))) {
        variants.value.forEach((variant) => {
            variant.price = parseFloat(newPrice).toFixed(2);
        });
        emit('update:variants', variants.value);
    }
};

// Bulk update quantities
const bulkUpdateQuantities = () => {
    const newQuantity = prompt('Enter new quantity for all variants:', '0');
    if (newQuantity && !isNaN(parseInt(newQuantity))) {
        variants.value.forEach((variant) => {
            variant.quantity = parseInt(newQuantity);
        });
        emit('update:variants', variants.value);
    }
};

// Total variants count
const totalVariants = computed(() => variants.value.length);
const enabledVariants = computed(
    () => variants.value.filter((v) => v.is_enabled).length,
);
const totalStock = computed(() =>
    variants.value.reduce((sum, v) => sum + v.quantity, 0),
);
</script>

<template>
    <div class="rounded-lg bg-white p-6 shadow">
        <div class="mb-6 flex items-center justify-between">
            <h3 class="text-lg font-semibold text-gray-900">
                Product Variants
            </h3>
            <div class="flex gap-2">
                <span class="text-sm text-gray-600">
                    {{ enabledVariants }} / {{ totalVariants }} enabled | Stock:
                    {{ totalStock }}
                </span>
            </div>
        </div>

        <!-- Attribute Selection -->
        <div v-if="configurable_attributes.length > 0" class="mb-6">
            <h4 class="mb-3 text-sm font-medium text-gray-700">
                1. Select Configurable Attributes
            </h4>

            <div class="space-y-4">
                <div
                    v-for="attribute in configurable_attributes"
                    :key="attribute.id"
                    class="rounded-lg border border-gray-200 p-4"
                >
                    <label class="mb-2 block text-sm font-medium text-gray-700">
                        {{ attribute.name }}
                    </label>

                    <div class="flex flex-wrap gap-2">
                        <label
                            v-for="option in attribute.options"
                            :key="option.id"
                            class="inline-flex cursor-pointer items-center"
                        >
                            <input
                                type="checkbox"
                                v-model="selectedAttributes[attribute.id]"
                                :value="option.id"
                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                            />
                            <span class="ml-2 text-sm text-gray-700">
                                {{ option.label }}
                                <span
                                    v-if="
                                        option.swatch_value &&
                                        attribute.code === 'color'
                                    "
                                    class="ml-1 inline-block h-4 w-4 rounded border border-gray-300"
                                    :style="{
                                        backgroundColor: option.swatch_value,
                                    }"
                                ></span>
                            </span>
                        </label>
                    </div>
                </div>
            </div>

            <button
                @click="generateVariants"
                :disabled="generating"
                class="mt-4 cursor-pointer rounded-lg bg-blue-600 px-4 py-2 text-white transition-colors hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
            >
                <span v-if="generating">Generating...</span>
                <span v-else>Generate Variants</span>
            </button>
        </div>

        <!-- No Configurable Attributes -->
        <div v-else class="rounded-lg bg-gray-50 py-8 text-center">
            <svg
                class="mx-auto h-12 w-12 text-gray-400"
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
            <p class="mt-2 text-sm text-gray-600">
                No configurable attributes available. Please create attributes
                first.
            </p>
        </div>

        <!-- Variants List -->
        <div v-if="variants.length > 0" class="mt-8">
            <div class="mb-4 flex items-center justify-between">
                <h4 class="text-sm font-medium text-gray-700">
                    2. Manage Variants ({{ variants.length }})
                </h4>
                <div class="flex gap-2">
                    <button
                        @click="bulkUpdatePrices"
                        class="cursor-pointer rounded bg-gray-100 px-3 py-1.5 text-sm text-gray-700 transition-colors hover:bg-gray-200"
                    >
                        Bulk Update Prices
                    </button>
                    <button
                        @click="bulkUpdateQuantities"
                        class="cursor-pointer rounded bg-gray-100 px-3 py-1.5 text-sm text-gray-700 transition-colors hover:bg-gray-200"
                    >
                        Bulk Update Stock
                    </button>
                </div>
            </div>

            <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                        <tr>
                            <th
                                class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase"
                            >
                                SKU
                            </th>
                            <th
                                class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase"
                            >
                                Variant
                            </th>
                            <th
                                class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase"
                            >
                                Price
                            </th>
                            <th
                                class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase"
                            >
                                Stock
                            </th>
                            <th
                                class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase"
                            >
                                Status
                            </th>
                            <th
                                class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase"
                            >
                                Actions
                            </th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-200 bg-white">
                        <tr v-for="(variant, index) in variants" :key="index">
                            <td class="px-4 py-3 text-sm text-gray-900">
                                {{ variant.sku }}
                            </td>
                            <td class="px-4 py-3">
                                <div class="text-sm font-medium text-gray-900">
                                    {{ variant.name }}
                                </div>
                                <div class="mt-1 text-xs text-gray-500">
                                    <span
                                        v-for="(
                                            optionId, attrId
                                        ) in variant.attributes"
                                        :key="attrId"
                                        class="mr-2 inline-block"
                                    >
                                        {{ getAttributeName(Number(attrId)) }}:
                                        {{
                                            getOptionLabel(
                                                Number(attrId),
                                                optionId,
                                            )
                                        }}
                                    </span>
                                </div>
                            </td>
                            <td class="px-4 py-3">
                                <div class="text-sm text-gray-900">
                                    {{ formatPrice(variant.price) }}
                                </div>
                                <div
                                    v-if="variant.special_price"
                                    class="text-xs text-green-600"
                                >
                                    Sale:
                                    {{ formatPrice(variant.special_price) }}
                                </div>
                            </td>
                            <td class="px-4 py-3">
                                <span
                                    class="rounded-full px-2 py-1 text-xs font-medium"
                                    :class="{
                                        'bg-green-100 text-green-800':
                                            variant.quantity > 10,
                                        'bg-yellow-100 text-yellow-800':
                                            variant.quantity > 0 &&
                                            variant.quantity <= 10,
                                        'bg-red-100 text-red-800':
                                            variant.quantity === 0,
                                    }"
                                >
                                    {{ variant.quantity }} units
                                </span>
                            </td>
                            <td class="px-4 py-3">
                                <span
                                    class="rounded-full px-2 py-1 text-xs font-medium"
                                    :class="{
                                        'bg-green-100 text-green-800':
                                            variant.is_enabled,
                                        'bg-gray-100 text-gray-800':
                                            !variant.is_enabled,
                                    }"
                                >
                                    {{
                                        variant.is_enabled
                                            ? 'Enabled'
                                            : 'Disabled'
                                    }}
                                </span>
                            </td>
                            <td class="px-4 py-3">
                                <div class="flex gap-2">
                                    <button
                                        @click="editVariant(variant)"
                                        class="cursor-pointer text-sm text-blue-600 hover:text-blue-800"
                                    >
                                        Edit
                                    </button>
                                    <button
                                        @click="removeVariant(index)"
                                        class="cursor-pointer text-sm text-red-600 hover:text-red-800"
                                    >
                                        Remove
                                    </button>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Edit Variant Modal -->
        <div
            v-if="showVariantForm && editingVariant"
            class="fixed inset-0 z-50 flex items-center justify-center bg-gray-500/75 dark:bg-gray-900/75"
        >
            <div class="mx-4 w-full max-w-md rounded-lg bg-white shadow-xl">
                <div class="p-6">
                    <h3 class="mb-4 text-lg font-semibold text-gray-900">
                        Edit Variant
                    </h3>

                    <div class="space-y-4">
                        <div>
                            <label
                                class="mb-1 block text-sm font-medium text-gray-700"
                                >SKU</label
                            >
                            <input
                                v-model="editingVariant.sku"
                                type="text"
                                class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500"
                            />
                        </div>

                        <div>
                            <label
                                class="mb-1 block text-sm font-medium text-gray-700"
                                >Price</label
                            >
                            <input
                                v-model="editingVariant.price"
                                type="number"
                                step="0.01"
                                class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500"
                            />
                        </div>

                        <div>
                            <label
                                class="mb-1 block text-sm font-medium text-gray-700"
                                >Special Price</label
                            >
                            <input
                                v-model="editingVariant.special_price"
                                type="number"
                                step="0.01"
                                class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500"
                            />
                        </div>

                        <div>
                            <label
                                class="mb-1 block text-sm font-medium text-gray-700"
                                >Quantity</label
                            >
                            <input
                                v-model.number="editingVariant.quantity"
                                type="number"
                                class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500"
                            />
                        </div>

                        <div class="flex items-center">
                            <input
                                v-model="editingVariant.is_enabled"
                                type="checkbox"
                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                            />
                            <label class="ml-2 text-sm text-gray-700"
                                >Enabled</label
                            >
                        </div>
                    </div>

                    <div class="mt-6 flex gap-3">
                        <button
                            @click="saveVariant"
                            class="flex-1 cursor-pointer rounded-lg bg-blue-600 px-4 py-2 text-white transition-colors hover:bg-blue-700"
                        >
                            Save Changes
                        </button>
                        <button
                            @click="
                                showVariantForm = false;
                                editingVariant = null;
                            "
                            class="cursor-pointer rounded-lg bg-gray-100 px-4 py-2 text-gray-700 transition-colors hover:bg-gray-200"
                        >
                            Cancel
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

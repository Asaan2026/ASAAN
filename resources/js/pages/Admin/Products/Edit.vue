<script setup lang="ts">
import ConfirmDeleteModal from '@/components/Admin/ConfirmDeleteModal.vue';
import ImageUploader from '@/components/Admin/ImageUploader.vue';
import InventoryTracker from '@/components/Admin/InventoryTracker.vue';
import TiptapEditor from '@/components/Admin/TiptapEditor.vue';
import DatePicker from '@/components/Calendar/DatePicker.vue';
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import axios from '@/lib/axios';
import * as productRoutes from '@/routes/admin/catalog/products';
import { Head, Link, router } from '@inertiajs/vue3';
import { computed, onMounted, ref } from 'vue';

interface Category {
    id: number;
    name: string;
    parent_id: number | null;
    children?: Category[];
}

interface Brand {
    id: number;
    name: string;
}

interface TaxClass {
    id: number;
    name: string;
    code: string;
}

interface AttributeOption {
    id: number;
    attribute_id: number;
    label: string;
    value: string;
    swatch_value?: string;
    sort_order: number;
}

interface Attribute {
    id: number;
    name: string;
    code: string;
    type:
        | 'text'
        | 'textarea'
        | 'select'
        | 'multiselect'
        | 'boolean'
        | 'date'
        | 'price';
    is_required: boolean;
    is_filterable: boolean;
    is_configurable: boolean;
    options?: AttributeOption[];
}

interface Product {
    id: number;
    name: string;
    slug: string;
    sku: string;
    description: string | null;
    short_description: string | null;
    price: string;
    special_price: string | null;
    special_price_from: string | null;
    special_price_to: string | null;
    cost: string | null;
    quantity: number;
    weight: string | null;
    status: string;
    visibility: string;
    featured: boolean;
    new: boolean;
    stock_status: string;
    manage_stock: boolean;
    type: string;
    brand_id: number | null;
    meta_title: string | null;
    meta_description: string | null;
    meta_keywords: string | null;
    tax_class_id?: number | null;
    categories: Array<{ id: number; name: string }>;
    main_image_id: number | null;
    images: Array<{
        id: number;
        path: string;
        url: string; // Added url property
        thumbnail_path: string;
        alt_text: string | null;
        position: number;
    }>;
    attribute_values?: Array<{
        id: number;
        attribute_id: number;
        value: any;
        attribute?: {
            id: number;
            code: string;
            name: string;
            type: string;
        };
    }>;
}

interface Props {
    product: Product;
    categories: Category[];
    brands: Brand[];
    taxClasses: TaxClass[];
    attributes: Attribute[];
    ai?: {
        enabled?: boolean;
        agents?: Array<{ name: string }>;
        product_description_agent?: string;
    };
    currency?: {
        code: string;
        symbol: string;
        symbol_position: string;
        decimal_places: number;
    };
    adjustmentHistory?: Array<{
        id: number;
        type: 'addition' | 'subtraction' | 'correction';
        quantity: number;
        quantity_adjusted: number;
        reason: string;
        notes: string | null;
        created_at: string;
        user?: { id: number; name: string };
    }>;
    errors?: Record<string, string>;
}

const props = defineProps<Props>();

interface PriceComparisonOption {
    variation: string;
    source_label: string;
    price: number;
    currency: string;
    details: string;
}

interface PriceComparisonResponse {
    options: PriceComparisonOption[];
    meta?: {
        store_country?: string;
        current_price?: number;
        cost?: number;
    };
}

const aiEnabled = computed(() => props.ai?.enabled ?? false);

// Currency symbol - use from props if available, otherwise use composable
const { getSymbol } = useCurrency();
const currencySymbol = computed(() => props.currency?.symbol || getSymbol());

// Active tab
const activeTab = ref<
    'general' | 'images' | 'attributes' | 'inventory' | 'seo' | 'downloads'
>('general');

// Images for upload
const images = ref<File[]>([]);
const isUploading = ref(false);

// Attribute values - Initialize multiselect attributes as arrays
const attributeValues = ref<Record<string, any>>({});

// Selected attributes to display
const selectedAttributeIds = ref<number[]>([]);

// Initialize multiselect attributes when they are selected
const addAttribute = (attributeId: number) => {
    if (!selectedAttributeIds.value.includes(attributeId)) {
        selectedAttributeIds.value.push(attributeId);

        // Initialize multiselect as array
        const attribute = props.attributes.find(
            (attr) => attr.id === attributeId,
        );
        if (attribute && attribute.type === 'multiselect') {
            attributeValues.value[attribute.code] = [];
        }
    }
};

const removeAttribute = (attributeId: number) => {
    const index = selectedAttributeIds.value.indexOf(attributeId);
    if (index > -1) {
        selectedAttributeIds.value.splice(index, 1);

        // Remove value
        const attribute = props.attributes.find(
            (attr) => attr.id === attributeId,
        );
        if (attribute) {
            delete attributeValues.value[attribute.code];
        }
    }
};

const getSelectedAttributes = computed(() => {
    return props.attributes.filter((attr) =>
        selectedAttributeIds.value.includes(attr.id),
    );
});

const getAvailableAttributes = computed(() => {
    return props.attributes.filter(
        (attr) => !selectedAttributeIds.value.includes(attr.id),
    );
});

// Delete image modal
const showDeleteImageModal = ref(false);
const imageToDelete = ref<number | null>(null);
const isDeletingImage = ref(false);

// Upload images to backend
const uploadImages = async () => {
    if (images.value.length === 0) {
        alert('Please select images to upload');
        return;
    }

    isUploading.value = true;
    const formData = new FormData();

    images.value.forEach((image) => {
        formData.append('images[]', image);
    });

    try {
        const response = await axios.post(
            `/admin/catalog/products/${props.product.id}/images/upload`,
            formData,
            {
                headers: {
                    'Content-Type': 'multipart/form-data',
                },
            },
        );

        images.value = []; // Clear selected images

        // Reload the page to show new images
        router.reload({
            only: ['product'],
            preserveScroll: true,
        });
    } catch (error: any) {
        console.error('Upload error:', error);
        const message =
            error.response?.data?.message ||
            error.message ||
            'Failed to upload images';
        alert(`Upload failed: ${message}`);
    } finally {
        isUploading.value = false;
    }
};

// Delete an image
const openDeleteImageModal = (imageId: number) => {
    imageToDelete.value = imageId;
    showDeleteImageModal.value = true;
};

const deleteImage = async () => {
    if (!imageToDelete.value) return;

    isDeletingImage.value = true;

    try {
        await axios.delete(
            `/admin/catalog/products/${props.product.id}/images/${imageToDelete.value}`,
        );

        showDeleteImageModal.value = false;
        imageToDelete.value = null;

        // Reload the page to update images
        router.reload({
            only: ['product'],
            preserveScroll: true,
        });
    } catch (error: any) {
        console.error('Delete error:', error);
        const message =
            error.response?.data?.message || 'Failed to delete image';
        alert(message);
    } finally {
        isDeletingImage.value = false;
    }
};

// Set main image
const setMainImage = async (imageId: number) => {
    try {
        await axios.post(
            `/admin/catalog/products/${props.product.id}/images/${imageId}/set-main`,
        );

        // Reload the page to update main image
        router.reload({
            only: ['product'],
            preserveScroll: true,
        });
    } catch (error: any) {
        console.error('Set main image error:', error);
        const message =
            error.response?.data?.message || 'Failed to set main image';
        alert(message);
    }
};

// Delete modal
const showDeleteModal = ref(false);
const isDeleting = ref(false);

// Form data
const form = ref({
    name: props.product.name,
    slug: props.product.slug,
    sku: props.product.sku,
    description: props.product.description || '',
    short_description: props.product.short_description || '',
    price: props.product.price,
    tax_class_id: props.product.tax_class_id || null,
    special_price: props.product.special_price || '',
    special_price_from: props.product.special_price_from || '',
    special_price_to: props.product.special_price_to || '',
    cost: props.product.cost || '',
    quantity: props.product.quantity.toString(),
    weight: props.product.weight || '',
    status: props.product.status,
    visibility: props.product.visibility,
    featured: props.product.featured,
    new: props.product.new,
    stock_status: props.product.stock_status,
    manage_stock: props.product.manage_stock,
    type: props.product.type,
    brand_id: props.product.brand_id || null,
    category_ids: props.product.categories.map((cat) => cat.id),
    meta_title: props.product.meta_title || '',
    meta_description: props.product.meta_description || '',
    meta_keywords: props.product.meta_keywords || '',
});

// AI Description Generator
const aiTone = ref<'professional' | 'casual' | 'luxury' | 'minimalist'>(
    'professional',
);
const aiLanguage = ref('en');
const aiTargetAudience = ref('');
const aiKeyFeatures = ref('');
const aiIsGenerating = ref(false);
const aiResult = ref<any | null>(null);
const aiError = ref<string | null>(null);
const aiAgent = ref(
    props.ai?.product_description_agent || 'Product Description Agent',
);

const showPriceComparisonModal = ref(false);
const isComparingPrice = ref(false);
const priceComparisonError = ref<string | null>(null);
const priceComparisonResult = ref<PriceComparisonResponse | null>(null);
const selectedComparisonIndex = ref<number | null>(null);

// Generate slug from name
const generateSlug = () => {
    form.value.slug = form.value.name
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-+|-+$/g, '');
};

// Flatten categories for multi-select
const flatCategories = computed(() => {
    const flatten = (
        cats: Category[],
        prefix = '',
    ): Array<{ id: number; name: string }> => {
        return cats.reduce((acc: Array<{ id: number; name: string }>, cat) => {
            acc.push({ id: cat.id, name: prefix + cat.name });
            if (cat.children && cat.children.length > 0) {
                acc.push(...flatten(cat.children, prefix + cat.name + ' > '));
            }
            return acc;
        }, []);
    };
    return flatten(props.categories);
});

const selectedCategoryPath = computed(() => {
    const names = flatCategories.value
        .filter((cat) => form.value.category_ids.includes(cat.id))
        .map((cat) => cat.name);
    return names.join(' > ');
});

const parseNumericInput = (value: unknown): number => {
    if (typeof value === 'number') {
        return Number.isFinite(value) ? value : 0;
    }

    if (typeof value !== 'string') {
        return 0;
    }

    const trimmed = value.trim();
    if (!trimmed) {
        return 0;
    }

    const normalized = trimmed.replace(/,/g, '').replace(/[^0-9.-]/g, '');
    const parsed = Number(normalized);
    return Number.isFinite(parsed) ? parsed : 0;
};

const currentPriceNumber = computed(() => {
    return parseNumericInput(form.value.price);
});

const costNumber = computed(() => {
    return parseNumericInput(form.value.cost);
});

const selectedComparison = computed(() => {
    if (
        !priceComparisonResult.value ||
        selectedComparisonIndex.value === null
    ) {
        return null;
    }

    return (
        priceComparisonResult.value.options[selectedComparisonIndex.value] ||
        null
    );
});

const selectedPriceProfit = computed(() => {
    if (!selectedComparison.value || costNumber.value <= 0) {
        return null;
    }

    const unitProfit = selectedComparison.value.price - costNumber.value;
    const margin =
        selectedComparison.value.price > 0
            ? (unitProfit / selectedComparison.value.price) * 100
            : 0;

    return {
        unitProfit,
        margin,
    };
});

const selectedBrandName = computed(() => {
    return (
        props.brands.find((brand) => brand.id === form.value.brand_id)?.name ||
        ''
    );
});

const keyFeaturesList = computed(() => {
    return aiKeyFeatures.value
        .split(',')
        .map((item) => item.trim())
        .filter(Boolean);
});

const generateAiDescription = async () => {
    aiIsGenerating.value = true;
    aiError.value = null;
    try {
        const response = await axios.post(
            `/admin/catalog/products/${props.product.id}/generate-description`,
            {
                product_title: form.value.name,
                category: selectedCategoryPath.value || undefined,
                attributes: attributeValues.value,
                brand: selectedBrandName.value || undefined,
                key_features: keyFeaturesList.value,
                target_audience: aiTargetAudience.value || undefined,
                tone_preference: aiTone.value,
                language: aiLanguage.value,
                agent: aiAgent.value || undefined,
            },
        );

        if (response.data?.success) {
            aiResult.value = response.data.data?.data || response.data.data;
        } else {
            aiError.value = response.data?.message || 'AI generation failed.';
        }
    } catch (error: any) {
        aiError.value =
            error.response?.data?.message ||
            error.message ||
            'AI generation failed.';
    } finally {
        aiIsGenerating.value = false;
    }
};

const applyAiDescription = () => {
    if (!aiResult.value) {
        return;
    }

    if (aiResult.value.short_description) {
        form.value.short_description = aiResult.value.short_description;
    }

    if (aiResult.value.long_description) {
        form.value.description = aiResult.value.long_description;
    }

    if (aiResult.value.meta_description) {
        form.value.meta_description = aiResult.value.meta_description;
    }

    if (Array.isArray(aiResult.value.keywords)) {
        form.value.meta_keywords = aiResult.value.keywords.join(', ');
    }
};

const openPriceComparison = async () => {
    showPriceComparisonModal.value = true;
    isComparingPrice.value = true;
    priceComparisonError.value = null;
    priceComparisonResult.value = null;
    selectedComparisonIndex.value = null;

    if (!form.value.name.trim()) {
        isComparingPrice.value = false;
        priceComparisonError.value =
            'Enter product name before running price comparison.';
        return;
    }

    if (!selectedCategoryPath.value) {
        isComparingPrice.value = false;
        priceComparisonError.value =
            'Select at least one category before running price comparison.';
        return;
    }

    try {
        const response = await axios.post(
            '/admin/catalog/products/price-comparison',
            {
                product_name: form.value.name,
                category: selectedCategoryPath.value,
                current_price: currentPriceNumber.value || undefined,
                cost: costNumber.value || undefined,
            },
        );

        if (response.data?.success) {
            const result = response.data.data as PriceComparisonResponse;
            const options = Array.isArray(result?.options)
                ? result.options.slice(0, 4)
                : [];

            priceComparisonResult.value = {
                ...result,
                options,
            };

            if (options.length > 0) {
                selectedComparisonIndex.value = 0;
            }
        } else {
            priceComparisonError.value =
                response.data?.message ||
                'Failed to generate price comparison.';
        }
    } catch (error: any) {
        priceComparisonError.value =
            error.response?.data?.message ||
            error.message ||
            'Failed to generate price comparison.';
    } finally {
        isComparingPrice.value = false;
    }
};

const applySelectedComparisonPrice = () => {
    if (!selectedComparison.value) {
        return;
    }

    form.value.price = selectedComparison.value.price.toFixed(2);
    showPriceComparisonModal.value = false;
};

// Toggle category selection
const toggleCategory = (categoryId: number) => {
    const index = form.value.category_ids.indexOf(categoryId);
    if (index > -1) {
        form.value.category_ids.splice(index, 1);
    } else {
        form.value.category_ids.push(categoryId);
    }
};

// Initialize existing attribute values on component mount
onMounted(() => {
    // Load existing attribute values from the product
    if (
        props.product.attribute_values &&
        props.product.attribute_values.length > 0
    ) {
        // Group attribute values by attribute_id for multiselect handling
        const groupedByAttribute = props.product.attribute_values.reduce(
            (acc: any, attrValue: any) => {
                if (!acc[attrValue.attribute_id]) {
                    acc[attrValue.attribute_id] = [];
                }
                acc[attrValue.attribute_id].push(attrValue);
                return acc;
            },
            {},
        );

        // Process each attribute
        Object.keys(groupedByAttribute).forEach((attributeIdStr) => {
            const attributeId = Number(attributeIdStr);
            const attribute = props.attributes.find(
                (attr) => attr.id === attributeId,
            );

            if (attribute) {
                // Add attribute to selected list
                if (!selectedAttributeIds.value.includes(attribute.id)) {
                    selectedAttributeIds.value.push(attribute.id);
                }

                const attrValues = groupedByAttribute[attributeId];

                // Set the value based on attribute type
                if (
                    attribute.type === 'multiselect' ||
                    attribute.type === 'select'
                ) {
                    // For multiselect/select, collect all option values
                    const optionValues = attrValues
                        .filter((av: any) => av.attribute_option_id)
                        .map(
                            (av: any) =>
                                av.option?.value ||
                                String(av.attribute_option_id),
                        );

                    if (attribute.type === 'multiselect') {
                        attributeValues.value[attribute.code] = optionValues;
                    } else {
                        attributeValues.value[attribute.code] =
                            optionValues[0] || '';
                    }
                } else if (attribute.type === 'boolean') {
                    // Convert to boolean
                    const boolValue = attrValues[0]?.boolean_value;
                    attributeValues.value[attribute.code] =
                        boolValue === 1 ||
                        boolValue === '1' ||
                        boolValue === true;
                } else if (attribute.type === 'date') {
                    // Date value
                    attributeValues.value[attribute.code] =
                        attrValues[0]?.date_value || '';
                } else {
                    // For text/textarea types, use text_value
                    attributeValues.value[attribute.code] =
                        attrValues[0]?.text_value || '';
                }
            }
        });
    }
});

const submitForm = () => {
    const formData = {
        ...form.value,
        attribute_values: attributeValues.value,
    };

    router.put(productRoutes.update({ product: props.product.id }), formData);
};

// Handle stock adjustment (save immediately)
const handleStockAdjustment = (data: { quantity: number; adjustment: any }) => {
    // Update form quantity
    form.value.quantity = data.quantity.toString();

    // Save to backend using Inertia router (preserves all form fields)
    router.put(
        productRoutes.update({ product: props.product.id }).url,
        form.value,
        {
            preserveScroll: true,
            preserveState: true,
            onSuccess: () => {
                // Success toast will be shown via flash message from backend
            },
            onError: (errors) => {
                console.error('Failed to adjust stock:', errors);
                // Error details logged to console for debugging
            },
        },
    );
};

// Delete product
const deleteProduct = () => {
    isDeleting.value = true;
    router.delete(productRoutes.destroy({ product: props.product.id }), {
        onFinish: () => {
            isDeleting.value = false;
            showDeleteModal.value = false;
        },
    });
};
</script>

<template>
    <Head :title="$t('Edit Product')" />

    <AdminLayout :title="$t('Edit Product')">
        <div class="mx-auto max-w-7xl space-y-6 p-6">
            <!-- Header -->
            <div
                class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
            >
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Edit Product') }}
                    </h1>
                    <div
                        class="mt-1 flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400"
                    >
                        <Link
                            :href="productRoutes.index().url"
                            class="transition-colors hover:text-blue-600"
                            >{{ $t('Products') }}</Link
                        >
                        <span class="text-gray-300 dark:text-gray-600">/</span>
                        <span>{{ product.name }}</span>
                    </div>
                </div>

                <div class="flex items-center gap-3">
                    <Link
                        :href="productRoutes.index().url"
                        class="hidden rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 focus:outline-none sm:inline-flex dark:border-gray-600 dark:bg-gray-800 dark:text-gray-200 dark:hover:bg-gray-700"
                    >
                        {{ $t('Cancel') }}
                    </Link>
                    <button
                        type="button"
                        @click="showDeleteModal = true"
                        class="rounded-lg border border-red-300 bg-white px-4 py-2 text-sm font-medium text-red-700 transition-colors hover:bg-red-50 focus:ring-2 focus:ring-red-500 focus:ring-offset-2 focus:outline-none dark:border-red-700 dark:bg-gray-800 dark:text-red-400 dark:hover:bg-red-900/20"
                    >
                        {{ $t('Delete') }}
                    </button>
                    <button
                        type="button"
                        @click="submitForm"
                        class="rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none"
                    >
                        {{ $t('Update Product') }}
                    </button>
                </div>
            </div>

            <!-- Main Content -->
            <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
                <!-- Main Column (2/3) -->
                <div class="space-y-6 lg:col-span-2">
                    <!-- Tabs Navigation -->
                    <div class="border-b border-gray-200 dark:border-gray-700">
                        <nav
                            class="-mb-px flex space-x-8 overflow-x-auto"
                            :aria-label="$t('Tabs')"
                        >
                            <button
                                @click="activeTab = 'general'"
                                :class="[
                                    activeTab === 'general'
                                        ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                        : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                                    'border-b-2 px-1 py-4 text-sm font-medium whitespace-nowrap',
                                ]"
                            >
                                {{ $t('General') }}
                            </button>
                            <button
                                @click="activeTab = 'images'"
                                :class="[
                                    activeTab === 'images'
                                        ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                        : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                                    'border-b-2 px-1 py-4 text-sm font-medium whitespace-nowrap',
                                ]"
                            >
                                {{ $t('Images') }}
                            </button>
                            <button
                                @click="activeTab = 'attributes'"
                                :class="[
                                    activeTab === 'attributes'
                                        ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                        : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                                    'border-b-2 px-1 py-4 text-sm font-medium whitespace-nowrap',
                                ]"
                            >
                                {{ $t('Attributes') }}
                            </button>
                            <button
                                @click="activeTab = 'inventory'"
                                :class="[
                                    activeTab === 'inventory'
                                        ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                        : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                                    'border-b-2 px-1 py-4 text-sm font-medium whitespace-nowrap',
                                ]"
                            >
                                {{ $t('Inventory & Pricing') }}
                            </button>
                            <button
                                v-if="form.type === 'downloadable'"
                                @click="activeTab = 'downloads'"
                                :class="[
                                    activeTab === 'downloads'
                                        ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                        : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                                    'border-b-2 px-1 py-4 text-sm font-medium whitespace-nowrap',
                                ]"
                            >
                                {{ $t('Downloads') }}
                            </button>
                            <button
                                @click="activeTab = 'seo'"
                                :class="[
                                    activeTab === 'seo'
                                        ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                        : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                                    'border-b-2 px-1 py-4 text-sm font-medium whitespace-nowrap',
                                ]"
                            >
                                {{ $t('SEO') }}
                            </button>
                        </nav>
                    </div>

                    <!-- General Tab -->
                    <div
                        v-show="activeTab === 'general'"
                        class="space-y-6 rounded-lg border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <!-- Product Name -->
                        <div>
                            <label
                                for="name"
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Product Name') }}
                                <span class="text-red-500">*</span>
                            </label>
                            <input
                                id="name"
                                v-model="form.name"
                                @input="generateSlug"
                                type="text"
                                class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                :class="{ 'border-red-500': errors?.name }"
                                :placeholder="$t('Enter product name')"
                            />
                            <p
                                v-if="errors?.name"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors.name }}
                            </p>
                        </div>

                        <!-- Slug -->
                        <div>
                            <label
                                for="slug"
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Slug') }}
                                <span class="text-red-500">*</span>
                            </label>
                            <input
                                id="slug"
                                v-model="form.slug"
                                type="text"
                                class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                :class="{ 'border-red-500': errors?.slug }"
                                :placeholder="$t('auto-generated-from-name')"
                            />
                            <p
                                v-if="errors?.slug"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors.slug }}
                            </p>
                            <p
                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{ $t('Auto-generated from product name') }}
                            </p>
                        </div>

                        <!-- SKU -->
                        <div>
                            <label
                                for="sku"
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('SKU') }}
                                <span class="text-red-500">*</span>
                            </label>
                            <input
                                id="sku"
                                v-model="form.sku"
                                type="text"
                                class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                :class="{ 'border-red-500': errors?.sku }"
                                :placeholder="$t('Enter SKU')"
                            />
                            <p
                                v-if="errors?.sku"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors.sku }}
                            </p>
                        </div>

                        <!-- Product Type -->
                        <div>
                            <label
                                for="type"
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Product Type') }}
                                <span class="text-red-500">*</span>
                            </label>
                            <select
                                id="type"
                                v-model="form.type"
                                class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                :class="{ 'border-red-500': errors?.type }"
                            >
                                <option value="simple">
                                    {{ $t('Simple Product') }}
                                </option>
                                <option value="configurable">
                                    {{ $t('Configurable Product (Variants)') }}
                                </option>
                                <option value="virtual">
                                    {{ $t('Virtual Product (No Shipping)') }}
                                </option>
                                <option value="downloadable">
                                    {{ $t('Downloadable Product (Digital)') }}
                                </option>
                            </select>
                            <p
                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                            >
                                <span v-if="form.type === 'simple'">{{
                                    $t('Physical product with no variants')
                                }}</span>
                                <span
                                    v-else-if="form.type === 'configurable'"
                                    >{{
                                        $t(
                                            'Product with options like size, color, etc.',
                                        )
                                    }}</span
                                >
                                <span v-else-if="form.type === 'virtual'">{{
                                    $t(
                                        'Non-physical product (no shipping required)',
                                    )
                                }}</span>
                                <span
                                    v-else-if="form.type === 'downloadable'"
                                    >{{
                                        $t(
                                            'Digital file product with download links',
                                        )
                                    }}</span
                                >
                            </p>
                            <p
                                v-if="errors?.type"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors.type }}
                            </p>
                        </div>

                        <!-- Brand -->
                        <div>
                            <label
                                for="brand"
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Brand') }}</label
                            >
                            <select
                                id="brand"
                                v-model="form.brand_id"
                                class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            >
                                <option :value="null">
                                    {{ $t('Select Brand') }}
                                </option>
                                <option
                                    v-for="brand in brands"
                                    :key="brand.id"
                                    :value="brand.id"
                                >
                                    {{ brand.name }}
                                </option>
                            </select>
                            <p
                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{ $t('Associate this product with a brand') }}
                            </p>
                        </div>

                        <!-- AI Description Generator -->
                        <div
                            v-if="aiEnabled"
                            class="space-y-4 rounded-lg border border-gray-200 bg-gray-50 p-4 dark:border-gray-700 dark:bg-gray-800/50"
                        >
                            <div class="flex items-center justify-between">
                                <div>
                                    <h3
                                        class="text-sm font-semibold text-gray-900 dark:text-white"
                                    >
                                        {{ $t('AI Product Description') }}
                                    </h3>
                                    <p
                                        class="text-xs text-gray-500 dark:text-gray-400"
                                    >
                                        {{
                                            $t(
                                                'Generate SEO-optimized descriptions from product data.',
                                            )
                                        }}
                                    </p>
                                </div>
                                <button
                                    type="button"
                                    @click="generateAiDescription"
                                    :disabled="aiIsGenerating"
                                    class="inline-flex items-center justify-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50"
                                >
                                    {{
                                        $t(
                                            aiIsGenerating
                                                ? 'Generating...'
                                                : 'Generate Description',
                                        )
                                    }}
                                </button>
                            </div>

                            <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                                <div>
                                    <label
                                        class="mb-1 block text-xs font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Tone') }}</label
                                    >
                                    <select
                                        v-model="aiTone"
                                        class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                    >
                                        <option value="professional">
                                            {{ $t('Professional') }}
                                        </option>
                                        <option value="casual">
                                            {{ $t('Casual') }}
                                        </option>
                                        <option value="luxury">
                                            {{ $t('Luxury') }}
                                        </option>
                                        <option value="minimalist">
                                            {{ $t('Minimalist') }}
                                        </option>
                                    </select>
                                </div>
                                <div>
                                    <label
                                        class="mb-1 block text-xs font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Language') }}</label
                                    >
                                    <select
                                        v-model="aiLanguage"
                                        class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                    >
                                        <option value="en">
                                            {{ $t('English') }}
                                        </option>
                                        <option value="es">
                                            {{ $t('Spanish') }}
                                        </option>
                                        <option value="fr">
                                            {{ $t('French') }}
                                        </option>
                                        <option value="de">
                                            {{ $t('German') }}
                                        </option>
                                        <option value="zh">
                                            {{ $t('Chinese') }}
                                        </option>
                                    </select>
                                </div>
                                <div>
                                    <label
                                        class="mb-1 block text-xs font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('AI Agent') }}</label
                                    >
                                    <input
                                        :value="aiAgent"
                                        type="text"
                                        readonly
                                        class="w-full rounded-md border border-gray-300 bg-gray-100 px-3 py-2 text-sm text-gray-900 dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                                    />
                                </div>
                                <div>
                                    <label
                                        class="mb-1 block text-xs font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Target Audience') }}</label
                                    >
                                    <input
                                        v-model="aiTargetAudience"
                                        type="text"
                                        class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                        :placeholder="
                                            $t('e.g., gym enthusiasts')
                                        "
                                    />
                                </div>
                                <div>
                                    <label
                                        class="mb-1 block text-xs font-medium text-gray-700 dark:text-gray-300"
                                        >{{
                                            $t('Key Features (comma separated)')
                                        }}</label
                                    >
                                    <input
                                        v-model="aiKeyFeatures"
                                        type="text"
                                        class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                        :placeholder="
                                            $t(
                                                'Active noise cancellation, 30-hour battery',
                                            )
                                        "
                                    />
                                </div>
                            </div>

                            <p v-if="aiError" class="text-xs text-red-600">
                                {{ aiError }}
                            </p>

                            <div
                                v-if="aiResult"
                                class="space-y-3 border-t border-gray-200 pt-4 dark:border-gray-700"
                            >
                                <div>
                                    <label
                                        class="mb-1 block text-xs font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Short Description') }}</label
                                    >
                                    <p
                                        class="rounded-md border border-gray-200 bg-white p-3 text-sm text-gray-700 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300"
                                        v-text="aiResult.short_description"
                                    ></p>
                                </div>
                                <div>
                                    <label
                                        class="mb-1 block text-xs font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Long Description') }}</label
                                    >
                                    <p
                                        class="rounded-md border border-gray-200 bg-white p-3 text-sm whitespace-pre-line text-gray-700 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300"
                                        v-text="aiResult.long_description"
                                    ></p>
                                </div>
                                <div>
                                    <label
                                        class="mb-1 block text-xs font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Meta Description') }}</label
                                    >
                                    <p
                                        class="rounded-md border border-gray-200 bg-white p-3 text-sm text-gray-700 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300"
                                        v-text="aiResult.meta_description"
                                    ></p>
                                </div>
                                <div
                                    class="grid grid-cols-1 gap-4 md:grid-cols-2"
                                >
                                    <div>
                                        <label
                                            class="mb-1 block text-xs font-medium text-gray-700 dark:text-gray-300"
                                            >{{ $t('Bullet Points') }}</label
                                        >
                                        <ul
                                            class="list-disc rounded-md border border-gray-200 bg-white p-3 pl-5 text-sm text-gray-700 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300"
                                            v-if="
                                                Array.isArray(
                                                    aiResult.bullet_points,
                                                )
                                            "
                                        >
                                            <li
                                                v-for="(
                                                    item, idx
                                                ) in aiResult.bullet_points"
                                                :key="idx"
                                            >
                                                {{ item }}
                                            </li>
                                        </ul>
                                    </div>
                                    <div>
                                        <label
                                            class="mb-1 block text-xs font-medium text-gray-700 dark:text-gray-300"
                                            >{{ $t('Keywords') }}</label
                                        >
                                        <div
                                            class="rounded-md border border-gray-200 bg-white p-3 text-sm text-gray-700 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300"
                                        >
                                            {{
                                                Array.isArray(aiResult.keywords)
                                                    ? aiResult.keywords.join(
                                                          ', ',
                                                      )
                                                    : ''
                                            }}
                                        </div>
                                    </div>
                                </div>
                                <div class="flex justify-end">
                                    <button
                                        type="button"
                                        class="rounded-md border border-blue-200 px-3 py-2 text-xs font-medium text-blue-600 hover:bg-blue-50 dark:border-blue-700 dark:text-blue-400 dark:hover:bg-blue-900/20"
                                        @click="applyAiDescription"
                                    >
                                        {{ $t('Apply to Product Fields') }}
                                    </button>
                                </div>
                            </div>
                        </div>

                        <!-- Short Description -->
                        <div>
                            <label
                                for="short_description"
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Short Description') }}
                            </label>
                            <TiptapEditor
                                v-model="form.short_description"
                                :placeholder="$t('Brief product description')"
                            />
                        </div>

                        <!-- Description -->
                        <div>
                            <label
                                for="description"
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Description') }}
                            </label>
                            <TiptapEditor
                                v-model="form.description"
                                :placeholder="
                                    $t(
                                        'Detailed product description with formatting...',
                                    )
                                "
                            />
                        </div>
                    </div>

                    <!-- Images Tab -->
                    <div
                        v-show="activeTab === 'images'"
                        class="space-y-6 rounded-lg border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <!-- Existing Images -->
                        <div v-if="product.images && product.images.length > 0">
                            <h3
                                class="mb-3 text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Current Images') }}
                            </h3>
                            <div
                                class="mb-6 grid grid-cols-2 gap-4 md:grid-cols-3 lg:grid-cols-4"
                            >
                                <div
                                    v-for="image in product.images"
                                    :key="image.id"
                                    class="space-y-2"
                                >
                                    <!-- Image Container -->
                                    <div
                                        class="aspect-square overflow-hidden rounded-lg border-2 border-gray-200 bg-gray-100 dark:border-gray-600 dark:bg-gray-700"
                                        :class="{
                                            'border-blue-500':
                                                product.main_image_id ===
                                                image.id,
                                        }"
                                    >
                                        <div
                                            class="group relative h-full w-full"
                                        >
                                            <img
                                                :src="image.url"
                                                :alt="
                                                    image.alt_text ||
                                                    product.name
                                                "
                                                class="block h-full w-full object-cover"
                                            />

                                            <!-- Main Image Badge -->
                                            <div
                                                v-if="
                                                    product.main_image_id ===
                                                    image.id
                                                "
                                                class="absolute top-2 left-2 z-20 rounded bg-blue-500 px-2 py-1 text-xs text-white"
                                            >
                                                {{ $t('Main') }}
                                            </div>

                                            <!-- Actions Overlay -->
                                            <div
                                                class="absolute inset-0 flex items-center justify-center gap-2 bg-black/0 transition-all duration-200 group-hover:bg-black/50"
                                            >
                                                <button
                                                    v-if="
                                                        product.main_image_id !==
                                                        image.id
                                                    "
                                                    type="button"
                                                    @click="
                                                        setMainImage(image.id)
                                                    "
                                                    class="scale-90 transform cursor-pointer rounded-lg bg-blue-600 px-3 py-1.5 text-xs text-white opacity-0 transition-all duration-200 group-hover:scale-100 group-hover:opacity-100 hover:bg-blue-700"
                                                    :title="
                                                        $t('Set as main image')
                                                    "
                                                >
                                                    {{ $t('Set Main') }}
                                                </button>
                                                <button
                                                    type="button"
                                                    @click="
                                                        openDeleteImageModal(
                                                            image.id,
                                                        )
                                                    "
                                                    class="scale-90 transform cursor-pointer rounded-lg bg-red-600 px-3 py-1.5 text-xs text-white opacity-0 transition-all duration-200 group-hover:scale-100 group-hover:opacity-100 hover:bg-red-700"
                                                    :title="$t('Delete image')"
                                                >
                                                    {{ $t('Delete') }}
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Upload New Images -->
                        <div>
                            <h3
                                class="mb-3 text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Upload New Images') }}
                            </h3>
                            <ImageUploader
                                v-model="images"
                                :maxFiles="10"
                                :maxSize="5"
                                accept="image/*"
                            />
                            <button
                                @click="uploadImages"
                                :disabled="images.length === 0 || isUploading"
                                type="button"
                                class="mt-4 inline-flex items-center rounded-md border border-transparent bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50"
                            >
                                <svg
                                    v-if="isUploading"
                                    class="mr-2 -ml-1 h-4 w-4 animate-spin text-white"
                                    fill="none"
                                    viewBox="0 0 24 24"
                                >
                                    <circle
                                        class="opacity-25"
                                        cx="12"
                                        cy="12"
                                        r="10"
                                        stroke="currentColor"
                                        stroke-width="4"
                                    ></circle>
                                    <path
                                        class="opacity-75"
                                        fill="currentColor"
                                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                                    ></path>
                                </svg>
                                {{
                                    isUploading
                                        ? $t('Uploading...')
                                        : $t(
                                              images.length > 1
                                                  ? 'Upload {count} Images'
                                                  : 'Upload {count} Image',
                                              { count: images.length },
                                          )
                                }}
                            </button>
                        </div>
                    </div>

                    <!-- Inventory Tab -->
                    <div
                        v-show="activeTab === 'inventory'"
                        class="rounded-lg border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <InventoryTracker
                            :product-id="product.id"
                            :current-stock="product.quantity"
                            :min-quantity="1"
                            :notify-stock-qty="5"
                            :manage-stock="product.manage_stock"
                            :warehouses="[]"
                            :adjustment-history="adjustmentHistory || []"
                            @update:stock="handleStockAdjustment"
                        />

                        <!-- Pricing Section (moved from old inventory tab) -->
                        <div class="mt-6 space-y-6">
                            <div
                                class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between"
                            >
                                <h3
                                    class="text-lg font-semibold text-gray-900 dark:text-white"
                                >
                                    {{ $t('Pricing') }}
                                </h3>
                                <button
                                    type="button"
                                    @click="openPriceComparison"
                                    class="inline-flex items-center justify-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition-colors hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none"
                                >
                                    {{ $t('Price Comparison') }}
                                </button>
                            </div>

                            <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
                                <div>
                                    <label
                                        for="price"
                                        class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >
                                        {{ $t('Regular Price') }}
                                        <span class="text-red-500">*</span>
                                    </label>
                                    <div class="relative">
                                        <span
                                            class="absolute inset-y-0 left-0 flex items-center pl-3 text-gray-500 dark:text-gray-400"
                                            >{{ currencySymbol }}</span
                                        >
                                        <input
                                            id="price"
                                            v-model="form.price"
                                            type="number"
                                            step="0.01"
                                            class="w-full rounded-md border border-gray-300 bg-white py-2 pr-3 pl-7 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                            :class="{
                                                'border-red-500': errors?.price,
                                            }"
                                        />
                                    </div>
                                    <p
                                        v-if="errors?.price"
                                        class="mt-1 text-sm text-red-600"
                                    >
                                        {{ errors.price }}
                                    </p>
                                </div>

                                <div>
                                    <label
                                        for="cost"
                                        class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >
                                        {{ $t('Cost') }}
                                    </label>
                                    <div class="relative">
                                        <span
                                            class="absolute inset-y-0 left-0 flex items-center pl-3 text-gray-500 dark:text-gray-400"
                                            >{{ currencySymbol }}</span
                                        >
                                        <input
                                            id="cost"
                                            v-model="form.cost"
                                            type="number"
                                            step="0.01"
                                            class="w-full rounded-md border border-gray-300 bg-white py-2 pr-3 pl-7 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                        />
                                    </div>
                                </div>

                                <div>
                                    <label
                                        for="tax_class_id"
                                        class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >
                                        {{ $t('Tax Class') }}
                                    </label>
                                    <select
                                        id="tax_class_id"
                                        v-model="form.tax_class_id"
                                        class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                    >
                                        <option :value="null">
                                            {{ $t('No Tax') }}
                                        </option>
                                        <option
                                            v-for="taxClass in props.taxClasses"
                                            :key="taxClass.id"
                                            :value="taxClass.id"
                                        >
                                            {{ taxClass.name }}
                                        </option>
                                    </select>
                                    <p
                                        class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                                    >
                                        {{
                                            $t(
                                                'Select applicable tax class for this product',
                                            )
                                        }}
                                    </p>
                                </div>
                            </div>

                            <div
                                v-if="costNumber > 0 && currentPriceNumber > 0"
                                class="rounded-md border border-gray-200 bg-gray-50 p-4 dark:border-gray-700 dark:bg-gray-900/20"
                            >
                                <p
                                    class="text-sm text-gray-700 dark:text-gray-300"
                                >
                                    {{ $t('Current unit profit:') }}
                                    <span class="font-semibold"
                                        >{{ currencySymbol
                                        }}{{
                                            (
                                                currentPriceNumber - costNumber
                                            ).toFixed(2)
                                        }}</span
                                    >
                                    ({{
                                        (
                                            ((currentPriceNumber - costNumber) /
                                                currentPriceNumber) *
                                            100
                                        ).toFixed(2)
                                    }}{{ $t('% margin') }})
                                </p>
                            </div>

                            <!-- Special Pricing -->
                            <div
                                class="border-t border-gray-200 pt-6 dark:border-gray-700"
                            >
                                <h4
                                    class="mb-4 text-sm font-medium text-gray-900 dark:text-white"
                                >
                                    {{ $t('Special Pricing') }}
                                </h4>
                                <div
                                    class="grid grid-cols-1 gap-6 md:grid-cols-3"
                                >
                                    <div>
                                        <label
                                            for="special_price"
                                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >
                                            {{ $t('Special Price') }}
                                        </label>
                                        <div class="relative">
                                            <span
                                                class="absolute inset-y-0 left-0 flex items-center pl-3 text-gray-500 dark:text-gray-400"
                                                >{{ currencySymbol }}</span
                                            >
                                            <input
                                                id="special_price"
                                                v-model="form.special_price"
                                                type="number"
                                                step="0.01"
                                                class="w-full rounded-md border border-gray-300 bg-white py-2 pr-3 pl-7 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                            />
                                        </div>
                                    </div>

                                    <div>
                                        <label
                                            for="special_price_from"
                                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >
                                            {{ $t('From Date') }}
                                        </label>
                                        <DatePicker
                                            id="special_price_from"
                                            v-model="form.special_price_from"
                                            class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                        />
                                    </div>

                                    <div>
                                        <label
                                            for="special_price_to"
                                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >
                                            {{ $t('To Date') }}
                                        </label>
                                        <DatePicker
                                            id="special_price_to"
                                            v-model="form.special_price_to"
                                            class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                        />
                                    </div>
                                </div>
                            </div>

                            <!-- Weight - Only for physical products -->
                            <div
                                v-if="
                                    form.type === 'simple' ||
                                    form.type === 'configurable'
                                "
                                class="border-t border-gray-200 pt-6 dark:border-gray-700"
                            >
                                <h4
                                    class="mb-4 text-sm font-medium text-gray-900 dark:text-white"
                                >
                                    {{ $t('Physical Attributes') }}
                                </h4>
                                <div>
                                    <label
                                        for="weight"
                                        class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >
                                        {{ $t('Weight (kg)') }}
                                    </label>
                                    <input
                                        id="weight"
                                        v-model="form.weight"
                                        type="number"
                                        step="0.01"
                                        class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                    />
                                </div>
                            </div>

                            <!-- Digital Product Notice -->
                            <div
                                v-if="
                                    form.type === 'virtual' ||
                                    form.type === 'downloadable'
                                "
                                class="border-t border-gray-200 pt-6 dark:border-gray-700"
                            >
                                <div
                                    class="rounded-md border border-blue-200 bg-blue-50 p-4 dark:border-blue-800 dark:bg-blue-900/20"
                                >
                                    <div class="flex">
                                        <svg
                                            class="mt-0.5 mr-3 h-5 w-5 text-blue-400"
                                            fill="none"
                                            viewBox="0 0 24 24"
                                            stroke="currentColor"
                                        >
                                            <path
                                                stroke-linecap="round"
                                                stroke-linejoin="round"
                                                stroke-width="2"
                                                d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                                            />
                                        </svg>
                                        <div>
                                            <p
                                                class="text-sm font-medium text-blue-800 dark:text-blue-300"
                                            >
                                                {{
                                                    $t(
                                                        form.type === 'virtual'
                                                            ? 'Virtual Product'
                                                            : 'Downloadable Product',
                                                    )
                                                }}
                                            </p>
                                            <p
                                                class="mt-1 text-sm text-blue-700 dark:text-blue-400"
                                            >
                                                {{
                                                    $t(
                                                        form.type === 'virtual'
                                                            ? 'This product does not require shipping.'
                                                            : 'This product will be available for download after purchase.',
                                                    )
                                                }}
                                            </p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Downloadable Files Tab -->
                    <div
                        v-show="activeTab === 'downloads'"
                        v-if="form.type === 'downloadable'"
                        class="space-y-6 rounded-lg border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <div>
                            <h3
                                class="mb-4 text-lg font-medium text-gray-900 dark:text-white"
                            >
                                {{ $t('Downloadable Files') }}
                            </h3>

                            <div
                                class="rounded-lg border-2 border-dashed border-gray-300 p-8 text-center transition-colors hover:border-blue-400 dark:border-gray-600 dark:hover:border-blue-500"
                            >
                                <svg
                                    class="mx-auto h-12 w-12 text-gray-400 dark:text-gray-500"
                                    stroke="currentColor"
                                    fill="none"
                                    viewBox="0 0 48 48"
                                >
                                    <path
                                        d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02"
                                        stroke-width="2"
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                    />
                                </svg>
                                <p
                                    class="mt-4 text-sm text-gray-600 dark:text-gray-400"
                                >
                                    <label
                                        for="file-upload-edit"
                                        class="relative cursor-pointer rounded-md font-medium text-blue-600 hover:text-blue-500 dark:text-blue-400"
                                    >
                                        <span>{{ $t('Upload files') }}</span>
                                        <input
                                            id="file-upload-edit"
                                            name="file-upload"
                                            type="file"
                                            class="sr-only"
                                            multiple
                                        />
                                    </label>
                                    {{ $t('or drag and drop') }}
                                </p>
                                <p
                                    class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                                >
                                    {{ $t('Any file type up to 50MB') }}
                                </p>
                            </div>

                            <div
                                class="mt-6 rounded-md border border-yellow-200 bg-yellow-50 p-4 dark:border-yellow-700/50 dark:bg-yellow-900/20"
                            >
                                <div class="flex">
                                    <svg
                                        class="mt-0.5 mr-3 h-5 w-5 text-yellow-400"
                                        fill="none"
                                        viewBox="0 0 24 24"
                                        stroke="currentColor"
                                    >
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            stroke-width="2"
                                            d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                                        />
                                    </svg>
                                    <div>
                                        <p
                                            class="text-sm font-medium text-yellow-800 dark:text-yellow-300"
                                        >
                                            {{
                                                $t(
                                                    'File Management Coming Soon',
                                                )
                                            }}
                                        </p>
                                        <p
                                            class="mt-1 text-sm text-yellow-700 dark:text-yellow-400"
                                        >
                                            {{
                                                $t(
                                                    'Downloadable file upload and management will be available in the next update.',
                                                )
                                            }}
                                        </p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- SEO Tab -->
                    <div
                        v-show="activeTab === 'seo'"
                        class="space-y-6 rounded-lg border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <div>
                            <label
                                for="meta_title"
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Meta Title') }}
                            </label>
                            <input
                                id="meta_title"
                                v-model="form.meta_title"
                                type="text"
                                class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                :placeholder="
                                    $t('SEO title for search engines')
                                "
                            />
                            <p
                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{ $t('Recommended: 50-60 characters') }}
                            </p>
                        </div>

                        <div>
                            <label
                                for="meta_description"
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Meta Description') }}
                            </label>
                            <textarea
                                id="meta_description"
                                v-model="form.meta_description"
                                rows="3"
                                class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                :placeholder="
                                    $t('SEO description for search engines')
                                "
                            />
                            <p
                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{ $t('Recommended: 150-160 characters') }}
                            </p>
                        </div>

                        <div>
                            <label
                                for="meta_keywords"
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Meta Keywords') }}
                            </label>
                            <input
                                id="meta_keywords"
                                v-model="form.meta_keywords"
                                type="text"
                                class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                :placeholder="
                                    $t('keyword1, keyword2, keyword3')
                                "
                            />
                            <p
                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{ $t('Separate keywords with commas') }}
                            </p>
                        </div>
                    </div>

                    <!-- Attributes Tab -->
                    <div
                        v-show="activeTab === 'attributes'"
                        class="space-y-6 rounded-lg border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <div class="mb-6">
                            <h3
                                class="text-lg font-semibold text-gray-900 dark:text-white"
                            >
                                {{ $t('Product Attributes') }}
                            </h3>
                            <p
                                class="mt-1 text-sm text-gray-600 dark:text-gray-400"
                            >
                                {{
                                    $t(
                                        'Add and specify product characteristics and specifications',
                                    )
                                }}
                            </p>
                        </div>

                        <!-- Attribute Selector -->
                        <div class="mb-6">
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Add Attribute') }}
                            </label>
                            <select
                                @change="
                                    (e) => {
                                        addAttribute(
                                            Number(
                                                (e.target as HTMLSelectElement)
                                                    .value,
                                            ),
                                        );
                                        (e.target as HTMLSelectElement).value =
                                            '';
                                    }
                                "
                                class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            >
                                <option value="">
                                    {{ $t('Select an attribute to add...') }}
                                </option>
                                <option
                                    v-for="attribute in getAvailableAttributes"
                                    :key="attribute.id"
                                    :value="attribute.id"
                                >
                                    {{ attribute.name }}
                                    <template v-if="attribute.is_required">
                                        {{ $t('(Required)') }}</template
                                    >
                                </option>
                            </select>
                            <p
                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{
                                    $t(
                                        'Choose attributes that apply to this product',
                                    )
                                }}
                            </p>
                        </div>

                        <!-- No Attributes Selected State -->
                        <div
                            v-if="selectedAttributeIds.length === 0"
                            class="rounded-lg border-2 border-dashed border-gray-300 bg-gray-50 py-12 text-center dark:border-gray-600 dark:bg-gray-700/50"
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
                                    d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                                />
                            </svg>
                            <p
                                class="mt-2 text-sm font-medium text-gray-900 dark:text-white"
                            >
                                {{ $t('No attributes added yet') }}
                            </p>
                            <p class="text-xs text-gray-500 dark:text-gray-400">
                                {{
                                    $t(
                                        'Select attributes from the dropdown above to add product specifications',
                                    )
                                }}
                            </p>
                        </div>

                        <!-- Selected Attributes -->
                        <div v-else class="space-y-4">
                            <div
                                v-for="attribute in getSelectedAttributes"
                                :key="attribute.id"
                                class="rounded-lg border border-gray-200 bg-white p-4 transition-colors hover:border-blue-300 dark:border-gray-700 dark:bg-gray-800 dark:hover:border-blue-500"
                            >
                                <!-- Attribute Header -->
                                <div
                                    class="mb-3 flex items-start justify-between"
                                >
                                    <div>
                                        <label
                                            class="block text-sm font-medium text-gray-900 dark:text-white"
                                        >
                                            {{ attribute.name }}
                                            <span
                                                v-if="attribute.is_required"
                                                class="ml-1 text-red-500"
                                                >*</span
                                            >
                                        </label>
                                        <div
                                            class="mt-1 flex items-center gap-2"
                                        >
                                            <span
                                                v-if="attribute.is_configurable"
                                                class="inline-flex items-center rounded bg-purple-100 px-2 py-0.5 text-xs font-medium text-purple-800 dark:bg-purple-900 dark:text-purple-200"
                                            >
                                                {{ $t('Configurable') }}
                                            </span>
                                            <span
                                                v-if="attribute.is_filterable"
                                                class="inline-flex items-center rounded bg-blue-100 px-2 py-0.5 text-xs font-medium text-blue-800 dark:bg-blue-900 dark:text-blue-200"
                                            >
                                                {{ $t('Filterable') }}
                                            </span>
                                            <span
                                                class="text-xs text-gray-500 dark:text-gray-400"
                                                >{{ attribute.type }}</span
                                            >
                                        </div>
                                    </div>
                                    <button
                                        v-if="!attribute.is_required"
                                        type="button"
                                        @click="removeAttribute(attribute.id)"
                                        class="text-gray-400 transition-colors hover:text-red-600 dark:hover:text-red-400"
                                        :title="$t('Remove attribute')"
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
                                                d="M6 18L18 6M6 6l12 12"
                                            />
                                        </svg>
                                    </button>
                                </div>

                                <!-- Attribute Input Fields -->
                                <div class="mt-3">
                                    <!-- Text Input -->
                                    <input
                                        v-if="attribute.type === 'text'"
                                        v-model="
                                            attributeValues[attribute.code]
                                        "
                                        type="text"
                                        class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                        :placeholder="
                                            $t('Enter {attribute}', {
                                                attribute:
                                                    attribute.name.toLowerCase(),
                                            })
                                        "
                                    />

                                    <!-- Textarea -->
                                    <textarea
                                        v-if="attribute.type === 'textarea'"
                                        v-model="
                                            attributeValues[attribute.code]
                                        "
                                        rows="3"
                                        class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                        :placeholder="
                                            $t('Enter {attribute}', {
                                                attribute:
                                                    attribute.name.toLowerCase(),
                                            })
                                        "
                                    />

                                    <!-- Select -->
                                    <select
                                        v-if="attribute.type === 'select'"
                                        v-model="
                                            attributeValues[attribute.code]
                                        "
                                        class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                    >
                                        <option value="">
                                            {{ $t('Select') }}
                                            {{ attribute.name }}
                                        </option>
                                        <option
                                            v-for="option in attribute.options"
                                            :key="option.id"
                                            :value="option.value"
                                        >
                                            {{ option.label }}
                                        </option>
                                    </select>

                                    <!-- Multiselect with better UI -->
                                    <div
                                        v-if="attribute.type === 'multiselect'"
                                        class="grid grid-cols-2 gap-3 md:grid-cols-3"
                                    >
                                        <label
                                            v-for="option in attribute.options"
                                            :key="option.id"
                                            class="flex cursor-pointer items-center rounded-md border border-gray-200 p-3 transition-colors hover:bg-blue-50 dark:border-gray-700 dark:hover:bg-blue-900/20"
                                            :class="{
                                                'border-blue-300 bg-blue-50 dark:border-blue-600 dark:bg-blue-900/30':
                                                    attributeValues[
                                                        attribute.code
                                                    ]?.includes(option.value),
                                            }"
                                        >
                                            <input
                                                :id="`${attribute.code}-${option.id}`"
                                                type="checkbox"
                                                :value="option.value"
                                                v-model="
                                                    attributeValues[
                                                        attribute.code
                                                    ]
                                                "
                                                class="h-4 w-4 rounded border-gray-300 bg-white text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                            />
                                            <span
                                                class="ml-3 flex items-center text-sm text-gray-700 dark:text-gray-300"
                                            >
                                                <span
                                                    v-if="option.swatch_value"
                                                    class="mr-2 h-5 w-5 rounded-full border border-gray-300 dark:border-gray-600"
                                                    :style="{
                                                        backgroundColor:
                                                            option.swatch_value,
                                                    }"
                                                ></span>
                                                {{ option.label }}
                                            </span>
                                        </label>
                                    </div>

                                    <!-- Boolean -->
                                    <div
                                        v-if="attribute.type === 'boolean'"
                                        class="flex items-center rounded-md border border-gray-200 bg-gray-50 p-3 dark:border-gray-700 dark:bg-gray-700/50"
                                    >
                                        <input
                                            :id="attribute.code"
                                            type="checkbox"
                                            v-model="
                                                attributeValues[attribute.code]
                                            "
                                            class="h-4 w-4 rounded border-gray-300 bg-white text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                        />
                                        <label
                                            :for="attribute.code"
                                            class="ml-3 text-sm text-gray-700 dark:text-gray-300"
                                        >
                                            {{ $t('Enable') }}
                                            {{ attribute.name }}
                                        </label>
                                    </div>

                                    <!-- Date -->
                                    <DatePicker
                                        v-if="attribute.type === 'date'"
                                        v-model="
                                            attributeValues[attribute.code]
                                        "
                                        class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                    />

                                    <!-- Price -->
                                    <div
                                        v-if="attribute.type === 'price'"
                                        class="relative"
                                    >
                                        <span
                                            class="absolute top-1/2 left-3 -translate-y-1/2 text-gray-500 dark:text-gray-400"
                                            >{{ currencySymbol }}</span
                                        >
                                        <input
                                            v-model="
                                                attributeValues[attribute.code]
                                            "
                                            type="number"
                                            step="0.01"
                                            min="0"
                                            class="w-full rounded-md border border-gray-300 bg-white py-2 pr-3 pl-8 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                            :placeholder="
                                                $t('Enter {attribute}', {
                                                    attribute:
                                                        attribute.name.toLowerCase(),
                                                })
                                            "
                                        />
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Sidebar (1/3) -->
                <div class="space-y-6">
                    <!-- Publish Card -->
                    <div
                        class="rounded-lg border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <h3
                            class="mb-4 text-sm font-semibold text-gray-900 dark:text-white"
                        >
                            {{ $t('Publish') }}
                        </h3>

                        <!-- Status -->
                        <div class="mb-4">
                            <label
                                for="status"
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Status') }}
                            </label>
                            <select
                                id="status"
                                v-model="form.status"
                                class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            >
                                <option value="enabled">
                                    {{ $t('Enabled') }}
                                </option>
                                <option value="disabled">
                                    {{ $t('Disabled') }}
                                </option>
                            </select>
                        </div>

                        <!-- Visibility -->
                        <div class="mb-4">
                            <label
                                for="visibility"
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Visibility') }}
                            </label>
                            <select
                                id="visibility"
                                v-model="form.visibility"
                                class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-gray-900 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            >
                                <option value="both">
                                    {{ $t('Catalog & Search') }}
                                </option>
                                <option value="catalog">
                                    {{ $t('Catalog Only') }}
                                </option>
                                <option value="search">
                                    {{ $t('Search Only') }}
                                </option>
                                <option value="none">
                                    {{ $t('Not Visible') }}
                                </option>
                            </select>
                        </div>

                        <!-- Featured & New -->
                        <div class="mb-6 space-y-3">
                            <label class="flex items-center">
                                <input
                                    v-model="form.featured"
                                    type="checkbox"
                                    class="h-4 w-4 rounded border-gray-300 bg-white text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                />
                                <span
                                    class="ml-2 text-sm text-gray-700 dark:text-gray-300"
                                    >{{ $t('Featured Product') }}</span
                                >
                            </label>
                            <label class="flex items-center">
                                <input
                                    v-model="form.new"
                                    type="checkbox"
                                    class="h-4 w-4 rounded border-gray-300 bg-white text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                />
                                <span
                                    class="ml-2 text-sm text-gray-700 dark:text-gray-300"
                                    >{{ $t('Mark as New') }}</span
                                >
                            </label>
                        </div>

                        <!-- Action Buttons (Moved to Header) -->
                        <div class="hidden space-y-2"></div>
                    </div>

                    <!-- Categories Card -->
                    <div
                        class="rounded-lg border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                    >
                        <h3
                            class="mb-4 text-sm font-semibold text-gray-900 dark:text-white"
                        >
                            {{ $t('Categories') }}
                        </h3>
                        <div class="max-h-64 space-y-2 overflow-y-auto">
                            <label
                                v-for="category in flatCategories"
                                :key="category.id"
                                class="flex items-start"
                            >
                                <input
                                    type="checkbox"
                                    :value="category.id"
                                    :checked="
                                        form.category_ids.includes(category.id)
                                    "
                                    @change="toggleCategory(category.id)"
                                    class="mt-0.5 h-4 w-4 rounded border-gray-300 bg-white text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                />
                                <span
                                    class="ml-2 text-sm text-gray-700 dark:text-gray-300"
                                    >{{ category.name }}</span
                                >
                            </label>
                        </div>
                        <p
                            v-if="errors?.category_ids"
                            class="mt-2 text-sm text-red-600"
                        >
                            {{ errors.category_ids }}
                        </p>
                    </div>
                </div>
            </div>
        </div>

        <Teleport to="body">
            <Transition
                enter-active-class="transition duration-200 ease-out"
                enter-from-class="opacity-0"
                enter-to-class="opacity-100"
                leave-active-class="transition duration-200 ease-in"
                leave-from-class="opacity-100"
                leave-to-class="opacity-0"
            >
                <div
                    v-if="showPriceComparisonModal"
                    class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-gray-500/75 p-4 sm:items-center dark:bg-gray-900/75"
                    @click="showPriceComparisonModal = false"
                >
                    <div
                        class="relative w-full max-w-4xl rounded-lg bg-white shadow-xl dark:bg-gray-800"
                        @click.stop
                    >
                        <div
                            class="flex items-center justify-between border-b border-gray-200 px-6 py-4 dark:border-gray-700"
                        >
                            <div>
                                <h2
                                    class="text-lg font-semibold text-gray-900 dark:text-white"
                                >
                                    {{ $t('Price Comparison') }}
                                </h2>
                                <p
                                    class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                                >
                                    {{
                                        $t(
                                            'Select one of 4 market-based price variations to apply.',
                                        )
                                    }}
                                </p>
                            </div>
                            <button
                                type="button"
                                class="rounded-lg p-1 text-gray-400 hover:bg-gray-100 hover:text-gray-600 dark:hover:bg-gray-700 dark:hover:text-gray-300"
                                @click="showPriceComparisonModal = false"
                            >
                                ✕
                            </button>
                        </div>

                        <div class="max-h-[70vh] overflow-y-auto px-6 py-5">
                            <div
                                v-if="isComparingPrice"
                                class="py-10 text-center text-sm text-gray-500 dark:text-gray-400"
                            >
                                {{ $t('Generating price comparison...') }}
                            </div>

                            <div
                                v-else-if="priceComparisonError"
                                class="rounded-md border border-red-200 bg-red-50 p-4 text-sm text-red-700 dark:border-red-800 dark:bg-red-900/20 dark:text-red-300"
                            >
                                {{ priceComparisonError }}
                            </div>

                            <div
                                v-else-if="
                                    priceComparisonResult &&
                                    priceComparisonResult.options.length > 0
                                "
                                class="space-y-4"
                            >
                                <div
                                    class="overflow-x-auto rounded-lg border border-gray-200 dark:border-gray-700"
                                >
                                    <table
                                        class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                                    >
                                        <thead
                                            class="bg-gray-50 dark:bg-gray-900/20"
                                        >
                                            <tr>
                                                <th
                                                    class="px-4 py-3 text-left text-xs font-semibold tracking-wide text-gray-500 uppercase dark:text-gray-400"
                                                >
                                                    {{ $t('Select') }}
                                                </th>
                                                <th
                                                    class="px-4 py-3 text-left text-xs font-semibold tracking-wide text-gray-500 uppercase dark:text-gray-400"
                                                >
                                                    {{ $t('Variation') }}
                                                </th>
                                                <th
                                                    class="px-4 py-3 text-left text-xs font-semibold tracking-wide text-gray-500 uppercase dark:text-gray-400"
                                                >
                                                    {{ $t('Source') }}
                                                </th>
                                                <th
                                                    class="px-4 py-3 text-right text-xs font-semibold tracking-wide text-gray-500 uppercase dark:text-gray-400"
                                                >
                                                    {{ $t('Price') }}
                                                </th>
                                                <th
                                                    class="px-4 py-3 text-right text-xs font-semibold tracking-wide text-gray-500 uppercase dark:text-gray-400"
                                                >
                                                    {{
                                                        $t(
                                                            'Current - Suggested',
                                                        )
                                                    }}
                                                </th>
                                                <th
                                                    class="px-4 py-3 text-right text-xs font-semibold tracking-wide text-gray-500 uppercase dark:text-gray-400"
                                                >
                                                    {{
                                                        $t(
                                                            'Profit / Unit (Price - Cost)',
                                                        )
                                                    }}
                                                </th>
                                            </tr>
                                        </thead>
                                        <tbody
                                            class="divide-y divide-gray-200 dark:divide-gray-700"
                                        >
                                            <tr
                                                v-for="(
                                                    option, index
                                                ) in priceComparisonResult.options"
                                                :key="`${option.variation}-${index}`"
                                                class="hover:bg-gray-50 dark:hover:bg-gray-900/20"
                                            >
                                                <td class="px-4 py-3">
                                                    <input
                                                        type="radio"
                                                        name="price-comparison-option"
                                                        :checked="
                                                            selectedComparisonIndex ===
                                                            index
                                                        "
                                                        @change="
                                                            selectedComparisonIndex =
                                                                index
                                                        "
                                                        class="h-4 w-4 border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600"
                                                    />
                                                </td>
                                                <td
                                                    class="px-4 py-3 text-sm text-gray-900 capitalize dark:text-gray-100"
                                                >
                                                    {{ option.variation }}
                                                </td>
                                                <td
                                                    class="px-4 py-3 text-sm text-gray-700 dark:text-gray-300"
                                                >
                                                    <div class="font-medium">
                                                        {{
                                                            option.source_label
                                                        }}
                                                    </div>
                                                    <div
                                                        class="text-xs text-gray-500 dark:text-gray-400"
                                                    >
                                                        {{ option.details }}
                                                    </div>
                                                </td>
                                                <td
                                                    class="px-4 py-3 text-right text-sm font-semibold text-gray-900 dark:text-gray-100"
                                                >
                                                    {{ currencySymbol
                                                    }}{{
                                                        option.price.toFixed(2)
                                                    }}
                                                </td>
                                                <td
                                                    class="px-4 py-3 text-right text-sm"
                                                    :class="
                                                        currentPriceNumber -
                                                            option.price >=
                                                        0
                                                            ? 'text-green-600 dark:text-green-400'
                                                            : 'text-red-600 dark:text-red-400'
                                                    "
                                                >
                                                    {{
                                                        currentPriceNumber -
                                                            option.price >=
                                                        0
                                                            ? '+'
                                                            : ''
                                                    }}{{
                                                        (
                                                            currentPriceNumber -
                                                            option.price
                                                        ).toFixed(2)
                                                    }}
                                                </td>
                                                <td
                                                    class="px-4 py-3 text-right text-sm text-gray-900 dark:text-gray-100"
                                                >
                                                    <span v-if="costNumber > 0"
                                                        >{{ currencySymbol
                                                        }}{{
                                                            (
                                                                option.price -
                                                                costNumber
                                                            ).toFixed(2)
                                                        }}</span
                                                    >
                                                    <span
                                                        v-else
                                                        class="text-xs text-gray-400 dark:text-gray-500"
                                                        >{{
                                                            $t(
                                                                'Add cost to calculate',
                                                            )
                                                        }}</span
                                                    >
                                                </td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>

                                <div
                                    v-if="
                                        selectedComparison &&
                                        selectedPriceProfit
                                    "
                                    class="rounded-md border border-green-200 bg-green-50 p-4 text-sm text-green-800 dark:border-green-800 dark:bg-green-900/20 dark:text-green-300"
                                >
                                    {{ $t('Selected price profit overview:') }}
                                    <span class="ml-1 font-semibold"
                                        >{{ currencySymbol
                                        }}{{
                                            selectedPriceProfit.unitProfit.toFixed(
                                                2,
                                            )
                                        }}</span
                                    >
                                    {{ $t('per unit (')
                                    }}{{ selectedPriceProfit.margin.toFixed(2)
                                    }}{{ $t('% margin') }})
                                </div>
                                <div
                                    v-else-if="
                                        selectedComparison && costNumber <= 0
                                    "
                                    class="rounded-md border border-yellow-200 bg-yellow-50 p-4 text-sm text-yellow-800 dark:border-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-300"
                                >
                                    {{
                                        $t(
                                            'Profit / Unit = Selected Price - Product Cost. Enter cost in the Inventory & Pricing section to see margin overview.',
                                        )
                                    }}
                                </div>
                            </div>
                        </div>

                        <div
                            class="flex items-center justify-end gap-3 border-t border-gray-200 px-6 py-4 dark:border-gray-700"
                        >
                            <button
                                type="button"
                                class="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                                @click="showPriceComparisonModal = false"
                            >
                                {{ $t('Cancel') }}
                            </button>
                            <button
                                type="button"
                                class="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
                                :disabled="selectedComparisonIndex === null"
                                @click="applySelectedComparisonPrice"
                            >
                                {{ $t('Apply Selected Price') }}
                            </button>
                        </div>
                    </div>
                </div>
            </Transition>
        </Teleport>

        <!-- Delete Confirmation Modal -->
        <ConfirmDeleteModal
            v-model:show="showDeleteModal"
            :title="product.name"
            :message="
                $t(
                    'Are you sure you want to delete {name}? This action cannot be undone.',
                    { name: product.name },
                )
            "
            @confirm="deleteProduct"
        />

        <!-- Delete Image Modal -->
        <div
            v-if="showDeleteImageModal"
            class="relative z-50"
            aria-labelledby="modal-title"
            role="dialog"
            aria-modal="true"
        >
            <div
                class="fixed inset-0 bg-gray-500/75 transition-opacity dark:bg-gray-900/75"
            ></div>

            <div class="fixed inset-0 z-50 w-screen overflow-y-auto">
                <div
                    class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0"
                >
                    <div
                        class="relative transform overflow-hidden rounded-lg bg-white text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg dark:bg-gray-800"
                        @click.stop
                    >
                        <div
                            class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4 dark:bg-gray-800"
                        >
                            <div class="sm:flex sm:items-start">
                                <div
                                    class="mx-auto flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-red-100 sm:mx-0 sm:h-10 sm:w-10 dark:bg-red-900"
                                >
                                    <svg
                                        class="h-6 w-6 text-red-600 dark:text-red-400"
                                        fill="none"
                                        viewBox="0 0 24 24"
                                        stroke-width="1.5"
                                        stroke="currentColor"
                                    >
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z"
                                        />
                                    </svg>
                                </div>
                                <div
                                    class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left"
                                >
                                    <h3
                                        class="text-base leading-6 font-semibold text-gray-900 dark:text-white"
                                    >
                                        {{ $t('Delete Image') }}
                                    </h3>
                                    <div class="mt-2">
                                        <p
                                            class="text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            {{
                                                $t(
                                                    'Are you sure you want to delete this image? This action cannot be undone.',
                                                )
                                            }}
                                        </p>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div
                            class="bg-gray-50 px-4 py-3 sm:flex sm:flex-row-reverse sm:px-6 dark:bg-gray-700/50"
                        >
                            <button
                                @click="deleteImage"
                                :disabled="isDeletingImage"
                                type="button"
                                class="inline-flex w-full cursor-pointer justify-center rounded-md bg-red-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-500 disabled:cursor-not-allowed disabled:opacity-50 sm:ml-3 sm:w-auto"
                            >
                                <span v-if="isDeletingImage">{{
                                    $t('Deleting...')
                                }}</span>
                                <span v-else>{{ $t('Delete') }}</span>
                            </button>
                            <button
                                @click="showDeleteImageModal = false"
                                type="button"
                                class="mt-3 inline-flex w-full cursor-pointer justify-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-gray-300 ring-inset hover:bg-gray-50 sm:mt-0 sm:w-auto dark:bg-gray-700 dark:text-white dark:ring-gray-600 dark:hover:bg-gray-600"
                            >
                                {{ $t('Cancel') }}
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

<script setup lang="ts">
import { Head, router } from '@inertiajs/vue3';
import axios from 'axios';
import { ref } from 'vue';

interface BusinessType {
    id: string;
    name: string;
    description: string;
}

interface Props {
    businessType: string;
    businessTypes: BusinessType[];
}

const props = defineProps<Props>();

const importProducts = ref(true);
const importing = ref(false);
const importSuccess = ref(false);
const importError = ref('');
const stats = ref<any>({});

const selectedBusinessType = props.businessTypes.find(
    (t) => t.id === props.businessType,
);

const startImport = async () => {
    importing.value = true;
    importError.value = '';

    try {
        const response = await axios.post('/setup/import-demo-data', {
            business_type: props.businessType,
            import_products: importProducts.value,
        });

        if (response.data.success) {
            importSuccess.value = true;
            stats.value = response.data.stats;

            // Wait 2 seconds then continue to finish page
            setTimeout(() => {
                router.visit('/setup/finish');
            }, 2000);
        } else {
            importError.value = response.data.message;
            importing.value = false;
        }
    } catch (error: any) {
        importError.value =
            error.response?.data?.message || 'Failed to import demo data';
        importing.value = false;
    }
};

const skipImport = () => {
    router.visit('/setup/finish');
};

const goBack = () => {
    router.visit(`/setup/business-settings?type=${props.businessType}`);
};
</script>

<template>
    <Head title="Import Demo Data" />

    <div
        class="flex min-h-screen items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 p-4"
    >
        <div
            class="w-full max-w-3xl overflow-hidden rounded-2xl bg-white shadow-2xl"
        >
            <!-- Header -->
            <div
                class="bg-gradient-to-r from-blue-600 to-indigo-600 p-6 text-white"
            >
                <h1 class="text-center text-3xl font-bold">Import Demo Data</h1>
                <p class="mt-2 text-center text-blue-100">
                    Pre-load your store with sample data
                </p>
            </div>

            <!-- Progress Bar -->
            <div class="px-8 pt-6">
                <div class="mb-2 flex items-center justify-between">
                    <span class="text-sm font-medium text-gray-700"
                        >Step 3 of 4</span
                    >
                    <span class="text-sm font-medium text-gray-700">75%</span>
                </div>
                <div class="h-2 w-full rounded-full bg-gray-200">
                    <div
                        class="h-2 rounded-full bg-blue-600 transition-all duration-300"
                        style="width: 75%"
                    ></div>
                </div>
            </div>

            <!-- Content -->
            <div class="p-8">
                <!-- Selected Business Type -->
                <div
                    class="mb-6 rounded-lg border-2 border-blue-200 bg-blue-50 p-4"
                >
                    <div class="flex items-center">
                        <svg
                            class="mr-3 h-6 w-6 text-blue-600"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                            />
                        </svg>
                        <div>
                            <p class="text-sm text-gray-600">
                                Selected Business Type
                            </p>
                            <p class="font-bold text-gray-800">
                                {{ selectedBusinessType?.name }}
                            </p>
                        </div>
                    </div>
                </div>

                <!-- Import Options -->
                <div v-if="!importing && !importSuccess" class="space-y-6">
                    <div class="rounded-lg border-2 border-gray-200 p-6">
                        <label class="flex cursor-pointer items-start">
                            <input
                                type="checkbox"
                                v-model="importProducts"
                                class="mt-1 h-5 w-5 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                            />
                            <div class="ml-3">
                                <h3 class="mb-2 font-semibold text-gray-800">
                                    Import Sample Products
                                </h3>
                                <p class="text-sm text-gray-600">
                                    Import pre-configured products, categories,
                                    and brands relevant to your business type.
                                    This will help you see how your store looks
                                    with real data.
                                </p>
                                <div class="mt-3 text-sm text-gray-500">
                                    Includes:
                                    <ul class="mt-1 ml-2 list-inside list-disc">
                                        <li>Product categories</li>
                                        <li>
                                            Sample products with descriptions
                                        </li>
                                        <li>Brand information</li>
                                        <li>Sample pages and blocks</li>
                                    </ul>
                                </div>
                            </div>
                        </label>
                    </div>

                    <div
                        class="rounded-lg border border-yellow-200 bg-yellow-50 p-4"
                    >
                        <div class="flex">
                            <svg
                                class="mt-0.5 mr-3 h-5 w-5 flex-shrink-0 text-yellow-600"
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
                            <div class="text-sm">
                                <p class="mb-1 font-medium text-yellow-800">
                                    Note:
                                </p>
                                <p class="text-yellow-700">
                                    Demo data is for demonstration purposes
                                    only. You can delete or modify it later from
                                    the admin panel.
                                </p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Importing State -->
                <div
                    v-if="importing && !importSuccess"
                    class="py-8 text-center"
                >
                    <div
                        class="mb-4 inline-flex h-16 w-16 items-center justify-center rounded-full bg-blue-100"
                    >
                        <svg
                            class="h-8 w-8 animate-spin text-blue-600"
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
                    </div>
                    <h3 class="mb-2 text-xl font-semibold text-gray-800">
                        Importing Demo Data...
                    </h3>
                    <p class="text-gray-600">
                        This may take a few moments. Please don't close this
                        window.
                    </p>
                </div>

                <!-- Success State -->
                <div v-if="importSuccess" class="py-8 text-center">
                    <div
                        class="mb-4 inline-flex h-16 w-16 items-center justify-center rounded-full bg-green-100"
                    >
                        <svg
                            class="h-8 w-8 text-green-600"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M5 13l4 4L19 7"
                            />
                        </svg>
                    </div>
                    <h3 class="mb-2 text-xl font-semibold text-gray-800">
                        Import Successful!
                    </h3>
                    <p class="mb-4 text-gray-600">
                        Demo data has been imported successfully.
                    </p>

                    <div
                        v-if="stats"
                        class="inline-block rounded-lg bg-gray-50 p-4 text-left"
                    >
                        <p class="mb-2 text-sm text-gray-600">Imported:</p>
                        <ul class="space-y-1 text-sm">
                            <li v-if="stats.categories">
                                ✓ {{ stats.categories }} Categories
                            </li>
                            <li v-if="stats.products">
                                ✓ {{ stats.products }} Products
                            </li>
                            <li v-if="stats.brands">
                                ✓ {{ stats.brands }} Brands
                            </li>
                            <li v-if="stats.pages">
                                ✓ {{ stats.pages }} Pages
                            </li>
                            <li v-if="stats.blocks">
                                ✓ {{ stats.blocks }} Blocks
                            </li>
                        </ul>
                    </div>

                    <p class="mt-4 text-sm text-gray-500">
                        Redirecting to final step...
                    </p>
                </div>

                <!-- Error State -->
                <div
                    v-if="importError"
                    class="mb-4 rounded-lg border border-red-200 bg-red-50 p-4"
                >
                    <div class="flex">
                        <svg
                            class="mt-0.5 mr-3 h-5 w-5 flex-shrink-0 text-red-600"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                            />
                        </svg>
                        <div>
                            <p class="font-medium text-red-800">
                                Import Failed
                            </p>
                            <p class="mt-1 text-sm text-red-700">
                                {{ importError }}
                            </p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Footer Actions -->
            <div
                v-if="!importing && !importSuccess"
                class="flex items-center justify-between bg-gray-50 px-8 py-4"
            >
                <button
                    @click="goBack"
                    class="inline-flex items-center rounded-lg border border-gray-300 px-6 py-2 font-medium text-gray-700 transition-colors hover:bg-gray-100"
                >
                    <svg
                        class="mr-2 h-5 w-5"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M11 17l-5-5m0 0l5-5m-5 5h12"
                        />
                    </svg>
                    Back
                </button>
                <div class="flex space-x-3">
                    <button
                        @click="skipImport"
                        class="inline-flex items-center rounded-lg border border-gray-300 px-6 py-2 font-medium text-gray-700 transition-colors hover:bg-gray-100"
                    >
                        Skip for Now
                    </button>
                    <button
                        @click="startImport"
                        class="inline-flex transform items-center rounded-lg bg-gradient-to-r from-blue-600 to-indigo-600 px-6 py-2 font-medium text-white transition-all duration-200 hover:scale-105 hover:from-blue-700 hover:to-indigo-700"
                    >
                        <svg
                            class="mr-2 h-5 w-5"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
                            />
                        </svg>
                        Import Demo Data
                    </button>
                </div>
            </div>
        </div>
    </div>
</template>

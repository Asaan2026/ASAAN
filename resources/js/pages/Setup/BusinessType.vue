<script setup lang="ts">
import { Head, router } from '@inertiajs/vue3';
import { ref } from 'vue';

interface BusinessType {
    id: string;
    name: string;
    description: string;
}

interface Props {
    businessTypes: BusinessType[];
}

const props = defineProps<Props>();

const selectedType = ref<string>('');

const selectBusinessType = (typeId: string) => {
    selectedType.value = typeId;
};

const continueToNextStep = () => {
    if (selectedType.value) {
        router.visit(`/setup/business-settings?type=${selectedType.value}`);
    }
};

const goBack = () => {
    router.visit('/setup');
};
</script>

<template>
    <Head title="Select Business Type" />

    <div
        class="flex min-h-screen items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 p-4"
    >
        <div
            class="w-full max-w-4xl overflow-hidden rounded-2xl bg-white shadow-2xl"
        >
            <!-- Header -->
            <div
                class="bg-gradient-to-r from-blue-600 to-indigo-600 p-6 text-white"
            >
                <h1 class="text-center text-3xl font-bold">
                    Select Your Business Type
                </h1>
                <p class="mt-2 text-center text-blue-100">
                    Choose the type that best matches your store
                </p>
            </div>

            <!-- Progress Bar -->
            <div class="px-8 pt-6">
                <div class="mb-2 flex items-center justify-between">
                    <span class="text-sm font-medium text-gray-700"
                        >Step 1 of 3</span
                    >
                    <span class="text-sm font-medium text-gray-700">33%</span>
                </div>
                <div class="h-2 w-full rounded-full bg-gray-200">
                    <div
                        class="h-2 rounded-full bg-blue-600 transition-all duration-300"
                        style="width: 33%"
                    ></div>
                </div>
            </div>

            <!-- Content -->
            <div class="p-8">
                <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
                    <div
                        v-for="type in businessTypes"
                        :key="type.id"
                        @click="selectBusinessType(type.id)"
                        :class="[
                            'cursor-pointer rounded-lg border-2 p-6 transition-all duration-200 hover:shadow-lg',
                            selectedType === type.id
                                ? 'border-blue-600 bg-blue-50 ring-2 ring-blue-600'
                                : 'border-gray-200 hover:border-blue-300',
                        ]"
                    >
                        <div class="mb-3 flex items-start justify-between">
                            <h3 class="text-xl font-bold text-gray-800">
                                {{ type.name }}
                            </h3>
                            <div
                                :class="[
                                    'flex h-6 w-6 items-center justify-center rounded-full border-2',
                                    selectedType === type.id
                                        ? 'border-blue-600 bg-blue-600'
                                        : 'border-gray-300',
                                ]"
                            >
                                <svg
                                    v-if="selectedType === type.id"
                                    class="h-4 w-4 text-white"
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
                        </div>
                        <p class="text-gray-600">{{ type.description }}</p>
                    </div>
                </div>

                <div class="mt-8 text-center text-sm text-gray-600">
                    <p>💡 Don't worry, you can customize everything later!</p>
                </div>
            </div>

            <!-- Footer Actions -->
            <div class="flex items-center justify-between bg-gray-50 px-8 py-4">
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
                <button
                    @click="continueToNextStep"
                    :disabled="!selectedType"
                    :class="[
                        'inline-flex items-center rounded-lg px-6 py-2 font-medium transition-all duration-200',
                        selectedType
                            ? 'transform bg-gradient-to-r from-blue-600 to-indigo-600 text-white hover:scale-105 hover:from-blue-700 hover:to-indigo-700'
                            : 'cursor-not-allowed bg-gray-300 text-gray-500',
                    ]"
                >
                    Continue
                    <svg
                        class="ml-2 h-5 w-5"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M13 7l5 5m0 0l-5 5m5-5H6"
                        />
                    </svg>
                </button>
            </div>
        </div>
    </div>
</template>

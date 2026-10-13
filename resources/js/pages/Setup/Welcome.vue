<script setup lang="ts">
import { Head, router } from '@inertiajs/vue3';

interface Props {
    appName: string;
    appVersion: string;
}

const props = defineProps<Props>();

const startSetup = () => {
    router.visit('/setup/business-type');
};
</script>

<template>
    <Head title="Setup Wizard" />

    <div
        class="flex min-h-screen items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 p-4"
    >
        <div
            class="w-full max-w-2xl overflow-hidden rounded-2xl bg-white shadow-2xl"
        >
            <!-- Header -->
            <div
                class="bg-gradient-to-r from-blue-600 to-indigo-600 p-8 text-white"
            >
                <div class="mb-4 flex items-center justify-center">
                    <div
                        class="flex h-20 w-20 items-center justify-center rounded-full bg-white"
                    >
                        <img
                            src="/logos/akbari-devlopment-group.jpeg"
                            alt="Akbari Development Group logo"
                            class="h-12 w-12 object-contain"
                        />
                    </div>
                </div>
                <h1 class="mb-2 text-center text-4xl font-bold">
                    {{ appName }}
                </h1>
                <p class="text-center text-blue-100">
                    Version {{ appVersion }}
                </p>
            </div>

            <!-- Content -->
            <div class="p-8">
                <div class="mb-8 text-center">
                    <h2 class="mb-4 text-3xl font-bold text-gray-800">
                        Welcome to Setup Wizard
                    </h2>
                    <p class="text-lg text-gray-600">
                        Let's get your eCommerce store up and running in just a
                        few steps!
                    </p>
                </div>

                <!-- Features -->
                <div class="mb-8 grid grid-cols-1 gap-6 md:grid-cols-2">
                    <div class="flex items-start space-x-3">
                        <div class="flex-shrink-0">
                            <svg
                                class="h-6 w-6 text-green-500"
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
                        <div>
                            <h3 class="font-semibold text-gray-800">
                                Business Type Selection
                            </h3>
                            <p class="text-sm text-gray-600">
                                Choose from Retail, Kirana, Electronics, or
                                Fashion
                            </p>
                        </div>
                    </div>

                    <div class="flex items-start space-x-3">
                        <div class="flex-shrink-0">
                            <svg
                                class="h-6 w-6 text-green-500"
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
                        <div>
                            <h3 class="font-semibold text-gray-800">
                                Demo Data Import
                            </h3>
                            <p class="text-sm text-gray-600">
                                Pre-loaded products, categories, and content
                            </p>
                        </div>
                    </div>

                    <div class="flex items-start space-x-3">
                        <div class="flex-shrink-0">
                            <svg
                                class="h-6 w-6 text-green-500"
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
                        <div>
                            <h3 class="font-semibold text-gray-800">
                                Ready-to-Use Store
                            </h3>
                            <p class="text-sm text-gray-600">
                                Start selling immediately after setup
                            </p>
                        </div>
                    </div>

                    <div class="flex items-start space-x-3">
                        <div class="flex-shrink-0">
                            <svg
                                class="h-6 w-6 text-green-500"
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
                        <div>
                            <h3 class="font-semibold text-gray-800">
                                Quick Setup
                            </h3>
                            <p class="text-sm text-gray-600">
                                Complete setup in less than 5 minutes
                            </p>
                        </div>
                    </div>
                </div>

                <!-- Action Button -->
                <div class="text-center">
                    <button
                        @click="startSetup"
                        class="inline-flex transform items-center rounded-lg bg-gradient-to-r from-blue-600 to-indigo-600 px-8 py-4 font-semibold text-white shadow-lg transition-all duration-200 hover:scale-105 hover:from-blue-700 hover:to-indigo-700"
                    >
                        <span>Get Started</span>
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

            <!-- Footer -->
            <div class="bg-gray-50 px-8 py-4 text-center text-sm text-gray-600">
                <p>Open-source eCommerce platform built with ❤️</p>
            </div>
        </div>
    </div>
</template>

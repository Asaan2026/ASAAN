<template>
    <Head title="Business Settings" />

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
                <h1 class="text-center text-3xl font-bold">
                    Business Settings
                </h1>
                <p class="mt-2 text-center text-blue-100">
                    Configure your store's basic information
                </p>
            </div>

            <!-- Progress Bar -->
            <div class="px-8 pt-6">
                <div class="mb-2 flex items-center justify-between">
                    <span class="text-sm font-medium text-gray-700"
                        >Step 2 of 4</span
                    >
                    <span class="text-sm font-medium text-gray-700">50%</span>
                </div>
                <div class="h-2 w-full rounded-full bg-gray-200">
                    <div
                        class="h-2 rounded-full bg-blue-600 transition-all duration-300"
                        style="width: 50%"
                    ></div>
                </div>
            </div>

            <!-- Content -->
            <div class="p-8">
                <form @submit.prevent="submitSettings" class="space-y-6">
                    <!-- Store Name -->
                    <div>
                        <label
                            for="store_name"
                            class="mb-2 block text-sm font-medium text-gray-700"
                        >
                            Store Name <span class="text-red-500">*</span>
                        </label>
                        <input
                            id="store_name"
                            v-model="form.store_name"
                            type="text"
                            required
                            placeholder="e.g., My Awesome Store"
                            class="w-full rounded-lg border border-gray-300 px-4 py-2 text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500"
                            :class="{ 'border-red-500': errors.store_name }"
                        />
                        <p
                            v-if="errors.store_name"
                            class="mt-1 text-sm text-red-600"
                        >
                            {{ errors.store_name }}
                        </p>
                    </div>

                    <!-- Contact Phone -->
                    <div>
                        <label
                            for="contact_phone"
                            class="mb-2 block text-sm font-medium text-gray-700"
                        >
                            Contact Phone
                        </label>
                        <input
                            id="contact_phone"
                            v-model="form.contact_phone"
                            type="tel"
                            placeholder="+1 (555) 123-4567"
                            class="w-full rounded-lg border border-gray-300 px-4 py-2 text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500"
                        />
                    </div>

                    <!-- Store Address -->
                    <div>
                        <label
                            for="store_address"
                            class="mb-2 block text-sm font-medium text-gray-700"
                        >
                            Store Address
                        </label>
                        <textarea
                            id="store_address"
                            v-model="form.store_address"
                            rows="3"
                            placeholder="123 Main Street, City, State, ZIP"
                            class="w-full rounded-lg border border-gray-300 px-4 py-2 text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500"
                        ></textarea>
                    </div>

                    <!-- Store Country (fixed: the store country is decided by the store) -->
                    <div>
                        <label
                            for="store_country"
                            class="mb-2 block text-sm font-medium text-gray-700"
                        >
                            Store Country
                        </label>
                        <div
                            id="store_country"
                            class="w-full rounded-lg border border-gray-300 bg-gray-100 px-4 py-2 text-gray-600"
                        >
                            {{ storeCountry }}
                        </div>
                    </div>

                    <!-- Currency -->
                    <div>
                        <label
                            for="currency"
                            class="mb-2 block text-sm font-medium text-gray-700"
                        >
                            Currency <span class="text-red-500">*</span>
                        </label>
                        <select
                            id="currency"
                            v-model="form.currency"
                            required
                            class="w-full rounded-lg border border-gray-300 px-4 py-2 text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500"
                        >
                            <option
                                v-for="currency in props.currencies"
                                :key="currency.code"
                                :value="currency.code"
                            >
                                {{ currency.code }} — {{ currency.name }} ({{
                                    currency.symbol
                                }})
                            </option>
                        </select>
                    </div>

                    <!-- Timezone -->
                    <div>
                        <label
                            for="timezone"
                            class="mb-2 block text-sm font-medium text-gray-700"
                        >
                            Timezone <span class="text-red-500">*</span>
                        </label>
                        <select
                            id="timezone"
                            v-model="form.timezone"
                            required
                            class="w-full rounded-lg border border-gray-300 px-4 py-2 text-gray-900 focus:border-transparent focus:ring-2 focus:ring-blue-500"
                        >
                            <option value="UTC">UTC</option>
                            <option value="America/New_York">
                                America/New York (EST)
                            </option>
                            <option value="America/Chicago">
                                America/Chicago (CST)
                            </option>
                            <option value="America/Los_Angeles">
                                America/Los Angeles (PST)
                            </option>
                            <option value="Europe/London">
                                Europe/London (GMT)
                            </option>
                            <option value="Europe/Paris">
                                Europe/Paris (CET)
                            </option>
                            <option value="Asia/Kolkata">
                                Asia/Kolkata (IST)
                            </option>
                            <option value="Asia/Dubai">Asia/Dubai (GST)</option>
                            <option value="Asia/Tokyo">Asia/Tokyo (JST)</option>
                            <option value="Australia/Sydney">
                                Australia/Sydney (AEDT)
                            </option>
                        </select>
                    </div>
                </form>
            </div>

            <!-- Navigation Buttons -->
            <div class="mt-4 flex justify-between px-8 pb-8">
                <button
                    type="button"
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
                            d="M15 19l-7-7 7-7"
                        />
                    </svg>
                    Back
                </button>

                <button
                    type="button"
                    @click="submitSettings"
                    :disabled="!isValid || processing"
                    class="inline-flex items-center rounded-lg px-6 py-2 font-medium transition-all duration-200"
                    :class="
                        isValid && !processing
                            ? 'bg-gradient-to-r from-blue-600 to-indigo-600 text-white hover:shadow-lg'
                            : 'cursor-not-allowed bg-gray-300 text-gray-500'
                    "
                >
                    <span v-if="processing">Processing...</span>
                    <span v-else>Continue</span>
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
                            d="M9 5l7 7-7 7"
                        />
                    </svg>
                </button>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { Head, router } from '@inertiajs/vue3';
import axios from 'axios';
import { computed, ref } from 'vue';

const props = defineProps<{
    businessType?: string;
    currencies: { code: string; symbol: string; name: string }[];
}>();

const form = ref({
    store_name: '',
    contact_phone: '',
    store_address: '',
    // The store is priced in AFN. This used to prefer USD, which made the
    // wizard make the dollar the default currency -- and a default of USD means
    // every afghani price on the site is printed with a dollar sign.
    currency: props.currencies.find((c) => c.code === 'AFN')
        ? 'AFN'
        : (props.currencies[0]?.code ?? 'AFN'),
    timezone: 'UTC',
});

// Shown read-only: the country is decided by the store, not the wizard.
const storeCountry = ref('Afghanistan');

const errors = ref({});
const processing = ref(false);

const isValid = computed(() => {
    return form.value.store_name && form.value.currency && form.value.timezone;
});

const goBack = () => {
    router.visit('/setup/business-type');
};

const submitSettings = async () => {
    if (!isValid.value || processing.value) return;

    errors.value = {};
    processing.value = true;

    try {
        const response = await axios.post('/setup/save-business-settings', {
            ...form.value,
            business_type: props.businessType,
        });

        if (response.data.success) {
            router.visit(`/setup/demo-data?type=${props.businessType}`);
        } else {
            errors.value = { general: response.data.message };
            processing.value = false;
        }
    } catch (error) {
        console.error('Error saving settings:', error);
        errors.value = {
            general: error.response?.data?.message || 'Failed to save settings',
        };
        processing.value = false;
    }
};
</script>

<script setup lang="ts">
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, Link, router, usePage } from '@inertiajs/vue3';
import { computed, onMounted, ref } from 'vue';

interface Props {
    customer: any;
}

const props = defineProps<Props>();
const page = usePage();

const form = ref({
    type: 'shipping',
    first_name: '',
    last_name: '',
    company: '',
    address_line_1: '',
    address_line_2: '',
    city: '',
    state: '',
    postal_code: '',
    phone: '',
    is_default_shipping: false,
    is_default_billing: false,
});

const errors = computed(() => page.props.errors || {});
const processing = ref(false);

// Pre-fill customer data
onMounted(() => {
    if (props.customer) {
        form.value.first_name = props.customer.first_name || '';
        form.value.last_name = props.customer.last_name || '';
        form.value.phone = props.customer.phone || '';
    }
});

function submit() {
    processing.value = true;
    router.post(`/admin/customers/${props.customer.id}/addresses`, form.value, {
        onFinish: () => {
            processing.value = false;
        },
    });
}

function cancel() {
    router.visit(`/admin/customers/${props.customer.id}`);
}
</script>

<template>
    <AdminLayout :title="$t('New Address')">
        <Head :title="$t('New Address')" />

        <div class="p-6">
            <!-- Header -->
            <div class="mb-6">
                <div class="flex items-center justify-between">
                    <div>
                        <h1
                            class="text-2xl font-bold text-gray-900 dark:text-gray-100"
                        >
                            {{ $t('Add Address') }}
                        </h1>
                        <p
                            class="mt-1 text-sm text-gray-600 dark:text-gray-400"
                        >
                            {{ $t('Add a new address for') }}
                            {{ props.customer.first_name }}
                            {{ props.customer.last_name }}
                        </p>
                    </div>
                    <Link
                        :href="`/admin/customers/${props.customer.id}`"
                        class="inline-flex items-center rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                    >
                        <svg
                            class="mr-2 h-4 w-4"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M10 19l-7-7m0 0l7-7m-7 7h18"
                            />
                        </svg>
                        {{ $t('Back to Customer') }}
                    </Link>
                </div>
            </div>

            <form @submit.prevent="submit">
                <!-- Address Type -->
                <div
                    class="mb-6 rounded-lg border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-gray-100"
                    >
                        {{ $t('Address Type') }}
                    </h2>
                    <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Type *') }}</label
                            >
                            <select
                                v-model="form.type"
                                class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                :class="{ 'border-red-500': errors.type }"
                            >
                                <option value="shipping">
                                    {{ $t('Shipping Address') }}
                                </option>
                                <option value="billing">
                                    {{ $t('Billing Address') }}
                                </option>
                            </select>
                            <p
                                v-if="errors.type"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors.type }}
                            </p>
                        </div>
                    </div>
                </div>

                <!-- Contact Information -->
                <div
                    class="mb-6 rounded-lg border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-gray-100"
                    >
                        {{ $t('Contact Information') }}
                    </h2>
                    <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('First Name *') }}</label
                            >
                            <input
                                v-model="form.first_name"
                                type="text"
                                class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                :class="{ 'border-red-500': errors.first_name }"
                                :placeholder="$t('Enter first name')"
                            />
                            <p
                                v-if="errors.first_name"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors.first_name }}
                            </p>
                        </div>
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Last Name *') }}</label
                            >
                            <input
                                v-model="form.last_name"
                                type="text"
                                class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                :class="{ 'border-red-500': errors.last_name }"
                                :placeholder="$t('Enter last name')"
                            />
                            <p
                                v-if="errors.last_name"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors.last_name }}
                            </p>
                        </div>
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Company') }}</label
                            >
                            <input
                                v-model="form.company"
                                type="text"
                                class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                :class="{ 'border-red-500': errors.company }"
                                :placeholder="$t('Company name (optional)')"
                            />
                            <p
                                v-if="errors.company"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors.company }}
                            </p>
                        </div>
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Phone *') }}</label
                            >
                            <input
                                v-model="form.phone"
                                type="tel"
                                class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                :class="{ 'border-red-500': errors.phone }"
                                :placeholder="$t('Enter phone number')"
                            />
                            <p
                                v-if="errors.phone"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors.phone }}
                            </p>
                        </div>
                    </div>
                </div>

                <!-- Address Details -->
                <div
                    class="mb-6 rounded-lg border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-gray-100"
                    >
                        {{ $t('Address Details') }}
                    </h2>
                    <div class="grid grid-cols-1 gap-4">
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Address Line 1 *') }}</label
                            >
                            <input
                                v-model="form.address_line_1"
                                type="text"
                                class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                :class="{
                                    'border-red-500': errors.address_line_1,
                                }"
                                :placeholder="
                                    $t('Street address, P.O. box, company name')
                                "
                            />
                            <p
                                v-if="errors.address_line_1"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors.address_line_1 }}
                            </p>
                        </div>
                        <div>
                            <label
                                class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Address Line 2') }}</label
                            >
                            <input
                                v-model="form.address_line_2"
                                type="text"
                                class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                :class="{
                                    'border-red-500': errors.address_line_2,
                                }"
                                :placeholder="
                                    $t(
                                        'Apartment, suite, unit, building, floor, etc. (optional)',
                                    )
                                "
                            />
                            <p
                                v-if="errors.address_line_2"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors.address_line_2 }}
                            </p>
                        </div>
                        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('City *') }}</label
                                >
                                <input
                                    v-model="form.city"
                                    type="text"
                                    class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                    :class="{ 'border-red-500': errors.city }"
                                    :placeholder="$t('Enter city')"
                                />
                                <p
                                    v-if="errors.city"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ errors.city }}
                                </p>
                            </div>
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('State / Province *') }}</label
                                >
                                <input
                                    v-model="form.state"
                                    type="text"
                                    class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                    :class="{ 'border-red-500': errors.state }"
                                    :placeholder="$t('Enter state or province')"
                                />
                                <p
                                    v-if="errors.state"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ errors.state }}
                                </p>
                            </div>
                        </div>
                        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                            <div>
                                <label
                                    class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Postal Code *') }}</label
                                >
                                <input
                                    v-model="form.postal_code"
                                    type="text"
                                    class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                    :class="{
                                        'border-red-500': errors.postal_code,
                                    }"
                                    :placeholder="$t('Enter postal code')"
                                />
                                <p
                                    v-if="errors.postal_code"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ errors.postal_code }}
                                </p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Default Address Settings -->
                <div
                    class="mb-6 rounded-lg border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                >
                    <h2
                        class="mb-4 text-lg font-semibold text-gray-900 dark:text-gray-100"
                    >
                        {{ $t('Default Address Settings') }}
                    </h2>
                    <div class="space-y-3">
                        <div class="flex items-start">
                            <div class="flex h-5 items-center">
                                <input
                                    v-model="form.is_default_shipping"
                                    type="checkbox"
                                    class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                />
                            </div>
                            <div class="ml-3">
                                <label
                                    class="text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{
                                        $t('Set as default shipping address')
                                    }}</label
                                >
                                <p
                                    class="text-sm text-gray-500 dark:text-gray-400"
                                >
                                    {{
                                        $t(
                                            'Use this address as the default for shipping orders',
                                        )
                                    }}
                                </p>
                            </div>
                        </div>
                        <div class="flex items-start">
                            <div class="flex h-5 items-center">
                                <input
                                    v-model="form.is_default_billing"
                                    type="checkbox"
                                    class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                />
                            </div>
                            <div class="ml-3">
                                <label
                                    class="text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{
                                        $t('Set as default billing address')
                                    }}</label
                                >
                                <p
                                    class="text-sm text-gray-500 dark:text-gray-400"
                                >
                                    {{
                                        $t(
                                            'Use this address as the default for billing and invoices',
                                        )
                                    }}
                                </p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Action Buttons -->
                <div class="flex items-center justify-end gap-3">
                    <button
                        type="button"
                        @click="cancel"
                        class="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                        :disabled="processing"
                    >
                        {{ $t('Cancel') }}
                    </button>
                    <button
                        type="submit"
                        class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50"
                        :disabled="processing"
                    >
                        <svg
                            v-if="processing"
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
                        {{ $t(processing ? 'Saving...' : 'Save Address') }}
                    </button>
                </div>
            </form>
        </div>
    </AdminLayout>
</template>

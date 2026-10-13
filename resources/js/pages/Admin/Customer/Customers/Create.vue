<script setup lang="ts">
import DatePicker from '@/components/Calendar/DatePicker.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { today } from '@/lib/solar-hijri';
import { Head, router, useForm } from '@inertiajs/vue3';

interface CustomerGroup {
    id: number;
    name: string;
    color: string;
}

interface Props {
    customerGroups: CustomerGroup[];
}

const props = defineProps<Props>();

/** A birthday can be any day up to today, and no earlier than 1900. */
const maxDob = today().gregorian;

const form = useForm({
    first_name: '',
    last_name: '',
    email: '',
    phone: '',
    date_of_birth: '',
    gender: '',
    customer_group_id: null as number | null,
    company_name: '',
    tax_id: '',
    is_active: true,
    is_verified: false,
    newsletter_subscribed: false,
    notes: '',
});

const submit = () => {
    form.post('/admin/customers', {
        preserveScroll: true,
    });
};
</script>

<template>
    <Head :title="$t('Create Customer')" />

    <AdminLayout :title="$t('Create Customer')">
        <div class="p-6">
            <!-- Back Button -->
            <div class="mb-4">
                <button
                    type="button"
                    @click="router.visit('/admin/customers')"
                    class="inline-flex items-center rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
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
                    {{ $t('Back to Customers') }}
                </button>
            </div>

            <div class="rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800">
                <form @submit.prevent="submit" class="space-y-6">
                    <!-- Customer Information -->
                    <div>
                        <h2
                            class="mb-4 text-lg font-medium text-gray-900 dark:text-gray-100"
                        >
                            {{ $t('Customer Information') }}
                        </h2>
                        <div class="space-y-4">
                            <!-- Basic Information -->
                            <div class="grid grid-cols-2 gap-4">
                                <div>
                                    <label
                                        class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('First Name *') }}</label
                                    >
                                    <input
                                        v-model="form.first_name"
                                        type="text"
                                        required
                                        class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                        :class="{
                                            'border-red-500':
                                                form.errors.first_name,
                                        }"
                                        :placeholder="$t('Enter first name')"
                                    />
                                    <div
                                        v-if="form.errors.first_name"
                                        class="mt-1 text-sm text-red-600"
                                    >
                                        {{ form.errors.first_name }}
                                    </div>
                                </div>
                                <div>
                                    <label
                                        class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Last Name *') }}</label
                                    >
                                    <input
                                        v-model="form.last_name"
                                        type="text"
                                        required
                                        class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                        :class="{
                                            'border-red-500':
                                                form.errors.last_name,
                                        }"
                                        :placeholder="$t('Enter last name')"
                                    />
                                    <div
                                        v-if="form.errors.last_name"
                                        class="mt-1 text-sm text-red-600"
                                    >
                                        {{ form.errors.last_name }}
                                    </div>
                                </div>
                            </div>

                            <!-- Contact Information -->
                            <div class="grid grid-cols-2 gap-4">
                                <div>
                                    <label
                                        class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Email *') }}</label
                                    >
                                    <input
                                        v-model="form.email"
                                        type="email"
                                        required
                                        class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                        :class="{
                                            'border-red-500': form.errors.email,
                                        }"
                                        placeholder="customer@example.com"
                                    />
                                    <div
                                        v-if="form.errors.email"
                                        class="mt-1 text-sm text-red-600"
                                    >
                                        {{ form.errors.email }}
                                    </div>
                                </div>
                                <div>
                                    <label
                                        class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Phone') }}</label
                                    >
                                    <input
                                        v-model="form.phone"
                                        type="text"
                                        class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                        :class="{
                                            'border-red-500': form.errors.phone,
                                        }"
                                        placeholder="+1 (555) 000-0000"
                                    />
                                    <div
                                        v-if="form.errors.phone"
                                        class="mt-1 text-sm text-red-600"
                                    >
                                        {{ form.errors.phone }}
                                    </div>
                                </div>
                            </div>

                            <!-- Personal Information -->
                            <div class="grid grid-cols-3 gap-4">
                                <div>
                                    <label
                                        class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Date of Birth') }}</label
                                    >
                                    <DatePicker
                                        v-model="form.date_of_birth"
                                        min="1900-01-01"
                                        :max="maxDob"
                                        class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 dark:border-gray-600"
                                        :class="{
                                            'border-red-500':
                                                form.errors.date_of_birth,
                                        }"
                                    />
                                    <div
                                        v-if="form.errors.date_of_birth"
                                        class="mt-1 text-sm text-red-600"
                                    >
                                        {{ form.errors.date_of_birth }}
                                    </div>
                                </div>
                                <div>
                                    <label
                                        class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Gender') }}</label
                                    >
                                    <select
                                        v-model="form.gender"
                                        class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                        :class="{
                                            'border-red-500':
                                                form.errors.gender,
                                        }"
                                    >
                                        <option value="">
                                            {{ $t('Select Gender') }}
                                        </option>
                                        <option value="male">
                                            {{ $t('Male') }}
                                        </option>
                                        <option value="female">
                                            {{ $t('Female') }}
                                        </option>
                                        <option value="other">
                                            {{ $t('Other') }}
                                        </option>
                                    </select>
                                    <div
                                        v-if="form.errors.gender"
                                        class="mt-1 text-sm text-red-600"
                                    >
                                        {{ form.errors.gender }}
                                    </div>
                                </div>
                                <div>
                                    <label
                                        class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Customer Group *') }}</label
                                    >
                                    <select
                                        v-model="form.customer_group_id"
                                        required
                                        class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                        :class="{
                                            'border-red-500':
                                                form.errors.customer_group_id,
                                        }"
                                    >
                                        <option value="">
                                            {{ $t('Select Group') }}
                                        </option>
                                        <option
                                            v-for="group in customerGroups"
                                            :key="group.id"
                                            :value="group.id"
                                        >
                                            {{ group.name }}
                                        </option>
                                    </select>
                                    <div
                                        v-if="form.errors.customer_group_id"
                                        class="mt-1 text-sm text-red-600"
                                    >
                                        {{ form.errors.customer_group_id }}
                                    </div>
                                </div>
                            </div>

                            <!-- Company Information -->
                            <div class="grid grid-cols-2 gap-4">
                                <div>
                                    <label
                                        class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Company Name') }}</label
                                    >
                                    <input
                                        v-model="form.company_name"
                                        type="text"
                                        class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                        :class="{
                                            'border-red-500':
                                                form.errors.company_name,
                                        }"
                                        :placeholder="$t('Enter company name')"
                                    />
                                    <div
                                        v-if="form.errors.company_name"
                                        class="mt-1 text-sm text-red-600"
                                    >
                                        {{ form.errors.company_name }}
                                    </div>
                                </div>
                                <div>
                                    <label
                                        class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Tax ID') }}</label
                                    >
                                    <input
                                        v-model="form.tax_id"
                                        type="text"
                                        class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                        :class="{
                                            'border-red-500':
                                                form.errors.tax_id,
                                        }"
                                        :placeholder="$t('Enter tax ID')"
                                    />
                                    <div
                                        v-if="form.errors.tax_id"
                                        class="mt-1 text-sm text-red-600"
                                    >
                                        {{ form.errors.tax_id }}
                                    </div>
                                </div>
                            </div>

                            <!-- Status Toggles -->
                            <div class="grid grid-cols-3 gap-4">
                                <div class="flex items-center">
                                    <input
                                        v-model="form.is_active"
                                        type="checkbox"
                                        id="is_active"
                                        class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                    />
                                    <label
                                        for="is_active"
                                        class="ml-2 text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Active') }}</label
                                    >
                                </div>
                                <div class="flex items-center">
                                    <input
                                        v-model="form.is_verified"
                                        type="checkbox"
                                        id="is_verified"
                                        class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                    />
                                    <label
                                        for="is_verified"
                                        class="ml-2 text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Verified') }}</label
                                    >
                                </div>
                                <div class="flex items-center">
                                    <input
                                        v-model="form.newsletter_subscribed"
                                        type="checkbox"
                                        id="newsletter"
                                        class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                    />
                                    <label
                                        for="newsletter"
                                        class="ml-2 text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Newsletter') }}</label
                                    >
                                </div>
                            </div>

                            <!-- Notes -->
                            <div>
                                <label
                                    class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Notes') }}</label
                                >
                                <textarea
                                    v-model="form.notes"
                                    class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                    :class="{
                                        'border-red-500': form.errors.notes,
                                    }"
                                    rows="4"
                                    :placeholder="
                                        $t('Add any additional notes')
                                    "
                                ></textarea>
                                <div
                                    v-if="form.errors.notes"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ form.errors.notes }}
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Form Actions -->
                    <div
                        class="flex items-center justify-end gap-3 border-t border-gray-200 pt-6 dark:border-gray-700"
                    >
                        <button
                            type="button"
                            @click="router.visit('/admin/customers')"
                            class="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                        >
                            {{ $t('Cancel') }}
                        </button>
                        <button
                            type="submit"
                            :disabled="form.processing"
                            class="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
                        >
                            <span v-if="form.processing">{{
                                $t('Creating...')
                            }}</span>
                            <span v-else>{{ $t('Create Customer') }}</span>
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </AdminLayout>
</template>

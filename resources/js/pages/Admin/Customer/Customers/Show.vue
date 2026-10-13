<script setup lang="ts">
import ConfirmDeleteModal from '@/components/Admin/ConfirmDeleteModal.vue';
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import { useCurrency } from '@/composables/useCurrency';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, Link, router } from '@inertiajs/vue3';
import { ref } from 'vue';

interface CustomerGroup {
    id: number;
    name: string;
    color: string;
}

interface CustomerAddress {
    id: number;
    type: string;
    first_name: string;
    last_name: string;
    company: string | null;
    address_line_1: string;
    address_line_2: string | null;
    city: string;
    state: string;
    postal_code: string;
    country: string;
    phone: string | null;
    is_default_shipping: boolean;
    is_default_billing: boolean;
    formatted_address: string;
}

interface CustomerNote {
    id: number;
    note: string;
    created_at: string;
    user: {
        name: string;
    };
}

interface Customer {
    id: number;
    first_name: string;
    last_name: string;
    full_name: string;
    email: string;
    phone: string | null;
    date_of_birth: string | null;
    gender: string | null;
    customer_group_id: number;
    company_name: string | null;
    tax_id: string | null;
    is_active: boolean;
    is_verified: boolean;
    is_guest: boolean;
    newsletter_subscribed: boolean;
    total_orders: number;
    total_spent: number;
    notes: string | null;
    created_at: string;
    updated_at: string;
    customer_group: CustomerGroup;
    addresses: CustomerAddress[];
    customer_notes: CustomerNote[];
}

interface Props {
    customer: Customer;
}

const props = defineProps<Props>();

const activeTab = ref('info');
const showDeleteModal = ref(false);

const { formatPrice } = useCurrency();

const deleteCustomer = () => {
    router.delete(`/admin/customers/${props.customer.id}`, {
        onSuccess: () => {
            // Redirect handled by controller
        },
    });
};

const formatCurrency = (amount: number) => {
    return formatPrice(amount);
};
</script>

<template>
    <Head :title="$t('Customer: {name}', { name: customer.full_name })" />

    <AdminLayout :title="customer.full_name">
        <div class="p-6">
            <!-- Header -->
            <div class="mb-6">
                <div class="mb-4 flex items-center justify-between">
                    <div>
                        <div class="flex items-center gap-3">
                            <h1
                                class="text-2xl font-semibold text-gray-900 dark:text-gray-100"
                            >
                                {{ customer.full_name }}
                            </h1>
                            <span
                                :class="[
                                    'rounded-full px-2.5 py-0.5 text-xs font-medium',
                                    customer.is_active
                                        ? 'bg-green-100 text-green-800 dark:bg-green-900/40 dark:text-green-300'
                                        : 'bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-300',
                                ]"
                            >
                                {{
                                    customer.is_active
                                        ? $t('Active')
                                        : $t('Inactive')
                                }}
                            </span>
                            <span
                                v-if="customer.is_guest"
                                class="rounded-full bg-purple-100 px-2.5 py-0.5 text-xs font-medium text-purple-800 dark:bg-purple-900/40 dark:text-purple-300"
                            >
                                {{ $t('Guest') }}
                            </span>
                            <span
                                v-if="customer.is_verified"
                                class="rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-800 dark:bg-blue-900/40 dark:text-blue-300"
                            >
                                {{ $t('Verified') }}
                            </span>
                        </div>
                        <p
                            class="mt-1 text-sm text-gray-600 dark:text-gray-400"
                        >
                            {{ $t('Customer ID: #{id}', { id: customer.id }) }}
                        </p>
                    </div>
                    <div class="flex items-center gap-2">
                        <button
                            type="button"
                            @click="router.visit('/admin/customers')"
                            class="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                        >
                            {{ $t('Back to List') }}
                        </button>
                        <a
                            :href="`/admin/customers/${customer.id}/edit`"
                            class="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
                        >
                            {{ $t('Edit Customer') }}
                        </a>
                        <button
                            @click="showDeleteModal = true"
                            class="rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700"
                        >
                            {{ $t('Delete') }}
                        </button>
                    </div>
                </div>

                <!-- Statistics Cards -->
                <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
                    <div
                        class="rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800"
                    >
                        <div
                            class="text-sm font-medium text-gray-600 dark:text-gray-400"
                        >
                            {{ $t('Total Orders') }}
                        </div>
                        <div
                            class="mt-2 text-3xl font-semibold text-gray-900 dark:text-gray-100"
                        >
                            {{ customer.total_orders }}
                        </div>
                    </div>
                    <div
                        class="rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800"
                    >
                        <div
                            class="text-sm font-medium text-gray-600 dark:text-gray-400"
                        >
                            {{ $t('Total Spent') }}
                        </div>
                        <div
                            class="mt-2 text-3xl font-semibold text-gray-900 dark:text-gray-100"
                        >
                            {{ formatCurrency(customer.total_spent) }}
                        </div>
                    </div>
                    <div
                        class="rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800"
                    >
                        <div
                            class="text-sm font-medium text-gray-600 dark:text-gray-400"
                        >
                            {{ $t('Customer Group') }}
                        </div>
                        <div class="mt-2">
                            <span
                                v-if="
                                    customer.customer_group &&
                                    customer.customer_group.id
                                "
                                class="inline-flex items-center rounded-full px-3 py-1 text-sm font-medium"
                                :style="{
                                    backgroundColor:
                                        customer.customer_group.color + '20',
                                    color: customer.customer_group.color,
                                }"
                            >
                                {{ customer.customer_group.name }}
                            </span>
                            <span
                                v-else
                                class="inline-flex items-center rounded-full bg-gray-100 px-3 py-1 text-sm font-medium text-gray-600 dark:bg-gray-700 dark:text-gray-400"
                            >
                                {{ $t('No Group') }}
                            </span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Tabs -->
            <div class="rounded-lg bg-white shadow-sm dark:bg-gray-800">
                <div class="border-b border-gray-200 dark:border-gray-700">
                    <nav class="flex gap-6 px-6" :aria-label="$t('Tabs')">
                        <button
                            @click="activeTab = 'info'"
                            :class="[
                                'border-b-2 px-1 py-4 text-sm font-medium transition-colors',
                                activeTab === 'info'
                                    ? 'border-blue-500 text-blue-600'
                                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                            ]"
                        >
                            {{ $t('Customer Information') }}
                        </button>
                        <button
                            @click="activeTab = 'addresses'"
                            :class="[
                                'border-b-2 px-1 py-4 text-sm font-medium transition-colors',
                                activeTab === 'addresses'
                                    ? 'border-blue-500 text-blue-600'
                                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                            ]"
                        >
                            {{
                                $t('Addresses ({count})', {
                                    count: customer.addresses?.length || 0,
                                })
                            }}
                        </button>
                        <button
                            @click="activeTab = 'notes'"
                            :class="[
                                'border-b-2 px-1 py-4 text-sm font-medium transition-colors',
                                activeTab === 'notes'
                                    ? 'border-blue-500 text-blue-600'
                                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                            ]"
                        >
                            {{
                                $t('Notes ({count})', {
                                    count: customer.customer_notes?.length || 0,
                                })
                            }}
                        </button>
                    </nav>
                </div>

                <div class="p-6">
                    <!-- Customer Information Tab -->
                    <div v-if="activeTab === 'info'">
                        <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
                            <!-- Contact Information -->
                            <div class="space-y-4">
                                <h3
                                    class="mb-4 text-lg font-medium text-gray-900 dark:text-gray-100"
                                >
                                    {{ $t('Contact Information') }}
                                </h3>
                                <div>
                                    <dt
                                        class="text-sm font-medium text-gray-500 dark:text-gray-400"
                                    >
                                        {{ $t('Email') }}
                                    </dt>
                                    <dd
                                        class="mt-1 text-sm text-gray-900 dark:text-gray-100"
                                    >
                                        {{ customer.email }}
                                    </dd>
                                </div>
                                <div v-if="customer.phone">
                                    <dt
                                        class="text-sm font-medium text-gray-500 dark:text-gray-400"
                                    >
                                        {{ $t('Phone') }}
                                    </dt>
                                    <dd
                                        class="mt-1 text-sm text-gray-900 dark:text-gray-100"
                                    >
                                        {{ customer.phone }}
                                    </dd>
                                </div>
                                <div v-if="customer.company_name">
                                    <dt
                                        class="text-sm font-medium text-gray-500 dark:text-gray-400"
                                    >
                                        {{ $t('Company') }}
                                    </dt>
                                    <dd
                                        class="mt-1 text-sm text-gray-900 dark:text-gray-100"
                                    >
                                        {{ customer.company_name }}
                                    </dd>
                                </div>
                                <div v-if="customer.tax_id">
                                    <dt
                                        class="text-sm font-medium text-gray-500 dark:text-gray-400"
                                    >
                                        {{ $t('Tax ID') }}
                                    </dt>
                                    <dd
                                        class="mt-1 text-sm text-gray-900 dark:text-gray-100"
                                    >
                                        {{ customer.tax_id }}
                                    </dd>
                                </div>
                            </div>

                            <!-- Personal Information -->
                            <div class="space-y-4">
                                <h3
                                    class="mb-4 text-lg font-medium text-gray-900 dark:text-gray-100"
                                >
                                    {{ $t('Personal Information') }}
                                </h3>
                                <div v-if="customer.date_of_birth">
                                    <dt
                                        class="text-sm font-medium text-gray-500 dark:text-gray-400"
                                    >
                                        {{ $t('Date of Birth') }}
                                    </dt>
                                    <dd
                                        class="mt-1 text-sm text-gray-900 dark:text-gray-100"
                                    >
                                        <DateDisplay
                                            :value="customer.date_of_birth"
                                        />
                                    </dd>
                                </div>
                                <div v-if="customer.gender">
                                    <dt
                                        class="text-sm font-medium text-gray-500 dark:text-gray-400"
                                    >
                                        {{ $t('Gender') }}
                                    </dt>
                                    <dd
                                        class="mt-1 text-sm text-gray-900 capitalize dark:text-gray-100"
                                    >
                                        {{ customer.gender }}
                                    </dd>
                                </div>
                                <div>
                                    <dt
                                        class="text-sm font-medium text-gray-500 dark:text-gray-400"
                                    >
                                        {{ $t('Newsletter') }}
                                    </dt>
                                    <dd class="mt-1 text-sm">
                                        <span
                                            :class="[
                                                'rounded px-2 py-1 text-xs font-medium',
                                                customer.newsletter_subscribed
                                                    ? 'bg-green-100 text-green-800'
                                                    : 'bg-gray-100 text-gray-800 dark:bg-gray-800/60 dark:text-gray-200',
                                            ]"
                                        >
                                            {{
                                                customer.newsletter_subscribed
                                                    ? $t('Subscribed')
                                                    : $t('Not Subscribed')
                                            }}
                                        </span>
                                    </dd>
                                </div>
                                <div>
                                    <dt
                                        class="text-sm font-medium text-gray-500 dark:text-gray-400"
                                    >
                                        {{ $t('Member Since') }}
                                    </dt>
                                    <dd
                                        class="mt-1 text-sm text-gray-900 dark:text-gray-100"
                                    >
                                        <DateDisplay
                                            :value="customer.created_at"
                                        />
                                    </dd>
                                </div>
                            </div>
                        </div>

                        <!-- Notes Section -->
                        <div
                            v-if="customer.notes"
                            class="mt-6 border-t border-gray-200 pt-6 dark:border-gray-700"
                        >
                            <h3
                                class="mb-4 text-lg font-medium text-gray-900 dark:text-gray-100"
                            >
                                {{ $t('Notes') }}
                            </h3>
                            <div
                                class="rounded-lg bg-gray-50 p-4 dark:bg-gray-900"
                            >
                                <p
                                    class="text-sm whitespace-pre-wrap text-gray-700 dark:text-gray-300"
                                >
                                    {{ customer.notes }}
                                </p>
                            </div>
                        </div>
                    </div>

                    <!-- Addresses Tab -->
                    <div v-if="activeTab === 'addresses'">
                        <div class="mb-4 flex items-center justify-between">
                            <Link
                                :href="`/admin/customers/${customer.id}/addresses`"
                                class="inline-flex items-center rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
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
                                        d="M4 6h16M4 10h16M4 14h16M4 18h16"
                                    />
                                </svg>
                                {{ $t('Manage All Addresses') }}
                            </Link>
                            <Link
                                :href="`/admin/customers/${customer.id}/addresses/create`"
                                class="inline-flex items-center rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
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
                                        d="M12 4v16m8-8H4"
                                    />
                                </svg>
                                {{ $t('Add Address') }}
                            </Link>
                        </div>
                        <div
                            v-if="
                                customer.addresses &&
                                customer.addresses.length > 0
                            "
                            class="grid grid-cols-1 gap-4 md:grid-cols-2"
                        >
                            <div
                                v-for="address in customer.addresses"
                                :key="address.id"
                                class="rounded-lg border border-gray-200 p-4 dark:border-gray-700"
                            >
                                <div
                                    class="mb-3 flex items-center justify-between"
                                >
                                    <span
                                        class="text-sm font-medium text-gray-900 capitalize dark:text-gray-100"
                                        >{{ address.type }}</span
                                    >
                                    <div class="flex gap-2">
                                        <span
                                            v-if="address.is_default_shipping"
                                            class="rounded bg-blue-100 px-2 py-1 text-xs font-medium text-blue-800"
                                        >
                                            {{ $t('Default Shipping') }}
                                        </span>
                                        <span
                                            v-if="address.is_default_billing"
                                            class="rounded bg-green-100 px-2 py-1 text-xs font-medium text-green-800"
                                        >
                                            {{ $t('Default Billing') }}
                                        </span>
                                    </div>
                                </div>
                                <div
                                    class="space-y-1 text-sm text-gray-700 dark:text-gray-300"
                                >
                                    <p class="font-medium">
                                        {{ address.first_name }}
                                        {{ address.last_name }}
                                    </p>
                                    <p v-if="address.company">
                                        {{ address.company }}
                                    </p>
                                    <p>{{ address.address_line_1 }}</p>
                                    <p v-if="address.address_line_2">
                                        {{ address.address_line_2 }}
                                    </p>
                                    <p>
                                        {{ address.city }}, {{ address.state }}
                                        {{ address.postal_code }}
                                    </p>
                                    <p>{{ address.country }}</p>
                                    <p v-if="address.phone" class="pt-2">
                                        {{ address.phone }}
                                    </p>
                                </div>
                            </div>
                        </div>
                        <div v-else class="py-12 text-center">
                            <svg
                                class="mx-auto h-12 w-12 text-gray-400"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                                />
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                                />
                            </svg>
                            <h3
                                class="mt-2 text-sm font-medium text-gray-900 dark:text-gray-100"
                            >
                                {{ $t('No addresses') }}
                            </h3>
                            <p
                                class="mt-1 text-sm text-gray-500 dark:text-gray-400"
                            >
                                {{
                                    $t(
                                        "This customer hasn't added any addresses yet.",
                                    )
                                }}
                            </p>
                        </div>
                    </div>

                    <!-- Notes Tab -->
                    <div v-if="activeTab === 'notes'">
                        <div
                            v-if="
                                customer.customer_notes &&
                                customer.customer_notes.length > 0
                            "
                            class="space-y-4"
                        >
                            <div
                                v-for="note in customer.customer_notes"
                                :key="note.id"
                                class="rounded-lg border border-gray-200 p-4 dark:border-gray-700"
                            >
                                <div
                                    class="mb-2 flex items-start justify-between"
                                >
                                    <div
                                        class="text-sm font-medium text-gray-900 dark:text-gray-100"
                                    >
                                        {{ note.user.name }}
                                    </div>
                                    <div
                                        class="text-xs text-gray-500 dark:text-gray-400"
                                    >
                                        <DateDisplay
                                            :value="note.created_at"
                                            time
                                        />
                                    </div>
                                </div>
                                <p
                                    class="text-sm whitespace-pre-wrap text-gray-700 dark:text-gray-300"
                                >
                                    {{ note.note }}
                                </p>
                            </div>
                        </div>
                        <div v-else class="py-12 text-center">
                            <svg
                                class="mx-auto h-12 w-12 text-gray-400"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                                />
                            </svg>
                            <h3
                                class="mt-2 text-sm font-medium text-gray-900 dark:text-gray-100"
                            >
                                {{ $t('No notes') }}
                            </h3>
                            <p
                                class="mt-1 text-sm text-gray-500 dark:text-gray-400"
                            >
                                {{
                                    $t(
                                        'No notes have been added for this customer.',
                                    )
                                }}
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Delete Modal -->
        <ConfirmDeleteModal
            v-model:show="showDeleteModal"
            :title="customer.full_name"
            :message="
                $t(
                    'Are you sure you want to delete {name}? This action cannot be undone.',
                    { name: customer.full_name },
                )
            "
            @confirm="deleteCustomer"
        />
    </AdminLayout>
</template>

<script setup lang="ts">
import DatePicker from '@/components/Calendar/DatePicker.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { useI18nStore } from '@/Stores/i18n';
import { Link, router, useForm } from '@inertiajs/vue3';
import { computed, ref } from 'vue';

const { t } = useI18nStore();

const form = useForm({
    code: '',
    name: '',
    description: '',
    type: 'percentage',
    value: 0,
    max_discount: null as number | null,
    min_order_amount: null as number | null,
    is_active: true,
    is_public: true,
    stackable: false,
    auto_apply: false,
    first_order_only: false,
    usage_limit_total: null as number | null,
    usage_limit_per_customer: null as number | null,
    start_date: '',
    end_date: '',
    days_of_week: [] as string[],
    time_restrictions: {
        start: '',
        end: '',
    },
    customer_groups: [] as number[],
    min_account_age_days: null as number | null,
    applicable_products: [] as number[],
    excluded_products: [] as number[],
    applicable_categories: [] as number[],
    excluded_categories: [] as number[],
    buy_quantity: null as number | null,
    get_quantity: null as number | null,
    priority: 0,
});

const activeTab = ref('general');

const daysOfWeek = [
    { value: 'monday', label: t('Monday') },
    { value: 'tuesday', label: t('Tuesday') },
    { value: 'wednesday', label: t('Wednesday') },
    { value: 'thursday', label: t('Thursday') },
    { value: 'friday', label: t('Friday') },
    { value: 'saturday', label: t('Saturday') },
    { value: 'sunday', label: t('Sunday') },
];

const showBuyXGetY = computed(() => form.type === 'buy_x_get_y');
const showMaxDiscount = computed(() => form.type === 'percentage');
const showValue = computed(() => form.type !== 'free_shipping');

const toggleDay = (day: string) => {
    const index = form.days_of_week.indexOf(day);
    if (index > -1) {
        form.days_of_week.splice(index, 1);
    } else {
        form.days_of_week.push(day);
    }
};

const submit = () => {
    form.post('/admin/marketing/coupons', {
        onSuccess: () => {
            router.visit('/admin/marketing/coupons');
        },
    });
};
</script>

<template>
    <AdminLayout :title="$t('Create Coupon')">
        <div class="space-y-6 p-6">
            <!-- Header -->
            <div class="flex items-center justify-between">
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-gray-100"
                    >
                        {{ $t('Create Coupon') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                        {{ $t('Create a new discount coupon') }}
                    </p>
                </div>
                <div class="flex gap-3">
                    <Link
                        href="/admin/marketing/coupons"
                        class="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                    >
                        {{ $t('Cancel') }}
                    </Link>
                    <button
                        @click="submit"
                        :disabled="form.processing"
                        class="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        {{ $t('Save Coupon') }}
                    </button>
                </div>
            </div>

            <!-- Tabs -->
            <div class="rounded-lg bg-white shadow-sm dark:bg-gray-800">
                <div class="border-b border-gray-200 dark:border-gray-700">
                    <nav class="-mb-px flex">
                        <button
                            @click="activeTab = 'general'"
                            :class="[
                                'border-b-2 px-6 py-4 text-sm font-medium transition-colors',
                                activeTab === 'general'
                                    ? 'border-blue-600 text-blue-600'
                                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                            ]"
                        >
                            {{ $t('General') }}
                        </button>
                        <button
                            @click="activeTab = 'conditions'"
                            :class="[
                                'border-b-2 px-6 py-4 text-sm font-medium transition-colors',
                                activeTab === 'conditions'
                                    ? 'border-blue-600 text-blue-600'
                                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                            ]"
                        >
                            {{ $t('Conditions') }}
                        </button>
                        <button
                            @click="activeTab = 'limits'"
                            :class="[
                                'border-b-2 px-6 py-4 text-sm font-medium transition-colors',
                                activeTab === 'limits'
                                    ? 'border-blue-600 text-blue-600'
                                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                            ]"
                        >
                            {{ $t('Usage Limits') }}
                        </button>
                        <button
                            @click="activeTab = 'restrictions'"
                            :class="[
                                'border-b-2 px-6 py-4 text-sm font-medium transition-colors',
                                activeTab === 'restrictions'
                                    ? 'border-blue-600 text-blue-600'
                                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                            ]"
                        >
                            {{ $t('Restrictions') }}
                        </button>
                    </nav>
                </div>

                <form @submit.prevent="submit" class="p-6">
                    <!-- General Tab -->
                    <div v-show="activeTab === 'general'" class="space-y-6">
                        <div>
                            <h3
                                class="mb-4 text-lg font-medium text-gray-900 dark:text-gray-100"
                            >
                                {{ $t('Basic Information') }}
                            </h3>
                            <div class="space-y-4">
                                <div class="grid grid-cols-2 gap-4">
                                    <div>
                                        <label
                                            for="code"
                                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >
                                            {{ $t('Coupon Code') }}
                                            <span class="text-red-500">*</span>
                                        </label>
                                        <input
                                            id="code"
                                            v-model="form.code"
                                            type="text"
                                            placeholder="SAVE20"
                                            class="w-full rounded-lg border border-gray-300 px-3 py-2 uppercase shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                            :class="{
                                                'border-red-500':
                                                    form.errors.code,
                                            }"
                                        />
                                        <p
                                            v-if="form.errors.code"
                                            class="mt-1 text-sm text-red-600"
                                        >
                                            {{ form.errors.code }}
                                        </p>
                                    </div>

                                    <div>
                                        <label
                                            for="name"
                                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >
                                            {{ $t('Display Name') }}
                                            <span class="text-red-500">*</span>
                                        </label>
                                        <input
                                            id="name"
                                            v-model="form.name"
                                            type="text"
                                            :placeholder="
                                                $t('20% Off All Orders')
                                            "
                                            class="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                            :class="{
                                                'border-red-500':
                                                    form.errors.name,
                                            }"
                                        />
                                        <p
                                            v-if="form.errors.name"
                                            class="mt-1 text-sm text-red-600"
                                        >
                                            {{ form.errors.name }}
                                        </p>
                                    </div>
                                </div>

                                <div>
                                    <label
                                        for="description"
                                        class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Description') }}</label
                                    >
                                    <textarea
                                        id="description"
                                        v-model="form.description"
                                        rows="3"
                                        :placeholder="
                                            $t(
                                                'Brief description of the coupon',
                                            )
                                        "
                                        class="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                    ></textarea>
                                </div>

                                <div class="grid grid-cols-3 gap-4">
                                    <div>
                                        <label
                                            for="type"
                                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >
                                            {{ $t('Discount Type') }}
                                            <span class="text-red-500">*</span>
                                        </label>
                                        <select
                                            id="type"
                                            v-model="form.type"
                                            class="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                            :class="{
                                                'border-red-500':
                                                    form.errors.type,
                                            }"
                                        >
                                            <option value="percentage">
                                                {{ $t('Percentage Discount') }}
                                            </option>
                                            <option value="fixed_amount">
                                                {{ $t('Fixed Amount') }}
                                            </option>
                                            <option value="free_shipping">
                                                {{ $t('Free Shipping') }}
                                            </option>
                                            <option value="buy_x_get_y">
                                                {{ $t('Buy X Get Y') }}
                                            </option>
                                            <option value="fixed_price">
                                                {{ $t('Fixed Price') }}
                                            </option>
                                        </select>
                                        <p
                                            v-if="form.errors.type"
                                            class="mt-1 text-sm text-red-600"
                                        >
                                            {{ form.errors.type }}
                                        </p>
                                    </div>

                                    <div v-if="showValue">
                                        <label
                                            for="value"
                                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >
                                            {{
                                                form.type === 'percentage'
                                                    ? $t('Percentage (%)')
                                                    : $t('Amount ($)')
                                            }}
                                            <span class="text-red-500">*</span>
                                        </label>
                                        <input
                                            id="value"
                                            v-model.number="form.value"
                                            type="number"
                                            step="0.01"
                                            min="0"
                                            class="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                            :class="{
                                                'border-red-500':
                                                    form.errors.value,
                                            }"
                                        />
                                        <p
                                            v-if="form.errors.value"
                                            class="mt-1 text-sm text-red-600"
                                        >
                                            {{ form.errors.value }}
                                        </p>
                                    </div>

                                    <div v-if="showMaxDiscount">
                                        <label
                                            for="max_discount"
                                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                            >{{ $t('Max Discount ($)') }}</label
                                        >
                                        <input
                                            id="max_discount"
                                            v-model.number="form.max_discount"
                                            type="number"
                                            step="0.01"
                                            min="0"
                                            :placeholder="$t('Optional')"
                                            class="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                        />
                                    </div>
                                </div>

                                <!-- Buy X Get Y Fields -->
                                <div
                                    v-if="showBuyXGetY"
                                    class="grid grid-cols-2 gap-4"
                                >
                                    <div>
                                        <label
                                            for="buy_quantity"
                                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >
                                            {{ $t('Buy Quantity') }}
                                            <span class="text-red-500">*</span>
                                        </label>
                                        <input
                                            id="buy_quantity"
                                            v-model.number="form.buy_quantity"
                                            type="number"
                                            min="1"
                                            placeholder="2"
                                            class="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                        />
                                    </div>
                                    <div>
                                        <label
                                            for="get_quantity"
                                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >
                                            {{ $t('Get Quantity') }}
                                            <span class="text-red-500">*</span>
                                        </label>
                                        <input
                                            id="get_quantity"
                                            v-model.number="form.get_quantity"
                                            type="number"
                                            min="1"
                                            placeholder="1"
                                            class="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                        />
                                    </div>
                                </div>

                                <div class="grid grid-cols-2 gap-4">
                                    <div>
                                        <label
                                            for="start_date"
                                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >
                                            {{ $t('Start Date') }}
                                            <span class="text-red-500">*</span>
                                        </label>
                                        <DatePicker
                                            id="start_date"
                                            v-model="form.start_date"
                                            with-time
                                            class="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600"
                                            :class="{
                                                'border-red-500':
                                                    form.errors.start_date,
                                            }"
                                        />
                                        <p
                                            v-if="form.errors.start_date"
                                            class="mt-1 text-sm text-red-600"
                                        >
                                            {{ form.errors.start_date }}
                                        </p>
                                    </div>
                                    <div>
                                        <label
                                            for="end_date"
                                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                            >{{ $t('End Date') }}</label
                                        >
                                        <DatePicker
                                            id="end_date"
                                            v-model="form.end_date"
                                            with-time
                                            :placeholder="
                                                $t('Optional - no expiry')
                                            "
                                            class="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600"
                                        />
                                        <p
                                            class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                                        >
                                            {{
                                                $t(
                                                    'Leave empty for no expiration',
                                                )
                                            }}
                                        </p>
                                    </div>
                                </div>

                                <div class="flex items-center gap-6">
                                    <label class="flex items-center">
                                        <input
                                            type="checkbox"
                                            v-model="form.is_active"
                                            class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                        />
                                        <span
                                            class="ml-2 text-sm text-gray-700 dark:text-gray-300"
                                            >{{ $t('Active') }}</span
                                        >
                                    </label>
                                    <label class="flex items-center">
                                        <input
                                            type="checkbox"
                                            v-model="form.is_public"
                                            class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                        />
                                        <span
                                            class="ml-2 text-sm text-gray-700 dark:text-gray-300"
                                            >{{
                                                $t(
                                                    'Public (visible to customers)',
                                                )
                                            }}</span
                                        >
                                    </label>
                                    <label class="flex items-center">
                                        <input
                                            type="checkbox"
                                            v-model="form.auto_apply"
                                            class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                        />
                                        <span
                                            class="ml-2 text-sm text-gray-700 dark:text-gray-300"
                                            >{{ $t('Auto Apply') }}</span
                                        >
                                    </label>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Conditions Tab -->
                    <div v-show="activeTab === 'conditions'" class="space-y-6">
                        <div>
                            <h3
                                class="mb-4 text-lg font-medium text-gray-900 dark:text-gray-100"
                            >
                                {{ $t('Order Conditions') }}
                            </h3>
                            <div class="space-y-4">
                                <div class="grid grid-cols-2 gap-4">
                                    <div>
                                        <label
                                            for="min_order_amount"
                                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >
                                            {{ $t('Minimum Order Amount ($)') }}
                                        </label>
                                        <input
                                            id="min_order_amount"
                                            v-model.number="
                                                form.min_order_amount
                                            "
                                            type="number"
                                            step="0.01"
                                            min="0"
                                            :placeholder="$t('Optional')"
                                            class="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                        />
                                    </div>
                                    <div>
                                        <label
                                            for="priority"
                                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                            >{{ $t('Priority') }}</label
                                        >
                                        <input
                                            id="priority"
                                            v-model.number="form.priority"
                                            type="number"
                                            min="0"
                                            :placeholder="$t('0 = highest')"
                                            class="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                        />
                                    </div>
                                </div>

                                <div class="flex items-center gap-6">
                                    <label class="flex items-center">
                                        <input
                                            type="checkbox"
                                            v-model="form.first_order_only"
                                            class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                        />
                                        <span
                                            class="ml-2 text-sm text-gray-700 dark:text-gray-300"
                                            >{{ $t('First Order Only') }}</span
                                        >
                                    </label>
                                    <label class="flex items-center">
                                        <input
                                            type="checkbox"
                                            v-model="form.stackable"
                                            class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                        />
                                        <span
                                            class="ml-2 text-sm text-gray-700 dark:text-gray-300"
                                            >{{
                                                $t(
                                                    'Can Stack with Other Coupons',
                                                )
                                            }}</span
                                        >
                                    </label>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Usage Limits Tab -->
                    <div v-show="activeTab === 'limits'" class="space-y-6">
                        <div>
                            <h3
                                class="mb-4 text-lg font-medium text-gray-900 dark:text-gray-100"
                            >
                                {{ $t('Usage Limits') }}
                            </h3>
                            <div class="space-y-4">
                                <div class="grid grid-cols-2 gap-4">
                                    <div>
                                        <label
                                            for="usage_limit_total"
                                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >
                                            {{ $t('Total Usage Limit') }}
                                        </label>
                                        <input
                                            id="usage_limit_total"
                                            v-model.number="
                                                form.usage_limit_total
                                            "
                                            type="number"
                                            min="1"
                                            :placeholder="$t('Unlimited')"
                                            class="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                        />
                                        <p
                                            class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                                        >
                                            {{
                                                $t(
                                                    'Leave empty for unlimited uses',
                                                )
                                            }}
                                        </p>
                                    </div>
                                    <div>
                                        <label
                                            for="usage_limit_per_customer"
                                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >
                                            {{ $t('Usage Limit Per Customer') }}
                                        </label>
                                        <input
                                            id="usage_limit_per_customer"
                                            v-model.number="
                                                form.usage_limit_per_customer
                                            "
                                            type="number"
                                            min="1"
                                            :placeholder="$t('Unlimited')"
                                            class="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                        />
                                        <p
                                            class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                                        >
                                            {{
                                                $t(
                                                    'How many times each customer can use this',
                                                )
                                            }}
                                        </p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Restrictions Tab -->
                    <div
                        v-show="activeTab === 'restrictions'"
                        class="space-y-6"
                    >
                        <div>
                            <h3
                                class="mb-4 text-lg font-medium text-gray-900 dark:text-gray-100"
                            >
                                {{ $t('Time Restrictions') }}
                            </h3>
                            <div class="space-y-4">
                                <div>
                                    <label
                                        class="mb-2 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Days of Week') }}</label
                                    >
                                    <div class="grid grid-cols-4 gap-3">
                                        <label
                                            v-for="day in daysOfWeek"
                                            :key="day.value"
                                            class="flex items-center"
                                        >
                                            <input
                                                type="checkbox"
                                                :checked="
                                                    form.days_of_week.includes(
                                                        day.value,
                                                    )
                                                "
                                                @change="toggleDay(day.value)"
                                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                            />
                                            <span
                                                class="ml-2 text-sm text-gray-700 dark:text-gray-300"
                                                >{{ day.label }}</span
                                            >
                                        </label>
                                    </div>
                                    <p
                                        class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                                    >
                                        {{
                                            $t('Leave empty to allow all days')
                                        }}
                                    </p>
                                </div>

                                <div class="grid grid-cols-2 gap-4">
                                    <div>
                                        <label
                                            for="time_start"
                                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                            >{{ $t('Start Time') }}</label
                                        >
                                        <input
                                            id="time_start"
                                            v-model="
                                                form.time_restrictions.start
                                            "
                                            type="time"
                                            class="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                        />
                                    </div>
                                    <div>
                                        <label
                                            for="time_end"
                                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                            >{{ $t('End Time') }}</label
                                        >
                                        <input
                                            id="time_end"
                                            v-model="form.time_restrictions.end"
                                            type="time"
                                            class="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                        />
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div>
                            <h3
                                class="mb-4 text-lg font-medium text-gray-900 dark:text-gray-100"
                            >
                                {{ $t('Customer Restrictions') }}
                            </h3>
                            <div class="space-y-4">
                                <div>
                                    <label
                                        for="min_account_age_days"
                                        class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >
                                        {{ $t('Minimum Account Age (Days)') }}
                                    </label>
                                    <input
                                        id="min_account_age_days"
                                        v-model.number="
                                            form.min_account_age_days
                                        "
                                        type="number"
                                        min="0"
                                        :placeholder="$t('Optional')"
                                        class="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                    />
                                    <p
                                        class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                                    >
                                        {{
                                            $t(
                                                'Customer account must be at least this many days old',
                                            )
                                        }}
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </AdminLayout>
</template>

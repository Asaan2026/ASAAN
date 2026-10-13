<template>
    <Head :title="$t('Create Tax Rule')" />

    <AdminLayout :title="$t('Create Tax Rule')">
        <div class="mx-auto max-w-4xl space-y-6">
            <!-- Header -->
            <div class="flex items-center justify-between">
                <div>
                    <div class="mb-1 flex items-center gap-2">
                        <Link
                            href="/admin/settings/tax-rules"
                            class="text-gray-500 transition-colors hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300"
                        >
                            <ArrowLeft class="h-5 w-5" />
                        </Link>
                        <h2
                            class="bg-gradient-to-r from-gray-900 to-gray-600 bg-clip-text text-2xl font-bold text-transparent dark:from-white dark:to-gray-300"
                        >
                            {{ $t('Create Tax Rule') }}
                        </h2>
                    </div>
                    <p class="ml-7 text-sm text-gray-500 dark:text-gray-400">
                        {{ $t('Configure a new tax calculation rule') }}
                    </p>
                </div>
            </div>

            <!-- Main Form -->
            <div
                class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <form @submit.prevent="submit" class="space-y-6 p-6">
                    <!-- Basic Info Section -->
                    <div class="space-y-6">
                        <h3
                            class="flex items-center gap-2 border-b border-gray-100 pb-4 text-lg font-medium text-gray-900 dark:border-gray-700 dark:text-white"
                        >
                            <Sparkles class="h-5 w-5 text-blue-500" />
                            {{ $t('Rule Details') }}
                        </h3>

                        <!-- Rule Name -->
                        <div>
                            <label
                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Rule Name') }}
                                <span class="text-red-500">*</span>
                            </label>
                            <div class="relative">
                                <input
                                    v-model="form.name"
                                    type="text"
                                    class="block w-full rounded-xl border border-gray-300 bg-gray-50 px-4 py-2.5 pl-10 text-sm transition-all focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-900/50 dark:text-white"
                                    :placeholder="$t('e.g., US Standard Tax')"
                                    required
                                />
                                <Type
                                    class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                                />
                            </div>
                            <p
                                v-if="errors.name"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors.name }}
                            </p>
                        </div>

                        <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
                            <!-- Tax Class -->
                            <div>
                                <label
                                    class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >
                                    {{ $t('Tax Class') }}
                                    <span class="text-red-500">*</span>
                                </label>
                                <div class="relative">
                                    <select
                                        v-model="form.tax_class_id"
                                        class="block w-full appearance-none rounded-xl border border-gray-300 bg-gray-50 px-4 py-2.5 pl-10 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-900/50 dark:text-white"
                                        required
                                    >
                                        <option value="">
                                            {{ $t('Select Tax Class...') }}
                                        </option>
                                        <option
                                            v-for="taxClass in taxClasses"
                                            :key="taxClass.id"
                                            :value="taxClass.id"
                                        >
                                            {{ taxClass.name }}
                                        </option>
                                    </select>
                                    <Tag
                                        class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                                    />
                                    <div
                                        class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4"
                                    >
                                        <ChevronDown
                                            class="h-4 w-4 text-gray-400"
                                        />
                                    </div>
                                </div>
                                <p
                                    v-if="errors.tax_class_id"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ errors.tax_class_id }}
                                </p>
                            </div>

                            <!-- Tax Zone -->
                            <div>
                                <label
                                    class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >
                                    {{ $t('Tax Zone') }}
                                    <span class="text-red-500">*</span>
                                </label>
                                <div class="relative">
                                    <select
                                        v-model="form.tax_zone_id"
                                        class="block w-full appearance-none rounded-xl border border-gray-300 bg-gray-50 px-4 py-2.5 pl-10 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-900/50 dark:text-white"
                                        required
                                    >
                                        <option value="">
                                            {{ $t('Select Tax Zone...') }}
                                        </option>
                                        <option
                                            v-for="zone in taxZones"
                                            :key="zone.id"
                                            :value="zone.id"
                                        >
                                            {{ zone.name }}
                                        </option>
                                    </select>
                                    <Map
                                        class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                                    />
                                    <div
                                        class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4"
                                    >
                                        <ChevronDown
                                            class="h-4 w-4 text-gray-400"
                                        />
                                    </div>
                                </div>
                                <p
                                    v-if="errors.tax_zone_id"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ errors.tax_zone_id }}
                                </p>
                            </div>

                            <!-- Tax Rate -->
                            <div>
                                <label
                                    class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >
                                    {{ $t('Tax Rate') }}
                                    <span class="text-red-500">*</span>
                                </label>
                                <div class="relative">
                                    <select
                                        v-model="form.tax_rate_id"
                                        class="block w-full appearance-none rounded-xl border border-gray-300 bg-gray-50 px-4 py-2.5 pl-10 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-900/50 dark:text-white"
                                        required
                                    >
                                        <option value="">
                                            {{ $t('Select Tax Rate...') }}
                                        </option>
                                        <option
                                            v-for="rate in taxRates"
                                            :key="rate.id"
                                            :value="rate.id"
                                        >
                                            {{ rate.name }} ({{
                                                rate.percentage
                                            }}%)
                                        </option>
                                    </select>
                                    <Percent
                                        class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                                    />
                                    <div
                                        class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4"
                                    >
                                        <ChevronDown
                                            class="h-4 w-4 text-gray-400"
                                        />
                                    </div>
                                </div>
                                <p
                                    v-if="errors.tax_rate_id"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ errors.tax_rate_id }}
                                </p>
                            </div>

                            <!-- Priority -->
                            <div>
                                <label
                                    class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >
                                    {{ $t('Priority') }}
                                </label>
                                <div class="relative">
                                    <input
                                        v-model.number="form.priority"
                                        type="number"
                                        min="0"
                                        class="block w-full rounded-xl border border-gray-300 bg-gray-50 px-4 py-2.5 pl-10 text-sm transition-all focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-900/50 dark:text-white"
                                        placeholder="0"
                                    />
                                    <Layers
                                        class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                                    />
                                </div>
                                <p
                                    class="mt-1.5 text-xs text-gray-500 dark:text-gray-400"
                                >
                                    {{
                                        $t(
                                            'Lower numbers have higher priority in calculation.',
                                        )
                                    }}
                                </p>
                                <p
                                    v-if="errors.priority"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ errors.priority }}
                                </p>
                            </div>
                        </div>
                    </div>

                    <!-- Settings Section -->
                    <div
                        class="space-y-6 border-t border-gray-100 pt-6 dark:border-gray-700"
                    >
                        <h3
                            class="flex items-center gap-2 pb-4 text-lg font-medium text-gray-900 dark:text-white"
                        >
                            <Settings class="h-5 w-5 text-blue-500" />
                            {{ $t('Settings') }}
                        </h3>

                        <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
                            <!-- Calculate Shipping -->
                            <div
                                class="relative flex cursor-pointer items-start rounded-xl border border-gray-200 bg-gray-50 p-4 transition-colors hover:border-blue-500 dark:border-gray-700 dark:bg-gray-800/50 dark:hover:border-blue-500"
                                @click="
                                    form.calculate_shipping =
                                        !form.calculate_shipping
                                "
                            >
                                <div class="flex h-5 items-center">
                                    <input
                                        v-model="form.calculate_shipping"
                                        type="checkbox"
                                        class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                        @click.stop
                                    />
                                </div>
                                <div class="ml-3 text-sm">
                                    <label
                                        class="cursor-pointer font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Include Shipping') }}</label
                                    >
                                    <p
                                        class="mt-0.5 text-xs text-gray-500 dark:text-gray-400"
                                    >
                                        {{
                                            $t(
                                                'Include shipping cost in tax calculation.',
                                            )
                                        }}
                                    </p>
                                </div>
                            </div>

                            <!-- Active Status -->
                            <div
                                class="relative flex cursor-pointer items-start rounded-xl border border-gray-200 bg-gray-50 p-4 transition-colors hover:border-blue-500 dark:border-gray-700 dark:bg-gray-800/50 dark:hover:border-blue-500"
                                @click="form.is_active = !form.is_active"
                            >
                                <div class="flex h-5 items-center">
                                    <input
                                        v-model="form.is_active"
                                        type="checkbox"
                                        class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                        @click.stop
                                    />
                                </div>
                                <div class="ml-3 text-sm">
                                    <label
                                        class="cursor-pointer font-medium text-gray-700 dark:text-gray-300"
                                        >{{ $t('Active Status') }}</label
                                    >
                                    <p
                                        class="mt-0.5 text-xs text-gray-500 dark:text-gray-400"
                                    >
                                        {{
                                            $t(
                                                'Enable or disable this tax rule.',
                                            )
                                        }}
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Form Actions -->
                    <div
                        class="flex items-center justify-end gap-3 border-t border-gray-100 pt-6 dark:border-gray-700"
                    >
                        <Link
                            href="/admin/settings/tax-rules"
                            class="rounded-xl border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700"
                        >
                            {{ $t('Cancel') }}
                        </Link>
                        <button
                            type="submit"
                            :disabled="processing"
                            class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900 disabled:cursor-not-allowed disabled:opacity-50"
                        >
                            <Save v-if="!processing" class="mr-2 h-4 w-4" />
                            <div
                                v-else
                                class="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent"
                            ></div>
                            <span>{{
                                processing
                                    ? $t('Creating...')
                                    : $t('Create Tax Rule')
                            }}</span>
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </AdminLayout>
</template>

<script setup lang="ts">
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, Link, router } from '@inertiajs/vue3';
import {
    ArrowLeft,
    ChevronDown,
    Layers,
    Map,
    Percent,
    Save,
    Settings,
    Sparkles,
    Tag,
    Type,
} from 'lucide-vue-next';
import { reactive, ref } from 'vue';

interface TaxClass {
    id: number;
    name: string;
}

interface TaxZone {
    id: number;
    name: string;
}

interface TaxRate {
    id: number;
    name: string;
    percentage: string;
}

interface Props {
    taxClasses: TaxClass[];
    taxZones: TaxZone[];
    taxRates: TaxRate[];
}

const props = defineProps<Props>();

const form = reactive({
    name: '',
    tax_class_id: '',
    tax_zone_id: '',
    tax_rate_id: '',
    priority: 0,
    calculate_shipping: false,
    is_active: true,
});

const errors = ref<Record<string, string>>({});
const processing = ref(false);

const submit = () => {
    processing.value = true;
    errors.value = {};

    router.post('/admin/settings/tax-rules', form, {
        onError: (err) => {
            errors.value = err;
            processing.value = false;
        },
        onFinish: () => {
            processing.value = false;
        },
    });
};
</script>

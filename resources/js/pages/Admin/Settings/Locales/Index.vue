<script setup lang="ts">
import ConfirmDeleteModal from '@/components/Admin/ConfirmDeleteModal.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { useI18nStore } from '@/Stores/i18n';
import { Head, router, usePage } from '@inertiajs/vue3';
import {
    Check,
    CheckCircle,
    ChevronDown,
    Coins,
    Edit,
    Filter,
    Globe,
    Languages,
    Plus,
    Save,
    Search,
    Trash2,
    X,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

interface Locale {
    id: number;
    code: string;
    name: string;
    native_name: string | null;
    direction: 'ltr' | 'rtl';
    is_default: boolean;
    is_active: boolean;
    sort_order: number;
}

interface Currency {
    id: number;
    code: string;
    name: string;
    symbol: string;
    symbol_position: 'before' | 'after';
    decimal_places: number;
    exchange_rate: number;
    is_default: boolean;
    is_active: boolean;
    sort_order: number;
}

interface Country {
    id: number;
    name: string;
    code: string;
    code3: string | null;
    phone_code: string | null;
    currency_code: string | null;
    currency_symbol: string | null;
    is_active: boolean;
    sort_order: number;
}

const props = defineProps<{
    locales: Locale[];
    currencies: Currency[];
    countries: Country[];
    /** "1 USD = ? AFN" -- built on the server so the label and the stored rate agree. */
    exchangeRateLabel?: string;
    usdToAfn?: number;
    supportedCurrencyCodes?: string[];
}>();

const { t } = useI18nStore();

/**
 * The rate field says which way round the number goes.
 *
 * Falls back to the same string the server builds, so the form is never left
 * with a bare "Exchange Rate" the owner has to guess the direction of.
 */
const exchangeRateLabel = computed(
    () => props.exchangeRateLabel || '1 USD = ? AFN',
);

const page = usePage();
const errors = computed(() => page.props.errors as Record<string, string>);

// Active tab
const activeTab = ref<'countries' | 'languages' | 'currencies'>('countries');

// Locale Modal State
const showLocaleModal = ref(false);
const localeMode = ref<'add' | 'edit'>('add');
const localeProcessing = ref(false);
const localeForm = ref<Partial<Locale>>({
    code: '',
    name: '',
    native_name: '',
    direction: 'ltr',
    is_default: false,
    is_active: true,
    sort_order: 0,
});

// Currency Modal State
const showCurrencyModal = ref(false);
const currencyMode = ref<'add' | 'edit'>('add');
const currencyProcessing = ref(false);
const currencyForm = ref<Partial<Currency>>({
    code: '',
    name: '',
    symbol: '',
    symbol_position: 'before',
    decimal_places: 2,
    exchange_rate: 1.0,
    is_default: false,
    is_active: true,
    sort_order: 0,
});

// Country State
const countrySearch = ref('');
const countryStatusFilter = ref('');
const filteredCountries = computed(() => {
    return props.countries.filter((c) => {
        const matchesSearch =
            !countrySearch.value ||
            c.name.toLowerCase().includes(countrySearch.value.toLowerCase()) ||
            c.code.toLowerCase().includes(countrySearch.value.toLowerCase()) ||
            (c.phone_code || '').includes(countrySearch.value);
        const matchesStatus =
            !countryStatusFilter.value ||
            (countryStatusFilter.value === '1' ? c.is_active : !c.is_active);
        return matchesSearch && matchesStatus;
    });
});

const showCountryModal = ref(false);
const countryMode = ref<'add' | 'edit'>('add');
const countryProcessing = ref(false);
const countryForm = ref<Partial<Country>>({
    name: '',
    code: '',
    code3: '',
    phone_code: '',
    currency_code: '',
    currency_symbol: '',
    is_active: true,
    sort_order: 0,
});

const openAddCountryModal = () => {
    countryMode.value = 'add';
    countryForm.value = {
        name: '',
        code: '',
        code3: '',
        phone_code: '',
        currency_code: '',
        currency_symbol: '',
        is_active: true,
        sort_order: 0,
    };
    showCountryModal.value = true;
};

const openEditCountryModal = (country: Country) => {
    countryMode.value = 'edit';
    countryForm.value = { ...country };
    showCountryModal.value = true;
};

const saveCountry = () => {
    countryProcessing.value = true;
    const url =
        countryMode.value === 'add'
            ? '/admin/settings/countries'
            : `/admin/settings/countries/${countryForm.value.id}`;
    const method = countryMode.value === 'add' ? 'post' : 'put';
    router[method](url, countryForm.value as any, {
        preserveScroll: true,
        preserveState: true,
        onSuccess: () => {
            showCountryModal.value = false;
            countryProcessing.value = false;
        },
        onError: () => {
            countryProcessing.value = false;
        },
    });
};

const toggleCountryStatus = (country: Country) => {
    router.post(
        `/admin/settings/countries/${country.id}/toggle`,
        {},
        { preserveScroll: true, preserveState: true },
    );
};

const countrySelectedIds = ref<number[]>([]);
const allCountriesSelected = computed(
    () =>
        filteredCountries.value.length > 0 &&
        countrySelectedIds.value.length === filteredCountries.value.length,
);
const someCountriesSelected = computed(
    () =>
        countrySelectedIds.value.length > 0 &&
        countrySelectedIds.value.length < filteredCountries.value.length,
);
const toggleAllCountries = () => {
    countrySelectedIds.value = allCountriesSelected.value
        ? []
        : filteredCountries.value.map((c) => c.id);
};
const bulkEnableCountries = () => {
    if (!countrySelectedIds.value.length) return;
    router.post(
        '/admin/settings/countries/bulk-toggle',
        { ids: countrySelectedIds.value, is_active: true },
        {
            preserveScroll: true,
            preserveState: true,
            onSuccess: () => {
                countrySelectedIds.value = [];
            },
        },
    );
};
const bulkDisableCountries = () => {
    if (!countrySelectedIds.value.length) return;
    router.post(
        '/admin/settings/countries/bulk-toggle',
        { ids: countrySelectedIds.value, is_active: false },
        {
            preserveScroll: true,
            preserveState: true,
            onSuccess: () => {
                countrySelectedIds.value = [];
            },
        },
    );
};

// Delete Modal State
const showDeleteModal = ref(false);
const deleteTarget = ref<{
    type: 'locale' | 'currency' | 'country';
    item: any;
} | null>(null);
const deleteConfirmMessage = computed(() =>
    t(
        "Are you sure you want to delete '{name}'? This action cannot be undone.",
        {
            name:
                deleteTarget?.value?.item?.name ??
                deleteTarget?.value?.item?.code ??
                '',
        },
    ),
);

// Locale Functions
const openAddLocaleModal = () => {
    localeMode.value = 'add';
    localeForm.value = {
        code: '',
        name: '',
        native_name: '',
        direction: 'ltr',
        is_default: false,
        is_active: true,
        sort_order: 0,
    };
    showLocaleModal.value = true;
};

const openEditLocaleModal = (locale: Locale) => {
    localeMode.value = 'edit';
    localeForm.value = { ...locale };
    showLocaleModal.value = true;
};

const saveLocale = () => {
    const url =
        localeMode.value === 'add'
            ? '/admin/settings/locales/locale'
            : `/admin/settings/locales/locale/${localeForm.value.id}`;

    const method = localeMode.value === 'add' ? 'post' : 'put';

    localeProcessing.value = true;
    router[method](url, localeForm.value, {
        preserveScroll: true,
        preserveState: true,
        onSuccess: () => {
            localeProcessing.value = false;
            showLocaleModal.value = false;
        },
        onError: () => {
            localeProcessing.value = false;
        },
        onFinish: () => {
            localeProcessing.value = false;
        },
    });
};

const deleteLocale = (locale: Locale) => {
    deleteTarget.value = { type: 'locale', item: locale };
    showDeleteModal.value = true;
};

// Currency Functions
const openAddCurrencyModal = () => {
    currencyMode.value = 'add';
    currencyForm.value = {
        code: '',
        name: '',
        symbol: '',
        symbol_position: 'before',
        decimal_places: 2,
        exchange_rate: 1.0,
        is_default: false,
        is_active: true,
        sort_order: 0,
    };
    showCurrencyModal.value = true;
};

const openEditCurrencyModal = (currency: Currency) => {
    currencyMode.value = 'edit';
    currencyForm.value = { ...currency };
    showCurrencyModal.value = true;
};

const saveCurrency = () => {
    const url =
        currencyMode.value === 'add'
            ? '/admin/settings/locales/currency'
            : `/admin/settings/locales/currency/${currencyForm.value.id}`;

    const method = currencyMode.value === 'add' ? 'post' : 'put';

    currencyProcessing.value = true;
    router[method](url, currencyForm.value, {
        preserveScroll: true,
        preserveState: true,
        onSuccess: () => {
            currencyProcessing.value = false;
            showCurrencyModal.value = false;
        },
        onError: () => {
            currencyProcessing.value = false;
        },
        onFinish: () => {
            currencyProcessing.value = false;
        },
    });
};

const deleteCurrency = (currency: Currency) => {
    deleteTarget.value = { type: 'currency', item: currency };
    showDeleteModal.value = true;
};

const confirmDelete = () => {
    if (!deleteTarget.value) return;

    const { type, item } = deleteTarget.value;
    const url =
        type === 'locale'
            ? `/admin/settings/locales/locale/${item.id}`
            : type === 'currency'
              ? `/admin/settings/locales/currency/${item.id}`
              : `/admin/settings/countries/${item.id}`;

    router.delete(url, {
        preserveScroll: true,
        onSuccess: () => {
            showDeleteModal.value = false;
            deleteTarget.value = null;
        },
    });
};
</script>

<template>
    <AdminLayout :title="$t('Locales & Countries')">
        <Head :title="$t('Locales & Countries')" />

        <div class="space-y-6">
            <!-- Header -->
            <div
                class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between"
            >
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Locales & Countries') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                        {{
                            $t(
                                'Manage countries, languages and currencies for your store',
                            )
                        }}
                    </p>
                </div>
                <div class="flex gap-3">
                    <button
                        v-if="activeTab === 'countries'"
                        @click="openAddCountryModal"
                        class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                    >
                        <Plus class="mr-2 h-4 w-4" />
                        {{ $t('Add Country') }}
                    </button>
                    <button
                        v-if="activeTab === 'languages'"
                        @click="openAddLocaleModal"
                        class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                    >
                        <Plus class="mr-2 h-4 w-4" />
                        {{ $t('Add Language') }}
                    </button>
                    <button
                        v-if="activeTab === 'currencies'"
                        @click="openAddCurrencyModal"
                        class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                    >
                        <Plus class="mr-2 h-4 w-4" />
                        {{ $t('Add Currency') }}
                    </button>
                </div>
            </div>

            <!-- Tabs -->
            <div
                class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div
                    class="border-b border-gray-200 bg-gray-50/50 dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="flex space-x-8 px-6">
                        <button
                            @click="activeTab = 'countries'"
                            :class="[
                                'group inline-flex items-center border-b-2 px-1 py-4 text-sm font-medium transition-colors duration-200',
                                activeTab === 'countries'
                                    ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                            ]"
                        >
                            <Globe
                                class="mr-2 h-4 w-4"
                                :class="
                                    activeTab === 'countries'
                                        ? 'text-blue-500'
                                        : 'text-gray-400 group-hover:text-gray-500'
                                "
                            />
                            {{ $t('Countries') }}
                        </button>
                        <button
                            @click="activeTab = 'languages'"
                            :class="[
                                'group inline-flex items-center border-b-2 px-1 py-4 text-sm font-medium transition-colors duration-200',
                                activeTab === 'languages'
                                    ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                            ]"
                        >
                            <Languages
                                class="mr-2 h-4 w-4"
                                :class="
                                    activeTab === 'languages'
                                        ? 'text-blue-500'
                                        : 'text-gray-400 group-hover:text-gray-500'
                                "
                            />
                            {{ $t('Languages') }}
                        </button>
                        <button
                            @click="activeTab = 'currencies'"
                            :class="[
                                'group inline-flex items-center border-b-2 px-1 py-4 text-sm font-medium transition-colors duration-200',
                                activeTab === 'currencies'
                                    ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 dark:text-gray-400 dark:hover:border-gray-600 dark:hover:text-gray-300',
                            ]"
                        >
                            <Coins
                                class="mr-2 h-4 w-4"
                                :class="
                                    activeTab === 'currencies'
                                        ? 'text-blue-500'
                                        : 'text-gray-400 group-hover:text-gray-500'
                                "
                            />
                            {{ $t('Currencies') }}
                        </button>
                    </div>
                </div>

                <!-- Tab Content -->
                <div class="p-6">
                    <!-- Countries Tab -->
                    <div v-show="activeTab === 'countries'">
                        <!-- Search & Filter -->
                        <div class="mb-4 flex flex-col gap-3 sm:flex-row">
                            <div class="relative flex-1">
                                <Search
                                    class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                                />
                                <input
                                    v-model="countrySearch"
                                    type="text"
                                    :placeholder="
                                        $t(
                                            'Search by name, code or phone code...',
                                        )
                                    "
                                    class="w-full rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-4 pl-10 text-sm text-gray-900 transition-all placeholder:text-gray-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                />
                            </div>
                            <div class="relative w-40">
                                <Filter
                                    class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                                />
                                <select
                                    v-model="countryStatusFilter"
                                    class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-8 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                >
                                    <option value="">
                                        {{ $t('All Status') }}
                                    </option>
                                    <option value="1">
                                        {{ $t('Active') }}
                                    </option>
                                    <option value="0">
                                        {{ $t('Inactive') }}
                                    </option>
                                </select>
                                <div
                                    class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2"
                                >
                                    <ChevronDown
                                        class="h-3 w-3 text-gray-400"
                                    />
                                </div>
                            </div>
                        </div>

                        <!-- Bulk Actions Bar -->
                        <transition
                            enter-active-class="transition ease-out duration-200"
                            enter-from-class="opacity-0 -translate-y-2"
                            enter-to-class="opacity-100 translate-y-0"
                            leave-active-class="transition ease-in duration-150"
                            leave-from-class="opacity-100 translate-y-0"
                            leave-to-class="opacity-0 -translate-y-2"
                        >
                            <div
                                v-if="countrySelectedIds.length > 0"
                                class="mb-3 flex items-center justify-between rounded-xl bg-blue-600 p-3 px-4 text-white"
                            >
                                <span
                                    class="flex items-center text-sm font-semibold"
                                >
                                    <CheckCircle class="mr-2 h-4 w-4" />
                                    {{
                                        $t(
                                            countrySelectedIds.length === 1
                                                ? '{count} country selected'
                                                : '{count} countries selected',
                                            {
                                                count: countrySelectedIds.length,
                                            },
                                        )
                                    }}
                                </span>
                                <div class="flex gap-2">
                                    <button
                                        @click="bulkEnableCountries"
                                        class="rounded-lg bg-white px-3 py-1.5 text-xs font-bold tracking-wide text-blue-600 uppercase transition-colors hover:bg-blue-50"
                                    >
                                        {{ $t('Enable') }}
                                    </button>
                                    <button
                                        @click="bulkDisableCountries"
                                        class="rounded-lg bg-white px-3 py-1.5 text-xs font-bold tracking-wide text-blue-600 uppercase transition-colors hover:bg-blue-50"
                                    >
                                        {{ $t('Disable') }}
                                    </button>
                                    <div
                                        class="mx-1 h-6 w-px bg-blue-400"
                                    ></div>
                                    <button
                                        @click="countrySelectedIds = []"
                                        class="rounded-lg px-3 py-1.5 text-xs font-bold tracking-wide text-blue-200 uppercase transition-colors hover:text-white"
                                    >
                                        {{ $t('Clear') }}
                                    </button>
                                </div>
                            </div>
                        </transition>

                        <!-- Table -->
                        <div
                            class="overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-700"
                        >
                            <table
                                class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                            >
                                <thead class="bg-gray-50 dark:bg-gray-700/50">
                                    <tr>
                                        <th class="w-12 px-6 py-3">
                                            <input
                                                type="checkbox"
                                                :checked="allCountriesSelected"
                                                :indeterminate.prop="
                                                    someCountriesSelected
                                                "
                                                @change="toggleAllCountries"
                                                class="h-4 w-4 rounded border-gray-300 bg-white text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </th>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Code') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Name') }}
                                        </th>
                                        <th
                                            class="hidden px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase md:table-cell dark:text-gray-400"
                                        >
                                            {{ $t('Phone') }}
                                        </th>
                                        <th
                                            class="hidden px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase md:table-cell dark:text-gray-400"
                                        >
                                            {{ $t('Currency') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Status') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Actions') }}
                                        </th>
                                    </tr>
                                </thead>
                                <tbody
                                    class="divide-y divide-gray-200 bg-white dark:divide-gray-700 dark:bg-gray-800"
                                >
                                    <tr v-if="filteredCountries.length === 0">
                                        <td
                                            colspan="7"
                                            class="px-6 py-12 text-center"
                                        >
                                            <Globe
                                                class="mx-auto h-12 w-12 text-gray-400"
                                            />
                                            <h3
                                                class="mt-2 text-sm font-medium text-gray-900 dark:text-white"
                                            >
                                                {{ $t('No countries found') }}
                                            </h3>
                                            <p
                                                class="mt-1 text-sm text-gray-500 dark:text-gray-400"
                                            >
                                                {{
                                                    $t(
                                                        'Try adjusting your search or filters.',
                                                    )
                                                }}
                                            </p>
                                        </td>
                                    </tr>
                                    <tr
                                        v-for="country in filteredCountries"
                                        :key="country.id"
                                        class="transition-colors hover:bg-gray-50 dark:hover:bg-gray-700/50"
                                    >
                                        <td class="w-12 px-6 py-4">
                                            <input
                                                type="checkbox"
                                                :value="country.id"
                                                v-model="countrySelectedIds"
                                                class="h-4 w-4 rounded border-gray-300 bg-white text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </td>
                                        <td
                                            class="px-6 py-4 text-sm font-medium whitespace-nowrap text-gray-900 uppercase dark:text-white"
                                        >
                                            {{ country.code }}
                                        </td>
                                        <td
                                            class="px-6 py-4 text-sm whitespace-nowrap text-gray-900 dark:text-white"
                                        >
                                            {{ country.name }}
                                        </td>
                                        <td
                                            class="hidden px-6 py-4 text-sm whitespace-nowrap text-gray-500 md:table-cell dark:text-gray-400"
                                        >
                                            {{ country.phone_code || '-' }}
                                        </td>
                                        <td
                                            class="hidden px-6 py-4 text-sm whitespace-nowrap text-gray-500 md:table-cell dark:text-gray-400"
                                        >
                                            {{ country.currency_code || '-' }}
                                            <span
                                                v-if="country.currency_symbol"
                                                class="ml-1 text-gray-400"
                                                >({{
                                                    country.currency_symbol
                                                }})</span
                                            >
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <button
                                                @click="
                                                    toggleCountryStatus(country)
                                                "
                                                :class="
                                                    country.is_active
                                                        ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                                                        : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
                                                "
                                                class="inline-flex cursor-pointer items-center rounded-full px-2.5 py-0.5 text-xs font-medium transition-opacity hover:opacity-75"
                                            >
                                                <span
                                                    class="mr-1.5 h-1.5 w-1.5 rounded-full"
                                                    :class="
                                                        country.is_active
                                                            ? 'bg-green-500'
                                                            : 'bg-gray-500'
                                                    "
                                                ></span>
                                                {{
                                                    $t(
                                                        country.is_active
                                                            ? 'Active'
                                                            : 'Inactive',
                                                    )
                                                }}
                                            </button>
                                        </td>
                                        <td
                                            class="space-x-2 px-6 py-4 text-right text-sm font-medium whitespace-nowrap"
                                        >
                                            <button
                                                @click="
                                                    openEditCountryModal(
                                                        country,
                                                    )
                                                "
                                                class="rounded-lg p-1.5 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:text-gray-400 dark:hover:bg-blue-900/20 dark:hover:text-blue-400"
                                                :title="$t('Edit')"
                                            >
                                                <Edit class="h-4 w-4" />
                                            </button>
                                            <button
                                                @click="
                                                    deleteTarget = {
                                                        type: 'country',
                                                        item: country,
                                                    };
                                                    showDeleteModal = true;
                                                "
                                                class="rounded-lg p-1.5 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-600 dark:text-gray-400 dark:hover:bg-red-900/20 dark:hover:text-red-400"
                                                :title="$t('Delete')"
                                            >
                                                <Trash2 class="h-4 w-4" />
                                            </button>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                        <p
                            class="mt-3 text-xs text-gray-400 dark:text-gray-500"
                        >
                            {{
                                $t('Showing {count} of {total} countries', {
                                    count: filteredCountries.length,
                                    total: countries.length,
                                })
                            }}
                        </p>
                    </div>

                    <!-- Languages Tab -->
                    <div v-show="activeTab === 'languages'">
                        <div
                            class="overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-700"
                        >
                            <table
                                class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                            >
                                <thead class="bg-gray-50 dark:bg-gray-700/50">
                                    <tr>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Code') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Name') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Native Name') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Direction') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Status') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Default') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Actions') }}
                                        </th>
                                    </tr>
                                </thead>
                                <tbody
                                    class="divide-y divide-gray-200 bg-white dark:divide-gray-700 dark:bg-gray-800"
                                >
                                    <tr
                                        v-for="locale in locales"
                                        :key="locale.id"
                                        class="transition-colors hover:bg-gray-50 dark:hover:bg-gray-700/50"
                                    >
                                        <td
                                            class="px-6 py-4 text-sm font-medium whitespace-nowrap text-gray-900 uppercase dark:text-white"
                                        >
                                            {{ locale.code }}
                                        </td>
                                        <td
                                            class="px-6 py-4 text-sm whitespace-nowrap text-gray-900 dark:text-white"
                                        >
                                            {{ locale.name }}
                                        </td>
                                        <td
                                            class="px-6 py-4 text-sm whitespace-nowrap text-gray-500 dark:text-gray-400"
                                        >
                                            {{ locale.native_name || '-' }}
                                        </td>
                                        <td
                                            class="px-6 py-4 text-sm whitespace-nowrap text-gray-900 dark:text-white"
                                        >
                                            {{ locale.direction.toUpperCase() }}
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <span
                                                :class="
                                                    locale.is_active
                                                        ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                                                        : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
                                                "
                                                class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium"
                                            >
                                                <span
                                                    class="mr-1.5 h-1.5 w-1.5 rounded-full"
                                                    :class="
                                                        locale.is_active
                                                            ? 'bg-green-500'
                                                            : 'bg-gray-500'
                                                    "
                                                ></span>
                                                {{
                                                    $t(
                                                        locale.is_active
                                                            ? 'Active'
                                                            : 'Inactive',
                                                    )
                                                }}
                                            </span>
                                        </td>
                                        <td
                                            class="px-6 py-4 text-sm whitespace-nowrap text-gray-900 dark:text-white"
                                        >
                                            <span
                                                v-if="locale.is_default"
                                                class="inline-flex items-center rounded bg-blue-50 px-2 py-1 text-xs font-medium text-blue-600 dark:bg-blue-900/20 dark:text-blue-400"
                                            >
                                                <Check class="mr-1 h-3 w-3" />
                                                {{ $t('Default') }}
                                            </span>
                                        </td>
                                        <td
                                            class="space-x-2 px-6 py-4 text-right text-sm font-medium whitespace-nowrap"
                                        >
                                            <button
                                                @click="
                                                    openEditLocaleModal(locale)
                                                "
                                                class="rounded-lg p-1.5 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:text-gray-400 dark:hover:bg-blue-900/20 dark:hover:text-blue-400"
                                                :title="$t('Edit')"
                                            >
                                                <Edit class="h-4 w-4" />
                                            </button>
                                            <button
                                                @click="deleteLocale(locale)"
                                                class="rounded-lg p-1.5 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-600 dark:text-gray-400 dark:hover:bg-red-900/20 dark:hover:text-red-400"
                                                :title="$t('Delete')"
                                            >
                                                <Trash2 class="h-4 w-4" />
                                            </button>
                                        </td>
                                    </tr>
                                    <tr v-if="locales.length === 0">
                                        <td
                                            colspan="7"
                                            class="px-6 py-12 text-center"
                                        >
                                            <Globe
                                                class="mx-auto h-12 w-12 text-gray-400"
                                            />
                                            <h3
                                                class="mt-2 text-sm font-medium text-gray-900 dark:text-white"
                                            >
                                                {{ $t('No languages') }}
                                            </h3>
                                            <p
                                                class="mt-1 text-sm text-gray-500 dark:text-gray-400"
                                            >
                                                {{
                                                    $t(
                                                        'Get started by creating a new language.',
                                                    )
                                                }}
                                            </p>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <!-- Currencies Tab -->
                    <div v-show="activeTab === 'currencies'">
                        <div
                            class="overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-700"
                        >
                            <table
                                class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                            >
                                <thead class="bg-gray-50 dark:bg-gray-700/50">
                                    <tr>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Code') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Name') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Symbol') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Position') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Exchange Rate') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Status') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Default') }}
                                        </th>
                                        <th
                                            class="px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                        >
                                            {{ $t('Actions') }}
                                        </th>
                                    </tr>
                                </thead>
                                <tbody
                                    class="divide-y divide-gray-200 bg-white dark:divide-gray-700 dark:bg-gray-800"
                                >
                                    <tr
                                        v-for="currency in currencies"
                                        :key="currency.id"
                                        class="transition-colors hover:bg-gray-50 dark:hover:bg-gray-700/50"
                                    >
                                        <td
                                            class="px-6 py-4 text-sm font-medium whitespace-nowrap text-gray-900 uppercase dark:text-white"
                                        >
                                            {{ currency.code }}
                                        </td>
                                        <td
                                            class="px-6 py-4 text-sm whitespace-nowrap text-gray-900 dark:text-white"
                                        >
                                            {{ currency.name }}
                                        </td>
                                        <td
                                            class="px-6 py-4 text-sm whitespace-nowrap text-gray-900 dark:text-white"
                                        >
                                            {{ currency.symbol }}
                                        </td>
                                        <td
                                            class="px-6 py-4 text-sm whitespace-nowrap text-gray-900 capitalize dark:text-white"
                                        >
                                            {{ currency.symbol_position }}
                                        </td>
                                        <td
                                            class="px-6 py-4 text-sm whitespace-nowrap text-gray-900 dark:text-white"
                                        >
                                            {{ currency.exchange_rate }}
                                        </td>
                                        <td class="px-6 py-4 whitespace-nowrap">
                                            <span
                                                :class="
                                                    currency.is_active
                                                        ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                                                        : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
                                                "
                                                class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium"
                                            >
                                                <span
                                                    class="mr-1.5 h-1.5 w-1.5 rounded-full"
                                                    :class="
                                                        currency.is_active
                                                            ? 'bg-green-500'
                                                            : 'bg-gray-500'
                                                    "
                                                ></span>
                                                {{
                                                    $t(
                                                        currency.is_active
                                                            ? 'Active'
                                                            : 'Inactive',
                                                    )
                                                }}
                                            </span>
                                        </td>
                                        <td
                                            class="px-6 py-4 text-sm whitespace-nowrap text-gray-900 dark:text-white"
                                        >
                                            <span
                                                v-if="currency.is_default"
                                                class="inline-flex items-center rounded bg-blue-50 px-2 py-1 text-xs font-medium text-blue-600 dark:bg-blue-900/20 dark:text-blue-400"
                                            >
                                                <Check class="mr-1 h-3 w-3" />
                                                {{ $t('Default') }}
                                            </span>
                                        </td>
                                        <td
                                            class="space-x-2 px-6 py-4 text-right text-sm font-medium whitespace-nowrap"
                                        >
                                            <button
                                                @click="
                                                    openEditCurrencyModal(
                                                        currency,
                                                    )
                                                "
                                                class="rounded-lg p-1.5 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:text-gray-400 dark:hover:bg-blue-900/20 dark:hover:text-blue-400"
                                                :title="$t('Edit')"
                                            >
                                                <Edit class="h-4 w-4" />
                                            </button>
                                            <button
                                                @click="
                                                    deleteCurrency(currency)
                                                "
                                                class="rounded-lg p-1.5 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-600 dark:text-gray-400 dark:hover:bg-red-900/20 dark:hover:text-red-400"
                                                :title="$t('Delete')"
                                            >
                                                <Trash2 class="h-4 w-4" />
                                            </button>
                                        </td>
                                    </tr>
                                    <tr v-if="currencies.length === 0">
                                        <td
                                            colspan="8"
                                            class="px-6 py-12 text-center"
                                        >
                                            <Coins
                                                class="mx-auto h-12 w-12 text-gray-400"
                                            />
                                            <h3
                                                class="mt-2 text-sm font-medium text-gray-900 dark:text-white"
                                            >
                                                {{ $t('No currencies') }}
                                            </h3>
                                            <p
                                                class="mt-1 text-sm text-gray-500 dark:text-gray-400"
                                            >
                                                {{
                                                    $t(
                                                        'Get started by creating a new currency.',
                                                    )
                                                }}
                                            </p>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Locale Modal -->
        <div
            v-if="showLocaleModal"
            class="fixed inset-0 z-50 flex items-center justify-center bg-gray-900/50 p-4 backdrop-blur-sm dark:bg-gray-900/80"
            @click.self="showLocaleModal = false"
        >
            <div
                class="flex max-h-[90vh] w-full max-w-md flex-col overflow-hidden rounded-2xl bg-white shadow-2xl dark:bg-gray-800"
            >
                <div
                    class="flex flex-shrink-0 items-center justify-between border-b border-gray-200 px-6 py-4 dark:border-gray-700"
                >
                    <div class="flex items-center gap-3">
                        <div
                            class="rounded-lg bg-blue-100 p-2 dark:bg-blue-900/30"
                        >
                            <Languages
                                class="h-5 w-5 text-blue-600 dark:text-blue-400"
                            />
                        </div>
                        <h3
                            class="text-lg font-semibold text-gray-900 dark:text-white"
                        >
                            {{
                                localeMode === 'add'
                                    ? $t('Add Language')
                                    : $t('Edit Language')
                            }}
                        </h3>
                    </div>
                    <button
                        type="button"
                        @click="showLocaleModal = false"
                        class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600 dark:text-gray-500 dark:hover:bg-gray-700 dark:hover:text-gray-300"
                    >
                        <X class="h-5 w-5" />
                    </button>
                </div>

                <div class="flex-1 space-y-4 overflow-y-auto px-6 py-6">
                    <div>
                        <label
                            class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >{{ $t('Language Code') }}
                            <span class="text-red-500">*</span></label
                        >
                        <input
                            v-model="localeForm.code"
                            type="text"
                            placeholder="en, es, fr..."
                            maxlength="10"
                            :class="[
                                'w-full rounded-xl border bg-white px-4 py-2.5 text-gray-900 shadow-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white',
                                errors.code
                                    ? 'border-red-500'
                                    : 'border-gray-300',
                            ]"
                        />
                        <p v-if="errors.code" class="mt-1 text-sm text-red-600">
                            {{ errors.code }}
                        </p>
                    </div>

                    <div>
                        <label
                            class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >{{ $t('Display Name') }}
                            <span class="text-red-500">*</span></label
                        >
                        <input
                            v-model="localeForm.name"
                            type="text"
                            placeholder="English, Spanish..."
                            :class="[
                                'w-full rounded-xl border bg-white px-4 py-2.5 text-gray-900 shadow-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white',
                                errors.name
                                    ? 'border-red-500'
                                    : 'border-gray-300',
                            ]"
                        />
                        <p v-if="errors.name" class="mt-1 text-sm text-red-600">
                            {{ errors.name }}
                        </p>
                    </div>

                    <div>
                        <label
                            class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >{{ $t('Native Name') }}</label
                        >
                        <input
                            v-model="localeForm.native_name"
                            type="text"
                            placeholder="Español, Français..."
                            :class="[
                                'w-full rounded-xl border bg-white px-4 py-2.5 text-gray-900 shadow-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white',
                                errors.native_name
                                    ? 'border-red-500'
                                    : 'border-gray-300',
                            ]"
                        />
                        <p
                            v-if="errors.native_name"
                            class="mt-1 text-sm text-red-600"
                        >
                            {{ errors.native_name }}
                        </p>
                    </div>

                    <div>
                        <label
                            class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >{{ $t('Text Direction') }}
                            <span class="text-red-500">*</span></label
                        >
                        <div class="relative">
                            <select
                                v-model="localeForm.direction"
                                :class="[
                                    'w-full appearance-none rounded-xl border bg-white px-4 py-2.5 text-gray-900 shadow-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white',
                                    errors.direction
                                        ? 'border-red-500'
                                        : 'border-gray-300',
                                ]"
                            >
                                <option value="ltr">
                                    {{ $t('Left to Right (LTR)') }}
                                </option>
                                <option value="rtl">
                                    {{ $t('Right to Left (RTL)') }}
                                </option>
                            </select>
                            <div
                                class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-gray-500"
                            >
                                <svg
                                    class="h-4 w-4"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="2"
                                        d="M19 9l-7 7-7-7"
                                    />
                                </svg>
                            </div>
                        </div>
                        <p
                            v-if="errors.direction"
                            class="mt-1 text-sm text-red-600"
                        >
                            {{ errors.direction }}
                        </p>
                    </div>

                    <div>
                        <label
                            class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >{{ $t('Sort Order') }}</label
                        >
                        <input
                            v-model.number="localeForm.sort_order"
                            type="number"
                            :class="[
                                'w-full rounded-xl border bg-white px-4 py-2.5 text-gray-900 shadow-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white',
                                errors.sort_order
                                    ? 'border-red-500'
                                    : 'border-gray-300',
                            ]"
                        />
                        <p
                            v-if="errors.sort_order"
                            class="mt-1 text-sm text-red-600"
                        >
                            {{ errors.sort_order }}
                        </p>
                    </div>

                    <div class="flex items-center space-x-6 pt-2">
                        <label class="flex cursor-pointer items-center">
                            <input
                                v-model="localeForm.is_active"
                                type="checkbox"
                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600"
                            />
                            <span
                                class="ml-2 text-sm text-gray-700 select-none dark:text-gray-300"
                                >{{ $t('Active') }}</span
                            >
                        </label>
                        <label class="flex cursor-pointer items-center">
                            <input
                                v-model="localeForm.is_default"
                                type="checkbox"
                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600"
                            />
                            <span
                                class="ml-2 text-sm text-gray-700 select-none dark:text-gray-300"
                                >{{ $t('Set as Default') }}</span
                            >
                        </label>
                    </div>
                </div>

                <div
                    class="flex flex-shrink-0 justify-end gap-3 border-t border-gray-200 bg-gray-50 px-6 py-4 dark:border-gray-700 dark:bg-gray-900/50"
                >
                    <button
                        @click="showLocaleModal = false"
                        class="rounded-xl border border-gray-300 bg-white px-5 py-2.5 font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                    >
                        {{ $t('Cancel') }}
                    </button>
                    <button
                        @click="saveLocale"
                        :disabled="localeProcessing"
                        class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        <Save v-if="!localeProcessing" class="mr-2 h-4 w-4" />
                        <svg
                            v-else
                            class="h-4 w-4 animate-spin"
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
                            $t(
                                localeProcessing
                                    ? 'Saving...'
                                    : localeMode === 'add'
                                      ? 'Add Language'
                                      : 'Save Changes',
                            )
                        }}
                    </button>
                </div>
            </div>
        </div>

        <!-- Country Modal -->
        <div
            v-if="showCountryModal"
            class="fixed inset-0 z-50 flex items-center justify-center bg-gray-900/50 p-4 backdrop-blur-sm dark:bg-gray-900/80"
            @click.self="showCountryModal = false"
        >
            <div
                class="flex max-h-[90vh] w-full max-w-lg flex-col overflow-hidden rounded-2xl bg-white shadow-2xl dark:bg-gray-800"
            >
                <div
                    class="flex flex-shrink-0 items-center justify-between border-b border-gray-200 px-6 py-4 dark:border-gray-700"
                >
                    <div class="flex items-center gap-3">
                        <div
                            class="rounded-lg bg-blue-100 p-2 dark:bg-blue-900/30"
                        >
                            <Globe
                                class="h-5 w-5 text-blue-600 dark:text-blue-400"
                            />
                        </div>
                        <h3
                            class="text-lg font-semibold text-gray-900 dark:text-white"
                        >
                            {{
                                countryMode === 'add'
                                    ? $t('Add Country')
                                    : $t('Edit Country')
                            }}
                        </h3>
                    </div>
                    <button
                        type="button"
                        @click="showCountryModal = false"
                        class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600 dark:text-gray-500 dark:hover:bg-gray-700 dark:hover:text-gray-300"
                    >
                        <X class="h-5 w-5" />
                    </button>
                </div>
                <div class="flex-1 space-y-4 overflow-y-auto px-6 py-6">
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label
                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Country Name') }}
                                <span class="text-red-500">*</span></label
                            >
                            <input
                                v-model="countryForm.name"
                                type="text"
                                placeholder="United States"
                                :class="[
                                    'w-full rounded-xl border bg-white px-4 py-2.5 text-gray-900 shadow-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white',
                                    errors.name
                                        ? 'border-red-500'
                                        : 'border-gray-300',
                                ]"
                            />
                            <p
                                v-if="errors.name"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors.name }}
                            </p>
                        </div>
                        <div>
                            <label
                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('ISO Code (2-char)') }}
                                <span class="text-red-500">*</span></label
                            >
                            <input
                                v-model="countryForm.code"
                                type="text"
                                placeholder="US"
                                maxlength="2"
                                :class="[
                                    'w-full rounded-xl border bg-white px-4 py-2.5 text-gray-900 uppercase shadow-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white',
                                    errors.code
                                        ? 'border-red-500'
                                        : 'border-gray-300',
                                ]"
                            />
                            <p
                                v-if="errors.code"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ errors.code }}
                            </p>
                        </div>
                    </div>
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label
                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('ISO Code (3-char)') }}</label
                            >
                            <input
                                v-model="countryForm.code3"
                                type="text"
                                placeholder="USA"
                                maxlength="3"
                                class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 text-gray-900 uppercase shadow-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            />
                        </div>
                        <div>
                            <label
                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Phone Code') }}</label
                            >
                            <input
                                v-model="countryForm.phone_code"
                                type="text"
                                placeholder="+1"
                                class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 text-gray-900 shadow-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            />
                        </div>
                    </div>
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label
                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Currency Code') }}</label
                            >
                            <input
                                v-model="countryForm.currency_code"
                                type="text"
                                placeholder="USD"
                                maxlength="3"
                                class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 text-gray-900 uppercase shadow-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            />
                        </div>
                        <div>
                            <label
                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Currency Symbol') }}</label
                            >
                            <input
                                v-model="countryForm.currency_symbol"
                                type="text"
                                placeholder="$"
                                class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 text-gray-900 shadow-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            />
                        </div>
                    </div>
                    <div class="flex items-center gap-6 pt-2">
                        <label class="flex cursor-pointer items-center">
                            <input
                                v-model="countryForm.is_active"
                                type="checkbox"
                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600"
                            />
                            <span
                                class="ml-2 text-sm text-gray-700 select-none dark:text-gray-300"
                                >{{ $t('Active') }}</span
                            >
                        </label>
                        <div>
                            <label
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Sort Order') }}</label
                            >
                            <input
                                v-model.number="countryForm.sort_order"
                                type="number"
                                class="w-24 rounded-xl border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            />
                        </div>
                    </div>
                </div>
                <div
                    class="flex flex-shrink-0 justify-end gap-3 border-t border-gray-200 bg-gray-50 px-6 py-4 dark:border-gray-700 dark:bg-gray-900/50"
                >
                    <button
                        @click="showCountryModal = false"
                        class="rounded-xl border border-gray-300 bg-white px-5 py-2.5 font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                    >
                        {{ $t('Cancel') }}
                    </button>
                    <button
                        @click="saveCountry"
                        :disabled="countryProcessing"
                        class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        <Save v-if="!countryProcessing" class="mr-2 h-4 w-4" />
                        <svg
                            v-else
                            class="h-4 w-4 animate-spin"
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
                            $t(
                                countryProcessing
                                    ? 'Saving...'
                                    : countryMode === 'add'
                                      ? 'Add Country'
                                      : 'Save Changes',
                            )
                        }}
                    </button>
                </div>
            </div>
        </div>

        <!-- Currency Modal -->
        <div
            v-if="showCurrencyModal"
            class="fixed inset-0 z-50 flex items-center justify-center bg-gray-900/50 p-4 backdrop-blur-sm dark:bg-gray-900/80"
            @click.self="showCurrencyModal = false"
        >
            <div
                class="flex max-h-[90vh] w-full max-w-md flex-col overflow-hidden rounded-2xl bg-white shadow-2xl dark:bg-gray-800"
            >
                <div
                    class="flex flex-shrink-0 items-center justify-between border-b border-gray-200 px-6 py-4 dark:border-gray-700"
                >
                    <div class="flex items-center gap-3">
                        <div
                            class="rounded-lg bg-blue-100 p-2 dark:bg-blue-900/30"
                        >
                            <Coins
                                class="h-5 w-5 text-blue-600 dark:text-blue-400"
                            />
                        </div>
                        <h3
                            class="text-lg font-semibold text-gray-900 dark:text-white"
                        >
                            {{
                                currencyMode === 'add'
                                    ? $t('Add Currency')
                                    : $t('Edit Currency')
                            }}
                        </h3>
                    </div>
                    <button
                        type="button"
                        @click="showCurrencyModal = false"
                        class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600 dark:text-gray-500 dark:hover:bg-gray-700 dark:hover:text-gray-300"
                    >
                        <X class="h-5 w-5" />
                    </button>
                </div>

                <div class="flex-1 space-y-4 overflow-y-auto px-6 py-6">
                    <div>
                        <label
                            class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >{{ $t('Currency Code') }}
                            <span class="text-red-500">*</span></label
                        >
                        <input
                            v-model="currencyForm.code"
                            type="text"
                            placeholder="USD, EUR, GBP..."
                            maxlength="10"
                            :class="[
                                'w-full rounded-xl border bg-white px-4 py-2.5 text-gray-900 shadow-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white',
                                errors.code
                                    ? 'border-red-500'
                                    : 'border-gray-300',
                            ]"
                        />
                        <p v-if="errors.code" class="mt-1 text-sm text-red-600">
                            {{ errors.code }}
                        </p>
                    </div>

                    <div>
                        <label
                            class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >{{ $t('Display Name') }}
                            <span class="text-red-500">*</span></label
                        >
                        <input
                            v-model="currencyForm.name"
                            type="text"
                            placeholder="US Dollar, Euro..."
                            :class="[
                                'w-full rounded-xl border bg-white px-4 py-2.5 text-gray-900 shadow-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white',
                                errors.name
                                    ? 'border-red-500'
                                    : 'border-gray-300',
                            ]"
                        />
                        <p v-if="errors.name" class="mt-1 text-sm text-red-600">
                            {{ errors.name }}
                        </p>
                    </div>

                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label
                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Symbol') }}
                                <span class="text-red-500">*</span></label
                            >
                            <input
                                v-model="currencyForm.symbol"
                                type="text"
                                placeholder="$, €, £..."
                                :class="[
                                    'w-full rounded-xl border bg-white px-4 py-2.5 text-gray-900 shadow-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white',
                                    errors.symbol
                                        ? 'border-red-500'
                                        : 'border-gray-300',
                                ]"
                            />
                        </div>
                        <div>
                            <label
                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Position') }}
                                <span class="text-red-500">*</span></label
                            >
                            <div class="relative">
                                <select
                                    v-model="currencyForm.symbol_position"
                                    :class="[
                                        'w-full appearance-none rounded-xl border bg-white px-4 py-2.5 text-gray-900 shadow-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white',
                                        errors.symbol_position
                                            ? 'border-red-500'
                                            : 'border-gray-300',
                                    ]"
                                >
                                    <option value="before">
                                        {{ $t('Before ($100)') }}
                                    </option>
                                    <option value="after">
                                        {{ $t('After (100€)') }}
                                    </option>
                                </select>
                                <div
                                    class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-gray-500"
                                >
                                    <svg
                                        class="h-4 w-4"
                                        fill="none"
                                        stroke="currentColor"
                                        viewBox="0 0 24 24"
                                    >
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            stroke-width="2"
                                            d="M19 9l-7 7-7-7"
                                        />
                                    </svg>
                                </div>
                            </div>
                        </div>
                    </div>
                    <p v-if="errors.symbol" class="mt-1 text-sm text-red-600">
                        {{ errors.symbol }}
                    </p>
                    <p
                        v-if="errors.symbol_position"
                        class="mt-1 text-sm text-red-600"
                    >
                        {{ errors.symbol_position }}
                    </p>

                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label
                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >{{ $t('Decimal Places') }}
                                <span class="text-red-500">*</span></label
                            >
                            <input
                                v-model.number="currencyForm.decimal_places"
                                type="number"
                                min="0"
                                max="10"
                                :class="[
                                    'w-full rounded-xl border bg-white px-4 py-2.5 text-gray-900 shadow-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white',
                                    errors.decimal_places
                                        ? 'border-red-500'
                                        : 'border-gray-300',
                                ]"
                            />
                        </div>
                        <div>
                            <label
                                class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Exchange Rate') }}
                                <span class="text-red-500">*</span>
                            </label>
                            <input
                                v-model.number="currencyForm.exchange_rate"
                                type="number"
                                step="0.0001"
                                :class="[
                                    'w-full rounded-xl border bg-white px-4 py-2.5 text-gray-900 shadow-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white',
                                    errors.exchange_rate
                                        ? 'border-red-500'
                                        : 'border-gray-300',
                                ]"
                            />
                            <!--
                                "Exchange Rate" on its own tells the owner nothing about
                                which way round the number goes, and getting it backwards
                                is the easiest way to set a rate that is wrong by a factor
                                of 71. The label says exactly what to type, and it comes
                                from the server so it can never disagree with the value
                                the model reads.
                            -->
                            <p
                                class="mt-1.5 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{ $t(exchangeRateLabel) }}
                                <span
                                    v-if="currencyForm.code === 'USD'"
                                    class="mt-0.5 block"
                                >
                                    {{
                                        $t(
                                            'Every price is stored in AFN. Changing this only changes what a shopper is shown when they choose USD.',
                                        )
                                    }}
                                </span>
                            </p>
                        </div>
                    </div>
                    <p
                        v-if="errors.decimal_places"
                        class="mt-1 text-sm text-red-600"
                    >
                        {{ errors.decimal_places }}
                    </p>
                    <p
                        v-if="errors.exchange_rate"
                        class="mt-1 text-sm text-red-600"
                    >
                        {{ errors.exchange_rate }}
                    </p>

                    <div>
                        <label
                            class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >{{ $t('Sort Order') }}</label
                        >
                        <input
                            v-model.number="currencyForm.sort_order"
                            type="number"
                            class="w-full rounded-xl border border-gray-300 bg-white px-4 py-2.5 text-gray-900 shadow-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                        />
                    </div>

                    <div class="flex items-center space-x-6 pt-2">
                        <label class="flex cursor-pointer items-center">
                            <input
                                v-model="currencyForm.is_active"
                                type="checkbox"
                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600"
                            />
                            <span
                                class="ml-2 text-sm text-gray-700 select-none dark:text-gray-300"
                                >{{ $t('Active') }}</span
                            >
                        </label>
                        <label class="flex cursor-pointer items-center">
                            <input
                                v-model="currencyForm.is_default"
                                type="checkbox"
                                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600"
                            />
                            <span
                                class="ml-2 text-sm text-gray-700 select-none dark:text-gray-300"
                                >{{ $t('Set as Default') }}</span
                            >
                        </label>
                    </div>
                </div>

                <div
                    class="flex flex-shrink-0 justify-end gap-3 border-t border-gray-200 bg-gray-50 px-6 py-4 dark:border-gray-700 dark:bg-gray-900/50"
                >
                    <button
                        @click="showCurrencyModal = false"
                        class="rounded-xl border border-gray-300 bg-white px-5 py-2.5 font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                    >
                        {{ $t('Cancel') }}
                    </button>
                    <button
                        @click="saveCurrency"
                        :disabled="currencyProcessing"
                        class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                        <Save v-if="!currencyProcessing" class="mr-2 h-4 w-4" />
                        <svg
                            v-else
                            class="h-4 w-4 animate-spin"
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
                            $t(
                                currencyProcessing
                                    ? 'Saving...'
                                    : currencyMode === 'add'
                                      ? 'Add Currency'
                                      : 'Save Changes',
                            )
                        }}
                    </button>
                </div>
            </div>
        </div>

        <!-- Delete Confirmation Modal -->
        <ConfirmDeleteModal
            v-model:show="showDeleteModal"
            :title="deleteTarget?.item?.name ?? deleteTarget?.item?.code ?? ''"
            :message="deleteConfirmMessage"
            @confirm="confirmDelete"
        />
    </AdminLayout>
</template>

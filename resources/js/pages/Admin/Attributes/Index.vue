<script setup lang="ts">
import AdminLayout from '@/layouts/AdminLayout.vue';
import * as attributeRoutes from '@/routes/admin/catalog/attributes';
import { useI18nStore } from '@/Stores/i18n';
import { Head, Link, router } from '@inertiajs/vue3';
import { debounce } from 'lodash';
import {
    ArrowDown,
    ArrowUp,
    ArrowUpDown,
    CheckCircle,
    Edit,
    Filter,
    List,
    MinusCircle,
    Plus,
    PlusCircle,
    Search,
    Trash2,
    X,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

interface Attribute {
    id: number;
    code: string;
    name: string;
    type:
        | 'text'
        | 'textarea'
        | 'select'
        | 'multiselect'
        | 'boolean'
        | 'date'
        | 'price'
        | 'number';
    is_required: boolean;
    is_filterable: boolean;
    is_configurable: boolean;
    sort_order: number;
    options_count: number;
    created_at: string;
}

interface PaginationLink {
    url: string | null;
    label: string;
    active: boolean;
}

interface Props {
    attributes: {
        data: Attribute[];
        current_page: number;
        last_page: number;
        per_page: number;
        total: number;
        links: PaginationLink[];
    };
    filters: {
        search?: string;
        type?: string;
        sort_by?: string;
        sort_order?: string;
    };
}

const props = defineProps<Props>();

const { t } = useI18nStore();

const search = ref(props.filters.search || '');
const typeFilter = ref(props.filters.type || '');
const sortBy = ref(props.filters.sort_by || 'sort_order');
const sortOrder = ref(props.filters.sort_order || 'asc');

const selectedAttributes = ref<number[]>([]);
const showDeleteModal = ref(false);
const attributeToDelete = ref<number | null>(null);
const showBulkDeleteModal = ref(false);
const expandedRows = ref<number[]>([]);

// Select all checkbox
const selectAll = computed({
    get: () =>
        selectedAttributes.value.length === props.attributes.data.length &&
        props.attributes.data.length > 0,
    set: (value: boolean) => {
        selectedAttributes.value = value
            ? props.attributes.data.map((attr) => attr.id)
            : [];
    },
});

// Row expansion
const toggleRow = (id: number) => {
    const index = expandedRows.value.indexOf(id);
    if (index === -1) {
        expandedRows.value.push(id);
    } else {
        expandedRows.value.splice(index, 1);
    }
};

// Debounced search
const performSearch = debounce(() => {
    applyFilters();
}, 300);

// Apply filters
const applyFilters = () => {
    router.get(
        attributeRoutes.index().url,
        {
            search: search.value || undefined,
            type: typeFilter.value || undefined,
            sort_by: sortBy.value,
            sort_order: sortOrder.value,
        },
        {
            preserveState: true,
            preserveScroll: true,
        },
    );
};

// Sort table
const sortTable = (column: string) => {
    if (sortBy.value === column) {
        sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
    } else {
        sortBy.value = column;
        sortOrder.value = 'asc';
    }
    applyFilters();
};

// Clear filters
const clearFilters = () => {
    search.value = '';
    typeFilter.value = '';
    sortBy.value = 'sort_order';
    sortOrder.value = 'asc';
    applyFilters();
};

// Delete attribute
const confirmDelete = (id: number) => {
    attributeToDelete.value = id;
    showDeleteModal.value = true;
};

const deleteAttribute = () => {
    if (attributeToDelete.value) {
        router.delete(attributeRoutes.destroy(attributeToDelete.value).url, {
            onSuccess: () => {
                showDeleteModal.value = false;
                attributeToDelete.value = null;
            },
        });
    }
};

// Bulk delete
const confirmBulkDelete = () => {
    if (selectedAttributes.value.length > 0) {
        showBulkDeleteModal.value = true;
    }
};

const bulkDelete = () => {
    if (selectedAttributes.value.length > 0) {
        router.post(
            attributeRoutes.bulkDestroy().url,
            {
                ids: selectedAttributes.value,
            },
            {
                onSuccess: () => {
                    selectedAttributes.value = [];
                    showBulkDeleteModal.value = false;
                },
            },
        );
    }
};

// Get type label
const getTypeLabel = (type: string): string => {
    const labels: Record<string, string> = {
        text: t('Text'),
        textarea: t('Textarea'),
        select: t('Select'),
        multiselect: t('Multi-select'),
        boolean: t('Boolean'),
        date: t('Date'),
        price: t('Price'),
        number: t('Number'),
    };
    return labels[type] || type;
};

// Get type badge color
const getTypeBadgeColor = (type: string): string => {
    const colors: Record<string, string> = {
        text: 'bg-blue-100 text-blue-800',
        textarea: 'bg-indigo-100 text-indigo-800',
        select: 'bg-green-100 text-green-800',
        multiselect: 'bg-emerald-100 text-emerald-800',
        boolean: 'bg-purple-100 text-purple-800',
        date: 'bg-pink-100 text-pink-800',
        price: 'bg-yellow-100 text-yellow-800',
        number: 'bg-orange-100 text-orange-800',
    };
    return colors[type] || 'bg-gray-100 text-gray-800';
};
</script>

<template>
    <Head :title="$t('Attributes')" />

    <AdminLayout :title="$t('Attributes')">
        <div class="space-y-6 p-6">
            <!-- Page Header -->
            <div class="flex items-center justify-between">
                <div>
                    <h1 class="text-2xl font-bold text-gray-900">
                        {{ $t('Attributes') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600">
                        {{ $t('Manage product attributes and their options') }}
                    </p>
                </div>
                <Link
                    :href="attributeRoutes.create().url"
                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                >
                    <Plus class="mr-2 h-4 w-4" />
                    {{ $t('Add Attribute') }}
                </Link>
            </div>

            <!-- Filters Card -->
            <div
                class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
                    <!-- Search -->
                    <div class="relative">
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Search') }}</label
                        >
                        <div class="relative">
                            <Search
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <input
                                v-model="search"
                                @input="performSearch"
                                type="text"
                                :placeholder="$t('Search by name or code...')"
                                class="w-full rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-4 pl-10 text-sm text-gray-900 transition-all placeholder:text-gray-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            />
                        </div>
                    </div>

                    <!-- Type Filter -->
                    <div>
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Type') }}</label
                        >
                        <div class="relative">
                            <Filter
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <select
                                v-model="typeFilter"
                                @change="applyFilters"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-10 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            >
                                <option value="">{{ $t('All Types') }}</option>
                                <option value="text">{{ $t('Text') }}</option>
                                <option value="textarea">
                                    {{ $t('Textarea') }}
                                </option>
                                <option value="select">
                                    {{ $t('Select') }}
                                </option>
                                <option value="multiselect">
                                    {{ $t('Multi-select') }}
                                </option>
                                <option value="boolean">
                                    {{ $t('Boolean') }}
                                </option>
                                <option value="date">{{ $t('Date') }}</option>
                                <option value="price">{{ $t('Price') }}</option>
                            </select>
                            <div
                                class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2"
                            >
                                <svg
                                    class="h-4 w-4 text-gray-400"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        stroke-width="2"
                                        d="M19 9l-7 7-7-7"
                                    ></path>
                                </svg>
                            </div>
                        </div>
                    </div>

                    <!-- Clear Filters Button -->
                    <div class="flex items-end">
                        <button
                            v-if="search || typeFilter"
                            @click="clearFilters"
                            class="flex w-full items-center justify-center gap-2 rounded-lg bg-gray-100 py-2.5 text-sm font-medium text-gray-600 transition-colors hover:bg-gray-200 hover:text-gray-900 dark:bg-gray-700 dark:text-gray-400 dark:hover:bg-gray-600 dark:hover:text-gray-200"
                        >
                            <X class="h-4 w-4" />
                            {{ $t('Clear Filters') }}
                        </button>
                    </div>
                </div>
            </div>

            <!-- Bulk Actions -->
            <transition
                enter-active-class="transition ease-out duration-200"
                enter-from-class="opacity-0 -translate-y-2"
                enter-to-class="opacity-100 translate-y-0"
                leave-active-class="transition ease-in duration-150"
                leave-from-class="opacity-100 translate-y-0"
                leave-to-class="opacity-0 -translate-y-2"
            >
                <div
                    v-if="selectedAttributes.length > 0"
                    class="sticky top-4 z-10 flex items-center justify-between rounded-xl bg-blue-600 p-3 px-6 text-white shadow-lg"
                >
                    <span class="flex items-center text-sm font-semibold">
                        <CheckCircle class="mr-2 h-4 w-4" />
                        {{
                            $t(
                                selectedAttributes.length === 1
                                    ? '{count} attribute selected'
                                    : '{count} attributes selected',
                                { count: selectedAttributes.length },
                            )
                        }}
                    </span>
                    <div class="flex gap-2">
                        <button
                            @click="confirmBulkDelete"
                            class="flex items-center rounded-lg bg-red-500 px-3 py-1.5 text-xs font-bold tracking-wide text-white uppercase transition-colors hover:bg-red-600"
                        >
                            <Trash2 class="mr-1.5 h-3 w-3" />
                            {{ $t('Delete Selected') }}
                        </button>
                    </div>
                </div>
            </transition>

            <!-- Table -->
            <div
                class="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div class="overflow-x-auto">
                    <table
                        class="min-w-full divide-y divide-gray-100 dark:divide-gray-700"
                    >
                        <thead class="bg-gray-50/80 dark:bg-gray-700/50">
                            <tr>
                                <th scope="col" class="w-12 px-6 py-4">
                                    <input
                                        type="checkbox"
                                        v-model="selectAll"
                                        class="h-4 w-4 rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </th>
                                <th
                                    scope="col"
                                    class="group cursor-pointer px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase transition-colors hover:text-blue-600 dark:text-gray-400 dark:hover:text-blue-400"
                                    @click="sortTable('name')"
                                >
                                    <div class="flex items-center gap-1">
                                        {{ $t('Name') }}
                                        <span
                                            v-if="sortBy === 'name'"
                                            class="text-blue-600 dark:text-blue-400"
                                        >
                                            <ArrowUp
                                                v-if="sortOrder === 'asc'"
                                                class="h-3 w-3"
                                            />
                                            <ArrowDown v-else class="h-3 w-3" />
                                        </span>
                                        <ArrowUpDown
                                            v-else
                                            class="h-3 w-3 opacity-0 group-hover:opacity-50"
                                        />
                                    </div>
                                </th>
                                <th
                                    scope="col"
                                    class="group hidden cursor-pointer px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase transition-colors hover:text-blue-600 md:table-cell dark:text-gray-400 dark:hover:text-blue-400"
                                    @click="sortTable('code')"
                                >
                                    <div class="flex items-center gap-1">
                                        {{ $t('Code') }}
                                        <span
                                            v-if="sortBy === 'code'"
                                            class="text-blue-600 dark:text-blue-400"
                                        >
                                            <ArrowUp
                                                v-if="sortOrder === 'asc'"
                                                class="h-3 w-3"
                                            />
                                            <ArrowDown v-else class="h-3 w-3" />
                                        </span>
                                        <ArrowUpDown
                                            v-else
                                            class="h-3 w-3 opacity-0 group-hover:opacity-50"
                                        />
                                    </div>
                                </th>
                                <th
                                    scope="col"
                                    class="px-6 py-4 text-left text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Type') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-4 text-center text-xs font-semibold tracking-wider text-gray-500 uppercase lg:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Options') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-4 text-center text-xs font-semibold tracking-wider text-gray-500 uppercase lg:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Required') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-4 text-center text-xs font-semibold tracking-wider text-gray-500 uppercase xl:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Filterable') }}
                                </th>
                                <th
                                    scope="col"
                                    class="hidden px-6 py-4 text-center text-xs font-semibold tracking-wider text-gray-500 uppercase xl:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Configurable') }}
                                </th>
                                <th
                                    scope="col"
                                    class="px-6 py-4 text-right text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Actions') }}
                                </th>
                            </tr>
                        </thead>
                        <tbody
                            class="divide-y divide-gray-100 bg-white dark:divide-gray-700 dark:bg-gray-800"
                        >
                            <template
                                v-for="attribute in attributes.data"
                                :key="attribute.id"
                            >
                                <tr
                                    class="group transition-colors hover:bg-blue-50/50 dark:hover:bg-blue-900/10"
                                >
                                    <td class="relative px-6 py-4">
                                        <div class="flex items-center">
                                            <button
                                                @click="toggleRow(attribute.id)"
                                                class="absolute left-2 p-1 text-blue-600 hover:text-blue-800 focus:outline-none lg:hidden"
                                            >
                                                <MinusCircle
                                                    v-if="
                                                        expandedRows.includes(
                                                            attribute.id,
                                                        )
                                                    "
                                                    class="h-5 w-5 fill-blue-100 dark:fill-blue-900/30"
                                                />
                                                <PlusCircle
                                                    v-else
                                                    class="h-5 w-5 fill-blue-50 dark:fill-blue-900/20"
                                                />
                                            </button>
                                            <input
                                                type="checkbox"
                                                :value="attribute.id"
                                                v-model="selectedAttributes"
                                                class="ml-4 h-4 w-4 cursor-pointer rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 lg:ml-0 dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <div
                                            class="text-sm font-bold text-gray-900 transition-colors group-hover:text-blue-600 dark:text-white dark:group-hover:text-blue-400"
                                        >
                                            {{ attribute.name }}
                                        </div>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 whitespace-nowrap md:table-cell"
                                    >
                                        <code
                                            class="rounded border border-gray-200 bg-gray-100 px-2 py-1 font-mono text-xs text-gray-600 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-400"
                                            >{{ attribute.code }}</code
                                        >
                                    </td>
                                    <td class="px-6 py-4 whitespace-nowrap">
                                        <span
                                            :class="[
                                                'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium shadow-sm',
                                                getTypeBadgeColor(
                                                    attribute.type,
                                                ),
                                            ]"
                                        >
                                            {{ getTypeLabel(attribute.type) }}
                                        </span>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 text-center text-sm whitespace-nowrap text-gray-500 lg:table-cell dark:text-gray-400"
                                    >
                                        <span
                                            v-if="
                                                [
                                                    'select',
                                                    'multiselect',
                                                ].includes(attribute.type)
                                            "
                                            class="inline-flex items-center rounded border border-gray-200 bg-gray-50 px-2 py-0.5 font-mono text-xs dark:border-gray-700 dark:bg-gray-800"
                                        >
                                            {{ attribute.options_count }}
                                        </span>
                                        <span
                                            v-else
                                            class="text-gray-300 dark:text-gray-600"
                                            >-</span
                                        >
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 text-center whitespace-nowrap lg:table-cell"
                                    >
                                        <span
                                            v-if="attribute.is_required"
                                            class="inline-flex items-center justify-center rounded-full bg-green-50 p-1 text-green-600 dark:bg-green-900/20 dark:text-green-400"
                                        >
                                            <CheckCircle class="h-4 w-4" />
                                        </span>
                                        <span
                                            v-else
                                            class="text-gray-300 dark:text-gray-600"
                                        >
                                            <MinusCircle class="h-4 w-4" />
                                        </span>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 text-center whitespace-nowrap xl:table-cell"
                                    >
                                        <span
                                            v-if="attribute.is_filterable"
                                            class="inline-flex items-center justify-center rounded-full bg-green-50 p-1 text-green-600 dark:bg-green-900/20 dark:text-green-400"
                                        >
                                            <CheckCircle class="h-4 w-4" />
                                        </span>
                                        <span
                                            v-else
                                            class="text-gray-300 dark:text-gray-600"
                                        >
                                            <MinusCircle class="h-4 w-4" />
                                        </span>
                                    </td>
                                    <td
                                        class="hidden px-6 py-4 text-center whitespace-nowrap xl:table-cell"
                                    >
                                        <span
                                            v-if="attribute.is_configurable"
                                            class="inline-flex items-center justify-center rounded-full bg-green-50 p-1 text-green-600 dark:bg-green-900/20 dark:text-green-400"
                                        >
                                            <CheckCircle class="h-4 w-4" />
                                        </span>
                                        <span
                                            v-else
                                            class="text-gray-300 dark:text-gray-600"
                                        >
                                            <MinusCircle class="h-4 w-4" />
                                        </span>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right text-sm font-medium whitespace-nowrap"
                                    >
                                        <div
                                            class="flex items-center justify-end gap-2 opacity-60 transition-opacity group-hover:opacity-100"
                                        >
                                            <Link
                                                :href="
                                                    attributeRoutes.edit(
                                                        attribute.id,
                                                    ).url
                                                "
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-900/20"
                                                :title="$t('Edit')"
                                            >
                                                <Edit class="h-4 w-4" />
                                            </Link>
                                            <button
                                                @click="
                                                    confirmDelete(attribute.id)
                                                "
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-900/20"
                                                :title="$t('Delete')"
                                            >
                                                <Trash2 class="h-4 w-4" />
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                                <!-- Expanded Mobile Row -->
                                <tr
                                    v-if="expandedRows.includes(attribute.id)"
                                    class="bg-gray-50/50 lg:hidden dark:bg-gray-900/50"
                                >
                                    <td
                                        colspan="9"
                                        class="border-t border-gray-100 px-6 py-4 dark:border-gray-700"
                                    >
                                        <div
                                            class="grid grid-cols-2 gap-4 text-sm"
                                        >
                                            <div
                                                class="flex flex-col gap-1 md:hidden"
                                            >
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Code') }}</span
                                                >
                                                <code
                                                    class="w-fit rounded border border-gray-200 bg-gray-100 px-2 py-1 font-mono text-xs text-gray-600 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-400"
                                                    >{{ attribute.code }}</code
                                                >
                                            </div>
                                            <div class="flex flex-col gap-1">
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Options') }}</span
                                                >
                                                <span
                                                    v-if="
                                                        [
                                                            'select',
                                                            'multiselect',
                                                        ].includes(
                                                            attribute.type,
                                                        )
                                                    "
                                                    class="font-medium text-gray-900 dark:text-gray-100"
                                                >
                                                    {{
                                                        $t('{count} options', {
                                                            count: attribute.options_count,
                                                        })
                                                    }}
                                                </span>
                                                <span
                                                    v-else
                                                    class="text-gray-400 italic"
                                                    >{{ $t('N/A') }}</span
                                                >
                                            </div>
                                            <div class="flex flex-col gap-1">
                                                <span
                                                    class="text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{ $t('Settings') }}</span
                                                >
                                                <div
                                                    class="flex flex-wrap gap-2"
                                                >
                                                    <span
                                                        v-if="
                                                            attribute.is_required
                                                        "
                                                        class="inline-flex items-center rounded border border-green-100 bg-green-50 px-1.5 py-0.5 text-[10px] text-green-700"
                                                        >{{
                                                            $t('Required')
                                                        }}</span
                                                    >
                                                    <span
                                                        v-if="
                                                            attribute.is_filterable
                                                        "
                                                        class="inline-flex items-center rounded border border-blue-100 bg-blue-50 px-1.5 py-0.5 text-[10px] text-blue-700"
                                                        >{{
                                                            $t('Filterable')
                                                        }}</span
                                                    >
                                                    <span
                                                        v-if="
                                                            attribute.is_configurable
                                                        "
                                                        class="inline-flex items-center rounded border border-purple-100 bg-purple-50 px-1.5 py-0.5 text-[10px] text-purple-700"
                                                        >{{
                                                            $t('Configurable')
                                                        }}</span
                                                    >
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                            </template>
                            <tr v-if="attributes.data.length === 0">
                                <td
                                    colspan="9"
                                    class="px-6 py-16 text-center text-gray-500 dark:text-gray-400"
                                >
                                    <div class="flex flex-col items-center">
                                        <div
                                            class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-50 text-gray-400 dark:bg-gray-700"
                                        >
                                            <List class="h-8 w-8" />
                                        </div>
                                        <p
                                            class="text-lg font-semibold text-gray-900 dark:text-white"
                                        >
                                            {{ $t('No attributes found') }}
                                        </p>
                                        <p
                                            class="mt-1 max-w-sm text-sm text-gray-500 dark:text-gray-400"
                                        >
                                            {{
                                                $t(
                                                    'Get started by creating your first attribute.',
                                                )
                                            }}
                                        </p>
                                    </div>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <!-- Pagination -->
                <div
                    v-if="attributes.total > attributes.per_page"
                    class="flex items-center justify-between border-t border-gray-200 bg-white px-4 py-3 sm:px-6"
                >
                    <div class="flex flex-1 justify-between sm:hidden">
                        <Link
                            v-if="attributes.current_page > 1"
                            :href="attributes.links[0].url || '#'"
                            class="relative inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
                        >
                            {{ $t('Previous') }}
                        </Link>
                        <Link
                            v-if="
                                attributes.current_page < attributes.last_page
                            "
                            :href="
                                attributes.links[attributes.links.length - 1]
                                    .url || '#'
                            "
                            class="relative ml-3 inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
                        >
                            {{ $t('Next') }}
                        </Link>
                    </div>
                    <div
                        class="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between"
                    >
                        <div>
                            <p class="text-sm text-gray-700">
                                {{ $t('Showing') }}
                                <span class="font-medium">{{
                                    (attributes.current_page - 1) *
                                        attributes.per_page +
                                    1
                                }}</span>
                                {{ $t('to') }}
                                <span class="font-medium">{{
                                    Math.min(
                                        attributes.current_page *
                                            attributes.per_page,
                                        attributes.total,
                                    )
                                }}</span>
                                {{ $t('of') }}
                                <span class="font-medium">{{
                                    attributes.total
                                }}</span>
                                {{ $t('results') }}
                            </p>
                        </div>
                        <div>
                            <nav
                                class="relative z-0 inline-flex -space-x-px rounded-md shadow-sm"
                            >
                                <Link
                                    v-for="(link, index) in attributes.links"
                                    :key="index"
                                    :href="link.url || '#'"
                                    :class="[
                                        'relative inline-flex items-center border px-4 py-2 text-sm font-medium',
                                        link.active
                                            ? 'z-10 border-blue-500 bg-blue-50 text-blue-600'
                                            : 'border-gray-300 bg-white text-gray-500 hover:bg-gray-50',
                                        index === 0 ? 'rounded-l-md' : '',
                                        index === attributes.links.length - 1
                                            ? 'rounded-r-md'
                                            : '',
                                    ]"
                                >
                                    <span v-html="link.label" />
                                </Link>
                            </nav>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Delete Confirmation Modal -->
        <div
            v-if="showDeleteModal"
            class="fixed inset-0 z-50 bg-gray-500/75 transition-opacity dark:bg-gray-900/75"
            @click="showDeleteModal = false"
        >
            <div class="fixed inset-0 z-50 overflow-y-auto">
                <div
                    class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0"
                >
                    <div
                        class="relative transform overflow-hidden rounded-lg bg-white text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg"
                        @click.stop
                    >
                        <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                            <div class="sm:flex sm:items-start">
                                <div
                                    class="mx-auto flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-red-100 sm:mx-0 sm:h-10 sm:w-10"
                                >
                                    <svg
                                        class="h-6 w-6 text-red-600"
                                        fill="none"
                                        viewBox="0 0 24 24"
                                        stroke-width="1.5"
                                        stroke="currentColor"
                                    >
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z"
                                        />
                                    </svg>
                                </div>
                                <div
                                    class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left"
                                >
                                    <h3
                                        class="text-base leading-6 font-semibold text-gray-900"
                                    >
                                        {{ $t('Delete Attribute') }}
                                    </h3>
                                    <div class="mt-2">
                                        <p class="text-sm text-gray-500">
                                            {{
                                                $t(
                                                    'Are you sure you want to delete this attribute? This action cannot be undone.',
                                                )
                                            }}
                                        </p>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div
                            class="bg-gray-50 px-4 py-3 sm:flex sm:flex-row-reverse sm:px-6"
                        >
                            <button
                                @click="deleteAttribute"
                                type="button"
                                class="inline-flex w-full cursor-pointer justify-center rounded-md bg-red-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-500 sm:ml-3 sm:w-auto"
                            >
                                {{ $t('Delete') }}
                            </button>
                            <button
                                @click="showDeleteModal = false"
                                type="button"
                                class="mt-3 inline-flex w-full cursor-pointer justify-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-gray-300 ring-inset hover:bg-gray-50 sm:mt-0 sm:w-auto"
                            >
                                {{ $t('Cancel') }}
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Bulk Delete Confirmation Modal -->
        <div
            v-if="showBulkDeleteModal"
            class="fixed inset-0 z-50 bg-gray-500/75 transition-opacity dark:bg-gray-900/75"
            @click="showBulkDeleteModal = false"
        >
            <div class="fixed inset-0 z-50 overflow-y-auto">
                <div
                    class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0"
                >
                    <div
                        class="relative transform overflow-hidden rounded-lg bg-white text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg"
                        @click.stop
                    >
                        <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                            <div class="sm:flex sm:items-start">
                                <div
                                    class="mx-auto flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-red-100 sm:mx-0 sm:h-10 sm:w-10"
                                >
                                    <svg
                                        class="h-6 w-6 text-red-600"
                                        fill="none"
                                        viewBox="0 0 24 24"
                                        stroke-width="1.5"
                                        stroke="currentColor"
                                    >
                                        <path
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                            d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z"
                                        />
                                    </svg>
                                </div>
                                <div
                                    class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left"
                                >
                                    <h3
                                        class="text-base leading-6 font-semibold text-gray-900"
                                    >
                                        {{ $t('Delete Multiple Attributes') }}
                                    </h3>
                                    <div class="mt-2">
                                        <p class="text-sm text-gray-500">
                                            {{
                                                $t(
                                                    'Are you sure you want to delete {count} selected {noun}? This action cannot be undone.',
                                                    {
                                                        count: selectedAttributes.length,
                                                        noun: $t(
                                                            selectedAttributes.length ===
                                                                1
                                                                ? 'attribute'
                                                                : 'attributes',
                                                        ),
                                                    },
                                                )
                                            }}
                                        </p>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div
                            class="bg-gray-50 px-4 py-3 sm:flex sm:flex-row-reverse sm:px-6"
                        >
                            <button
                                @click="bulkDelete"
                                type="button"
                                class="inline-flex w-full cursor-pointer justify-center rounded-md bg-red-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-500 sm:ml-3 sm:w-auto"
                            >
                                {{ $t('Delete All') }}
                            </button>
                            <button
                                @click="showBulkDeleteModal = false"
                                type="button"
                                class="mt-3 inline-flex w-full cursor-pointer justify-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-gray-300 ring-inset hover:bg-gray-50 sm:mt-0 sm:w-auto"
                            >
                                {{ $t('Cancel') }}
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

<script setup lang="ts">
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import { Head, router } from '@inertiajs/vue3';
import {
    ArrowUpDown,
    Download,
    Filter,
    Mail,
    Search,
    Trash2,
    UserCheck,
    Users,
    UserX,
    X,
} from 'lucide-vue-next';
import { computed, ref, watch } from 'vue';

interface Subscriber {
    id: number;
    first_name: string;
    last_name: string;
    email: string;
    is_guest: boolean;
    updated_at: string;
}

interface PaginatedSubscribers {
    data: Subscriber[];
    current_page: number;
    last_page: number;
    per_page: number;
    total: number;
    from: number | null;
    to: number | null;
    links: { url: string | null; label: string; active: boolean }[];
}

interface Stats {
    total: number;
    registered: number;
    guest: number;
}

const props = defineProps<{
    subscribers: PaginatedSubscribers;
    filters: {
        search?: string;
        type?: string;
        sort_by?: string;
        sort_order?: string;
    };
    stats: Stats;
}>();

const search = ref(props.filters.search || '');
const typeFilter = ref(props.filters.type || '');
const sortBy = ref(props.filters.sort_by || 'updated_at');
const sortOrder = ref(props.filters.sort_order || 'desc');

const showFilters = ref(false);
const selectAll = ref(false);
const selectedIds = ref<number[]>([]);

const applyFilters = () => {
    router.get(
        '/admin/marketing/newsletters',
        {
            search: search.value || undefined,
            type: typeFilter.value || undefined,
            sort_by: sortBy.value,
            sort_order: sortOrder.value,
        },
        { preserveState: true, preserveScroll: true },
    );
};

const clearFilters = () => {
    search.value = '';
    typeFilter.value = '';
    sortBy.value = 'updated_at';
    sortOrder.value = 'desc';
    applyFilters();
};

watch(search, (val, old) => {
    if (val === '' && old !== '') applyFilters();
});

const hasActiveFilters = computed(() => !!(search.value || typeFilter.value));

const toggleSort = (field: string) => {
    if (sortBy.value === field) {
        sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
    } else {
        sortBy.value = field;
        sortOrder.value = 'asc';
    }
    applyFilters();
};

// Selection
const toggleSelectAll = () => {
    selectAll.value = !selectAll.value;
    selectedIds.value = selectAll.value
        ? props.subscribers.data.map((s) => s.id)
        : [];
};
const toggleSelect = (id: number) => {
    if (selectedIds.value.includes(id)) {
        selectedIds.value = selectedIds.value.filter((i) => i !== id);
    } else {
        selectedIds.value = [...selectedIds.value, id];
    }
    selectAll.value =
        selectedIds.value.length === props.subscribers.data.length;
};

// Unsubscribe single
const unsubscribe = (id: number) => {
    if (!confirm('Remove this subscriber from the newsletter list?')) return;
    router.delete(`/admin/marketing/newsletters/${id}`, {
        preserveScroll: true,
        onSuccess: () => {
            selectedIds.value = selectedIds.value.filter((i) => i !== id);
        },
    });
};

// Bulk unsubscribe
const bulkUnsubscribe = () => {
    if (!selectedIds.value.length) return;
    if (
        !confirm(
            `Remove ${selectedIds.value.length} subscriber(s) from the newsletter list?`,
        )
    )
        return;
    router.post(
        '/admin/marketing/newsletters/bulk-unsubscribe',
        { ids: selectedIds.value },
        {
            preserveScroll: true,
            onSuccess: () => {
                selectedIds.value = [];
                selectAll.value = false;
            },
        },
    );
};

// CSV export (passes current filters)
const exportUrl = computed(() => {
    const params = new URLSearchParams();
    if (search.value) params.set('search', search.value);
    if (typeFilter.value) params.set('type', typeFilter.value);
    return '/admin/marketing/newsletters/export?' + params.toString();
});
</script>

<template>
    <AdminLayout>
        <Head :title="$t('Newsletter Subscribers')" />

        <div class="space-y-6">
            <!-- Page Header -->
            <div
                class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between"
            >
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-gray-100"
                    >
                        {{ $t('Newsletter Subscribers') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                        {{ $t('Manage all email newsletter subscribers') }}
                    </p>
                </div>
                <div class="flex items-center gap-3">
                    <a
                        :href="exportUrl"
                        class="inline-flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                    >
                        <Download class="h-4 w-4" />
                        {{ $t('Export CSV') }}
                    </a>
                </div>
            </div>

            <!-- Stats Cards -->
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
                <div
                    class="flex items-center gap-4 rounded-xl border border-gray-200 bg-white p-5 dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="rounded-lg bg-blue-50 p-3">
                        <Mail class="h-5 w-5 text-blue-600" />
                    </div>
                    <div>
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                            {{ $t('Total Subscribers') }}
                        </p>
                        <p
                            class="text-2xl font-bold text-gray-900 dark:text-gray-100"
                        >
                            {{ stats.total.toLocaleString() }}
                        </p>
                    </div>
                </div>
                <div
                    class="flex items-center gap-4 rounded-xl border border-gray-200 bg-white p-5 dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="rounded-lg bg-green-50 p-3">
                        <UserCheck class="h-5 w-5 text-green-600" />
                    </div>
                    <div>
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                            {{ $t('Registered') }}
                        </p>
                        <p
                            class="text-2xl font-bold text-gray-900 dark:text-gray-100"
                        >
                            {{ stats.registered.toLocaleString() }}
                        </p>
                    </div>
                </div>
                <div
                    class="flex items-center gap-4 rounded-xl border border-gray-200 bg-white p-5 dark:border-gray-700 dark:bg-gray-800"
                >
                    <div class="rounded-lg bg-orange-50 p-3">
                        <Users class="h-5 w-5 text-orange-600" />
                    </div>
                    <div>
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                            {{ $t('Guest') }}
                        </p>
                        <p
                            class="text-2xl font-bold text-gray-900 dark:text-gray-100"
                        >
                            {{ stats.guest.toLocaleString() }}
                        </p>
                    </div>
                </div>
            </div>

            <!-- Toolbar -->
            <div
                class="rounded-xl border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-800"
            >
                <div class="flex flex-col gap-3 p-4 sm:flex-row">
                    <!-- Search -->
                    <div class="relative flex-1">
                        <Search
                            class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                        />
                        <input
                            v-model="search"
                            type="text"
                            :placeholder="$t('Search by name or email…')"
                            class="w-full rounded-lg border border-gray-300 py-2 pr-4 pl-9 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            @keyup.enter="applyFilters"
                        />
                    </div>

                    <div class="flex items-center gap-2">
                        <button
                            class="inline-flex items-center gap-2 rounded-lg border px-3 py-2 text-sm font-medium transition-colors"
                            :class="
                                showFilters || hasActiveFilters
                                    ? 'border-blue-300 bg-blue-50 text-blue-700'
                                    : 'border-gray-300 bg-white text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700'
                            "
                            @click="showFilters = !showFilters"
                        >
                            <Filter class="h-4 w-4" />
                            {{ $t('Filters') }}
                            <span
                                v-if="hasActiveFilters"
                                class="h-2 w-2 rounded-full bg-blue-500"
                            />
                        </button>

                        <button
                            class="inline-flex items-center gap-2 rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700"
                            @click="applyFilters"
                        >
                            {{ $t('Search') }}
                        </button>
                    </div>
                </div>

                <!-- Expanded Filters -->
                <div
                    v-if="showFilters"
                    class="flex flex-wrap gap-4 border-t border-gray-100 px-4 pt-4 pb-4"
                >
                    <div>
                        <label
                            class="mb-1 block text-xs font-medium text-gray-700 dark:text-gray-300"
                            >{{ $t('Type') }}</label
                        >
                        <select
                            v-model="typeFilter"
                            class="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            @change="applyFilters"
                        >
                            <option value="">{{ $t('All') }}</option>
                            <option value="registered">
                                {{ $t('Registered') }}
                            </option>
                            <option value="guest">{{ $t('Guest') }}</option>
                        </select>
                    </div>

                    <div v-if="hasActiveFilters" class="flex items-end">
                        <button
                            class="inline-flex items-center gap-1 rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-600 transition-colors hover:bg-gray-50 hover:text-gray-900 dark:border-gray-600 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-gray-100"
                            @click="clearFilters"
                        >
                            <X class="h-3 w-3" />
                            {{ $t('Clear') }}
                        </button>
                    </div>
                </div>

                <!-- Bulk Action Bar -->
                <div
                    v-if="selectedIds.length"
                    class="flex items-center justify-between border-t border-blue-100 bg-blue-50 px-4 py-3"
                >
                    <span class="text-sm font-medium text-blue-700">{{
                        $t('{count} selected', { count: selectedIds.length })
                    }}</span>
                    <button
                        class="inline-flex items-center gap-2 rounded-lg border border-red-200 bg-white px-3 py-1.5 text-sm font-medium text-red-700 transition-colors hover:bg-red-50 dark:bg-gray-800"
                        @click="bulkUnsubscribe"
                    >
                        <UserX class="h-4 w-4" />
                        {{ $t('Unsubscribe Selected') }}
                    </button>
                </div>

                <!-- Table -->
                <div class="overflow-x-auto">
                    <table class="w-full text-sm">
                        <thead
                            class="border-t border-b border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-700/50"
                        >
                            <tr>
                                <th class="w-10 px-4 py-3 text-left">
                                    <input
                                        type="checkbox"
                                        :checked="selectAll"
                                        class="rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                        @change="toggleSelectAll"
                                    />
                                </th>
                                <th
                                    class="px-4 py-3 text-left font-medium text-gray-700 dark:text-gray-300"
                                >
                                    <button
                                        class="inline-flex items-center gap-1 hover:text-gray-900 dark:hover:text-gray-100"
                                        @click="toggleSort('first_name')"
                                    >
                                        {{ $t('Name') }}
                                        <ArrowUpDown class="h-3 w-3" />
                                    </button>
                                </th>
                                <th
                                    class="px-4 py-3 text-left font-medium text-gray-700 dark:text-gray-300"
                                >
                                    <button
                                        class="inline-flex items-center gap-1 hover:text-gray-900 dark:hover:text-gray-100"
                                        @click="toggleSort('email')"
                                    >
                                        {{ $t('Email') }}
                                        <ArrowUpDown class="h-3 w-3" />
                                    </button>
                                </th>
                                <th
                                    class="px-4 py-3 text-left font-medium text-gray-700 dark:text-gray-300"
                                >
                                    {{ $t('Type') }}
                                </th>
                                <th
                                    class="px-4 py-3 text-left font-medium text-gray-700 dark:text-gray-300"
                                >
                                    <button
                                        class="inline-flex items-center gap-1 hover:text-gray-900 dark:hover:text-gray-100"
                                        @click="toggleSort('updated_at')"
                                    >
                                        {{ $t('Subscribed') }}
                                        <ArrowUpDown class="h-3 w-3" />
                                    </button>
                                </th>
                                <th
                                    class="px-4 py-3 text-right font-medium text-gray-700 dark:text-gray-300"
                                >
                                    {{ $t('Actions') }}
                                </th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-gray-100">
                            <tr v-if="!subscribers.data.length">
                                <td
                                    colspan="6"
                                    class="px-4 py-16 text-center text-gray-400"
                                >
                                    <Mail
                                        class="mx-auto mb-3 h-10 w-10 text-gray-300"
                                    />
                                    <p class="font-medium">
                                        {{ $t('No subscribers found') }}
                                    </p>
                                    <p class="mt-1 text-sm">
                                        {{
                                            $t(
                                                'Try adjusting your search or filters.',
                                            )
                                        }}
                                    </p>
                                </td>
                            </tr>
                            <tr
                                v-for="sub in subscribers.data"
                                :key="sub.id"
                                class="transition-colors hover:bg-gray-50 dark:hover:bg-gray-700"
                            >
                                <td class="px-4 py-3">
                                    <input
                                        type="checkbox"
                                        :checked="selectedIds.includes(sub.id)"
                                        class="rounded border-gray-300 text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                        @change="toggleSelect(sub.id)"
                                    />
                                </td>
                                <td
                                    class="px-4 py-3 font-medium text-gray-900 dark:text-gray-100"
                                >
                                    {{ sub.first_name }} {{ sub.last_name }}
                                </td>
                                <td
                                    class="px-4 py-3 text-gray-600 dark:text-gray-400"
                                >
                                    {{ sub.email }}
                                </td>
                                <td class="px-4 py-3">
                                    <span
                                        class="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium"
                                        :class="
                                            sub.is_guest
                                                ? 'bg-orange-100 text-orange-700'
                                                : 'bg-green-100 text-green-700'
                                        "
                                    >
                                        {{
                                            sub.is_guest
                                                ? $t('Guest')
                                                : $t('Registered')
                                        }}
                                    </span>
                                </td>
                                <td
                                    class="px-4 py-3 text-gray-500 dark:text-gray-400"
                                >
                                    <DateDisplay :value="sub.updated_at" />
                                </td>
                                <td class="px-4 py-3 text-right">
                                    <button
                                        class="inline-flex items-center gap-1 rounded-lg border border-red-200 px-3 py-1 text-xs font-medium text-red-600 transition-colors hover:border-red-300 hover:bg-red-50 hover:text-red-800"
                                        @click="unsubscribe(sub.id)"
                                    >
                                        <Trash2 class="h-3 w-3" />
                                        {{ $t('Unsubscribe') }}
                                    </button>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <!-- Pagination -->
                <div
                    v-if="subscribers.last_page > 1"
                    class="flex items-center justify-between border-t border-gray-200 px-4 py-4 dark:border-gray-700"
                >
                    <p class="text-sm text-gray-500 dark:text-gray-400">
                        {{
                            $t('Showing {from}–{to} of {total} subscribers', {
                                from: subscribers.from,
                                to: subscribers.to,
                                total: subscribers.total,
                            })
                        }}
                    </p>
                    <div class="flex items-center gap-1">
                        <button
                            v-for="link in subscribers.links"
                            :key="link.label"
                            :disabled="!link.url"
                            class="rounded-lg border px-3 py-1 text-sm transition-colors"
                            :class="
                                link.active
                                    ? 'border-blue-600 bg-blue-600 text-white'
                                    : link.url
                                      ? 'border-gray-300 bg-white text-gray-700 hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700'
                                      : 'cursor-not-allowed border-gray-200 bg-white text-gray-300 dark:border-gray-700 dark:bg-gray-800'
                            "
                            @click="
                                link.url &&
                                router.get(
                                    link.url,
                                    {},
                                    { preserveScroll: true },
                                )
                            "
                            v-html="link.label"
                        />
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

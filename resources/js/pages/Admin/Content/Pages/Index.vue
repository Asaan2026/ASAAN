<template>
    <AdminLayout :title="$t('Pages')">
        <Head :title="$t('Pages')" />

        <div class="space-y-6 p-6">
            <!-- Header -->
            <div
                class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
            >
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Pages') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                        {{ $t('Manage static content pages for your store') }}
                    </p>
                </div>
                <Link
                    :href="pageRoutes.create().url"
                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                >
                    <PlusCircle class="mr-2 h-4 w-4" />
                    {{ $t('Create Page') }}
                </Link>
            </div>

            <!-- Statistics Cards -->
            <div class="grid grid-cols-1 gap-4 md:grid-cols-4">
                <div
                    class="group rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-colors hover:border-blue-200 dark:border-gray-700 dark:bg-gray-800 dark:hover:border-blue-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Total Pages') }}
                            </p>
                            <p
                                class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.total }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-blue-50 p-3 transition-colors group-hover:bg-blue-100 dark:bg-blue-900/20 dark:group-hover:bg-blue-900/40"
                        >
                            <FileText
                                class="h-6 w-6 text-blue-600 dark:text-blue-400"
                            />
                        </div>
                    </div>
                </div>
                <div
                    class="group rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-colors hover:border-green-200 dark:border-gray-700 dark:bg-gray-800 dark:hover:border-green-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Published') }}
                            </p>
                            <p
                                class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.published }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-green-50 p-3 transition-colors group-hover:bg-green-100 dark:bg-green-900/20 dark:group-hover:bg-green-900/40"
                        >
                            <CheckCircle
                                class="h-6 w-6 text-green-600 dark:text-green-400"
                            />
                        </div>
                    </div>
                </div>
                <div
                    class="group rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-colors hover:border-yellow-200 dark:border-gray-700 dark:bg-gray-800 dark:hover:border-yellow-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Draft') }}
                            </p>
                            <p
                                class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.draft }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-yellow-50 p-3 transition-colors group-hover:bg-yellow-100 dark:bg-yellow-900/20 dark:group-hover:bg-yellow-900/40"
                        >
                            <PenTool
                                class="h-6 w-6 text-yellow-600 dark:text-yellow-400"
                            />
                        </div>
                    </div>
                </div>
                <div
                    class="group rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-colors hover:border-gray-200 dark:border-gray-700 dark:bg-gray-800 dark:hover:border-gray-600"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Disabled') }}
                            </p>
                            <p
                                class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.disabled }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-gray-50 p-3 transition-colors group-hover:bg-gray-100 dark:bg-gray-700 dark:group-hover:bg-gray-600"
                        >
                            <XCircle
                                class="h-6 w-6 text-gray-600 dark:text-gray-400"
                            />
                        </div>
                    </div>
                </div>
            </div>

            <!-- Filters -->
            <div
                class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <div class="grid grid-cols-1 gap-4 md:grid-cols-12">
                    <!-- Search -->
                    <div class="md:col-span-6 lg:col-span-4">
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Search') }}</label
                        >
                        <div class="relative">
                            <Search
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <input
                                v-model="form.search"
                                type="text"
                                :placeholder="$t('Search by title or URL...')"
                                class="w-full rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-4 pl-10 text-sm text-gray-900 transition-all placeholder:text-gray-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                @input="debouncedSearch"
                            />
                        </div>
                    </div>

                    <!-- Status Filter -->
                    <div class="md:col-span-3 lg:col-span-2">
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Status') }}</label
                        >
                        <div class="relative">
                            <Filter
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <select
                                v-model="form.status"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-8 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                @change="applyFilters"
                            >
                                <option value="">{{ $t('All Status') }}</option>
                                <option value="published">
                                    {{ $t('Published') }}
                                </option>
                                <option value="draft">{{ $t('Draft') }}</option>
                                <option value="disabled">
                                    {{ $t('Disabled') }}
                                </option>
                            </select>
                            <div
                                class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2"
                            >
                                <ArrowUpDown class="h-3 w-3 text-gray-400" />
                            </div>
                        </div>
                    </div>

                    <!-- Sort Filter -->
                    <div class="md:col-span-3 lg:col-span-2">
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Sort By') }}</label
                        >
                        <div class="relative">
                            <ArrowUpDown
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <select
                                v-model="form.sort_by"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-8 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                @change="applyFilters"
                            >
                                <option value="created_at">
                                    {{ $t('Created Date') }}
                                </option>
                                <option value="updated_at">
                                    {{ $t('Updated Date') }}
                                </option>
                                <option value="title">{{ $t('Title') }}</option>
                                <option value="status">
                                    {{ $t('Status') }}
                                </option>
                            </select>
                            <div
                                class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2"
                            >
                                <ArrowUpDown class="h-3 w-3 text-gray-400" />
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Filter Actions -->
                <div
                    v-if="form.search || form.status"
                    class="mt-4 flex justify-end border-t border-gray-200 pt-4 dark:border-gray-700"
                >
                    <button
                        @click="clearFilters"
                        class="flex items-center gap-2 rounded-lg bg-gray-100 px-4 py-2 text-sm font-medium text-gray-600 transition-colors hover:bg-gray-200 hover:text-gray-900 dark:bg-gray-700 dark:text-gray-400 dark:hover:bg-gray-600 dark:hover:text-gray-200"
                    >
                        <X class="h-4 w-4" />
                        {{ $t('Clear Filters') }}
                    </button>
                </div>
            </div>

            <!-- Pages Table -->
            <div
                class="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <!-- Bulk Actions -->
                <div
                    v-if="selectedPages.length > 0"
                    class="border-b border-blue-100 bg-blue-50 p-4 dark:border-blue-800 dark:bg-blue-900/20"
                >
                    <div class="flex items-center justify-between">
                        <div class="flex items-center">
                            <CheckCircle
                                class="mr-2 h-4 w-4 text-blue-600 dark:text-blue-400"
                            />
                            <span
                                class="text-sm font-semibold text-blue-700 dark:text-blue-300"
                            >
                                {{
                                    $t('{count} page(s) selected', {
                                        count: selectedPages.length,
                                    })
                                }}
                            </span>
                        </div>
                        <div class="flex gap-2">
                            <button
                                @click="bulkAction('enable')"
                                class="inline-flex items-center rounded border border-transparent bg-green-100 px-3 py-1.5 text-xs font-medium text-green-700 hover:bg-green-200 focus:ring-2 focus:ring-green-500 focus:ring-offset-2 focus:outline-none dark:bg-green-900/40 dark:text-green-300 dark:hover:bg-green-900/60"
                            >
                                <Check class="mr-1.5 h-4 w-4" />
                                {{ $t('Enable') }}
                            </button>
                            <button
                                @click="bulkAction('disable')"
                                class="inline-flex items-center rounded border border-transparent bg-orange-100 px-3 py-1.5 text-xs font-medium text-orange-700 hover:bg-orange-200 focus:ring-2 focus:ring-orange-500 focus:ring-offset-2 focus:outline-none dark:bg-orange-900/40 dark:text-orange-300 dark:hover:bg-orange-900/60"
                            >
                                <XCircle class="mr-1.5 h-4 w-4" />
                                {{ $t('Disable') }}
                            </button>
                            <button
                                @click="bulkAction('delete')"
                                class="inline-flex items-center rounded border border-transparent bg-red-100 px-3 py-1.5 text-xs font-medium text-red-700 hover:bg-red-200 focus:ring-2 focus:ring-red-500 focus:ring-offset-2 focus:outline-none dark:bg-red-900/40 dark:text-red-300 dark:hover:bg-red-900/60"
                            >
                                <Trash2 class="mr-1.5 h-4 w-4" />
                                {{ $t('Delete') }}
                            </button>
                        </div>
                    </div>
                </div>

                <div class="overflow-x-auto">
                    <table
                        class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
                    >
                        <thead class="bg-gray-50 dark:bg-gray-700/50">
                            <tr>
                                <th class="w-12 px-6 py-3 text-left">
                                    <input
                                        type="checkbox"
                                        :checked="allSelected"
                                        @change="toggleAllPages"
                                        class="h-4 w-4 rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </th>
                                <th
                                    class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Title') }}
                                </th>
                                <th
                                    class="hidden px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase md:table-cell dark:text-gray-400"
                                >
                                    {{ $t('URL Key') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Status') }}
                                </th>
                                <th
                                    class="hidden px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase lg:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Created') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-right text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Actions') }}
                                </th>
                            </tr>
                        </thead>
                        <tbody
                            class="divide-y divide-gray-200 dark:divide-gray-700"
                        >
                            <template v-for="page in pages.data" :key="page.id">
                                <tr
                                    :class="[
                                        'group transition-colors hover:bg-blue-50/50 dark:hover:bg-blue-900/10',
                                        {
                                            'bg-blue-50 dark:bg-blue-900/10':
                                                selectedPages.includes(page.id),
                                        },
                                    ]"
                                >
                                    <td class="relative px-6 py-4">
                                        <div class="flex items-center">
                                            <button
                                                @click="toggleRow(page.id)"
                                                class="absolute left-2 p-1 text-blue-600 hover:text-blue-800 focus:outline-none md:hidden"
                                            >
                                                <MinusCircle
                                                    v-if="
                                                        expandedRows.includes(
                                                            page.id,
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
                                                :value="page.id"
                                                v-model="selectedPages"
                                                class="ml-4 h-4 w-4 cursor-pointer rounded border-gray-300 bg-white text-blue-600 transition-all focus:ring-blue-500 md:ml-0 dark:border-gray-600 dark:bg-gray-700"
                                            />
                                        </div>
                                    </td>
                                    <td class="px-6 py-4">
                                        <div class="flex items-center gap-3">
                                            <div>
                                                <div
                                                    class="flex items-center gap-2 text-sm font-medium text-gray-900 dark:text-white"
                                                >
                                                    {{ page.title }}
                                                    <span
                                                        v-if="page.is_homepage"
                                                        class="inline-flex items-center rounded bg-blue-100 px-1.5 py-0.5 text-xs font-semibold text-blue-700 dark:bg-blue-900/40 dark:text-blue-300"
                                                    >
                                                        {{ $t('Home') }}
                                                    </span>
                                                </div>
                                                <div
                                                    class="mt-1 font-mono text-xs text-gray-500 md:hidden"
                                                >
                                                    /{{ page.url_key }}
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                    <td class="hidden px-6 py-4 md:table-cell">
                                        <div
                                            class="inline-block rounded bg-gray-100 px-2 py-1 font-mono text-sm text-gray-600 dark:bg-gray-700 dark:text-gray-400"
                                        >
                                            /{{ page.url_key }}
                                        </div>
                                    </td>
                                    <td class="px-6 py-4">
                                        <span
                                            class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium shadow-sm"
                                            :class="statusClass(page.status)"
                                        >
                                            {{
                                                page.status
                                                    .charAt(0)
                                                    .toUpperCase() +
                                                page.status.slice(1)
                                            }}
                                        </span>
                                    </td>
                                    <td class="hidden px-6 py-4 lg:table-cell">
                                        <div
                                            class="text-sm text-gray-600 dark:text-gray-400"
                                        >
                                            <DateDisplay
                                                :value="page.created_at"
                                            />
                                        </div>
                                        <div
                                            v-if="page.creator"
                                            class="mt-0.5 flex items-center gap-1 text-xs text-gray-500 dark:text-gray-500"
                                        >
                                            <User class="h-3 w-3" />
                                            {{ page.creator.name }}
                                        </div>
                                    </td>
                                    <td
                                        class="px-6 py-4 text-right text-sm font-medium whitespace-nowrap"
                                    >
                                        <div
                                            class="flex items-center justify-end gap-2 opacity-60 transition-opacity group-hover:opacity-100"
                                        >
                                            <a
                                                :href="page.url"
                                                target="_blank"
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-900/20"
                                                :title="$t('Preview Page')"
                                            >
                                                <ExternalLink class="h-4 w-4" />
                                            </a>
                                            <Link
                                                :href="
                                                    pageRoutes.edit({
                                                        page: page.id,
                                                    }).url
                                                "
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-indigo-50 hover:text-indigo-600 dark:hover:bg-indigo-900/20"
                                                :title="$t('Edit Page')"
                                            >
                                                <Edit class="h-4 w-4" />
                                            </Link>
                                            <button
                                                @click="duplicatePage(page)"
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-green-50 hover:text-green-600 dark:hover:bg-green-900/20"
                                                :title="$t('Duplicate Page')"
                                            >
                                                <Copy class="h-4 w-4" />
                                            </button>
                                            <button
                                                v-if="!page.is_homepage"
                                                @click="deletePage(page)"
                                                class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-900/20"
                                                :title="$t('Delete Page')"
                                            >
                                                <Trash2 class="h-4 w-4" />
                                            </button>
                                            <span
                                                v-else
                                                class="cursor-not-allowed p-2 text-gray-200 dark:text-gray-700"
                                                :title="
                                                    $t(
                                                        'Homepage cannot be deleted',
                                                    )
                                                "
                                            >
                                                <Trash2 class="h-4 w-4" />
                                            </span>
                                        </div>
                                    </td>
                                </tr>

                                <!-- Mobile Expanded Row -->
                                <tr
                                    v-if="expandedRows.includes(page.id)"
                                    class="bg-gray-50/50 md:hidden dark:bg-gray-900/50"
                                >
                                    <td
                                        colspan="6"
                                        class="border-t border-gray-100 px-6 py-4 dark:border-gray-700"
                                    >
                                        <div
                                            class="grid grid-cols-1 gap-4 text-sm"
                                        >
                                            <div>
                                                <span
                                                    class="mb-1 block text-xs font-medium tracking-wider text-gray-500 uppercase"
                                                    >{{
                                                        $t('Created At')
                                                    }}</span
                                                >
                                                <div
                                                    class="text-sm text-gray-900 dark:text-white"
                                                >
                                                    <DateDisplay
                                                        :value="page.created_at"
                                                    />
                                                </div>
                                                <div
                                                    v-if="page.creator"
                                                    class="mt-1 text-xs text-gray-500"
                                                >
                                                    {{
                                                        $t('by {name}', {
                                                            name: page.creator
                                                                .name,
                                                        })
                                                    }}
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                </tr>
                            </template>
                        </tbody>
                    </table>
                </div>

                <!-- Empty State -->
                <div v-if="pages.data.length === 0" class="py-12 text-center">
                    <div class="flex flex-col items-center justify-center">
                        <div
                            class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-50 text-gray-400 dark:bg-gray-700"
                        >
                            <FileText class="h-8 w-8" />
                        </div>
                        <h3
                            class="mb-1 text-lg font-bold text-gray-900 dark:text-white"
                        >
                            {{ $t('No pages found') }}
                        </h3>
                        <p
                            class="mb-4 text-sm text-gray-500 dark:text-gray-400"
                        >
                            {{ $t('Get started by creating your first page.') }}
                        </p>
                        <Link
                            :href="pageRoutes.create().url"
                            class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none active:bg-blue-900"
                        >
                            <PlusCircle class="mr-2 h-4 w-4" />
                            {{ $t('Create Page') }}
                        </Link>
                    </div>
                </div>

                <!-- Pagination -->
                <div
                    v-if="pages.data.length > 0"
                    class="border-t border-gray-200 px-4 py-3 dark:border-gray-700"
                >
                    <Pagination :data="pages" resource-name="pages" />
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

<script setup lang="ts">
import Pagination from '@/components/Admin/Pagination.vue';
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import * as pageRoutes from '@/routes/admin/content/pages';
import type {
    Page,
    PageFilters,
    PageStatistics,
    PaginatedPages,
} from '@/types/cms';
import { Head, Link, router } from '@inertiajs/vue3';
import { debounce } from 'lodash';
import {
    ArrowUpDown,
    Check,
    CheckCircle,
    Copy,
    Edit,
    ExternalLink,
    FileText,
    Filter,
    MinusCircle,
    PenTool,
    PlusCircle,
    Search,
    Trash2,
    User,
    X,
    XCircle,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

interface Props {
    pages: PaginatedPages;
    statistics: PageStatistics;
    filters: PageFilters;
}

const props = defineProps<Props>();

const form = ref<PageFilters>({
    search: props.filters.search || '',
    status: (props.filters.status || '') as any,
    sort_by: props.filters.sort_by || 'created_at',
    sort_order: props.filters.sort_order || 'desc',
});

const selectedPages = ref<number[]>([]);
const expandedRows = ref<number[]>([]);

const allSelected = computed(() => {
    return (
        props.pages.data.length > 0 &&
        selectedPages.value.length === props.pages.data.length
    );
});

const toggleAllPages = () => {
    if (allSelected.value) {
        selectedPages.value = [];
    } else {
        selectedPages.value = props.pages.data.map((page) => page.id);
    }
};

const toggleRow = (id: number) => {
    if (expandedRows.value.includes(id)) {
        expandedRows.value = expandedRows.value.filter((rowId) => rowId !== id);
    } else {
        expandedRows.value.push(id);
    }
};

const applyFilters = () => {
    router.get(
        pageRoutes.index().url,
        {
            search: form.value.search || undefined,
            status: form.value.status || undefined,
            sort_by: form.value.sort_by,
            sort_order: form.value.sort_order,
        },
        {
            preserveState: true,
            preserveScroll: true,
        },
    );
};

const clearFilters = () => {
    form.value.search = '';
    form.value.status = '';
    applyFilters();
};

const debouncedSearch = debounce(() => {
    applyFilters();
}, 500);

const bulkAction = (action: string) => {
    if (selectedPages.value.length === 0) return;

    const message =
        action === 'delete'
            ? 'Are you sure you want to delete the selected pages?'
            : `Are you sure you want to ${action} the selected pages?`;

    if (!confirm(message)) return;

    router.post(
        pageRoutes.bulkAction().url,
        {
            ids: selectedPages.value,
            action,
        },
        {
            onSuccess: () => {
                selectedPages.value = [];
            },
        },
    );
};

const deletePage = (page: Page) => {
    if (!confirm(`Are you sure you want to delete "${page.title}"?`)) return;

    router.delete(pageRoutes.destroy({ page: page.id }).url);
};

const duplicatePage = (page: Page) => {
    router.post(pageRoutes.duplicate({ page: page.id }).url);
};

const statusClass = (status: string) => {
    const classes = {
        published:
            'bg-green-50 text-green-700 border-green-200 dark:bg-green-900/20 dark:text-green-300 dark:border-green-800',
        draft: 'bg-yellow-50 text-yellow-700 border-yellow-200 dark:bg-yellow-900/20 dark:text-yellow-300 dark:border-yellow-800',
        disabled:
            'bg-gray-50 text-gray-700 border-gray-200 dark:bg-gray-900/20 dark:text-gray-300 dark:border-gray-800',
    };
    return (
        classes[status as keyof typeof classes] ||
        'bg-gray-50 text-gray-700 border-gray-200 dark:bg-gray-900/20 dark:text-gray-300 dark:border-gray-800'
    );
};
</script>

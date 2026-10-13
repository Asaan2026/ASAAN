<template>
    <AdminLayout :title="$t('Blog Categories')">
        <Head :title="$t('Blog Categories')" />

        <div class="space-y-6 p-6">
            <!-- Header -->
            <div
                class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
            >
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Blog Categories') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                        {{ $t('Organise your blog posts into categories') }}
                    </p>
                </div>
                <Link
                    :href="categoryRoutes.create().url"
                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none"
                >
                    <PlusCircle class="mr-2 h-4 w-4" />
                    {{ $t('New Category') }}
                </Link>
            </div>

            <!-- Statistics -->
            <div class="grid grid-cols-1 gap-4 md:grid-cols-4">
                <div
                    class="group rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-colors hover:border-blue-200 dark:border-gray-700 dark:bg-gray-800 dark:hover:border-blue-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Total') }}
                            </p>
                            <p
                                class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.total }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-blue-50 p-3 dark:bg-blue-900/20"
                        >
                            <Tags
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
                                {{ $t('Active') }}
                            </p>
                            <p
                                class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.active }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-green-50 p-3 dark:bg-green-900/20"
                        >
                            <CheckCircle
                                class="h-6 w-6 text-green-600 dark:text-green-400"
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
                                {{ $t('Inactive') }}
                            </p>
                            <p
                                class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.inactive }}
                            </p>
                        </div>
                        <div class="rounded-lg bg-gray-50 p-3 dark:bg-gray-700">
                            <XCircle
                                class="h-6 w-6 text-gray-500 dark:text-gray-400"
                            />
                        </div>
                    </div>
                </div>
                <div
                    class="group rounded-xl border border-gray-100 bg-white p-5 shadow-sm transition-colors hover:border-purple-200 dark:border-gray-700 dark:bg-gray-800 dark:hover:border-purple-800"
                >
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('With Posts') }}
                            </p>
                            <p
                                class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.with_posts }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-purple-50 p-3 dark:bg-purple-900/20"
                        >
                            <FileText
                                class="h-6 w-6 text-purple-600 dark:text-purple-400"
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
                    <div class="md:col-span-6 lg:col-span-5">
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Search') }}</label
                        >
                        <div class="relative">
                            <Search
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <input
                                v-model="filters.search"
                                @input="debouncedSearch"
                                type="text"
                                :placeholder="$t('Search by name or slug...')"
                                class="w-full rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-4 pl-10 text-sm text-gray-900 transition-all placeholder:text-gray-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            />
                        </div>
                    </div>
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
                                v-model="filters.status"
                                @change="applyFilters"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-8 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                            >
                                <option value="">
                                    {{ $t('All Statuses') }}
                                </option>
                                <option value="active">
                                    {{ $t('Active') }}
                                </option>
                                <option value="inactive">
                                    {{ $t('Inactive') }}
                                </option>
                            </select>
                            <div
                                class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2"
                            >
                                <ArrowUpDown class="h-3 w-3 text-gray-400" />
                            </div>
                        </div>
                    </div>
                    <div
                        class="flex items-end md:col-span-3 lg:col-span-2"
                        v-if="filters.search || filters.status"
                    >
                        <button
                            @click="clearFilters"
                            class="w-full rounded-lg bg-gray-100 px-4 py-2.5 text-xs font-semibold tracking-wider text-gray-600 uppercase transition-colors hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-400 dark:hover:bg-gray-600"
                        >
                            {{ $t('Clear Filters') }}
                        </button>
                    </div>
                </div>
            </div>

            <!-- Table -->
            <div
                class="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <table class="w-full text-left text-sm">
                    <thead
                        class="border-b border-gray-100 dark:border-gray-700"
                    >
                        <tr>
                            <th
                                class="px-6 py-3.5 text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Name') }}
                            </th>
                            <th
                                class="px-6 py-3.5 text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Slug') }}
                            </th>
                            <th
                                class="px-6 py-3.5 text-center text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Posts') }}
                            </th>
                            <th
                                class="px-6 py-3.5 text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Status') }}
                            </th>
                            <th
                                class="px-6 py-3.5 text-right text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >
                                {{ $t('Actions') }}
                            </th>
                        </tr>
                    </thead>
                    <tbody
                        class="divide-y divide-gray-100 dark:divide-gray-700"
                    >
                        <tr v-if="categories.data.length === 0">
                            <td colspan="5" class="px-6 py-16 text-center">
                                <div class="flex flex-col items-center gap-3">
                                    <div
                                        class="rounded-full bg-gray-100 p-4 dark:bg-gray-700"
                                    >
                                        <Tags
                                            class="h-8 w-8 text-gray-400 dark:text-gray-500"
                                        />
                                    </div>
                                    <p
                                        class="font-medium text-gray-500 dark:text-gray-400"
                                    >
                                        {{ $t('No categories found.') }}
                                    </p>
                                    <Link
                                        :href="categoryRoutes.create().url"
                                        class="text-sm font-medium text-blue-600 hover:text-blue-700"
                                        >{{
                                            $t('Create your first category →')
                                        }}</Link
                                    >
                                </div>
                            </td>
                        </tr>
                        <tr
                            v-for="category in categories.data"
                            :key="category.id"
                            class="transition-colors hover:bg-gray-50 dark:hover:bg-gray-700/30"
                        >
                            <td class="px-6 py-4">
                                <div class="flex items-center gap-3">
                                    <div
                                        class="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-lg bg-blue-50 dark:bg-blue-900/20"
                                    >
                                        <Tag
                                            class="h-4 w-4 text-blue-600 dark:text-blue-400"
                                        />
                                    </div>
                                    <span
                                        class="font-medium text-gray-900 dark:text-white"
                                        >{{ category.name }}</span
                                    >
                                </div>
                            </td>
                            <td class="px-6 py-4">
                                <code
                                    class="rounded bg-gray-100 px-2 py-1 text-xs text-gray-600 dark:bg-gray-700 dark:text-gray-400"
                                    >{{ category.slug }}</code
                                >
                            </td>
                            <td class="px-6 py-4 text-center">
                                <span
                                    class="inline-flex h-7 min-w-[28px] items-center justify-center rounded-full bg-blue-100 px-2 text-xs font-semibold text-blue-700 dark:bg-blue-900/30 dark:text-blue-300"
                                >
                                    {{ category.posts_count }}
                                </span>
                            </td>
                            <td class="px-6 py-4">
                                <span
                                    class="inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-semibold"
                                    :class="
                                        category.status === 'active'
                                            ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                                            : 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400'
                                    "
                                >
                                    <span
                                        class="h-1.5 w-1.5 rounded-full"
                                        :class="
                                            category.status === 'active'
                                                ? 'bg-green-500'
                                                : 'bg-gray-400'
                                        "
                                    ></span>
                                    {{
                                        category.status === 'active'
                                            ? $t('Active')
                                            : $t('Inactive')
                                    }}
                                </span>
                            </td>
                            <td class="px-6 py-4 text-right">
                                <div
                                    class="flex items-center justify-end gap-1.5"
                                >
                                    <Link
                                        :href="
                                            categoryRoutes.edit({
                                                category: category.slug,
                                            }).url
                                        "
                                        class="inline-flex items-center gap-1.5 rounded-lg bg-blue-50 px-3 py-1.5 text-xs font-medium text-blue-700 transition-colors hover:bg-blue-100 dark:bg-blue-900/20 dark:text-blue-400 dark:hover:bg-blue-900/40"
                                        :title="$t('Edit')"
                                    >
                                        <Pencil class="h-3.5 w-3.5" />
                                        {{ $t('Edit') }}
                                    </Link>
                                    <button
                                        @click="deleteCategory(category)"
                                        class="inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-medium transition-colors"
                                        :class="
                                            category.posts_count > 0
                                                ? 'cursor-not-allowed bg-gray-50 text-gray-400 opacity-50 dark:bg-gray-700/50'
                                                : 'bg-red-50 text-red-700 hover:bg-red-100 dark:bg-red-900/20 dark:text-red-400 dark:hover:bg-red-900/40'
                                        "
                                        :title="$t('Delete')"
                                        :disabled="category.posts_count > 0"
                                    >
                                        <Trash2 class="h-3.5 w-3.5" />
                                        {{ $t('Delete') }}
                                    </button>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>

                <!-- Pagination -->
                <div
                    v-if="categories.last_page > 1"
                    class="flex items-center justify-between border-t border-gray-100 px-6 py-4 dark:border-gray-700"
                >
                    <p class="text-sm text-gray-500 dark:text-gray-400">
                        {{
                            $t('Showing {from}–{to} of {total} categories', {
                                from: categories.from,
                                to: categories.to,
                                total: categories.total,
                            })
                        }}
                    </p>
                    <div class="flex gap-1">
                        <Link
                            v-for="link in categories.links"
                            :key="link.label"
                            :href="link.url ?? '#'"
                            v-html="link.label"
                            class="rounded-lg border px-3 py-1.5 text-xs font-medium transition-colors"
                            :class="
                                link.active
                                    ? 'border-blue-600 bg-blue-600 text-white'
                                    : 'border-gray-200 text-gray-600 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-400 dark:hover:bg-gray-700'
                            "
                            :aria-disabled="!link.url"
                        />
                    </div>
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

<script setup lang="ts">
import AdminLayout from '@/layouts/AdminLayout.vue';
import * as categoryRoutes from '@/routes/admin/blog/categories';
import { Head, Link, router } from '@inertiajs/vue3';
import { useDebounceFn } from '@vueuse/core';
import {
    ArrowUpDown,
    CheckCircle,
    FileText,
    Filter,
    Pencil,
    PlusCircle,
    Search,
    Tag,
    Tags,
    Trash2,
    XCircle,
} from 'lucide-vue-next';
import { reactive } from 'vue';

interface Category {
    id: number;
    name: string;
    slug: string;
    status: 'active' | 'inactive';
    posts_count: number;
}

interface Paginator<T> {
    data: T[];
    from: number;
    to: number;
    total: number;
    last_page: number;
    links: { label: string; url: string | null; active: boolean }[];
}

interface Statistics {
    total: number;
    active: number;
    inactive: number;
    with_posts: number;
}

const props = defineProps<{
    categories: Paginator<Category>;
    filters: { search?: string; status?: string };
    statistics: Statistics;
}>();

const filters = reactive({
    search: props.filters.search ?? '',
    status: props.filters.status ?? '',
});

function applyFilters() {
    router.get(categoryRoutes.index().url, filters, {
        preserveState: true,
        replace: true,
    });
}

const debouncedSearch = useDebounceFn(applyFilters, 350);

function clearFilters() {
    filters.search = '';
    filters.status = '';
    applyFilters();
}

function deleteCategory(category: Category) {
    if (category.posts_count > 0) return;
    if (!confirm(`Delete category "${category.name}"? This cannot be undone.`))
        return;
    router.delete(categoryRoutes.destroy({ category: category.slug }).url);
}
</script>

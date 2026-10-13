<template>
    <AdminLayout :title="$t('Blog Posts')">
        <Head :title="$t('Blog Posts')" />

        <div class="space-y-6 p-6">
            <!-- Header -->
            <div
                class="flex flex-col justify-between gap-4 sm:flex-row sm:items-center"
            >
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Blog Posts') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                        {{ $t('Manage blog content for your store') }}
                    </p>
                </div>
                <Link
                    :href="blogRoutes.create().url"
                    class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:outline-none"
                >
                    <PlusCircle class="mr-2 h-4 w-4" />
                    {{ $t('Create Post') }}
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
                                {{ $t('Total Posts') }}
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
                            <Newspaper
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
                            class="rounded-lg bg-green-50 p-3 dark:bg-green-900/20"
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
                            class="rounded-lg bg-yellow-50 p-3 dark:bg-yellow-900/20"
                        >
                            <PenTool
                                class="h-6 w-6 text-yellow-600 dark:text-yellow-400"
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
                                {{ $t('Scheduled') }}
                            </p>
                            <p
                                class="mt-2 text-2xl font-bold text-gray-900 dark:text-white"
                            >
                                {{ statistics.scheduled }}
                            </p>
                        </div>
                        <div
                            class="rounded-lg bg-purple-50 p-3 dark:bg-purple-900/20"
                        >
                            <Clock
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
                    <div class="md:col-span-5 lg:col-span-4">
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
                                :placeholder="$t('Search by title or slug...')"
                                class="w-full rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-4 pl-10 text-sm text-gray-900 transition-all placeholder:text-gray-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                @input="debouncedSearch"
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
                                v-model="form.status"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-8 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                @change="applyFilters"
                            >
                                <option value="">{{ $t('All Status') }}</option>
                                <option value="published">
                                    {{ $t('Published') }}
                                </option>
                                <option value="draft">{{ $t('Draft') }}</option>
                                <option value="scheduled">
                                    {{ $t('Scheduled') }}
                                </option>
                            </select>
                            <div
                                class="pointer-events-none absolute top-1/2 right-3 -translate-y-1/2"
                            >
                                <ArrowUpDown class="h-3 w-3 text-gray-400" />
                            </div>
                        </div>
                    </div>
                    <div class="md:col-span-4 lg:col-span-3">
                        <label
                            class="mb-1.5 block text-xs font-semibold tracking-wider text-gray-500 uppercase dark:text-gray-400"
                            >{{ $t('Category') }}</label
                        >
                        <div class="relative">
                            <Folder
                                class="absolute top-1/2 left-3 h-4 w-4 -translate-y-1/2 text-gray-400"
                            />
                            <select
                                v-model="form.category_id"
                                class="w-full cursor-pointer appearance-none rounded-lg border border-gray-200 bg-gray-50 py-2.5 pr-8 pl-10 text-sm text-gray-900 transition-all focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 dark:border-gray-600 dark:bg-gray-700/50 dark:text-gray-100"
                                @change="applyFilters"
                            >
                                <option value="">
                                    {{ $t('All Categories') }}
                                </option>
                                <option
                                    v-for="cat in categories"
                                    :key="cat.id"
                                    :value="cat.id"
                                >
                                    {{ cat.name }}
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
                <div
                    v-if="form.search || form.status || form.category_id"
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

            <!-- Table -->
            <div
                class="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800"
            >
                <!-- Bulk Actions -->
                <div
                    v-if="selectedPosts.length > 0"
                    class="border-b border-blue-100 bg-blue-50 p-4 dark:border-blue-800 dark:bg-blue-900/20"
                >
                    <div class="flex items-center justify-between">
                        <div class="flex items-center">
                            <CheckCircle
                                class="mr-2 h-4 w-4 text-blue-600 dark:text-blue-400"
                            />
                            <span
                                class="text-sm font-semibold text-blue-700 dark:text-blue-300"
                                >{{
                                    $t('{count} post(s) selected', {
                                        count: selectedPosts.length,
                                    })
                                }}</span
                            >
                        </div>
                        <div class="flex gap-2">
                            <button
                                @click="bulkAction('publish')"
                                class="inline-flex items-center rounded bg-green-100 px-3 py-1.5 text-xs font-medium text-green-700 hover:bg-green-200 dark:bg-green-900/40 dark:text-green-300"
                            >
                                <Check class="mr-1.5 h-4 w-4" />{{
                                    $t('Publish')
                                }}
                            </button>
                            <button
                                @click="bulkAction('draft')"
                                class="inline-flex items-center rounded bg-orange-100 px-3 py-1.5 text-xs font-medium text-orange-700 hover:bg-orange-200 dark:bg-orange-900/40 dark:text-orange-300"
                            >
                                <PenTool class="mr-1.5 h-4 w-4" />{{
                                    $t('Draft')
                                }}
                            </button>
                            <button
                                @click="bulkAction('delete')"
                                class="inline-flex items-center rounded bg-red-100 px-3 py-1.5 text-xs font-medium text-red-700 hover:bg-red-200 dark:bg-red-900/40 dark:text-red-300"
                            >
                                <Trash2 class="mr-1.5 h-4 w-4" />{{
                                    $t('Delete')
                                }}
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
                                        @change="toggleAll"
                                        class="h-4 w-4 rounded border-gray-300 bg-white text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
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
                                    {{ $t('Category') }}
                                </th>
                                <th
                                    class="px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase dark:text-gray-400"
                                >
                                    {{ $t('Status') }}
                                </th>
                                <th
                                    class="hidden px-6 py-3 text-left text-xs font-medium tracking-wider text-gray-500 uppercase lg:table-cell dark:text-gray-400"
                                >
                                    {{ $t('Published') }}
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
                            <tr
                                v-for="post in posts.data"
                                :key="post.id"
                                :class="[
                                    'group transition-colors hover:bg-blue-50/50 dark:hover:bg-blue-900/10',
                                    {
                                        'bg-blue-50 dark:bg-blue-900/10':
                                            selectedPosts.includes(post.id),
                                    },
                                ]"
                            >
                                <td class="px-6 py-4">
                                    <input
                                        type="checkbox"
                                        :value="post.id"
                                        v-model="selectedPosts"
                                        class="h-4 w-4 cursor-pointer rounded border-gray-300 bg-white text-blue-600 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
                                    />
                                </td>
                                <td class="px-6 py-4">
                                    <div
                                        class="text-sm font-medium text-gray-900 dark:text-white"
                                    >
                                        {{ post.title }}
                                    </div>
                                    <div
                                        class="mt-0.5 font-mono text-xs text-gray-500 dark:text-gray-400"
                                    >
                                        /blog/{{ post.slug }}
                                    </div>
                                </td>
                                <td class="hidden px-6 py-4 md:table-cell">
                                    <span
                                        v-if="post.category"
                                        class="inline-flex items-center rounded bg-indigo-50 px-2 py-0.5 text-xs font-medium text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-300"
                                    >
                                        {{ post.category.name }}
                                    </span>
                                    <span v-else class="text-xs text-gray-400"
                                        >—</span
                                    >
                                </td>
                                <td class="px-6 py-4">
                                    <span
                                        class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium shadow-sm"
                                        :class="statusClass(post.status)"
                                    >
                                        {{
                                            post.status
                                                .charAt(0)
                                                .toUpperCase() +
                                            post.status.slice(1)
                                        }}
                                    </span>
                                </td>
                                <td class="hidden px-6 py-4 lg:table-cell">
                                    <div
                                        class="text-sm text-gray-600 dark:text-gray-400"
                                    >
                                        <DateDisplay
                                            v-if="post.published_at"
                                            :value="post.published_at"
                                        />
                                        <span v-else>—</span>
                                    </div>
                                    <div
                                        v-if="post.creator"
                                        class="mt-0.5 flex items-center gap-1 text-xs text-gray-500"
                                    >
                                        <User class="h-3 w-3" />{{
                                            post.creator.name
                                        }}
                                    </div>
                                </td>
                                <td
                                    class="px-6 py-4 text-right text-sm font-medium whitespace-nowrap"
                                >
                                    <div
                                        class="flex items-center justify-end gap-2 opacity-60 transition-opacity group-hover:opacity-100"
                                    >
                                        <a
                                            :href="`/blog/${post.slug}`"
                                            target="_blank"
                                            class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-blue-50 hover:text-blue-600 dark:hover:bg-blue-900/20"
                                            :title="$t('Preview Post')"
                                        >
                                            <ExternalLink class="h-4 w-4" />
                                        </a>
                                        <Link
                                            :href="
                                                blogRoutes.edit({
                                                    post: post.slug,
                                                }).url
                                            "
                                            class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-indigo-50 hover:text-indigo-600 dark:hover:bg-indigo-900/20"
                                            :title="$t('Edit Post')"
                                        >
                                            <Edit class="h-4 w-4" />
                                        </Link>
                                        <button
                                            @click="deletePost(post)"
                                            class="rounded-lg p-2 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-900/20"
                                            :title="$t('Delete Post')"
                                        >
                                            <Trash2 class="h-4 w-4" />
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <div v-if="posts.data.length === 0" class="py-12 text-center">
                    <div class="flex flex-col items-center justify-center">
                        <div
                            class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-gray-50 text-gray-400 dark:bg-gray-700"
                        >
                            <Newspaper class="h-8 w-8" />
                        </div>
                        <h3
                            class="mb-1 text-lg font-bold text-gray-900 dark:text-white"
                        >
                            {{ $t('No posts found') }}
                        </h3>
                        <p
                            class="mb-4 text-sm text-gray-500 dark:text-gray-400"
                        >
                            {{
                                $t(
                                    'Get started by creating your first blog post.',
                                )
                            }}
                        </p>
                        <Link
                            :href="blogRoutes.create().url"
                            class="inline-flex items-center rounded-lg border border-transparent bg-blue-600 px-4 py-2 text-xs font-semibold tracking-widest text-white uppercase transition duration-150 ease-in-out hover:bg-blue-700"
                        >
                            <PlusCircle class="mr-2 h-4 w-4" />{{
                                $t('Create Post')
                            }}
                        </Link>
                    </div>
                </div>

                <div
                    v-if="posts.data.length > 0"
                    class="border-t border-gray-200 px-4 py-3 dark:border-gray-700"
                >
                    <Pagination :data="posts" resource-name="posts" />
                </div>
            </div>
        </div>
    </AdminLayout>
</template>

<script setup lang="ts">
import Pagination from '@/components/Admin/Pagination.vue';
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import * as blogRoutes from '@/routes/admin/blog';
import { Head, Link, router } from '@inertiajs/vue3';
import { debounce } from 'lodash';
import {
    ArrowUpDown,
    Check,
    CheckCircle,
    Clock,
    Edit,
    ExternalLink,
    Filter,
    Folder,
    Newspaper,
    PenTool,
    PlusCircle,
    Search,
    Trash2,
    User,
    X,
} from 'lucide-vue-next';
import { computed, ref } from 'vue';

interface Category {
    id: number;
    name: string;
    slug: string;
}
interface Post {
    id: number;
    title: string;
    slug: string;
    status: string;
    published_at: string | null;
    category: Category | null;
    creator: { name: string } | null;
}
interface PaginatedPosts {
    data: Post[];
    links: unknown;
    meta: unknown;
}

const props = defineProps<{
    posts: PaginatedPosts;
    statistics: {
        total: number;
        published: number;
        draft: number;
        scheduled: number;
    };
    categories: Category[];
    filters: Record<string, string>;
}>();

const form = ref({
    search: props.filters.search || '',
    status: props.filters.status || '',
    category_id: props.filters.category_id || '',
});

const selectedPosts = ref<number[]>([]);

const allSelected = computed(
    () =>
        props.posts.data.length > 0 &&
        selectedPosts.value.length === props.posts.data.length,
);

const toggleAll = () => {
    if (allSelected.value) {
        selectedPosts.value = [];
    } else {
        selectedPosts.value = props.posts.data.map((p) => p.id);
    }
};

const applyFilters = () => {
    router.get(
        blogRoutes.index().url,
        {
            search: form.value.search || undefined,
            status: form.value.status || undefined,
            category_id: form.value.category_id || undefined,
        },
        { preserveState: true, preserveScroll: true },
    );
};

const clearFilters = () => {
    form.value.search = '';
    form.value.status = '';
    form.value.category_id = '';
    applyFilters();
};

const debouncedSearch = debounce(() => applyFilters(), 500);

const bulkAction = (action: string) => {
    if (selectedPosts.value.length === 0) return;
    if (!confirm(`Are you sure you want to ${action} the selected posts?`))
        return;
    router.post(
        blogRoutes.bulkAction().url,
        { ids: selectedPosts.value, action },
        {
            onSuccess: () => {
                selectedPosts.value = [];
            },
        },
    );
};

const deletePost = (post: Post) => {
    if (!confirm(`Are you sure you want to delete "${post.title}"?`)) return;
    router.delete(blogRoutes.destroy({ post: post.slug }).url);
};

const statusClass = (status: string) => {
    const classes: Record<string, string> = {
        published:
            'bg-green-50 text-green-700 border-green-200 dark:bg-green-900/20 dark:text-green-300 dark:border-green-800',
        draft: 'bg-yellow-50 text-yellow-700 border-yellow-200 dark:bg-yellow-900/20 dark:text-yellow-300 dark:border-yellow-800',
        scheduled:
            'bg-purple-50 text-purple-700 border-purple-200 dark:bg-purple-900/20 dark:text-purple-300 dark:border-purple-800',
    };
    return (
        classes[status] ||
        'bg-gray-50 text-gray-700 border-gray-200 dark:bg-gray-900/20 dark:text-gray-300 dark:border-gray-800'
    );
};
</script>

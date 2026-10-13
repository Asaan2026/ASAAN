<template>
    <AdminLayout :title="$t('Create Blog Category')">
        <Head :title="$t('Create Blog Category')" />

        <div class="space-y-6 p-6">
            <!-- Header -->
            <div class="flex items-center justify-between">
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Create Blog Category') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                        {{ $t('Add a new category to organise blog posts') }}
                    </p>
                </div>
                <Link
                    :href="categoryRoutes.index().url"
                    class="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                >
                    <svg
                        class="h-5 w-5"
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
                    {{ $t('Back to Categories') }}
                </Link>
            </div>

            <form @submit.prevent="submit">
                <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
                    <!-- Main -->
                    <div class="space-y-6 lg:col-span-2">
                        <div
                            class="space-y-6 rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800"
                        >
                            <!-- Name -->
                            <div>
                                <label
                                    for="name"
                                    class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >
                                    {{ $t('Name') }}
                                    <span class="text-red-500">*</span>
                                </label>
                                <input
                                    id="name"
                                    v-model="form.name"
                                    @input="generateSlug"
                                    type="text"
                                    required
                                    autofocus
                                    class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                    :class="{
                                        'border-red-500': form.errors.name,
                                    }"
                                    :placeholder="$t('e.g. News, Tutorials')"
                                />
                                <p
                                    v-if="form.errors.name"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ form.errors.name }}
                                </p>
                            </div>

                            <!-- Slug -->
                            <div>
                                <label
                                    for="slug"
                                    class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >
                                    {{ $t('URL Slug') }}
                                    <span class="text-red-500">*</span>
                                </label>
                                <div class="flex gap-2">
                                    <input
                                        id="slug"
                                        v-model="form.slug"
                                        type="text"
                                        required
                                        class="flex-1 rounded-lg border border-gray-300 px-3 py-2 font-mono focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                        :class="{
                                            'border-red-500': form.errors.slug,
                                        }"
                                        placeholder="category-slug"
                                    />
                                    <button
                                        type="button"
                                        @click="generateSlug"
                                        class="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300"
                                    >
                                        {{ $t('Generate') }}
                                    </button>
                                </div>
                                <p
                                    v-if="form.errors.slug"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ form.errors.slug }}
                                </p>
                            </div>

                            <!-- Description -->
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
                                    class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                    :placeholder="
                                        $t(
                                            'Optional description for this category',
                                        )
                                    "
                                ></textarea>
                            </div>
                        </div>

                        <!-- SEO -->
                        <div
                            class="space-y-4 rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800"
                        >
                            <h3
                                class="text-lg font-medium text-gray-900 dark:text-white"
                            >
                                {{ $t('SEO Settings') }}
                            </h3>
                            <div>
                                <label
                                    for="meta_title"
                                    class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Meta Title') }}</label
                                >
                                <input
                                    id="meta_title"
                                    v-model="form.meta_title"
                                    type="text"
                                    maxlength="255"
                                    class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                    :placeholder="$t('SEO title')"
                                />
                                <p class="mt-1 text-xs text-gray-500">
                                    {{ form.meta_title?.length || 0 }}/255
                                </p>
                            </div>
                            <div>
                                <label
                                    for="meta_description"
                                    class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Meta Description') }}</label
                                >
                                <textarea
                                    id="meta_description"
                                    v-model="form.meta_description"
                                    rows="2"
                                    maxlength="500"
                                    class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                    :placeholder="
                                        $t(
                                            'Brief description for search results',
                                        )
                                    "
                                ></textarea>
                                <p class="mt-1 text-xs text-gray-500">
                                    {{ form.meta_description?.length || 0 }}/500
                                </p>
                            </div>
                        </div>
                    </div>

                    <!-- Sidebar -->
                    <div class="space-y-6">
                        <div
                            class="space-y-4 rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800"
                        >
                            <h3
                                class="text-base font-medium text-gray-900 dark:text-white"
                            >
                                {{ $t('Settings') }}
                            </h3>
                            <div>
                                <label
                                    for="status"
                                    class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Status') }}</label
                                >
                                <select
                                    id="status"
                                    v-model="form.status"
                                    class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                >
                                    <option value="active">
                                        {{ $t('Active') }}
                                    </option>
                                    <option value="inactive">
                                        {{ $t('Inactive') }}
                                    </option>
                                </select>
                            </div>
                            <div
                                class="border-t border-gray-200 pt-4 dark:border-gray-700"
                            >
                                <button
                                    type="submit"
                                    :disabled="form.processing"
                                    class="w-full rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
                                >
                                    <span v-if="form.processing">{{
                                        $t('Saving...')
                                    }}</span>
                                    <span v-else>{{
                                        $t('Create Category')
                                    }}</span>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </form>
        </div>
    </AdminLayout>
</template>

<script setup lang="ts">
import AdminLayout from '@/layouts/AdminLayout.vue';
import * as categoryRoutes from '@/routes/admin/blog/categories';
import { Head, Link, useForm } from '@inertiajs/vue3';

const form = useForm({
    name: '',
    slug: '',
    description: '',
    status: 'active' as 'active' | 'inactive',
    meta_title: '',
    meta_description: '',
});

function generateSlug() {
    if (form.name) {
        form.slug = form.name
            .toLowerCase()
            .replace(/[^a-z0-9\s-]/g, '')
            .trim()
            .replace(/[\s_-]+/g, '-');
    }
}

function submit() {
    form.post(categoryRoutes.store().url);
}
</script>

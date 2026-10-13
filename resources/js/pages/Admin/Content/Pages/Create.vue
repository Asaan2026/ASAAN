<template>
    <Head :title="$t('Create Page')" />

    <AdminLayout :title="$t('Create Page')">
        <div class="space-y-6 p-6">
            <!-- Page Header -->
            <div class="flex items-center justify-between">
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Create Page') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                        {{ $t('Add a new content page to your store') }}
                    </p>
                </div>
                <Link
                    :href="pageRoutes.index().url"
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
                    {{ $t('Back to Pages') }}
                </Link>
            </div>

            <!-- Form Card -->
            <form
                @submit.prevent="submitForm"
                class="rounded-lg bg-white shadow-sm dark:bg-gray-800"
            >
                <div class="space-y-6 p-6">
                    <!-- Title -->
                    <div>
                        <label
                            for="title"
                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                        >
                            {{ $t('Title') }}
                            <span class="text-red-500">*</span>
                        </label>
                        <input
                            id="title"
                            v-model="form.title"
                            @input="generateSlug"
                            type="text"
                            required
                            class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            :class="{ 'border-red-500': form.errors.title }"
                            :placeholder="$t('Enter page title')"
                        />
                        <p
                            v-if="form.errors.title"
                            class="mt-1 text-sm text-red-600"
                        >
                            {{ form.errors.title }}
                        </p>
                    </div>

                    <!-- URL Key -->
                    <div>
                        <label
                            for="url_key"
                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                        >
                            {{ $t('URL Key') }}
                            <span class="text-red-500">*</span>
                        </label>
                        <div class="flex gap-2">
                            <div class="flex-1">
                                <input
                                    id="url_key"
                                    v-model="form.url_key"
                                    @input="checkSlugAvailability"
                                    type="text"
                                    required
                                    class="w-full rounded-lg border border-gray-300 px-3 py-2 font-mono focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                    :class="{
                                        'border-red-500':
                                            form.errors.url_key ||
                                            !slugAvailable,
                                    }"
                                    placeholder="page-url-key"
                                />
                                <p
                                    v-if="form.errors.url_key"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ form.errors.url_key }}
                                </p>
                                <p
                                    v-else-if="!slugAvailable && form.url_key"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ $t('This URL key is already taken') }}
                                </p>
                                <p
                                    v-else-if="
                                        slugAvailable &&
                                        form.url_key &&
                                        slugChecked
                                    "
                                    class="mt-1 text-sm text-green-600"
                                >
                                    {{ $t('✓ URL key is available') }}
                                </p>
                            </div>
                            <button
                                type="button"
                                @click="generateSlug"
                                class="h-10 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium whitespace-nowrap text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600"
                            >
                                {{ $t('Generate') }}
                            </button>
                        </div>
                        <p
                            class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                        >
                            {{
                                $t(
                                    'Lowercase letters, numbers, and hyphens only. Will be: {url}',
                                    { url: previewUrl },
                                )
                            }}
                        </p>
                    </div>

                    <!-- Content Editor removed — layout is built in the UIEditor after creation -->

                    <!-- SEO Meta Fields -->
                    <div
                        class="border-t border-gray-200 pt-6 dark:border-gray-700"
                    >
                        <h3
                            class="mb-4 text-lg font-medium text-gray-900 dark:text-white"
                        >
                            {{ $t('SEO Settings') }}
                        </h3>

                        <!-- Meta Title -->
                        <div class="mb-4">
                            <label
                                for="meta_title"
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Meta Title') }}
                            </label>
                            <input
                                id="meta_title"
                                v-model="form.meta_title"
                                type="text"
                                maxlength="255"
                                class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                :class="{
                                    'border-red-500': form.errors.meta_title,
                                }"
                                :placeholder="
                                    $t('SEO title for search engines')
                                "
                            />
                            <p
                                v-if="form.errors.meta_title"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ form.errors.meta_title }}
                            </p>
                            <p
                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{
                                    $t(
                                        '{count}/255 characters. Leave empty to use page title.',
                                        { count: form.meta_title?.length || 0 },
                                    )
                                }}
                            </p>
                        </div>

                        <!-- Meta Description -->
                        <div class="mb-4">
                            <label
                                for="meta_description"
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Meta Description') }}
                            </label>
                            <textarea
                                id="meta_description"
                                v-model="form.meta_description"
                                rows="3"
                                maxlength="500"
                                class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                :class="{
                                    'border-red-500':
                                        form.errors.meta_description,
                                }"
                                :placeholder="
                                    $t('Brief description for search results')
                                "
                            ></textarea>
                            <p
                                v-if="form.errors.meta_description"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ form.errors.meta_description }}
                            </p>
                            <p
                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{
                                    $t(
                                        '{count}/500 characters. Recommended: 150-160 characters.',
                                        {
                                            count:
                                                form.meta_description?.length ||
                                                0,
                                        },
                                    )
                                }}
                            </p>
                        </div>

                        <!-- Meta Keywords -->
                        <div>
                            <label
                                for="meta_keywords"
                                class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                            >
                                {{ $t('Meta Keywords') }}
                            </label>
                            <input
                                id="meta_keywords"
                                v-model="form.meta_keywords"
                                type="text"
                                maxlength="500"
                                class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                :class="{
                                    'border-red-500': form.errors.meta_keywords,
                                }"
                                placeholder="keyword1, keyword2, keyword3"
                            />
                            <p
                                v-if="form.errors.meta_keywords"
                                class="mt-1 text-sm text-red-600"
                            >
                                {{ form.errors.meta_keywords }}
                            </p>
                            <p
                                class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                            >
                                {{
                                    $t(
                                        'Comma-separated keywords. Not widely used by search engines anymore.',
                                    )
                                }}
                            </p>
                        </div>
                    </div>

                    <!-- Status -->
                    <div
                        class="border-t border-gray-200 pt-6 dark:border-gray-700"
                    >
                        <label
                            for="status"
                            class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                        >
                            {{ $t('Status') }}
                            <span class="text-red-500">*</span>
                        </label>
                        <select
                            id="status"
                            v-model="form.status"
                            required
                            class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            :class="{ 'border-red-500': form.errors.status }"
                        >
                            <option value="draft">{{ $t('Draft') }}</option>
                            <option value="published">
                                {{ $t('Published') }}
                            </option>
                            <option value="disabled">
                                {{ $t('Disabled') }}
                            </option>
                        </select>
                        <p
                            v-if="form.errors.status"
                            class="mt-1 text-sm text-red-600"
                        >
                            {{ form.errors.status }}
                        </p>
                        <p
                            class="mt-1 text-xs text-gray-500 dark:text-gray-400"
                        >
                            {{
                                $t(
                                    'Draft pages are not visible on storefront. Published pages are live.',
                                )
                            }}
                        </p>
                    </div>
                </div>

                <!-- Form Actions -->
                <div
                    class="flex items-center justify-between rounded-b-lg border-t border-gray-200 bg-gray-50 px-6 py-4 dark:border-gray-600 dark:bg-gray-700"
                >
                    <Link
                        :href="pageRoutes.index().url"
                        class="text-sm font-medium text-gray-700 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white"
                    >
                        {{ $t('Cancel') }}
                    </Link>
                    <div class="flex gap-3">
                        <button
                            type="button"
                            @click="saveDraft"
                            class="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-500 dark:bg-gray-600 dark:text-gray-300 dark:hover:bg-gray-500"
                            :disabled="form.processing"
                        >
                            {{ $t('Save as Draft') }}
                        </button>
                        <button
                            type="submit"
                            class="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
                            :disabled="form.processing || !slugAvailable"
                        >
                            <span v-if="form.processing">{{
                                $t('Saving...')
                            }}</span>
                            <span v-else>{{
                                form.status === 'published'
                                    ? $t('Publish Page')
                                    : $t('Save Page')
                            }}</span>
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </AdminLayout>
</template>

<script setup lang="ts">
import AdminLayout from '@/layouts/AdminLayout.vue';
import * as pageRoutes from '@/routes/admin/content/pages';
import { useI18nStore } from '@/Stores/i18n';
import { Head, Link, useForm } from '@inertiajs/vue3';
import { useDebounceFn } from '@vueuse/core';
import axios from 'axios';
import { computed, ref } from 'vue';

const { t } = useI18nStore();

const form = useForm({
    title: '',
    url_key: '',
    meta_title: '',
    meta_description: '',
    meta_keywords: '',
    status: 'draft',
});

const slugAvailable = ref(true);
const slugChecked = ref(false);

const previewUrl = computed(() => {
    return form.url_key
        ? `${window.location.origin}/${form.url_key}`
        : t('Enter URL key to preview');
});

const generateSlug = () => {
    if (!form.title) return;

    // Convert to lowercase and replace spaces with hyphens
    const slug = form.title
        .toLowerCase()
        .trim()
        .replace(/[^\w\s-]/g, '') // Remove special characters
        .replace(/\s+/g, '-') // Replace spaces with hyphens
        .replace(/-+/g, '-') // Replace multiple hyphens with single hyphen
        .replace(/^-+|-+$/g, ''); // Remove leading and trailing hyphens

    form.url_key = slug;
    checkSlugAvailability();
};

const checkSlugAvailability = useDebounceFn(async () => {
    if (!form.url_key) {
        slugChecked.value = false;
        slugAvailable.value = true;
        return;
    }

    try {
        const response = await axios.post(pageRoutes.checkSlug().url, {
            slug: form.url_key,
        });
        slugAvailable.value = response.data.available;
        slugChecked.value = true;
    } catch (error) {
        console.error('Error checking slug:', error);
        slugAvailable.value = true;
        slugChecked.value = false;
    }
}, 500);

const submitForm = () => {
    if (!slugAvailable.value) return;

    form.post(pageRoutes.store().url, {
        onSuccess: () => {
            // Redirect handled by controller
        },
    });
};

const saveDraft = () => {
    form.status = 'draft';
    submitForm();
};
</script>

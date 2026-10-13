<template>
    <AdminLayout :title="$t('Create Blog Post')">
        <Head :title="$t('Create Blog Post')" />

        <div class="space-y-6 p-6">
            <!-- Header -->
            <div class="flex items-center justify-between">
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Create Blog Post') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                        {{ $t('Write a new article for your blog') }}
                    </p>
                </div>
                <Link
                    :href="blogRoutes.index().url"
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
                    {{ $t('Back to Posts') }}
                </Link>
            </div>

            <form @submit.prevent="submitForm">
                <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
                    <!-- Main Content -->
                    <div class="space-y-6 lg:col-span-2">
                        <div
                            class="space-y-6 rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800"
                        >
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
                                    :class="{
                                        'border-red-500': form.errors.title,
                                    }"
                                    :placeholder="$t('Enter post title')"
                                />
                                <p
                                    v-if="form.errors.title"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ form.errors.title }}
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
                                    <div class="flex-1">
                                        <input
                                            id="slug"
                                            v-model="form.slug"
                                            @input="checkSlugAvailability"
                                            type="text"
                                            required
                                            class="w-full rounded-lg border border-gray-300 px-3 py-2 font-mono focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                            :class="{
                                                'border-red-500':
                                                    form.errors.slug ||
                                                    !slugAvailable,
                                            }"
                                            placeholder="post-url-slug"
                                        />
                                        <p
                                            v-if="form.errors.slug"
                                            class="mt-1 text-sm text-red-600"
                                        >
                                            {{ form.errors.slug }}
                                        </p>
                                        <p
                                            v-else-if="
                                                !slugAvailable && form.slug
                                            "
                                            class="mt-1 text-sm text-red-600"
                                        >
                                            {{
                                                $t('This slug is already taken')
                                            }}
                                        </p>
                                        <p
                                            v-else-if="
                                                slugAvailable &&
                                                form.slug &&
                                                slugChecked
                                            "
                                            class="mt-1 text-sm text-green-600"
                                        >
                                            {{ $t('✓ Slug is available') }}
                                        </p>
                                    </div>
                                    <button
                                        type="button"
                                        @click="generateSlug"
                                        class="h-10 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300"
                                    >
                                        {{ $t('Generate') }}
                                    </button>
                                </div>
                                <p class="mt-1 text-xs text-gray-500">
                                    {{
                                        $t('Preview: {url}', {
                                            url: previewUrl,
                                        })
                                    }}
                                </p>
                            </div>

                            <!-- Excerpt -->
                            <div>
                                <label
                                    for="excerpt"
                                    class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Excerpt') }}</label
                                >
                                <textarea
                                    id="excerpt"
                                    v-model="form.excerpt"
                                    rows="2"
                                    maxlength="500"
                                    class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                    :placeholder="
                                        $t(
                                            'Brief summary shown in post listings (max 500 chars)',
                                        )
                                    "
                                ></textarea>
                                <p class="mt-1 text-xs text-gray-500">
                                    {{
                                        $t('{count}/500 characters', {
                                            count: form.excerpt?.length || 0,
                                        })
                                    }}
                                </p>
                            </div>

                            <!-- Content -->
                            <div>
                                <label
                                    class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                >
                                    {{ $t('Content') }}
                                    <span class="text-red-500">*</span>
                                </label>
                                <TipTapEditor
                                    v-model="form.content"
                                    :placeholder="
                                        $t(
                                            'Write your blog post content here...',
                                        )
                                    "
                                    :show-character-count="true"
                                />
                                <p
                                    v-if="form.errors.content"
                                    class="mt-1 text-sm text-red-600"
                                >
                                    {{ form.errors.content }}
                                </p>
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
                                    :placeholder="
                                        $t('SEO title for search engines')
                                    "
                                />
                                <p class="mt-1 text-xs text-gray-500">
                                    {{
                                        $t('{count}/255 characters', {
                                            count: form.meta_title?.length || 0,
                                        })
                                    }}
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
                                    {{
                                        $t('{count}/500 characters', {
                                            count:
                                                form.meta_description?.length ||
                                                0,
                                        })
                                    }}
                                </p>
                            </div>
                            <div>
                                <label
                                    for="meta_keywords"
                                    class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Meta Keywords') }}</label
                                >
                                <input
                                    id="meta_keywords"
                                    v-model="form.meta_keywords"
                                    type="text"
                                    maxlength="255"
                                    class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                    placeholder="keyword1, keyword2, keyword3"
                                />
                            </div>
                        </div>
                    </div>

                    <!-- Sidebar -->
                    <div class="space-y-6">
                        <!-- Publish Settings -->
                        <div
                            class="space-y-4 rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800"
                        >
                            <h3
                                class="text-base font-medium text-gray-900 dark:text-white"
                            >
                                {{ $t('Publish Settings') }}
                            </h3>
                            <div>
                                <label
                                    for="status"
                                    class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Status') }}
                                    <span class="text-red-500">*</span></label
                                >
                                <select
                                    id="status"
                                    v-model="form.status"
                                    class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                >
                                    <option value="draft">
                                        {{ $t('Draft') }}
                                    </option>
                                    <option value="published">
                                        {{ $t('Published') }}
                                    </option>
                                    <option value="scheduled">
                                        {{ $t('Scheduled') }}
                                    </option>
                                </select>
                            </div>
                            <div v-if="form.status === 'scheduled'">
                                <label
                                    for="published_at"
                                    class="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-300"
                                    >{{ $t('Publish Date') }}</label
                                >
                                <DatePicker
                                    id="published_at"
                                    v-model="form.published_at"
                                    with-time
                                    class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                />
                            </div>
                            <div
                                class="flex flex-col gap-2 border-t border-gray-200 pt-4 dark:border-gray-700"
                            >
                                <button
                                    type="submit"
                                    class="w-full rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
                                    :disabled="
                                        form.processing || !slugAvailable
                                    "
                                >
                                    <span v-if="form.processing">{{
                                        $t('Saving...')
                                    }}</span>
                                    <span v-else>{{
                                        form.status === 'published'
                                            ? $t('Publish Post')
                                            : $t('Save Post')
                                    }}</span>
                                </button>
                                <button
                                    type="button"
                                    @click="saveDraft"
                                    class="w-full rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300"
                                    :disabled="form.processing"
                                >
                                    {{ $t('Save as Draft') }}
                                </button>
                            </div>
                        </div>

                        <!-- Category -->
                        <div
                            class="rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800"
                        >
                            <h3
                                class="mb-4 text-base font-medium text-gray-900 dark:text-white"
                            >
                                {{ $t('Category') }}
                            </h3>
                            <select
                                v-model="form.blog_category_id"
                                class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                            >
                                <option :value="null">
                                    {{ $t('No Category') }}
                                </option>
                                <option
                                    v-for="cat in categories"
                                    :key="cat.id"
                                    :value="cat.id"
                                >
                                    {{ cat.name }}
                                </option>
                            </select>
                        </div>

                        <!-- Featured Image -->
                        <div
                            class="rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800"
                        >
                            <h3
                                class="mb-4 text-base font-medium text-gray-900 dark:text-white"
                            >
                                {{ $t('Featured Image') }}
                            </h3>
                            <div v-if="form.featured_image" class="mb-3">
                                <img
                                    :src="form.featured_image"
                                    :alt="$t('Featured Image')"
                                    class="h-36 w-full rounded-lg object-cover"
                                />
                            </div>
                            <input
                                v-model="form.featured_image"
                                type="text"
                                class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                :placeholder="$t('Enter image URL')"
                            />
                            <p class="mt-1 text-xs text-gray-500">
                                {{
                                    $t(
                                        'Paste a URL or upload via Media Library',
                                    )
                                }}
                            </p>
                        </div>
                    </div>
                </div>
            </form>
        </div>
    </AdminLayout>
</template>

<script setup lang="ts">
import TipTapEditor from '@/components/Admin/CMS/TipTapEditor.vue';
import DatePicker from '@/components/Calendar/DatePicker.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import * as blogRoutes from '@/routes/admin/blog';
import { useI18nStore } from '@/Stores/i18n';
import { Head, Link, useForm } from '@inertiajs/vue3';
import { useDebounceFn } from '@vueuse/core';
import axios from 'axios';
import { computed, ref } from 'vue';

interface Category {
    id: number;
    name: string;
    slug: string;
}

const { t } = useI18nStore();

const props = defineProps<{ categories: Category[] }>();

const form = useForm({
    title: '',
    slug: '',
    excerpt: '',
    content: '',
    featured_image: '',
    status: 'draft' as 'draft' | 'published' | 'scheduled',
    published_at: '',
    blog_category_id: null as number | null,
    meta_title: '',
    meta_description: '',
    meta_keywords: '',
});

const slugAvailable = ref(true);
const slugChecked = ref(false);

const previewUrl = computed(() =>
    form.slug
        ? `${window.location.origin}/blog/${form.slug}`
        : t('Enter slug to preview'),
);

const generateSlug = () => {
    if (!form.title) return;
    form.slug = form.title
        .toLowerCase()
        .trim()
        .replace(/[^\w\s-]/g, '')
        .replace(/\s+/g, '-')
        .replace(/-+/g, '-')
        .replace(/^-+|-+$/g, '');
    checkSlugAvailability();
};

const checkSlugAvailability = useDebounceFn(async () => {
    if (!form.slug) {
        slugChecked.value = false;
        slugAvailable.value = true;
        return;
    }
    try {
        const response = await axios.post(blogRoutes.checkSlug().url, {
            slug: form.slug,
        });
        slugAvailable.value = response.data.available;
        slugChecked.value = true;
    } catch {
        slugAvailable.value = true;
        slugChecked.value = false;
    }
}, 500);

const submitForm = () => {
    if (!slugAvailable.value) return;
    form.post(blogRoutes.store().url);
};

const saveDraft = () => {
    form.status = 'draft';
    submitForm();
};
</script>

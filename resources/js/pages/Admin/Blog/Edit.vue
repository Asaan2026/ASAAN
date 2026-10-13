<template>
    <AdminLayout :title="$t('Edit Blog Post')">
        <Head :title="$t('Edit: {title}', { title: post.title })" />

        <div class="space-y-6 p-6">
            <!-- Header -->
            <div class="flex items-center justify-between">
                <div>
                    <h1
                        class="text-2xl font-bold text-gray-900 dark:text-white"
                    >
                        {{ $t('Edit Blog Post') }}
                    </h1>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
                        {{ post.title }}
                    </p>
                </div>
                <div class="flex gap-2">
                    <a
                        :href="`/blog/${post.slug}`"
                        target="_blank"
                        class="flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300"
                    >
                        <ExternalLink class="h-4 w-4" />
                        {{ $t('View Post') }}
                    </a>
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
            </div>

            <!-- Flash messages -->
            <div
                v-if="$page.props.flash?.success"
                class="rounded-lg border border-green-200 bg-green-50 p-4 text-sm text-green-800 dark:border-green-800 dark:bg-green-900/20 dark:text-green-300"
            >
                {{ $page.props.flash.success }}
            </div>
            <div
                v-if="$page.props.flash?.error"
                class="rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-800 dark:border-red-800 dark:bg-red-900/20 dark:text-red-300"
            >
                {{ $page.props.flash.error }}
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
                                    type="text"
                                    required
                                    class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:border-transparent focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                    :class="{
                                        'border-red-500': form.errors.title,
                                    }"
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
                                                slugAvailable && slugChecked
                                            "
                                            class="mt-1 text-sm text-green-600"
                                        >
                                            {{ $t('✓ Slug is available') }}
                                        </p>
                                    </div>
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
                                />
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
                                ></textarea>
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
                                    >{{ $t('Status') }}</label
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
                                    <span v-else>{{ $t('Save Changes') }}</span>
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
                        </div>

                        <!-- Post Info -->
                        <div
                            class="rounded-lg bg-white p-6 shadow-sm dark:bg-gray-800"
                        >
                            <h3
                                class="mb-4 text-base font-medium text-gray-900 dark:text-white"
                            >
                                {{ $t('Post Info') }}
                            </h3>
                            <dl class="space-y-2 text-sm">
                                <div class="flex justify-between">
                                    <dt class="text-gray-500">
                                        {{ $t('Views') }}
                                    </dt>
                                    <dd
                                        class="font-medium text-gray-900 dark:text-white"
                                    >
                                        {{ post.view_count }}
                                    </dd>
                                </div>
                                <div class="flex justify-between">
                                    <dt class="text-gray-500">
                                        {{ $t('Created') }}
                                    </dt>
                                    <dd class="text-gray-900 dark:text-white">
                                        <DateDisplay :value="post.created_at" />
                                    </dd>
                                </div>
                                <div
                                    v-if="post.creator"
                                    class="flex justify-between"
                                >
                                    <dt class="text-gray-500">
                                        {{ $t('Author') }}
                                    </dt>
                                    <dd class="text-gray-900 dark:text-white">
                                        {{ post.creator.name }}
                                    </dd>
                                </div>
                            </dl>
                        </div>

                        <!-- Danger Zone -->
                        <div
                            class="rounded-lg border border-red-200 bg-white p-6 shadow-sm dark:border-red-800/50 dark:bg-gray-800"
                        >
                            <h3
                                class="mb-4 text-base font-medium text-red-700 dark:text-red-400"
                            >
                                {{ $t('Danger Zone') }}
                            </h3>
                            <button
                                type="button"
                                @click="deletePost"
                                class="w-full rounded-lg border border-red-200 bg-red-50 px-4 py-2 text-sm font-medium text-red-700 transition-colors hover:bg-red-100 dark:border-red-800 dark:bg-red-900/20 dark:text-red-400"
                            >
                                {{ $t('Delete Post') }}
                            </button>
                        </div>
                    </div>
                </div>
            </form>
        </div>
    </AdminLayout>
</template>

<script setup lang="ts">
import TipTapEditor from '@/components/Admin/CMS/TipTapEditor.vue';
import DateDisplay from '@/components/Calendar/DateDisplay.vue';
import DatePicker from '@/components/Calendar/DatePicker.vue';
import AdminLayout from '@/layouts/AdminLayout.vue';
import * as blogRoutes from '@/routes/admin/blog';
import { Head, Link, router, useForm } from '@inertiajs/vue3';
import { useDebounceFn } from '@vueuse/core';
import axios from 'axios';
import { ExternalLink } from 'lucide-vue-next';
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
    excerpt: string;
    content: string;
    featured_image: string;
    status: string;
    published_at: string | null;
    blog_category_id: number | null;
    meta_title: string;
    meta_description: string;
    meta_keywords: string;
    view_count: number;
    created_at: string;
    creator: { name: string } | null;
}

const props = defineProps<{ post: Post; categories: Category[] }>();

const form = useForm({
    title: props.post.title,
    slug: props.post.slug,
    excerpt: props.post.excerpt || '',
    content: props.post.content || '',
    featured_image: props.post.featured_image || '',
    status: props.post.status as 'draft' | 'published' | 'scheduled',
    published_at: props.post.published_at
        ? new Date(props.post.published_at).toISOString().slice(0, 16)
        : '',
    blog_category_id: props.post.blog_category_id,
    meta_title: props.post.meta_title || '',
    meta_description: props.post.meta_description || '',
    meta_keywords: props.post.meta_keywords || '',
});

const slugAvailable = ref(true);
const slugChecked = ref(false);

const previewUrl = computed(() =>
    form.slug ? `${window.location.origin}/blog/${form.slug}` : '',
);

const checkSlugAvailability = useDebounceFn(async () => {
    if (!form.slug || form.slug === props.post.slug) {
        slugAvailable.value = true;
        slugChecked.value = false;
        return;
    }
    try {
        const response = await axios.post(blogRoutes.checkSlug().url, {
            slug: form.slug,
            exclude_id: props.post.id,
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
    form.put(blogRoutes.update({ post: props.post.slug }).url);
};

const deletePost = () => {
    if (!confirm(`Are you sure you want to delete "${props.post.title}"?`))
        return;
    router.delete(blogRoutes.destroy({ post: props.post.slug }).url);
};
</script>

<script setup lang="ts">
import axios from 'axios';
import { onMounted, ref } from 'vue';

const props = defineProps<{
    settings: Record<string, unknown>;
    editorMode?: boolean;
}>();

interface BlogPost {
    id: number;
    title: string;
    slug: string;
    featured_image: string | null;
    published_at: string;
    category: { id: number; name: string } | null;
}

const posts = ref<BlogPost[]>([]);
const loading = ref(false);
const scrollEl = ref<HTMLElement | null>(null);

const formatDate = (date: string) =>
    new Date(date).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
    });

const scrollLeft = () =>
    scrollEl.value?.scrollBy({ left: -320, behavior: 'smooth' });
const scrollRight = () =>
    scrollEl.value?.scrollBy({ left: 320, behavior: 'smooth' });

onMounted(async () => {
    if (props.editorMode) return;
    loading.value = true;
    try {
        const params: Record<string, unknown> = {
            limit: props.settings.count ?? 6,
        };
        if (props.settings.category_id)
            params.category_id = props.settings.category_id;
        const { data } = await axios.get('/api/blog/posts', { params });
        posts.value = data.data ?? data;
    } catch {
        // silently fail
    } finally {
        loading.value = false;
    }
});
</script>

<template>
    <div class="w-full">
        <div class="mb-6 flex items-center justify-between">
            <h2
                v-if="settings.title"
                class="text-2xl font-bold text-gray-900 dark:text-white"
            >
                {{ settings.title }}
            </h2>
            <div v-if="!editorMode && posts.length" class="flex gap-2">
                <button
                    class="rounded-full border border-gray-200 p-2 transition-colors hover:bg-gray-100 dark:border-gray-700 dark:hover:bg-gray-700"
                    @click="scrollLeft"
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
                            d="M15 19l-7-7 7-7"
                        />
                    </svg>
                </button>
                <button
                    class="rounded-full border border-gray-200 p-2 transition-colors hover:bg-gray-100 dark:border-gray-700 dark:hover:bg-gray-700"
                    @click="scrollRight"
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
                            d="M9 5l7 7-7 7"
                        />
                    </svg>
                </button>
            </div>
        </div>

        <!-- Loading -->
        <div v-if="loading" class="flex gap-5 overflow-hidden">
            <div
                v-for="n in settings.count ?? 6"
                :key="n"
                class="h-72 w-64 flex-shrink-0 animate-pulse rounded-xl bg-gray-100 dark:bg-gray-800"
            />
        </div>

        <!-- Carousel -->
        <div
            v-else-if="posts.length"
            ref="scrollEl"
            class="flex snap-x snap-mandatory gap-5 overflow-x-auto scroll-smooth pb-4"
            style="
                -webkit-overflow-scrolling: touch;
                scrollbar-width: none;
                -ms-overflow-style: none;
            "
        >
            <article
                v-for="post in posts"
                :key="post.id"
                class="group w-64 flex-shrink-0 snap-start overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm transition-shadow hover:shadow-md dark:border-gray-700 dark:bg-gray-800"
            >
                <a :href="`/blog/${post.slug}`">
                    <div
                        class="h-40 overflow-hidden bg-gray-100 dark:bg-gray-700"
                    >
                        <img
                            v-if="post.featured_image"
                            :src="post.featured_image"
                            :alt="post.title"
                            class="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
                        />
                        <div
                            v-else
                            class="flex h-full w-full items-center justify-center text-gray-300"
                        >
                            <svg
                                class="h-8 w-8"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="1.5"
                                    d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 12h6m-6-4h6"
                                />
                            </svg>
                        </div>
                    </div>
                </a>
                <div class="p-4">
                    <div
                        v-if="settings.show_category && post.category"
                        class="mb-2"
                    >
                        <a
                            :href="`/blog?category_id=${post.category.id}`"
                            class="text-xs font-semibold tracking-wide text-blue-600 uppercase hover:underline dark:text-blue-400"
                        >
                            {{ post.category.name }}
                        </a>
                    </div>
                    <h3
                        class="mb-2 line-clamp-2 text-sm font-semibold text-gray-900 transition-colors group-hover:text-blue-600 dark:text-white"
                    >
                        <a :href="`/blog/${post.slug}`">{{ post.title }}</a>
                    </h3>
                    <span
                        v-if="settings.show_date"
                        class="text-xs text-gray-400"
                    >
                        {{ formatDate(post.published_at) }}
                    </span>
                </div>
            </article>
        </div>

        <!-- Editor placeholder -->
        <div v-else-if="editorMode" class="flex gap-5 overflow-hidden">
            <div
                v-for="n in settings.count ?? 6"
                :key="n"
                class="flex h-64 w-64 flex-shrink-0 items-center justify-center rounded-xl border-2 border-dashed border-gray-200 bg-gray-50 text-sm text-gray-400 dark:border-gray-700 dark:bg-gray-800"
            >
                Post {{ n }}
            </div>
        </div>

        <!-- No posts -->
        <div v-else class="py-12 text-center text-gray-400">
            <p>No posts found.</p>
        </div>
    </div>
</template>

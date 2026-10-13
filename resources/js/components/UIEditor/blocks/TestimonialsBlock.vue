<script setup lang="ts">
defineProps<{ settings: Record<string, unknown>; editorMode?: boolean }>();

interface TestimonialItem {
    author: string;
    avatar: string | null;
    text: string;
    rating: number;
}
</script>

<template>
    <div class="grid grid-cols-1 gap-6 py-2 md:grid-cols-2 lg:grid-cols-3">
        <div
            v-for="(item, i) in (settings.items as TestimonialItem[]) ?? []"
            :key="i"
            class="rounded-xl border border-gray-100 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
        >
            <!-- Stars -->
            <div class="mb-3 flex gap-0.5">
                <svg
                    v-for="star in 5"
                    :key="star"
                    class="h-4 w-4"
                    :class="
                        star <= item.rating
                            ? 'text-yellow-400'
                            : 'text-gray-200 dark:text-gray-600'
                    "
                    fill="currentColor"
                    viewBox="0 0 20 20"
                >
                    <path
                        d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"
                    />
                </svg>
            </div>
            <p
                class="mb-4 text-sm leading-relaxed text-gray-600 dark:text-gray-300"
            >
                "{{ item.text }}"
            </p>
            <div class="flex items-center gap-3">
                <div
                    class="flex h-8 w-8 flex-shrink-0 items-center justify-center overflow-hidden rounded-full bg-blue-100 dark:bg-blue-900"
                >
                    <img
                        v-if="item.avatar"
                        :src="item.avatar"
                        :alt="item.author"
                        class="h-full w-full object-cover"
                    />
                    <span
                        v-else
                        class="text-xs font-bold text-blue-600 dark:text-blue-400"
                        >{{ item.author[0] }}</span
                    >
                </div>
                <span
                    class="text-sm font-semibold text-gray-900 dark:text-white"
                    >{{ item.author }}</span
                >
            </div>
        </div>
        <!-- Editor placeholder -->
        <div
            v-if="editorMode && !(settings.items as unknown[])?.length"
            class="col-span-3 flex h-32 items-center justify-center rounded-xl border-2 border-dashed border-gray-300 text-sm text-gray-400 dark:border-gray-600"
        >
            Add testimonials in settings panel
        </div>
    </div>
</template>

<script setup lang="ts">
import { Link } from '@inertiajs/vue3';
import { computed } from 'vue';

interface PaginationLink {
    url: string | null;
    label: string;
    active: boolean;
}

interface PaginationData {
    current_page: number;
    last_page: number;
    from: number | null;
    to: number | null;
    total: number;
    per_page: number;
    links?: PaginationLink[];
}

interface Props {
    data: PaginationData;
    resourceName?: string;
    preserveState?: boolean;
    preserveScroll?: boolean;
    onlyQueryString?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
    resourceName: 'items',
    preserveState: true,
    preserveScroll: true,
    onlyQueryString: false, // Force full reload to ensure menu state refreshes
});

const emit = defineEmits<{
    pageChange: [page: number];
}>();

// Generate page numbers with ellipsis logic
const pageNumbers = computed(() => {
    const pages: Array<number | 'ellipsis-start' | 'ellipsis-end'> = [];
    const current = props.data.current_page;
    const last = props.data.last_page;
    const delta = 2; // Number of pages to show on each side of current page

    for (let i = 1; i <= last; i++) {
        // Always show first page, last page, and pages near current
        if (
            i === 1 ||
            i === last ||
            (i >= current - delta && i <= current + delta)
        ) {
            pages.push(i);
        } else if (
            pages[pages.length - 1] !== 'ellipsis-start' &&
            i < current
        ) {
            pages.push('ellipsis-start');
        } else if (pages[pages.length - 1] !== 'ellipsis-end' && i > current) {
            pages.push('ellipsis-end');
        }
    }

    return pages;
});

const previousUrl = computed(() => {
    if (props.data.current_page <= 1) return null;
    return props.data.links?.[0]?.url || null;
});

const nextUrl = computed(() => {
    if (props.data.current_page >= props.data.last_page) return null;
    return props.data.links?.[props.data.links.length - 1]?.url || null;
});

const getPageUrl = (page: number) => {
    if (!props.data.links) return null;

    // Find the link for this page
    const link = props.data.links.find((l) => {
        const label = l.label.replace(/&laquo;|&raquo;/g, '').trim();
        return label === page.toString();
    });

    return link?.url || null;
};

const handlePageClick = (page: number, url: string | null) => {
    if (url) {
        emit('pageChange', page);
    }
};
</script>

<template>
    <div
        v-if="data.last_page > 1"
        class="flex items-center justify-between border-t border-gray-200 bg-white px-4 py-3 sm:px-6 dark:border-gray-700 dark:bg-gray-800"
    >
        <!-- Mobile Pagination -->
        <div class="flex flex-1 justify-between sm:hidden">
            <Link
                v-if="previousUrl"
                :href="previousUrl"
                :preserve-state="preserveState"
                :preserve-scroll="preserveScroll"
                :only="onlyQueryString ? ['data'] : undefined"
                class="relative inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600"
            >
                {{ $t('Previous') }}
            </Link>
            <span
                v-else
                class="relative inline-flex cursor-not-allowed items-center rounded-md border border-gray-300 bg-gray-50 px-4 py-2 text-sm font-medium text-gray-400 dark:border-gray-600 dark:bg-gray-800/50 dark:text-gray-500"
            >
                {{ $t('Previous') }}
            </span>

            <Link
                v-if="nextUrl"
                :href="nextUrl"
                :preserve-state="preserveState"
                :preserve-scroll="preserveScroll"
                :only="onlyQueryString ? ['data'] : undefined"
                class="relative ml-3 inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600"
            >
                {{ $t('Next') }}
            </Link>
            <span
                v-else
                class="relative ml-3 inline-flex cursor-not-allowed items-center rounded-md border border-gray-300 bg-gray-50 px-4 py-2 text-sm font-medium text-gray-400 dark:border-gray-600 dark:bg-gray-800/50 dark:text-gray-500"
            >
                {{ $t('Next') }}
            </span>
        </div>

        <!-- Desktop Pagination -->
        <div
            class="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between"
        >
            <div>
                <p class="text-sm text-gray-700 dark:text-gray-300">
                    {{ $t('Showing') }}
                    <span class="font-medium">{{ data.from || 0 }}</span>
                    {{ $t('to') }}
                    <span class="font-medium">{{ data.to || 0 }}</span>
                    {{ $t('of') }}
                    <span class="font-medium">{{ data.total }}</span>
                    {{ resourceName }}
                </p>
            </div>

            <div>
                <nav
                    class="relative z-0 inline-flex -space-x-px rounded-md shadow-sm"
                    :aria-label="$t('Pagination')"
                >
                    <!-- Previous Button -->
                    <Link
                        v-if="previousUrl"
                        :href="previousUrl"
                        :preserve-state="preserveState"
                        :preserve-scroll="preserveScroll"
                        :only="onlyQueryString ? ['data'] : undefined"
                        class="relative inline-flex items-center rounded-l-md border border-gray-300 bg-white px-2 py-2 text-sm font-medium text-gray-500 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-400 dark:hover:bg-gray-600"
                        :aria-label="$t('Previous page')"
                    >
                        <svg
                            class="h-5 w-5"
                            fill="currentColor"
                            viewBox="0 0 20 20"
                            aria-hidden="true"
                        >
                            <path
                                fill-rule="evenodd"
                                d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z"
                                clip-rule="evenodd"
                            />
                        </svg>
                    </Link>
                    <span
                        v-else
                        class="relative inline-flex cursor-not-allowed items-center rounded-l-md border border-gray-300 bg-gray-50 px-2 py-2 text-sm font-medium text-gray-300 dark:border-gray-600 dark:bg-gray-800/50 dark:text-gray-600"
                        :aria-label="$t('Previous page')"
                    >
                        <svg
                            class="h-5 w-5"
                            fill="currentColor"
                            viewBox="0 0 20 20"
                            aria-hidden="true"
                        >
                            <path
                                fill-rule="evenodd"
                                d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z"
                                clip-rule="evenodd"
                            />
                        </svg>
                    </span>

                    <!-- Page Numbers -->
                    <template
                        v-for="(page, index) in pageNumbers"
                        :key="`page-${index}`"
                    >
                        <!-- Page Number Button -->
                        <Link
                            v-if="typeof page === 'number'"
                            :href="getPageUrl(page) || '#'"
                            :preserve-state="preserveState"
                            :preserve-scroll="preserveScroll"
                            :only="onlyQueryString ? ['data'] : undefined"
                            @click="handlePageClick(page, getPageUrl(page))"
                            class="relative inline-flex items-center border px-4 py-2 text-sm font-medium transition-colors"
                            :class="{
                                'z-10 border-blue-500 bg-blue-50 text-blue-600 dark:border-blue-500 dark:bg-blue-900/30 dark:text-blue-400':
                                    page === data.current_page,
                                'border-gray-300 bg-white text-gray-500 hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-400 dark:hover:bg-gray-600':
                                    page !== data.current_page,
                            }"
                            :aria-label="$t('Page {page}', { page })"
                            :aria-current="
                                page === data.current_page ? 'page' : undefined
                            "
                        >
                            {{ page }}
                        </Link>

                        <!-- Ellipsis -->
                        <span
                            v-else
                            class="relative inline-flex items-center border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300"
                        >
                            ...
                        </span>
                    </template>

                    <!-- Next Button -->
                    <Link
                        v-if="nextUrl"
                        :href="nextUrl"
                        :preserve-state="preserveState"
                        :preserve-scroll="preserveScroll"
                        :only="onlyQueryString ? ['data'] : undefined"
                        class="relative inline-flex items-center rounded-r-md border border-gray-300 bg-white px-2 py-2 text-sm font-medium text-gray-500 transition-colors hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-700 dark:text-gray-400 dark:hover:bg-gray-600"
                        :aria-label="$t('Next page')"
                    >
                        <svg
                            class="h-5 w-5"
                            fill="currentColor"
                            viewBox="0 0 20 20"
                            aria-hidden="true"
                        >
                            <path
                                fill-rule="evenodd"
                                d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                                clip-rule="evenodd"
                            />
                        </svg>
                    </Link>
                    <span
                        v-else
                        class="relative inline-flex cursor-not-allowed items-center rounded-r-md border border-gray-300 bg-gray-50 px-2 py-2 text-sm font-medium text-gray-300 dark:border-gray-600 dark:bg-gray-800/50 dark:text-gray-600"
                        :aria-label="$t('Next page')"
                    >
                        <svg
                            class="h-5 w-5"
                            fill="currentColor"
                            viewBox="0 0 20 20"
                            aria-hidden="true"
                        >
                            <path
                                fill-rule="evenodd"
                                d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                                clip-rule="evenodd"
                            />
                        </svg>
                    </span>
                </nav>
            </div>
        </div>
    </div>
</template>
